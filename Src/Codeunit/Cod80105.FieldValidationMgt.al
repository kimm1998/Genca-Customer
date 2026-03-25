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

    procedure CheckCustomerField(Customer: Record Customer; xCustomer: Record Customer): Boolean
    begin
        if Customer.Name <> xCustomer.Name then
            exit(true);
        if Customer."Name 2" <> xCustomer."Name 2" then
            exit(true);
        if Customer.Address <> xCustomer.Address then
            exit(true);
        if Customer."Address 2" <> xCustomer."Address 2" then
            exit(true);
        if Customer.City <> xCustomer.City then
            exit(true);
        if Customer.County <> xCustomer.County then
            exit(true);
        if Customer."Post Code" <> xCustomer."Post Code" then
            exit(true);
        if Customer."Country/Region Code" <> xCustomer."Country/Region Code" then
            exit(true);
        if Customer."Phone No." <> xCustomer."Phone No." then
            exit(true);
        if Customer."E-Mail" <> xCustomer."E-Mail" then
            exit(true);
        if Customer.Contact <> xCustomer.Contact then
            exit(true);
        if Customer."Currency Code" <> xCustomer."Currency Code" then
            exit(true);
        if Customer."Payment Terms Code" <> xCustomer."Payment Terms Code" then
            exit(true);
        if Customer.Blocked <> xCustomer.Blocked then
            exit(true);
        exit(false);
    end;
}