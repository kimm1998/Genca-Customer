page 80101 "NuORDER Credentials Dialog"
{
    PageType = StandardDialog;
    Caption = 'NuORDER Credentials';

    layout
    {
        area(content)
        {
            group(General)
            {
                field(ConsumerKey; ConsumerKeyTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Consumer Key';
                }

                field(ConsumerSecret; ConsumerSecretTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Consumer Secret';
                    ExtendedDatatype = Masked;
                }
            }
        }
    }

    var
        ConsumerKeyTxt: Text[200];
        ConsumerSecretTxt: Text[300];

    procedure SetDefaults(DefaultKey: Text; DefaultSecret: Text)
    begin
        ConsumerKeyTxt := DefaultKey;
        ConsumerSecretTxt := DefaultSecret;
    end;

    procedure GetConsumerKey(): Text[200]
    begin
        exit(ConsumerKeyTxt);
    end;

    procedure GetConsumerSecret(): Text[300]
    begin
        exit(ConsumerSecretTxt);
    end;
}