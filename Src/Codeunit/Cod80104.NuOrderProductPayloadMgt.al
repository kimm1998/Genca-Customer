codeunit 80104 "NuOrder Product Payload Mgt."
{

    procedure BuildCreateOrUpdateProductPayload(Buffer: Record "NuOrder Product Buffer"; Setup: Record "NuORDER Environment Setup") PayloadTxt: Text
var
    Payload: JsonObject;
    Item: Record Item;
    Color: Record "K3PF Color";
    Season: Record "K3PF Season";
    SizesArr: JsonArray;
    BannersArr: JsonArray;
    SizeGroupsArr: JsonArray;
    SeasonsArr: JsonArray;
    PricingObj: JsonObject;
    ColorTxt: Text;
    SeasonTxt: Text;
    ProductName: Text;
    ProductDescription: Text;
    BrandId: Text;
    UniqueKey: Text;
    SalesUOM: Text;
    BrandText: Text;
    weavingText: Text;
    finishText: Text;
    activeBoolean: Boolean;
    archivedBoolean: Boolean;
    CategoryTxt: Text;
    SubcategoryTxt: Text;
    DivisionTxt: Text;
begin
    if not Item.Get(Buffer."Item No.") then
        Error('Item %1 was not found.', Buffer."Item No.");

    Color.SetRange("Code", Buffer."Color Code");
    if not Color.FindFirst() then
        Error('Color %1 was not found.', Buffer."Color Code");

    if not Season.Get(Buffer."Season Code") then
        Error('Season %1 was not found.', Buffer."Season Code");

    ColorTxt := GetColorText(Setup, Color, Buffer);
    SeasonTxt := GetSeasonText(Season, Buffer);
    ProductName := GetProductName(Setup, Item);
    ProductDescription := GetProductDescription(Setup, Item);
    BrandId := StrSubstNo('%1_%2', Buffer."Item No.", Buffer."Color Code");
    UniqueKey := StrSubstNo('%1,%2,%3', Buffer."Item No.", SeasonTxt, ColorTxt);
    SalesUOM := GetSalesUOM(Item);
    BrandText := GetBrandText(Item);
    weavingText := GetWeavingText(Item);
    // finishText := GetFinishText(Item);
    activeBoolean := (not Item.Blocked);
    archivedBoolean := GetArchivedStatus(Item);

    CategoryTxt := Item."NuORDER Category";
    SubcategoryTxt := Item."NuORDER Subcategory";
    DivisionTxt := Item."NuORDER Division";

    Payload.Add('style_number', Buffer."Item No.");
    Payload.Add('season', SeasonTxt);
    Payload.Add('color', ColorTxt);
    Payload.Add('name', ProductName);
    Payload.Add('brand_id', BrandId);
    Payload.Add('unique_key', UniqueKey);

    Payload.Add('sales_unit_of_measure', SalesUOM);
    Payload.Add('brands', BrandText);
    Payload.Add('weaving', weavingText);
    // Payload.Add('customer', finishText);
    Payload.Add('active', activeBoolean);
    Payload.Add('archived', archivedBoolean);

    Payload.Add('category', CategoryTxt);
    Payload.Add('subcategory', SubcategoryTxt);
    Payload.Add('division', DivisionTxt);

    SizesArr := BuildSizesArray(Buffer);
    Payload.Add('sizes', SizesArr);

    Payload.Add('description', ProductDescription);

    // TODO: Map actual product-level pricing and currencies.
    // PricingObj := BuildRootPricingObject();
    Payload.Add('pricing', PricingObj);

    // Seasons
    SeasonsArr.Add(SeasonTxt);
    Payload.Add('seasons', SeasonsArr);

    Payload.WriteTo(PayloadTxt);
end;

    local procedure BuildSizesArray(Buffer: Record "NuOrder Product Buffer"): JsonArray
    var
        SizesArr: JsonArray;
        SizeObj: JsonObject;
        PricingObj: JsonObject;
        Sizes: Record "K3PF Item Size";
    begin
        Sizes.SetRange("Item No.", Buffer."Item No.");
        if Sizes.FindSet() then
            repeat
                Clear(SizeObj);
                SizeObj.Add('size', Sizes.Description);
                PricingObj := BuildRootPricingObject(Buffer, Sizes."Size Code");
                SizeObj.Add('pricing', PricingObj);
                SizesArr.Add(SizeObj);

            until Sizes.Next() = 0;

        exit(SizesArr);
    end;

    local procedure BuildRootPricingObject(Buffer: Record "NuOrder Product Buffer"; SizeCode: Code[20]): JsonObject
    var
        PricingObj: JsonObject;
        CurrencyObj: JsonObject;
        PriceListLine: Record "Price List Line";
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetRange("Item No.", Buffer."Item No.");
        ItemVariant.SetRange("K3PFColor Code", Buffer."Color Code");
        ItemVariant.SetRange("K3PF2nd Size Code");
        if SizeCode <> '' then
            ItemVariant.SetRange("K3PFSize Code", SizeCode);

        if ItemVariant.FindSet() then
            repeat
                PriceListLine.setrange(PriceListLine."Asset Type", PriceListLine."Asset Type"::Item);
                PriceListLine.setrange("Asset No.", Buffer."Item No.");
                PriceListLine.setrange("Variant Code", ItemVariant.Code);
                // PriceListLine.SetRange("Crt Nuorder", true);// TODO: add field in table price
                PriceListLine.setfilter("Unit Price", '<>%1', 0);
                if PriceListLine.FindSet() then
                    repeat
                        Clear(CurrencyObj);
                        CurrencyObj.Add('wholesale', PriceListLine."Unit Price");
                        CurrencyObj.Add('retail', 0);// TODO: add retail price and map here
                        CurrencyObj.Add('disabled', (PriceListLine."Starting Date" >= WorkDate()) and (PriceListLine."Ending Date" <= WorkDate()));

                        if PricingObj.Add('USD', CurrencyObj) then;
                    until PriceListLine.Next() = 0;
            until ItemVariant.Next() = 0;



        exit(PricingObj);
    end;

    local procedure GetColorText(Setup: Record "NuORDER Environment Setup"; Color: Record "K3PF Color"; Buffer: Record "NuOrder Product Buffer"): Text
    var
        Translation: Record "K3PF Color Translation";
    begin
        if Setup.Language <> '' then begin
            Translation.SetRange("Code", Buffer."Color Code");
            Translation.SetRange("Language Code", Setup.Language);
            if Translation.FindFirst() then
                exit(Translation.Description);
        end;
        exit(Color.Description);

    end;

    local procedure GetSeasonText(Season: Record "K3PF Season"; Buffer: Record "NuOrder Product Buffer"): Text
    begin
        exit(Buffer."Season Code");
    end;

    local procedure GetProductName(Setup: Record "NuORDER Environment Setup"; Item: Record Item): Text
    var
        ItemTranslation: Record "Item Translation";
    begin
        if Setup.Language <> '' then begin
            ItemTranslation.SetRange("Item No.", Item."No.");
            ItemTranslation.SetRange("Language Code", Setup.Language);
            if ItemTranslation.FindFirst() then
                exit(ItemTranslation.Description);
        end;
        exit(Item.Description)
    end;

    local procedure GetProductDescription(Setup: Record "NuORDER Environment Setup"; Item: Record Item): Text
    var
        DescriptionTxt: Text;
    begin
        DescriptionTxt := Item.Description;
        if Setup.Language in ['', 'FRC'] then
            DescriptionTxt := Item.GetCrtDescriptionlongueFRC();
        if Setup.Language = 'ENC' then
            DescriptionTxt := Item.GetCrtDescriptionlongueENC();
        exit(DescriptionTxt);
    end;

    local procedure GetSalesUOM(Item: Record Item): Text
    var
        SalesUOM: Text;
    begin
        SalesUOM := Item."Sales Unit of Measure";
        if SalesUOM = '' then
            SalesUOM := Item."Sales Unit of Measure";

        exit(SalesUOM);
    end;

    local procedure GetBrandText(Item: Record Item): Text
    var
        BrandRec: Record "K3PF Brand";
    begin
        if BrandRec.Get(Item."K3PFBrand Code") then
            exit(UpperCase(BrandRec.Description));

        exit('');
    end;

    local procedure GetWeavingText(Item: Record Item): Text
    begin
        exit(Item."K3PFWeave Type Code");
    end;

    local procedure GetFinishText(Item: Record Item): Text
    var
        FinishRec: Record "K3PF Finish";
    begin
        if FinishRec.Get(Item."K3PFFinish Code") then
            exit(UpperCase(FinishRec.Description));

        exit('');
    end;

    local procedure GetArchivedStatus(Item: Record Item): Boolean
    begin
        if Item."K3PFItem Phase Code" = 'PRÊT POUR VENTE' then
            exit(false);
        exit(true);
    end;
}