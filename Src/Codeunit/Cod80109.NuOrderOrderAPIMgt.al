codeunit 80109 "NuOrder Order API Mgt."
{
    procedure SyncOrdersToBuffer(): Integer
    var
        Setup: Record "NuORDER Environment Setup";
        StartDate: Date;
        EndDate: Date;
        OrderIdsResponseTxt: Text;
        OrderIds: List of [Text];
        OrderJsonList: List of [Text];
    begin
        PrepareSetup(Setup);

        repeat
            PrepareDates(Setup, StartDate, EndDate);


            OrderIdsResponseTxt := GetOrderIdsByDate(Setup, StartDate, EndDate);
            OrderIds := ParseOrderIdsResponse(OrderIdsResponseTxt);

            OrderJsonList := GetOrdersByIds(Setup, OrderIds);

            SyncOrderJsonListToBuffer(Setup, OrderJsonList);
        until Setup.Next() = 0;
    end;


    //========== Main API Sync Logic Endpoints ==========

    local procedure GetOrderIdsByDate(Setup: Record "NuORDER Environment Setup"; StartDate: Date; EndDate: Date): Text
    var
        AuthMgt: Codeunit "NuORDER Auth Mgt";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ResponseTxt: Text;
        Url: Text;
        AuthorizationHeader: Text;
    begin
        Url := BuildOrdersByDateUrl(Setup, StartDate, EndDate);
        AuthorizationHeader := AuthMgt.GetApiAuthorizationHeader(Setup, 'GET', Url);

        Request.SetRequestUri(Url);
        Request.Method := 'GET';

        Request.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', AuthorizationHeader);
        RequestHeaders.Add('Accept', 'application/json');

        Client.Send(Request, Response);
        Response.Content().ReadAs(ResponseTxt);

        if not Response.IsSuccessStatusCode() then
            Error(
                'NuORDER order list by date failed.\Status Code: %1\Response: %2',
                Response.HttpStatusCode(),
                ResponseTxt);

        exit(ResponseTxt);
    end;

    local procedure GetOrdersByIds(Setup: Record "NuORDER Environment Setup"; OrderIds: List of [Text]) OrderJsonList: List of [Text]
    var
        OrderId: Text;
    begin
        foreach OrderId in OrderIds do
            OrderJsonList.Add(GetOrderById(Setup, OrderId));
    end;

    local procedure GetOrderById(Setup: Record "NuORDER Environment Setup"; OrderId: Text): Text
    var
        AuthMgt: Codeunit "NuORDER Auth Mgt";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ResponseTxt: Text;
        Url: Text;
        AuthorizationHeader: Text;
    begin
        Url := BuildOrderByIdUrl(Setup, OrderId);
        AuthorizationHeader := AuthMgt.GetApiAuthorizationHeader(Setup, 'GET', Url);

        Request.SetRequestUri(Url);
        Request.Method := 'GET';

        Request.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', AuthorizationHeader);
        RequestHeaders.Add('Accept', 'application/json');

        Client.Send(Request, Response);
        Response.Content().ReadAs(ResponseTxt);

        if not Response.IsSuccessStatusCode() then
            Error(
                'NuORDER order by id failed.\Status Code: %1\Order ID: %2\Response: %3',
                Response.HttpStatusCode(),
                OrderId,
                ResponseTxt);

        exit(ResponseTxt);
    end;


    //===================================================
    //========== Json iteration ===========================

    local procedure SyncOrderJsonListToBuffer(var Setup: Record "NuORDER Environment Setup"; OrderJsonList: List of [Text]): Integer
    var
        OrderJsonTxt: Text;
        SyncedCount: Integer;
    begin
        foreach OrderJsonTxt in OrderJsonList do
            SyncedCount += SyncSingleOrderJsonToBuffer(Setup, OrderJsonTxt);

        Setup."Last Order Sync Date" := Today;
        Setup.Modify(true);

        exit(SyncedCount);
    end;

    local procedure SyncSingleOrderJsonToBuffer(Setup: Record "NuORDER Environment Setup"; OrderJsonTxt: Text): Integer
    var
        OrderObj: JsonObject;
    begin
        OrderObj := ParseOrderObject(OrderJsonTxt);

        if not IsApprovedOrder(OrderObj) then
            exit(HandleNonApprovedOrder(Setup, OrderObj, OrderJsonTxt));

        exit(UpsertApprovedOrder(Setup, OrderObj, OrderJsonTxt));
    end;

    //===================================================
    //========== Date Functions =========================


    local procedure PrepareSetup(var Setup: Record "NuORDER Environment Setup")
    begin

        Setup.SetRange(Enabled, true);
        Setup.SetRange("Auth Status", Setup."Auth Status"::Connected);
        Setup.SetRange("Enable Order Sync", true);
        if not Setup.FindFirst() then
            Error('No connected Environment was found');
    end;

    local procedure PrepareDates(Setup: Record "NuORDER Environment Setup"; var StartDate: Date; var EndDate: Date)
    begin
        StartDate := Setup."Last Order Sync Date";
        if StartDate = 0D then begin
            StartDate := DMY2Date(1, 1, 2000);
            EndDate := CalcDate('<+4Y>', Today);
        end else
            EndDate := CalcDate('<+4Y>', StartDate);
    end;

    //===================================================
    //========== Buffer Header Helpers ==================

    local procedure HandleNonApprovedOrder(Setup: Record "NuORDER Environment Setup"; OrderObj: JsonObject; OrderJsonTxt: Text): Integer
    var
        Buffer: Record "NuOrder Order Buffer";
        OrderId: Text;
        LineMgt: Codeunit "NuOrder Order Line Mgt.";
    begin
        OrderId := GetRequiredText(OrderObj, '_id');

        if not Buffer.Get(Setup.Code, OrderId) then
            exit(0);

        if Buffer."Buffer Status" = Buffer."Buffer Status"::Processed then
            exit(0);

        ApplyOrderToBuffer(Buffer, OrderObj);
        Buffer."Buffer Status" := Buffer."Buffer Status"::Ready;
        Buffer."Last Error" := '';
        Buffer.Modify(true);

        LineMgt.SyncLineItemsToBuffer(Setup, Buffer."NuOrder ID", OrderObj, Buffer."Buffer Status"::Ready);

        exit(0);
    end;

    local procedure UpsertApprovedOrder(Setup: Record "NuORDER Environment Setup"; OrderObj: JsonObject; OrderJsonTxt: Text): Integer
    var
        Buffer: Record "NuOrder Order Buffer";
        OrderId: Text;
    begin
        OrderId := GetRequiredText(OrderObj, '_id');

        if Buffer.Get(Setup.Code, OrderId) then
            exit(UpdateExistingApprovedOrder(Setup, Buffer, OrderObj, OrderJsonTxt));

        exit(InsertNewApprovedOrder(Setup, OrderObj, OrderJsonTxt));
    end;

    local procedure UpdateExistingApprovedOrder(Setup: Record "NuORDER Environment Setup"; var Buffer: Record "NuOrder Order Buffer"; OrderObj: JsonObject; OrderJsonTxt: Text): Integer
    var
        LineMgt: Codeunit "NuOrder Order Line Mgt.";
    begin
        if Buffer."Buffer Status" = Buffer."Buffer Status"::Processed then
            exit(0);

        ApplyOrderToBuffer(Buffer, OrderObj);
        Buffer."Buffer Status" := Buffer."Buffer Status"::Ready;
        Buffer."Processed At" := 0DT;
        Buffer."Last Error" := '';
        Buffer.Modify(true);

        LineMgt.SyncLineItemsToBuffer(Setup, Buffer."NuOrder ID", OrderObj, Buffer."Buffer Status"::Ready);

        exit(1);
    end;

    local procedure InsertNewApprovedOrder(Setup: Record "NuORDER Environment Setup"; OrderObj: JsonObject; OrderJsonTxt: Text): Integer
    var
        Buffer: Record "NuOrder Order Buffer";
        LineMgt: Codeunit "NuOrder Order Line Mgt.";
    begin
        Buffer.Init();
        Buffer."Environment Code" := Setup.Code;
        ApplyOrderToBuffer(Buffer, OrderObj);
        Buffer."Buffer Status" := Buffer."Buffer Status"::Ready;
        Buffer."Last Error" := '';
        Buffer.Insert(true);

        Buffer.Modify(true);

        LineMgt.SyncLineItemsToBuffer(Setup, Buffer."NuOrder ID", OrderObj, Buffer."Buffer Status"::Ready);

        exit(1);
    end;

    local procedure ApplyOrderToBuffer(var Buffer: Record "NuOrder Order Buffer"; OrderObj: JsonObject)
    var
        TotalDec: Decimal;
        TempDec: Decimal;
        TempTxt: Text;
        TempBool: Boolean;
    begin
        Buffer."NuOrder ID" := CopyStr(GetRequiredText(OrderObj, '_id'), 1, MaxStrLen(Buffer."NuOrder ID"));
        Buffer."Retrieved At" := CurrentDateTime();

        GetOptionalText(OrderObj, 'order_number', TempTxt);
        Buffer."Order No." := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Order No."));

        GetOptionalText(OrderObj, 'external_id', TempTxt);
        Buffer."External ID" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."External ID"));

        GetOptionalText(OrderObj, 'customer_po_number', TempTxt);
        Buffer."Customer PO No." := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Customer PO No."));

        GetOptionalText(OrderObj, 'currency_code', TempTxt);
        Buffer."Currency Code" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Currency Code"));

        GetOptionalText(OrderObj, 'status', TempTxt);
        Buffer."NuOrder Status" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."NuOrder Status"));

        GetNestedText(OrderObj, 'product', 'brand_id', TempTxt);
        Buffer."Product Brand ID" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Product Brand ID"));

        GetNestedText(OrderObj, 'product', 'season', TempTxt);
        Buffer."Product Season" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Product Season"));

        GetNestedText(OrderObj, 'product', 'style_number', TempTxt);
        Buffer."Product Style No." := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Product Style No."));

        GetNestedText(OrderObj, 'product', 'color', TempTxt);
        Buffer."Product Color" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Product Color"));

        GetOptionalDecimal(OrderObj, 'total', TotalDec);
        Buffer.Total := TotalDec;

        GetOptionalDecimal(OrderObj, 'discount', TempDec);
        Buffer.Discount := TempDec;

        GetOptionalDecimal(OrderObj, 'additional_percentage', TempDec);
        Buffer."Additional Percentage" := TempDec;

        GetOptionalText(OrderObj, 'additional_percentage_label', TempTxt);
        Buffer."Additional Percentage Label" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Additional Percentage Label"));

        GetOptionalDecimal(OrderObj, 'total_quantity', TempDec);
        Buffer."Total Quantity" := TempDec;

        GetOptionalText(OrderObj, 'created_on', TempTxt);
        Buffer."Created On" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Created On"));

        GetOptionalText(OrderObj, 'modified_on', TempTxt);
        Buffer."Modified On" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Modified On"));

        GetOptionalText(OrderObj, 'start_ship', TempTxt);
        Buffer."Start Ship" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Start Ship"));

        GetOptionalText(OrderObj, 'end_ship', TempTxt);
        Buffer."End Ship" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."End Ship"));

        GetOptionalText(OrderObj, 'notes', TempTxt);
        Buffer.Notes := CopyStr(TempTxt, 1, MaxStrLen(Buffer.Notes));

        GetOptionalText(OrderObj, 'submitted_by', TempTxt);
        Buffer."Submitted By" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Submitted By"));

        GetOptionalText(OrderObj, 'payment_status', TempTxt);
        Buffer."Payment Status" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Payment Status"));

        GetOptionalText(OrderObj, 'schema_id', TempTxt);
        Buffer."Schema ID" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Schema ID"));

        GetOptionalText(OrderObj, 'order_group_id', TempTxt);
        Buffer."Order Group ID" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Order Group ID"));

        GetOptionalText(OrderObj, 'style_number', TempTxt);
        Buffer."Top Style Number" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Top Style Number"));

        GetOptionalBoolean(OrderObj, 'split', TempBool);
        Buffer.Split := TempBool;

        GetOptionalBoolean(OrderObj, 'buyer_submitted', TempBool);
        Buffer."Buyer Submitted" := TempBool;

        GetOptionalBoolean(OrderObj, 'edited', TempBool);
        Buffer.Edited := TempBool;

        GetOptionalBoolean(OrderObj, 'locked', TempBool);
        Buffer.Locked := TempBool;

        GetOptionalText(OrderObj, 'rep_name', TempTxt);
        Buffer."Rep Name" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Rep Name"));

        GetOptionalText(OrderObj, 'rep_code', TempTxt);
        Buffer."Rep Code" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Rep Code"));

        GetOptionalText(OrderObj, 'rep_email', TempTxt);
        Buffer."Rep Email" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Rep Email"));

        GetOptionalText(OrderObj, 'creator_name', TempTxt);
        Buffer."Creator Name" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Creator Name"));

        GetNestedText(OrderObj, 'retailer', '_id', TempTxt);
        Buffer."Retailer ID" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Retailer ID"));

        GetNestedText(OrderObj, 'retailer', 'retailer_name', TempTxt);
        Buffer."Retailer Name" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Retailer Name"));

        GetNestedText(OrderObj, 'retailer', 'retailer_code', TempTxt);
        Buffer."Retailer Code" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Retailer Code"));

        GetNestedText(OrderObj, 'retailer', 'buyer_name', TempTxt);
        Buffer."Buyer Name" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Buyer Name"));

        GetNestedText(OrderObj, 'retailer', 'buyer_email', TempTxt);
        Buffer."Buyer Email" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Buyer Email"));

        GetNestedText(OrderObj, 'billing_address', 'line_1', TempTxt);
        Buffer."Bill-to Line 1" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Bill-to Line 1"));

        GetNestedText(OrderObj, 'billing_address', 'country', TempTxt);
        Buffer."Bill-to Country" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Bill-to Country"));

        GetNestedText(OrderObj, 'billing_address', 'city', TempTxt);
        Buffer."Bill-to City" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Bill-to City"));

        GetNestedText(OrderObj, 'billing_address', 'state', TempTxt);
        Buffer."Bill-to State" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Bill-to State"));

        GetNestedText(OrderObj, 'billing_address', 'zip', TempTxt);
        Buffer."Bill-to Zip" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Bill-to Zip"));

        GetNestedText(OrderObj, 'billing_address', 'ref', TempTxt);
        Buffer."Bill-to Ref" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Bill-to Ref"));

        GetNestedText(OrderObj, 'billing_address', 'code', TempTxt);
        Buffer."Bill-to Code" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Bill-to Code"));

        GetNestedText(OrderObj, 'shipping_address', 'line_1', TempTxt);
        Buffer."Ship-to Line 1" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Ship-to Line 1"));

        GetNestedText(OrderObj, 'shipping_address', 'country', TempTxt);
        Buffer."Ship-to Country" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Ship-to Country"));

        GetNestedText(OrderObj, 'shipping_address', 'city', TempTxt);
        Buffer."Ship-to City" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Ship-to City"));

        GetNestedText(OrderObj, 'shipping_address', 'state', TempTxt);
        Buffer."Ship-to State" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Ship-to State"));

        GetNestedText(OrderObj, 'shipping_address', 'zip', TempTxt);
        Buffer."Ship-to Zip" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Ship-to Zip"));

        GetNestedText(OrderObj, 'shipping_address', 'ref', TempTxt);
        Buffer."Ship-to Ref" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Ship-to Ref"));

        GetNestedText(OrderObj, 'shipping_address', 'code', TempTxt);
        Buffer."Ship-to Code" := CopyStr(TempTxt, 1, MaxStrLen(Buffer."Ship-to Code"));
    end;
    //===================================================
    //========== JSON Helpers ===========================

    local procedure ParseOrderIdsResponse(ResponseTxt: Text) OrderIds: List of [Text]
    var
        RootToken: JsonToken;
        IdArray: JsonArray;
        IdToken: JsonToken;
        OrderId: Text;
    begin
        if not RootToken.ReadFrom(ResponseTxt) then
            Error('Order list response is not valid JSON.');

        if not RootToken.IsArray() then
            Error('Order list response must be a JSON array.');

        IdArray := RootToken.AsArray();

        foreach IdToken in IdArray do begin
            if not IdToken.IsValue() then
                Error('Order list contains a non-text entry.');

            OrderId := IdToken.AsValue().AsText();
            if OrderId = '' then
                Error('Order list contains a blank order ID.');

            OrderIds.Add(OrderId);
        end;
    end;

    local procedure ParseOrderObject(OrderJsonTxt: Text) OrderObj: JsonObject
    begin
        if not OrderObj.ReadFrom(OrderJsonTxt) then
            Error('Order detail response is not valid JSON.');
    end;

    local procedure IsApprovedOrder(OrderObj: JsonObject): Boolean
    var
        StatusTxt: Text;
    begin
        GetOptionalText(OrderObj, 'status', StatusTxt);
        exit(LowerCase(StatusTxt) in ['approved', 'processed', 'approved', 'shipped']);
    end;

    local procedure GetRequiredText(JObject: JsonObject; PropertyName: Text): Text
    var
        ValueTxt: Text;
    begin
        GetOptionalText(JObject, PropertyName, ValueTxt);

        if ValueTxt = '' then
            Error('Required property %1 is missing.', PropertyName);

        exit(ValueTxt);
    end;

    local procedure GetOptionalText(JObject: JsonObject; PropertyName: Text; var ValueTxt: Text)
    var
        JToken: JsonToken;
    begin
        Clear(ValueTxt);

        if not JObject.Get(PropertyName, JToken) then
            exit;

        if not JToken.IsValue() then
            exit;

        ValueTxt := JToken.AsValue().AsText();
    end;

    local procedure GetNestedText(JObject: JsonObject; ParentPropertyName: Text; ChildPropertyName: Text; var ValueTxt: Text)
    var
        ParentToken: JsonToken;
        ParentObj: JsonObject;
    begin
        Clear(ValueTxt);

        if not JObject.Get(ParentPropertyName, ParentToken) then
            exit;

        if not ParentToken.IsObject() then
            exit;

        ParentObj := ParentToken.AsObject();
        GetOptionalText(ParentObj, ChildPropertyName, ValueTxt);
    end;

    local procedure GetOptionalDecimal(JObject: JsonObject; PropertyName: Text; var ValueDec: Decimal)
    var
        JToken: JsonToken;
        ValueTxt: Text;
    begin
        Clear(ValueDec);

        if not JObject.Get(PropertyName, JToken) then
            exit;

        if not JToken.IsValue() then
            exit;

        ValueTxt := JToken.AsValue().AsText();
        if ValueTxt = '' then
            exit;

        Evaluate(ValueDec, ValueTxt);
    end;

    local procedure GetOptionalBoolean(JObject: JsonObject; PropertyName: Text; var ValueBool: Boolean)
    var
        JToken: JsonToken;
    begin
        Clear(ValueBool);

        if not JObject.Get(PropertyName, JToken) then
            exit;

        if not JToken.IsValue() then
            exit;

        ValueBool := JToken.AsValue().AsBoolean();
    end;
    //===================================================




    local procedure FormatDateForApi(InputDate: Date): Text
    begin
        exit(
            StrSubstNo(
                '%1-%2-%3',
                Format(Date2DMY(InputDate, 3)),
                Pad2(Date2DMY(InputDate, 2)),
                Pad2(Date2DMY(InputDate, 1))));
    end;

    local procedure Pad2(Number: Integer): Text
    begin
        if Number < 10 then
            exit('0' + Format(Number));

        exit(Format(Number));
    end;






    //#TODO move these to authmgt codeunit
    local procedure BuildOrdersByDateUrl(Setup: Record "NuORDER Environment Setup"; StartDate: Date; EndDate: Date): Text
    begin
        exit(
            GetBaseUrl(Setup) +
            StrSubstNo(
                '/orders/list?start_date=%1&end_date=%2',
                FormatDateForApi(StartDate),
                FormatDateForApi(EndDate)));
    end;

    local procedure BuildOrderByIdUrl(Setup: Record "NuORDER Environment Setup"; OrderId: Text): Text
    begin
        exit(GetBaseUrl(Setup) + StrSubstNo('/order/%1', OrderId));
    end;

    local procedure GetBaseUrl(Setup: Record "NuORDER Environment Setup"): Text
    begin
        if Setup."Base URL" <> '' then
            exit(StrSubstNo(Setup."Base URL", Format(Setup.Environment)));

        exit(StrSubstNo('https://%1.nuorder.com', Format(Setup.Environment)));
    end;


}