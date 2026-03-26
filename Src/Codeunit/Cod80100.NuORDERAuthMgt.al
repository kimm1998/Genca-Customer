codeunit 80100 "NuORDER Auth Mgt"
{
    procedure Initiate(var Setup: Record "NuORDER Setup")
    var
        ResponseTxt: Text;
        Tok: Text;
        TokSecret: Text;
    begin
        Setup.TestField(Enabled, true);
        Setup.TestField("Consumer Key");
        Setup.TestField("Consumer Secret");
        Setup.TestField("Application Name");

        ResponseTxt := CallAuthEndpoint(
            Setup,
            'initiate',
            '',      // token empty
            '',      // token_secret empty
            '');     // verifier empty

        ParseTokenResponse(ResponseTxt, Tok, TokSecret);

        Setup.Token := Tok;
        Setup."Token Secret" := TokSecret;
        Setup."Auth Status" := Setup."Auth Status"::Initiated;
        Setup.Modify(false);

        Message(
          'Initiate done. Approve the pending application "%1" in NuORDER and copy the Verifier, then run Token.',
          Setup."Application Name");
    end;

    procedure ExchangeToken(var Setup: Record "NuORDER Setup"; Verifier: Text)
    var
        ResponseTxt: Text;
        Tok: Text;
        TokSecret: Text;
    begin
        Setup.TestField(Enabled, true);

        if Setup."Auth Status" <> Setup."Auth Status"::Initiated then
            Error('Run Initiate first.');

        Setup.TestField("Consumer Key");
        Setup.TestField("Consumer Secret");
        Setup.TestField(Token);
        Setup.TestField("Token Secret");

        ResponseTxt := CallAuthEndpoint(
            Setup,
            'token',
            Setup.Token,
            Setup."Token Secret",
            Verifier);

        ParseTokenResponse(ResponseTxt, Tok, TokSecret);

        Setup.Token := Tok;
        Setup."Token Secret" := TokSecret;
        Setup."Auth Status" := Setup."Auth Status"::Connected;
        Setup.Modify(true);

        Message('Connected. Token/Token Secret updated.');
    end;

    local procedure CallAuthEndpoint(
        Setup: Record "NuORDER Setup";
        AuthType: Text;
        Token: Text;
        TokenSecret: Text;
        Verifier: Text
    ) ResponseTxt: Text
    var
        Url: Text;
        Req: HttpRequestMessage;
        Resp: HttpResponseMessage;
        Client: HttpClient;
        Headers: HttpHeaders;
        AuthHeader: Text;
    begin
        case AuthType of
            'initiate':
                begin
                    Url := ParseURL(StrSubstNo(GetBaseUrlSafe(Setup), Setup.Env), Setup."Initiate URL");
                    AuthHeader := BuildAuthHeader_PostmanStyle(
                        Setup,
                        'GET',
                        Url,
                        Token,
                        TokenSecret,
                        Verifier,
                        true);
                end;
            'token':
                begin
                    Url := ParseURL(StrSubstNo(GetBaseUrlSafe(Setup), Setup.Env), Setup."Token URL");
                    AuthHeader := BuildAuthHeader_PostmanStyle(
                        Setup,
                        'GET',
                        Url,
                        Token,
                        TokenSecret,
                        Verifier,
                        false);
                end;
        end;

        Req.SetRequestUri(Url);
        Req.Method := 'GET';

        Req.GetHeaders(Headers);
        Headers.Add('Authorization', AuthHeader);

        Client.Send(Req, Resp);
        Resp.Content().ReadAs(ResponseTxt);

        if not Resp.IsSuccessStatusCode() then
            Error('NuORDER auth failed (%1): %2', Resp.HttpStatusCode(), ResponseTxt);

        exit(ResponseTxt);
    end;

    procedure GetBaseUrlSafe(Setup: Record "NuORDER Setup"): Text
    begin
        // If Base URL field is empty -> default to https://{env}.nuorder.com
        if Setup."Base URL" <> '' then
            exit(Setup."Base URL");

        exit(StrSubstNo(Setup."Base URL", Format(Setup.Env)));
    end;


    procedure ParseURL(Endpoint: Text; Path: Text): Text
    var
        FullURL: Text;
    begin
        FullURL := Endpoint.TrimEnd('/') + '/' + Path.TrimStart('/');
        exit(FullURL);
    end;

    // ============================
    // GET SPECIFIC URL
    // ============================

    procedure GetProductURL(): Text
    var
        Setup: Record "NuORDER Setup";
        Url: Text;
    begin
        Setup.Get();
        Url := ParseURL(StrSubstNo(GetBaseUrlSafe(Setup), Setup.Env), Setup."Product API URL");
        exit(Url);
    end;

    procedure GetCustomerURL(): Text
    var
        Setup: Record "NuORDER Setup";
        Url: Text;
    begin
        Setup.Get();
        Url := ParseURL(StrSubstNo(GetBaseUrlSafe(Setup), Setup.Env), Setup."Customer API URL");
        exit(Url);
    end;

    procedure GetPriceSheetURL(): Text
    var
        Setup: Record "NuORDER Setup";
        Url: Text;
    begin
        Setup.Get();
        Url := ParseURL(StrSubstNo(GetBaseUrlSafe(Setup), Setup.Env), Setup."Price Sheet API URL");
        exit(Url);
    end;

    // ============================
    // POSTMAN-STYLE HEADER CREATION
    // ============================
    local procedure BuildAuthHeader_PostmanStyle(
        Setup: Record "NuORDER Setup";
        HttpMethod: Text;
        Endpoint: Text;
        Token: Text;
        TokenSecret: Text;
        Verifier: Text;
        IncludeCallbackAndAppName: Boolean
    ) Header: Text
    var
        Timestamp: Text;
        Nonce: Text;
        Signature: Text;
    begin
        // Postman: (+new Date()).toString().slice(0, 10)
        Timestamp := GetOAuthTimestamp10Digits();

        // Postman: generateTokenString(16) from specific keylist
        Nonce := GenerateTokenString(16);

        Signature := CreateSignature_PostmanStyle(
            HttpMethod,
            Endpoint,
            Setup."Consumer Key",
            Setup."Consumer Secret",
            Token,
            TokenSecret,
            Timestamp,
            Nonce,
            IncludeCallbackAndAppName,
            Verifier);

        Header :=
            'OAuth oauth_consumer_key="' + Setup."Consumer Key" + '",' +
            'oauth_timestamp="' + Timestamp + '",' +
            'oauth_nonce="' + Nonce + '",' +
            'oauth_version="1.0",' +
            'oauth_signature_method="HMAC-SHA1",' +
            'oauth_token="' + Token + '",' +
            'oauth_signature="' + Signature + '"';

        if IncludeCallbackAndAppName then
            Header += ',oauth_callback="oob",application_name="' + Setup."Application Name" + '"';

        if Verifier <> '' then
            Header += ',oauth_verifier="' + Verifier + '"';

        exit(Header);
    end;

    local procedure CreateSignature_PostmanStyle(
        HttpMethod: Text;
        Endpoint: Text;
        ConsumerKey: Text;
        ConsumerSecret: Text;
        Token: Text;
        TokenSecret: Text;
        Timestamp: Text;
        Nonce: Text;
        IncludeCallback: Boolean;
        Verifier: Text
    ) Signature: Text
    var
        StringToSign: Text;
        SigningKey: SecretText;
        HashAlg: Option HMACMD5,HMACSHA1,HMACSHA256,HMACSHA384,HMACSHA512;
        CryptoMgt: Codeunit "Cryptography Management";
    begin
        // EXACT like your Postman function createSignature()
        StringToSign :=
            UpperCase(HttpMethod) +
            Endpoint +
            '?oauth_consumer_key=' + ConsumerKey + '&' +
            'oauth_token=' + Token + '&' +
            'oauth_timestamp=' + Timestamp + '&' +
            'oauth_nonce=' + Nonce + '&' +
            'oauth_version=1.0&' +
            'oauth_signature_method=HMAC-SHA1';

        if IncludeCallback then
            StringToSign += '&oauth_callback=oob';

        if Verifier <> '' then
            StringToSign += '&oauth_verifier=' + Verifier;

        // EXACT key: consumer_secret + '&' + token_secret
        SigningKey := ConsumerSecret + '&' + TokenSecret;

        HashAlg := HashAlg::HMACSHA1;

        // Postman outputs HEX string. GenerateHash() typically returns hex for HMAC as Text.
        exit(CryptoMgt.GenerateHash(StringToSign, SigningKey, HashAlg));
    end;


    procedure GetApiAuthorizationHeader(Setup: Record "NuORDER Setup"; HttpMethod: Text; FullUrl: Text): Text
    begin
        Setup.TestField(Enabled, true);
        Setup.TestField("Consumer Key");
        Setup.TestField("Consumer Secret");
        Setup.TestField(Token);
        Setup.TestField("Token Secret");

        if Setup."Auth Status" <> Setup."Auth Status"::Connected then
            Error('NuORDER is not connected. Run Initiate first, then Token.');

        exit(
            BuildAuthHeader_PostmanStyle(
                Setup,
                UpperCase(HttpMethod),
                FullUrl,
                Setup.Token,
                Setup."Token Secret",
                '',
                false)
        );
    end;

    // ============================
    // TIMESTAMP + NONCE HELPERS
    // ============================
    local procedure GetOAuthTimestamp10Digits(): Text
    var
        UnixTs: Codeunit "Unix Timestamp";
        TsInt: BigInteger;
        TsTxt: Text;
    begin
        TsInt := UnixTs.CreateTimestampSeconds();
        TsTxt := BigIntToDigits(TsInt);

        // enforce 10 digits (seconds)
        if StrLen(TsTxt) > 10 then
            TsTxt := CopyStr(TsTxt, 1, 10);

        exit(TsTxt);
    end;

    local procedure BigIntToDigits(Value: BigInteger): Text
    var
        Result: Text;
        Digit: Integer;
    begin
        if Value = 0 then
            exit('0');

        Result := '';
        while Value > 0 do begin
            Digit := Value mod 10;
            Result := Format(Digit) + Result;
            Value := Value div 10;
        end;

        exit(Result);
    end;

    local procedure GenerateTokenString(Length: Integer): Text
    var
        KeyList: Text;
        I: Integer;
        Pick: Integer;
        Token: Text;
    begin
        KeyList := 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
        Token := '';

        Randomize();
        for I := 1 to Length do begin
            Pick := Random(StrLen(KeyList)) + 1;
            Token += CopyStr(KeyList, Pick, 1);
        end;

        exit(Token);
    end;

    // ============================
    // RESPONSE PARSER
    // ============================
    local procedure ParseTokenResponse(ResponseTxt: Text; var Token: Text; var TokenSecret: Text)
    var
        JObj: JsonObject;
        JTok: JsonToken;
        AmpPos: Integer;
        Pair: Text;
        EqPos: Integer;
        K: Text;
        V: Text;
    begin
        Token := '';
        TokenSecret := '';

        ResponseTxt := DelChr(ResponseTxt, '<>', ' '); // trim spaces

        // ---- 1) JSON response (your case) ----
        if (StrLen(ResponseTxt) > 0) and (CopyStr(ResponseTxt, 1, 1) = '{') then begin
            if not JObj.ReadFrom(ResponseTxt) then
                Error('Invalid JSON token response: %1', ResponseTxt);

            if JObj.Get('oauth_token', JTok) then
                Token := JTok.AsValue().AsText();

            if JObj.Get('oauth_token_secret', JTok) then
                TokenSecret := JTok.AsValue().AsText();

            // some APIs use token/token_secret naming
            if (Token = '') and JObj.Get('token', JTok) then
                Token := JTok.AsValue().AsText();

            if (TokenSecret = '') and JObj.Get('token_secret', JTok) then
                TokenSecret := JTok.AsValue().AsText();

        end else begin
            // ---- 2) Query-string response fallback ----
            while ResponseTxt <> '' do begin
                AmpPos := StrPos(ResponseTxt, '&');
                if AmpPos = 0 then begin
                    Pair := ResponseTxt;
                    ResponseTxt := '';
                end else begin
                    Pair := CopyStr(ResponseTxt, 1, AmpPos - 1);
                    ResponseTxt := CopyStr(ResponseTxt, AmpPos + 1);
                end;

                EqPos := StrPos(Pair, '=');
                if EqPos > 0 then begin
                    K := CopyStr(Pair, 1, EqPos - 1);
                    V := CopyStr(Pair, EqPos + 1);

                    if (K = 'oauth_token') or (K = 'token') then
                        Token := V;

                    if (K = 'oauth_token_secret') or (K = 'token_secret') then
                        TokenSecret := V;
                end;
            end;
        end;

        if (Token = '') or (TokenSecret = '') then
            Error('Could not parse token/token_secret from response: %1', ResponseTxt);
    end;

}