codeunit 80106 "NuOrder Product API Mgt."
{
    procedure ProcessAllBufferedEntries()
    var
        Buffer: Record "NuOrder Product Buffer";
    begin
        while Buffer.FindFirst() do begin
            ProcessBufferedEntry(Buffer);
        end;
    end;

    procedure ProcessBufferedEntry(var Buffer: Record "NuOrder Product Buffer")
    var
        ResponseTxt: Text;
    begin
        if PushCreateOrUpdateProduct(Buffer, ResponseTxt) then
            Buffer.Delete()
        else
            Error(GetLastErrorText);
    end;

    [TryFunction]
    procedure PushCreateOrUpdateProduct(Buffer: Record "NuOrder Product Buffer"; var ResponseTxt: Text)
    var
        Setup: Record "NuORDER Setup";
        AuthMgt: Codeunit "NuORDER Auth Mgt";
        PayloadMgt: Codeunit "NuOrder Product Payload Mgt.";
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
        Buffer.TestField("Item No.");
        Buffer.TestField("Color Code");
        Buffer.TestField("Season Code");
        if not Setup.Get() then
            Error('NuORDER Setup was not found.');

        PayloadTxt := PayloadMgt.BuildCreateOrUpdateProductPayload(Buffer);

        Url := AuthMgt.GetProductURL();
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
                'NuORDER create/update product failed.\Status Code: %1\Response: %2\Item: %3\Color: %4\Season: %5',
                Response.HttpStatusCode(),
                ResponseTxt,
                Buffer."Item No.",
                Buffer."Color Code",
                Buffer."Season Code");
    end;
}