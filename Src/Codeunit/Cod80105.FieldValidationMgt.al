codeunit 80105 "Field Validation Mgt."
{
    procedure CheckItemField(Item: Record Item; xItem: Record Item): Boolean
    var
        IsChanged: Boolean;
    begin
        IsChanged := false;

        if Item."K3PFSeason Code" <> xItem."K3PFSeason Code" then
            IsChanged := true;

        if Item.Description <> xItem.Description then
            IsChanged := true;

        if Item."Description 2" <> xItem."Description 2" then
            IsChanged := true;

        exit(IsChanged);
    end;


    procedure CheckItemVariantFieldInsert(ItemVariant: Record "Item Variant"): Boolean
    begin
        if ItemVariant."K3PFSize Code" <> '' then
            exit(true);

        if ItemVariant."K3PF2nd Size Code" <> '' then
            exit(true);

        exit(false);
    end;

    procedure CheckItemVariantField(ItemVariant: Record "Item Variant"; xItemVariant: Record "Item Variant"): Boolean
    begin
        if ItemVariant."K3PFSize Code" <> xItemVariant."K3PFSize Code" then
            exit(true);

        if ItemVariant."K3PF2nd Size Code" <> xItemVariant."K3PF2nd Size Code" then
            exit(true);

        exit(false);
    end;

    procedure CheckPriceListLineField(PriceListLine: Record "Price List Line"; xPriceListLine: Record "Price List Line"): Boolean
    begin
        if PriceListLine."Asset Type" <> xPriceListLine."Asset Type" then
            exit(true);

        if PriceListLine."Asset No." <> xPriceListLine."Asset No." then
            exit(true);

        if PriceListLine."Variant Code" <> xPriceListLine."Variant Code" then
            exit(true);

        if PriceListLine."Unit Price" <> xPriceListLine."Unit Price" then
            exit(true);

        exit(false);
    end;
}