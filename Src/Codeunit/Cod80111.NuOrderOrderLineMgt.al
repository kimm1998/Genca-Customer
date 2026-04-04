codeunit 80111 "NuOrder Order Line Mgt."
{
    procedure SyncLineItemsToBuffer(Setup: Record "NuORDER Environment Setup"; OrderId: Text; OrderObj: JsonObject; NewStatus: Enum "NuOrder Buffer Status")
    var
        LineItemsArray: JsonArray;
        LineItemToken: JsonToken;
        LineItemObj: JsonObject;
        CurrentKeys: List of [Text];
    begin
        if TryGetArray(OrderObj, 'line_items', LineItemsArray) then
            foreach LineItemToken in LineItemsArray do begin
                if not LineItemToken.IsObject() then
                    Error('line_items contains a non-object entry.');

                LineItemObj := LineItemToken.AsObject();
                SyncSingleLineItem(Setup, OrderId, LineItemObj, NewStatus, CurrentKeys);
            end;

        MarkMissingLinesAsIgnored(OrderId, CurrentKeys);
    end;

    local procedure SyncSingleLineItem(Setup: Record "NuORDER Environment Setup"; OrderId: Text; LineItemObj: JsonObject; NewStatus: Enum "NuOrder Buffer Status"; var CurrentKeys: List of [Text])
    var
        SizesArray: JsonArray;
        SizeToken: JsonToken;
        SizeObj: JsonObject;
        CurrentKey: Text;
    begin
        if not TryGetArray(LineItemObj, 'sizes', SizesArray) then
            exit;

        foreach SizeToken in SizesArray do begin
            if not SizeToken.IsObject() then
                Error('sizes contains a non-object entry.');

            SizeObj := SizeToken.AsObject();
            CurrentKey := UpsertSizeLine(Setup, OrderId, LineItemObj, SizeObj, NewStatus);
            CurrentKeys.Add(CurrentKey);
        end;
    end;

    local procedure UpsertSizeLine(Setup: Record "NuORDER Environment Setup"; OrderId: Text; LineItemObj: JsonObject; SizeObj: JsonObject; NewStatus: Enum "NuOrder Buffer Status"): Text
    var
        LineBuffer: Record "NuOrder Order Line Buffer";
        LineItemId: Text;
        SizeTxt: Text;
    begin
        LineItemId := GetRequiredText(LineItemObj, 'id');
        SizeTxt := GetRequiredText(SizeObj, 'size');

        if LineBuffer.Get(Setup.Code, OrderId, LineItemId, SizeTxt) then begin
            ApplyLineToBuffer(LineBuffer, OrderId, LineItemObj, SizeObj);
            LineBuffer."Buffer Status" := NewStatus;
            if NewStatus = NewStatus::Ready then
                LineBuffer."Processed At" := 0DT;
            LineBuffer."Last Error" := '';
            LineBuffer.Modify(true);
        end else begin
            LineBuffer.Init();
            LineBuffer."Environment Code" := Setup."Code";
            LineBuffer."Order ID" := CopyStr(OrderId, 1, MaxStrLen(LineBuffer."Order ID"));
            LineBuffer."Line Item ID" := CopyStr(LineItemId, 1, MaxStrLen(LineBuffer."Line Item ID"));
            LineBuffer.Size := CopyStr(SizeTxt, 1, MaxStrLen(LineBuffer.Size));
            ApplyLineToBuffer(LineBuffer, OrderId, LineItemObj, SizeObj);
            LineBuffer."Buffer Status" := NewStatus;
            LineBuffer."Last Error" := '';
            LineBuffer.Insert(true);
        end;

        exit(BuildCompositeKey(OrderId, LineItemId, SizeTxt));
    end;

    local procedure ApplyLineToBuffer(var LineBuffer: Record "NuOrder Order Line Buffer"; OrderId: Text; LineItemObj: JsonObject; SizeObj: JsonObject)
    var
        TempTxt: Text;
        TempDec: Decimal;
        TempInt: Integer;
        TempBool: Boolean;
    begin
        LineBuffer."Order ID" := CopyStr(OrderId, 1, MaxStrLen(LineBuffer."Order ID"));
        LineBuffer."Line Item ID" := CopyStr(GetRequiredText(LineItemObj, 'id'), 1, MaxStrLen(LineBuffer."Line Item ID"));
        LineBuffer.Size := CopyStr(GetRequiredText(SizeObj, 'size'), 1, MaxStrLen(LineBuffer.Size));
        LineBuffer."Retrieved At" := CurrentDateTime();

        GetNestedText(LineItemObj, 'product', '_id', TempTxt);
        LineBuffer."Product ID" := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer."Product ID"));

        GetNestedText(LineItemObj, 'product', 'style_number', TempTxt);
        LineBuffer."Style Number" := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer."Style Number"));

        GetNestedText(LineItemObj, 'product', 'color', TempTxt);
        LineBuffer.Color := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer.Color));

        GetNestedText(LineItemObj, 'product', 'color_code', TempTxt);
        LineBuffer."Color Code" := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer."Color Code"));

        GetNestedText(LineItemObj, 'product', 'brand_id', TempTxt);
        LineBuffer."Brand ID" := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer."Brand ID"));

        GetNestedText(LineItemObj, 'product', 'season', TempTxt);
        LineBuffer.Season := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer.Season));

        GetNestedText(LineItemObj, 'product', 'department', TempTxt);
        LineBuffer.Department := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer.Department));

        GetOptionalText(LineItemObj, 'ship_start', TempTxt);
        LineBuffer."Ship Start" := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer."Ship Start"));

        GetOptionalText(LineItemObj, 'ship_end', TempTxt);
        LineBuffer."Ship End" := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer."Ship End"));

        GetOptionalText(LineItemObj, 'retail_string', TempTxt);
        LineBuffer."Retail String" := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer."Retail String"));

        GetOptionalText(LineItemObj, 'warehouse', TempTxt);
        LineBuffer.Warehouse := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer.Warehouse));

        GetOptionalBoolean(LineItemObj, 'prebook', TempBool);
        LineBuffer.Prebook := TempBool;

        GetOptionalDecimal(SizeObj, 'quantity', TempDec);
        LineBuffer.Quantity := TempDec;

        GetOptionalDecimal(SizeObj, 'price', TempDec);
        LineBuffer.Price := TempDec;

        GetOptionalDecimal(SizeObj, 'retail', TempDec);
        LineBuffer.Retail := TempDec;

        GetOptionalText(SizeObj, 'price_precise', TempTxt);
        LineBuffer."Price Precise" := CopyStr(TempTxt, 1, MaxStrLen(LineBuffer."Price Precise"));

        GetOptionalDecimal(SizeObj, 'original_price', TempDec);
        LineBuffer."Original Price" := TempDec;

        GetOptionalInteger(SizeObj, 'units_per_pack', TempInt);
        LineBuffer."Units Per Pack" := TempInt;
    end;

    local procedure MarkMissingLinesAsIgnored(OrderId: Text; CurrentKeys: List of [Text])
    var
        LineBuffer: Record "NuOrder Order Line Buffer";
    begin
        LineBuffer.SetRange("Order ID", OrderId);

        if LineBuffer.FindSet() then
            repeat
                if not CompositeKeyExists(CurrentKeys, BuildCompositeKey(LineBuffer."Order ID", LineBuffer."Line Item ID", LineBuffer.Size)) then begin
                    if LineBuffer."Buffer Status" <> LineBuffer."Buffer Status"::Ignored then begin
                        LineBuffer."Buffer Status" := LineBuffer."Buffer Status"::Ignored;
                        LineBuffer.Modify(true);
                    end;
                end;
            until LineBuffer.Next() = 0;
    end;

    local procedure BuildCompositeKey(OrderId: Text; LineItemId: Text; SizeTxt: Text): Text
    begin
        exit(OrderId + '|' + LineItemId + '|' + SizeTxt);
    end;

    local procedure CompositeKeyExists(Keys: List of [Text]; SearchKey: Text): Boolean
    var
        CurrentKey: Text;
    begin
        foreach CurrentKey in Keys do
            if CurrentKey = SearchKey then
                exit(true);

        exit(false);
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

    local procedure GetOptionalInteger(JObject: JsonObject; PropertyName: Text; var ValueInt: Integer)
    var
        JToken: JsonToken;
        ValueTxt: Text;
    begin
        Clear(ValueInt);

        if not JObject.Get(PropertyName, JToken) then
            exit;

        if not JToken.IsValue() then
            exit;

        ValueTxt := JToken.AsValue().AsText();
        if ValueTxt = '' then
            exit;

        Evaluate(ValueInt, ValueTxt);
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

    local procedure TryGetArray(JObject: JsonObject; PropertyName: Text; var JArray: JsonArray): Boolean
    var
        JToken: JsonToken;
    begin
        Clear(JArray);

        if not JObject.Get(PropertyName, JToken) then
            exit(false);

        if not JToken.IsArray() then
            exit(false);

        JArray := JToken.AsArray();
        exit(true);
    end;
}