codeunit 80131 "NuOrder Price Payload Mgt."
{
    procedure BuildPriceSheetPayload(HeaderBuffer: Record "NuOrder Price Header Buffer") PayloadTxt: Text
    var
        PriceListHeader: Record "Price List Header";
        LineBuffer: Record "NuOrder Price Line Buffer";
        Payload: JsonObject;
        PricingArr: JsonArray;
        CurrencyCode: Text;
        CurrentItemNo: Code[20];
        CurrentColorCode: Code[10];
        CurrentSeasonCode: Code[20];
        PricingObj: JsonObject;
        SizesArr: JsonArray;
        SizeObj: JsonObject;
        ColorDescription: Text;
        SeasonDescription: Text;
        Template: Text;
        BrandId: Text;
        WholesalePrice: Decimal;
        IsFirstGroup: Boolean;
    begin
        if not PriceListHeader.Get(HeaderBuffer."Price List Code") then
            Error('Price List Header %1 was not found.', HeaderBuffer."Price List Code");

        // Determine currency code
        CurrencyCode := PriceListHeader."Currency Code";
        if CurrencyCode = '' then
            CurrencyCode := 'USD';

        Template := GetTemplateName(PriceListHeader);

        Payload.Add('currency_code', CurrencyCode);

        // Get all unprocessed line buffer records ordered by Item No., Color Code, Season Code for grouping
        LineBuffer.SetRange("Price List Code", HeaderBuffer."Price List Code");
        LineBuffer.SetRange(Processed, false);
        LineBuffer.SetCurrentKey("Price List Code", "Item No.", "Color Code", "Season Code");

        if not LineBuffer.FindSet() then begin
            Payload.Add('pricing', PricingArr);
            Payload.WriteTo(PayloadTxt);
            exit;
        end;

        CurrentItemNo := '';
        CurrentColorCode := '';
        CurrentSeasonCode := '';
        IsFirstGroup := true;

        repeat
            // Check if we have a new group (Item No. + Color Code + Season Code)
            if (LineBuffer."Item No." <> CurrentItemNo) or
               (LineBuffer."Color Code" <> CurrentColorCode) or
               (LineBuffer."Season Code" <> CurrentSeasonCode)
            then begin
                // Save previous group if exists
                if not IsFirstGroup then begin
                    PricingObj.Add('sizes', SizesArr);
                    PricingArr.Add(PricingObj);
                end;

                // Start new group
                CurrentItemNo := LineBuffer."Item No.";
                CurrentColorCode := LineBuffer."Color Code";
                CurrentSeasonCode := LineBuffer."Season Code";
                WholesalePrice := LineBuffer."Unit Price";
                IsFirstGroup := false;

                ColorDescription := GetColorDescription(LineBuffer."Color Code");
                SeasonDescription := GetSeasonDescription(LineBuffer."Season Code");
                BrandId := StrSubstNo('%1_%2', LineBuffer."Item No.", LineBuffer."Color Code");

                Clear(PricingObj);
                Clear(SizesArr);

                PricingObj.Add('wholesale', WholesalePrice);
                PricingObj.Add('retail', 0);
                PricingObj.Add('disabled', false);
                PricingObj.Add('template', Template);
                PricingObj.Add('style_number', LineBuffer."Item No.");
                PricingObj.Add('season', SeasonDescription);
                PricingObj.Add('color', ColorDescription);
                PricingObj.Add('brand_id', BrandId);
            end;

            // Add size entry
            Clear(SizeObj);
            SizeObj.Add('wholesale', Format(LineBuffer."Unit Price", 0, 9));
            SizeObj.Add('retail', '0');
            SizeObj.Add('size', GetSizeDescription(LineBuffer."Size Code"));
            SizesArr.Add(SizeObj);

        until LineBuffer.Next() = 0;

        // Save last group
        if not IsFirstGroup then begin
            PricingObj.Add('sizes', SizesArr);
            PricingArr.Add(PricingObj);
        end;

        Payload.Add('pricing', PricingArr);
        Payload.WriteTo(PayloadTxt);
    end;

    local procedure GetTemplateName(PriceListHeader: Record "Price List Header"): Text
    begin
        if PriceListHeader.Description <> '' then
            exit(PriceListHeader.Description);
        exit(PriceListHeader.Code);
    end;

    local procedure GetColorDescription(ColorCode: Code[10]): Text
    var
        Color: Record "K3PF Color";
    begin
        if ColorCode = '' then
            exit('');
        Color.SetRange(Code, ColorCode);
        if Color.FindFirst() then begin
            if Color."External Description" <> '' then
                exit(UpperCase(Color."External Description"));
            if Color.Description <> '' then
                exit(UpperCase(Color.Description));
        end;
        exit(ColorCode);
    end;

    local procedure GetSeasonDescription(SeasonCode: Code[20]): Text
    var
        Season: Record "K3PF Season";
    begin
        if SeasonCode = '' then
            exit('');
        if Season.Get(SeasonCode) then begin
            if Season.Description <> '' then
                exit(Season.Description);
        end;
        exit(SeasonCode);
    end;

    local procedure GetSizeDescription(SizeCode: Code[20]): Text
    var
        ItemSize: Record "K3PF Item Size";
    begin
        if SizeCode = '' then
            exit('');
        ItemSize.SetRange("Size Code", SizeCode);
        if ItemSize.FindFirst() then begin
            if ItemSize.Description <> '' then
                exit(ItemSize.Description);
        end;
        exit(SizeCode);
    end;
}
