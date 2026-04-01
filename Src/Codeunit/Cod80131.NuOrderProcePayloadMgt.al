codeunit 80131 "NuOrder Price Payload Mgt."
{
    procedure BuildPriceSheetPayload(PriceListCode: Code[20]): Text
    var
        Buffer: Record "NuOrder Price Buffer";
        Root: JsonObject;
        PricingArr: JsonArray;
        PricingObj: JsonObject;
        SizesArr: JsonArray;
        CurrencyCode: Code[10];
        LastGroupKey: Text;
        GroupKey: Text;
        CurrentItemNo: Code[20];
        CurrentColor: Code[20];
        CurrentSeason: Code[20];
        CurrentCurrency: Code[10];
        PayloadTxt: Text;
        ProductId: Text;
    begin
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

                ProductId := ResolveNuOrderProductId(CurrentItemNo, CurrentColor);

                PricingObj.Add('_id', ProductId);
                PricingObj.Add('style_number', CurrentItemNo);
                PricingObj.Add('season', CurrentSeason);
                PricingObj.Add('color', CurrentColor);
                PricingObj.Add('template', PriceListCode);
                PricingObj.Add('wholesale', 0);
                PricingObj.Add('retail', 0);
                PricingObj.Add('disabled', false);

                LastGroupKey := GroupKey;
            end;

            AddSizesForGroup(SizesArr, PriceListCode, CurrentItemNo, CurrentColor, CurrentCurrency);
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

    local procedure AddSizesForGroup(var SizesArr: JsonArray; PriceListCode: Code[20]; ItemNo: Code[20]; ColorCode: Code[20]; CurrencyCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
        PriceListLine: Record "Price List Line";
        SizeObj: JsonObject;
        UnitPrice: Decimal;
    begin
        ItemVariant.SetRange("Item No.", ItemNo);
        ItemVariant.SetRange("K3PFColor Code", ColorCode);
        if ItemVariant.FindSet() then
            repeat
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
            until ItemVariant.Next() = 0;
    end;

    local procedure ResolveNuOrderProductId(ItemNo: Code[20]; ColorCode: Code[20]): Text
    begin
        exit(''); // Filled by API Mgt at runtime with cache (brand_id = ItemNo + ''_'' + ColorCode)
    end;
}