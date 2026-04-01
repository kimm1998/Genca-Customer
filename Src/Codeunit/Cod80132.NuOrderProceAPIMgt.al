codeunit 80132 "NuOrder Price API Mgt."
{
    procedure ProcessAllPending()
    var
        Buffer: Record "NuOrder Price Buffer";
        LastTemplate: Code[20];
    begin
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::New, Buffer.Status::"Needs Sync");
        Buffer.SetCurrentKey("Price List Code", "Item No.", "Color Code", "Season Code", "Currency Code");
        if not Buffer.FindSet() then
            exit;

        LastTemplate := '';
        repeat
            if Buffer."Price List Code" <> LastTemplate then begin
                ProcessTemplate(Buffer."Price List Code");
                LastTemplate := Buffer."Price List Code";
            end;
        until Buffer.Next() = 0;
    end;

    procedure ProcessTemplate(TemplateCode: Code[20])
    var
        Setup: Record "NuORDER Setup";
        PayloadMgt: Codeunit "NuOrder Price Payload Mgt.";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        Url: Text;
        PayloadTxt: Text;
        RespTxt: Text;
    begin
        Setup.Get();
        Setup.TestField(Enabled, true);

        PayloadTxt := BuildPayloadWithResolvedIds(TemplateCode);
        if PayloadTxt = '' then
            exit;

        Url := Setup.GetBaseUrl() + '/api/pricesheet/' + TemplateCode;

        Content.WriteFrom(PayloadTxt);
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        Request.Method := 'POST';
        Request.SetRequestUri(Url);
        Request.Content := Content;

        // TODO: add OAuth/signature header same as your existing NuOrder API codeunit

        if not Client.Send(Request, Response) then
            Error('NuORDER pricesheet call failed.');

        Response.Content.ReadAs(RespTxt);

        if Response.IsSuccessStatusCode() then
            MarkTemplateAsSynced(TemplateCode, Format(Response.HttpStatusCode()), RespTxt)
        else
            MarkTemplateAsError(TemplateCode, Format(Response.HttpStatusCode()), RespTxt);
    end;

    local procedure BuildPayloadWithResolvedIds(TemplateCode: Code[20]): Text
    var
        // Implement by cloning payload builder and resolving _id via GetProductByExternalId
        PayloadTxt: Text;
    begin
        // brand_id = ItemNo + '_' + ColorCode
        // cache dictionary per template processing
        exit(PayloadTxt);
    end;

    local procedure MarkTemplateAsSynced(TemplateCode: Code[20]; HttpStatus: Text; ResponseTxt: Text)
    var
        Buffer: Record "NuOrder Price Buffer";
    begin
        Buffer.SetRange("Price List Code", TemplateCode);
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::New, Buffer.Status::"Needs Sync");
        if Buffer.FindSet() then
            repeat
                Buffer.Status := Buffer.Status::Synced;
                Buffer."Last Http Status" := HttpStatus;
                Buffer."Last Http Response" := CopyStr(ResponseTxt, 1, MaxStrLen(Buffer."Last Http Response"));
                Buffer."Last Error" := '';
                Buffer."Modified At" := CurrentDateTime;
                Buffer.Modify();
            until Buffer.Next() = 0;
    end;

    local procedure MarkTemplateAsError(TemplateCode: Code[20]; HttpStatus: Text; ResponseTxt: Text)
    var
        Buffer: Record "NuOrder Price Buffer";
    begin
        Buffer.SetRange("Price List Code", TemplateCode);
        Buffer.SetFilter(Status, '%1|%2', Buffer.Status::New, Buffer.Status::"Needs Sync");
        if Buffer.FindSet() then
            repeat
                Buffer.Status := Buffer.Status::Error;
                Buffer."Last Http Status" := HttpStatus;
                Buffer."Last Http Response" := CopyStr(ResponseTxt, 1, MaxStrLen(Buffer."Last Http Response"));
                Buffer."Last Error" := CopyStr(ResponseTxt, 1, MaxStrLen(Buffer."Last Error"));
                Buffer."Modified At" := CurrentDateTime;
                Buffer.Modify();
            until Buffer.Next() = 0;
    end;
}