codeunit 80132 "NuOrder Price API Mgt."
{
    procedure ProcessAllBufferedEntries()
    var
        HeaderBuffer: Record "NuOrder Price Header Buffer";
    begin
        HeaderBuffer.SetRange(Processed, false);
        if HeaderBuffer.FindSet() then
            repeat
                ProcessBufferedEntry(HeaderBuffer);
            until HeaderBuffer.Next() = 0;
    end;

    procedure ProcessBufferedEntry(var HeaderBuffer: Record "NuOrder Price Header Buffer")
    var
        ResponseTxt: Text;
    begin
        if PushPriceSheet(HeaderBuffer, ResponseTxt) then begin
            HeaderBuffer.Processed := true;
            HeaderBuffer."Status" := HeaderBuffer."Status"::Synced;
            HeaderBuffer."Last Error" := '';
            HeaderBuffer.Modify();
            MarkLinesProcessed(HeaderBuffer."Price List Code");
        end else begin
            HeaderBuffer."Status" := HeaderBuffer."Status"::Error;
            HeaderBuffer."Last Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(HeaderBuffer."Last Error"));
            HeaderBuffer.Modify();
            Error(GetLastErrorText());
        end;
    end;

    [TryFunction]
    procedure PushPriceSheet(HeaderBuffer: Record "NuOrder Price Header Buffer"; var ResponseTxt: Text)
    var
        Setup: Record "NuORDER Setup";
        AuthMgt: Codeunit "NuORDER Auth Mgt";
        PayloadMgt: Codeunit "NuOrder Price Payload Mgt.";
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
        HeaderBuffer.TestField("Price List Code");
        if not Setup.Get() then
            Error('NuORDER Setup was not found.');

        PayloadTxt := PayloadMgt.BuildPriceSheetPayload(HeaderBuffer);

        Url := AuthMgt.GetPriceSheetURL();
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
                'NuORDER create/update price sheet failed.\Status Code: %1\Response: %2\Price List: %3',
                Response.HttpStatusCode(),
                ResponseTxt,
                HeaderBuffer."Price List Code");
    end;

    local procedure MarkLinesProcessed(PriceListCode: Code[20])
    var
        LineBuffer: Record "NuOrder Price Line Buffer";
    begin
        LineBuffer.SetRange("Price List Code", PriceListCode);
        LineBuffer.SetRange(Processed, false);
        if LineBuffer.FindSet() then
            repeat
                LineBuffer.Processed := true;
                LineBuffer."Status" := LineBuffer."Status"::Synced;
                LineBuffer.Modify();
            until LineBuffer.Next() = 0;
    end;
}
