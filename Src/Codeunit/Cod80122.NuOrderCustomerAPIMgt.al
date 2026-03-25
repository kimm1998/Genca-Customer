codeunit 80122 "NuOrder Customer API Mgt."
{
    procedure ProcessAllBufferedEntries()
    var
        Buffer: Record "NuOrder Customer Buffer";
    begin
        while Buffer.FindFirst() do begin
            ProcessBufferedEntry(Buffer);
        end;
    end;

    procedure ProcessBufferedEntry(var Buffer: Record "NuOrder Customer Buffer")
    var
        ResponseTxt: Text;
    begin
        if PushCreateOrUpdateCustomer(Buffer, ResponseTxt) then
            Buffer.Delete()
        else
            Error(GetLastErrorText);
    end;

    [TryFunction]
    procedure PushCreateOrUpdateCustomer(Buffer: Record "NuOrder Customer Buffer"; var ResponseTxt: Text)
    var
        Setup: Record "NuORDER Setup";
        AuthMgt: Codeunit "NuORDER Auth Mgt";
        PayloadMgt: Codeunit "NuOrder Customer Payload Mgt.";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        PayloadTxt: Text;
        Url: Text;
        AuthorizationHeader: Text;
    begin
        Buffer.TestField("Customer No.");
        if not Setup.Get() then
            Error('NuORDER Setup was not found.');

        PayloadTxt := PayloadMgt.BuildCreateOrUpdateCustomerPayload(Buffer);

        Url := AuthMgt.GetCustomerURL();
        AuthorizationHeader := AuthMgt.GetApiAuthorizationHeader(Setup, 'PUT', Url);

        Content.WriteFrom(PayloadTxt);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        Request.SetRequestUri(Url);
        Request.Method := 'PUT';
        Request.Content := Content;

        Request.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', AuthorizationHeader);
        RequestHeaders.Add('Accept', 'application/json');

        Client.Send(Request, Response);
        Response.Content().ReadAs(ResponseTxt);

        if not Response.IsSuccessStatusCode() then
            Error(
                'NuORDER create/update customer failed.\Status Code: %1\Response: %2\Customer: %3',
                Response.HttpStatusCode(),
                ResponseTxt,
                Buffer."Customer No.");
    end;
}
