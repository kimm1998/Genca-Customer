codeunit 80121 "NuOrder Customer Payload Mgt."
{
    procedure BuildCreateOrUpdateCustomerPayload(Buffer: Record "NuOrder Customer Buffer") PayloadTxt: Text
    var
        Payload: JsonObject;
        Customer: Record Customer;
        AddressesArr: JsonArray;
    begin
        if not Customer.Get(Buffer."Customer No.") then
            Error('Customer %1 was not found.', Buffer."Customer No.");

        Payload.Add('name', Customer.Name);
        Payload.Add('code', Customer."No.");

        AddressesArr := BuildAddressesArray(Customer);
        Payload.Add('addresses', AddressesArr);

        Payload.Add('allow_bulk', false);
        Payload.Add('surcharge', 0);
        Payload.Add('discount', 0);
        Payload.Add('currency_code', GetCurrencyCode(Customer));
        Payload.Add('active', not (Customer.Blocked = Customer.Blocked::All));
        Payload.Add('payment_terms', GetPaymentTermsCode(Customer));

        Payload.WriteTo(PayloadTxt);
    end;

    local procedure BuildAddressesArray(Customer: Record Customer): JsonArray
    var
        AddressesArr: JsonArray;
        AddressObj: JsonObject;
        ShipTo: Record "Ship-to Address";
    begin
        // Main customer address as default billing + shipping ("both")
        Clear(AddressObj);
        if Customer.City <> '' then
            AddressObj.Add('display_name', Customer.Name + ' - ' + Customer.City)
        else
            AddressObj.Add('display_name', Customer.Name);
        AddressObj.Add('line_1', Customer.Address);
        AddressObj.Add('line_2', Customer."Address 2");
        AddressObj.Add('city', Customer.City);
        AddressObj.Add('state', Customer.County);
        AddressObj.Add('zip', Customer."Post Code");
        AddressObj.Add('country', Customer."Country/Region Code");
        AddressObj.Add('shipping_code', Customer."No.");
        AddressObj.Add('billing_code', Customer."No.");
        AddressObj.Add('default_shipping', true);
        AddressObj.Add('default_billing', true);
        AddressObj.Add('type', 'both');
        AddressesArr.Add(AddressObj);

        // Ship-to addresses as shipping-only
        ShipTo.SetRange("Customer No.", Customer."No.");
        if ShipTo.FindSet() then
            repeat
                Clear(AddressObj);
                if ShipTo.Name <> '' then
                    AddressObj.Add('display_name', Customer.Name + ' - ' + ShipTo.Name)
                else
                    AddressObj.Add('display_name', Customer.Name + ' - ' + ShipTo.Code);
                AddressObj.Add('line_1', ShipTo.Address);
                AddressObj.Add('line_2', ShipTo."Address 2");
                AddressObj.Add('city', ShipTo.City);
                AddressObj.Add('state', ShipTo.County);
                AddressObj.Add('zip', ShipTo."Post Code");
                AddressObj.Add('country', ShipTo."Country/Region Code");
                AddressObj.Add('shipping_code', ShipTo.Code);
                AddressObj.Add('billing_code', '');
                AddressObj.Add('default_shipping', false);
                AddressObj.Add('default_billing', false);
                AddressObj.Add('type', 'shipping');
                AddressesArr.Add(AddressObj);
            until ShipTo.Next() = 0;

        exit(AddressesArr);
    end;

    local procedure GetCurrencyCode(Customer: Record Customer): Text
    begin
        if Customer."Currency Code" <> '' then
            exit(Customer."Currency Code");
        exit('USD');
    end;

    local procedure GetPaymentTermsCode(Customer: Record Customer): Text
    begin
        exit(Customer."Payment Terms Code");
    end;
}
