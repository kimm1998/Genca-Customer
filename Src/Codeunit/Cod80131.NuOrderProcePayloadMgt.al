codeunit 80131 "NuOrder Price Payload Mgt."
{
    var
        ProductIdCache: Dictionary of [Text, Text];
        ProductDataCache: Dictionary of [Text, JsonObject];

    procedure BuildPriceSheetPayload(PriceListCode: Code[20]; var ProductIdCacheParam: Dictionary of [Text, Text]; var ProductDataCacheParam: Dictionary of [Text, JsonObject]): Text
    var
        Buffer: Record "NuOrder Price Buffer";
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
    begin
        ProductIdCache := ProductIdCacheParam;
        ProductDataCache := ProductDataCacheParam;

        Buffer.SetRange("Price List Code", PriceListCode);
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

                // Resolve product ID and data from NuOrder API
                ResolveNuOrderProductData(CurrentItemNo, CurrentColor, ProductId, ProductColor, ProductSeason);

                PricingObj.Add('_id', ProductId);
                PricingObj.Add('style_number', CurrentItemNo);
                PricingObj.Add('season', ProductSeason);
                PricingObj.Add('color', ProductColor);
                PricingObj.Add('template', PriceListCode);
                PricingObj.Add('wholesale', 0);
                PricingObj.Add('retail', 0);
                PricingObj.Add('disabled', false);

                // Add sizes for this group
                AddSizesForGroup(SizesArr, PriceListCode, CurrentItemNo, CurrentColor, CurrentCurrency);

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

        // Return updated caches
        ProductIdCacheParam := ProductIdCache;
        ProductDataCacheParam := ProductDataCache;

        exit(PayloadTxt);
    end;

    local procedure AddSizesForGroup(var SizesArr: JsonArray; PriceListCode: Code[20]; ItemNo: Code[20]; ColorCode: Code[20]; CurrencyCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
        PriceListLine: Record "Price List Line";
        SizeObj: JsonObject;
        UnitPrice: Decimal;
        ProcessedVariants: Dictionary of [Code[20], Boolean];
    begin
        ItemVariant.SetRange("Item No.", ItemNo);
        ItemVariant.SetRange("K3PFColor Code", ColorCode);
        if ItemVariant.FindSet() then
            repeat
                // Skip if we already processed this size code for this color
                if not ProcessedVariants.ContainsKey(ItemVariant."K3PFSize Code") then begin
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

                    ProcessedVariants.Add(ItemVariant."K3PFSize Code", true);
                end;
            until ItemVariant.Next() = 0;
    end;

    local procedure ResolveNuOrderProductData(ItemNo: Code[20]; ColorCode: Code[20]; var ProductId: Text; var ProductColor: Text; var ProductSeason: Text)
    var
        BrandId: Text;
        ProductData: JsonObject;
        JToken: JsonToken;
    begin
        BrandId := StrSubstNo('%1_%2', ItemNo, ColorCode);

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

        // Will be resolved by API Mgt at runtime
        ProductId := '';
        ProductColor := ColorCode;
        ProductSeason := '';
    end;

    procedure SetProductCache(BrandId: Text; ProductId: Text; ProductData: JsonObject)
    begin
        if not ProductIdCache.ContainsKey(BrandId) then
            ProductIdCache.Add(BrandId, ProductId)
        else
            ProductIdCache.Set(BrandId, ProductId);

        if not ProductDataCache.ContainsKey(BrandId) then
            ProductDataCache.Add(BrandId, ProductData)
        else
            ProductDataCache.Set(BrandId, ProductData);
    end;
}