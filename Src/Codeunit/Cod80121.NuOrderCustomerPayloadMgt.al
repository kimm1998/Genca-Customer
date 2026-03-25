codeunit 80121 "NuOrder Customer Payload Mgt."
{
    procedure BuildCreateOrUpdateCustomerPayload(Buffer: Record "NuOrder Customer Buffer") PayloadTxt: Text
    var
        Customer: Record Customer;
        Payload: JsonObject;
        AddressObj: JsonObject;
    begin
        if not Customer.Get(Buffer."Customer No.") then
            Error('Customer %1 was not found.', Buffer."Customer No.");

        AddressObj.Add('line_1', Customer.Address);
        AddressObj.Add('line_2', Customer."Address 2");
        AddressObj.Add('city', Customer.City);
        AddressObj.Add('state', Customer.County);
        AddressObj.Add('zip', Customer."Post Code");
        AddressObj.Add('country', Customer."Country/Region Code");

        Payload.Add('name', Customer.Name);
        Payload.Add('code', Customer."No.");
        Payload.Add('email', Customer."E-Mail");
        Payload.Add('phone', Customer."Phone No.");
        Payload.Add('address', AddressObj);
        Payload.Add('buyer_name', Customer.Contact);

        Payload.WriteTo(PayloadTxt);
    end;
}
