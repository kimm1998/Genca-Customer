codeunit 80132 "NuOrder Price API Mgt."
{
    var
        ProductIdCache: Dictionary of [Text, Text];
        ProductDataCache: Dictionary of [Text, JsonObject];

    procedure ProcessAllPending()
    var
        Buffer: Record "NuOrder Price Buffer";
        LastTemplate: Code[20];
    begin
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::New, Buffer.Status::"Needs Sync");
        Buffer.SetCurrentKey("Price List Code", "Item No.", "Color Code", "Season Code", "Currency Code");
        if not Buffer.FindSet() then
            exit;

        LastTemplate := '';
        repeat
            if Buffer."Price List Code" <> LastTemplate then begin
                // Clear cache for each template
                Clear(ProductIdCache);
                Clear(ProductDataCache);
                ProcessTemplate(Buffer."Price List Code");
                LastTemplate := Buffer."Price List Code";
            end;
        until Buffer.Next() = 0;
    end;

    procedure ProcessTemplate(TemplateCode: Code[20])
    var
        Setup: Record "NuORDER Setup";
        AuthMgt: Codeunit "NuORDER Auth Mgt";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        Url: Text;
        PayloadTxt: Text;
        RespTxt: Text;
        AuthorizationHeader: Text;
    begin
        Setup.Get();
        Setup.TestField(Enabled, true);

        // Build payload with resolved product IDs
        PayloadTxt := BuildPayloadWithResolvedIds(TemplateCode);
        if PayloadTxt = '' then
            exit;

        // Build URL: https://{env}.nuorder.com/api/pricesheet/{template}
        Url := AuthMgt.GetPriceSheetURL() + '/' + TemplateCode;

        // Get OAuth authorization header
        AuthorizationHeader := AuthMgt.GetApiAuthorizationHeader(Setup, 'POST', Url);

        Content.WriteFrom(PayloadTxt);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        Request.Method := 'POST';
        Request.SetRequestUri(Url);
        Request.Content := Content;

        Request.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', AuthorizationHeader);
        RequestHeaders.Add('Accept', 'application/json');

        if not Client.Send(Request, Response) then
            Error('NuORDER pricesheet call failed.');

        Response.Content.ReadAs(RespTxt);

        if Response.IsSuccessStatusCode() then
            MarkTemplateAsSynced(TemplateCode, Format(Response.HttpStatusCode()), RespTxt)
        else
            MarkTemplateAsError(TemplateCode, Format(Response.HttpStatusCode()), RespTxt);
    end;

    local procedure BuildPayloadWithResolvedIds(TemplateCode: Code[20]): Text
    var
        Buffer: Record "NuOrder Price Buffer";
        PayloadMgt: Codeunit "NuOrder Price Payload Mgt.";
        Root: JsonObject;
        PricingArr: JsonArray;
        PricingObj: JsonObject;
        SizesArr: JsonArray;
        LastGroupKey: Text;
        GroupKey: Text;
        CurrentItemNo: Code[20];
        CurrentColor: Code[20];
        CurrentSeason: Code[20];
        CurrentCurrency: Code[10];
        PayloadTxt: Text;
        ProductId: Text;
        ProductColor: Text;
        ProductSeason: Text;
        BrandId: Text;
    begin
        Buffer.SetRange("Price List Code", TemplateCode);
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::New, Buffer.Status::"Needs Sync");
        Buffer.SetCurrentKey("Price List Code", "Item No.", "Color Code", "Season Code", "Currency Code");
        if not Buffer.FindSet() then
            exit('');

        LastGroupKey := '';
        repeat
            GroupKey := StrSubstNo('%1|%2|%3|%4', Buffer."Item No.", Buffer."Color Code", Buffer."Season Code", Buffer."Currency Code");
            if GroupKey <> LastGroupKey then begin
                if LastGroupKey <> '' then begin
                    PricingObj.Add('sizes', SizesArr);
                    PricingArr.Add(PricingObj);
                end;

                Clear(PricingObj);
                Clear(SizesArr);

                CurrentItemNo := Buffer."Item No.";
                CurrentColor := Buffer."Color Code";
                CurrentSeason := Buffer."Season Code";
                CurrentCurrency := Buffer."Currency Code";

                // Build brand_id and resolve product data from NuOrder API
                BrandId := StrSubstNo('%1_%2', CurrentItemNo, CurrentColor);
                ResolveProductFromApi(BrandId, ProductId, ProductColor, ProductSeason);

                PricingObj.Add('_id', ProductId);
                PricingObj.Add('style_number', CurrentItemNo);
                PricingObj.Add('season', ProductSeason);
                PricingObj.Add('color', ProductColor);
                PricingObj.Add('template', TemplateCode);
                PricingObj.Add('wholesale', 0);
                PricingObj.Add('retail', 0);
                PricingObj.Add('disabled', false);

                // Add sizes for this group
                AddSizesForGroup(SizesArr, TemplateCode, CurrentItemNo, CurrentColor, CurrentCurrency);

                LastGroupKey := GroupKey;
            end;
        until Buffer.Next() = 0;

        if LastGroupKey <> '' then begin
            PricingObj.Add('sizes', SizesArr);
            PricingArr.Add(PricingObj);
        end;

        Root.Add('currency_code', CurrentCurrency);
        Root.Add('pricing', PricingArr);
        Root.WriteTo(PayloadTxt);
        exit(PayloadTxt);
    end;

    local procedure ResolveProductFromApi(BrandId: Text; var ProductId: Text; var ProductColor: Text; var ProductSeason: Text)
    var
        Setup: Record "NuORDER Setup";
        AuthMgt: Codeunit "NuORDER Auth Mgt";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        Url: Text;
        ResponseTxt: Text;
        AuthorizationHeader: Text;
        JObj: JsonObject;
        JToken: JsonToken;
        ProductData: JsonObject;
    begin
        // Check cache first
        if ProductIdCache.ContainsKey(BrandId) then begin
            ProductId := ProductIdCache.Get(BrandId);
            if ProductDataCache.ContainsKey(BrandId) then begin
                ProductData := ProductDataCache.Get(BrandId);
                if ProductData.Get('color_code', JToken) then
                    ProductColor := JToken.AsValue().AsText();
                if ProductData.Get('season', JToken) then
                    ProductSeason := JToken.AsValue().AsText();
            end;
            exit;
        end;

        Setup.Get();
        Setup.TestField(Enabled, true);

        // Build URL: https://{env}.nuorder.com/api/product/external_id/{brand_id}
        Url := GetProductExternalIdUrl(BrandId);

        // Get OAuth authorization header
        AuthorizationHeader := AuthMgt.GetApiAuthorizationHeader(Setup, 'GET', Url);

        Request.Method := 'GET';
        Request.SetRequestUri(Url);

        Request.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', AuthorizationHeader);
        RequestHeaders.Add('Accept', 'application/json');

        if not Client.Send(Request, Response) then
            Error('NuORDER product lookup failed for brand_id: %1', BrandId);

        Response.Content.ReadAs(ResponseTxt);

        if not Response.IsSuccessStatusCode() then
            Error('NuORDER product lookup failed.\Status Code: %1\Response: %2\Brand ID: %3',
                Response.HttpStatusCode(), ResponseTxt, BrandId);

        // Parse response
        if not JObj.ReadFrom(ResponseTxt) then
            Error('Invalid JSON response from product lookup: %1', ResponseTxt);

        // Extract _id
        if JObj.Get('_id', JToken) then
            ProductId := JToken.AsValue().AsText()
        else
            Error('Product _id not found in response for brand_id: %1', BrandId);

        // Extract color_code
        if JObj.Get('color_code', JToken) then
            ProductColor := JToken.AsValue().AsText()
        else
            ProductColor := '';

        // Extract season
        if JObj.Get('season', JToken) then
            ProductSeason := JToken.AsValue().AsText()
        else
            ProductSeason := '';

        // Cache the results
        ProductIdCache.Add(BrandId, ProductId);
        ProductDataCache.Add(BrandId, JObj);
    end;

    local procedure GetProductExternalIdUrl(BrandId: Text): Text
    var
        Setup: Record "NuORDER Setup";
        AuthMgt: Codeunit "NuORDER Auth Mgt";
        BaseUrl: Text;
    begin
        Setup.Get();
        BaseUrl := StrSubstNo(Setup."Base URL", Setup.Env);
        exit(BaseUrl.TrimEnd('/') + '/api/product/external_id/' + BrandId);
    end;

    local procedure AddSizesForGroup(var SizesArr: JsonArray; PriceListCode: Code[20]; ItemNo: Code[20]; ColorCode: Code[20]; CurrencyCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
        PriceListLine: Record "Price List Line";
        SizeObj: JsonObject;
        UnitPrice: Decimal;
        ProcessedSizes: Dictionary of [Code[20], Boolean];
    begin
        ItemVariant.SetRange("Item No.", ItemNo);
        ItemVariant.SetRange("K3PFColor Code", ColorCode);
        if ItemVariant.FindSet() then
            repeat
                // Skip if we already processed this size code
                if not ProcessedSizes.ContainsKey(ItemVariant."K3PFSize Code") then begin
                    UnitPrice := 0;
                    PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
                    PriceListLine.SetRange("Asset No.", ItemNo);
                    PriceListLine.SetRange("Variant Code", ItemVariant.Code);
                    PriceListLine.SetRange("Price List Code", PriceListCode);
                    PriceListLine.SetRange("Currency Code", CurrencyCode);
                    if PriceListLine.FindFirst() then
                        UnitPrice := PriceListLine."Unit Price";

                    Clear(SizeObj);
                    SizeObj.Add('size', ItemVariant."K3PFSize Code");
                    SizeObj.Add('wholesale', Format(UnitPrice, 0, 9));
                    SizeObj.Add('retail', '0');
                    SizesArr.Add(SizeObj);

                    ProcessedSizes.Add(ItemVariant."K3PFSize Code", true);
                end;
            until ItemVariant.Next() = 0;
    end;

    local procedure MarkTemplateAsSynced(TemplateCode: Code[20]; HttpStatus: Text; ResponseTxt: Text)
    var
        Buffer: Record "NuOrder Price Buffer";
    begin
        Buffer.SetRange("Price List Code", TemplateCode);
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::New, Buffer.Status::"Needs Sync");
        if Buffer.FindSet() then
            repeat
                Buffer.Status := Buffer.Status::Synced;
                Buffer."Last Http Status" := HttpStatus;
                Buffer."Last Http Response" := CopyStr(ResponseTxt, 1, MaxStrLen(Buffer."Last Http Response"));
                Buffer."Last Error" := '';
                Buffer."Modified At" := CurrentDateTime;
                Buffer.Modify();
            until Buffer.Next() = 0;
    end;

    local procedure MarkTemplateAsError(TemplateCode: Code[20]; HttpStatus: Text; ResponseTxt: Text)
    var
        Buffer: Record "NuOrder Price Buffer";
    begin
        Buffer.SetRange("Price List Code", TemplateCode);
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::New, Buffer.Status::"Needs Sync");
        if Buffer.FindSet() then
            repeat
                Buffer.Status := Buffer.Status::Error;
                Buffer."Last Http Status" := HttpStatus;
                Buffer."Last Http Response" := CopyStr(ResponseTxt, 1, MaxStrLen(Buffer."Last Http Response"));
                Buffer."Last Error" := CopyStr(ResponseTxt, 1, MaxStrLen(Buffer."Last Error"));
                Buffer."Modified At" := CurrentDateTime;
                Buffer.Modify();
            until Buffer.Next() = 0;
    end;
}