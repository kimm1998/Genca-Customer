page 80100 "NuORDER Setup"
{
    PageType = Card;
    SourceTable = "NuORDER Setup";
    Caption = 'NuORDER Setup';
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;


    AccessByPermission = tabledata "NuORDER Setup" = RIMD;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Enabled field.';
                }
                field("Auth Status"; Rec."Auth Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Auth Status field.';
                }
                // field("Last Handshake At"; Rec."Last Handshake At") { ApplicationArea = All; Editable = false; }
            }

            group(PostmanVariables)
            {
                Caption = 'Authorization';

                field(env; Rec.Env)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Env field.';
                }
                field(application_name; Rec."Application Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Application Name field.';
                }
                field(consumer_key; Rec."Consumer Key")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = Masked;
                    Editable = false;
                    ToolTip = 'Specifies the value of the Consumer Key field.';
                }
                field(consumer_secret; Rec."Consumer Secret")
                {
                    ApplicationArea = All;
                    Caption = 'Consumer Secret';
                    Editable = false;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the value of the Consumer Secret field.';
                }
                field(token_set; Rec.Token)
                {
                    ApplicationArea = All;
                    Caption = 'Token';
                    Editable = false;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the value of the Token field.';
                }

                field(token_secret_set; Rec."Token Secret")
                {
                    ApplicationArea = All;
                    Caption = 'Token Secret';
                    Editable = false;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the value of the Token Secret field.';
                }
            }
            group(Endpoints)
            {
                Caption = 'Integration Endpoints';

                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Base URL field.';
                }
                field("Initiate URL"; Rec."Initiate URL")
                {
                    ApplicationArea = all;
                }
                field("Token URL"; Rec."Token URL")
                {
                    ApplicationArea = all;
                }
                field("Product API URL"; Rec."Product API URL")
                {
                    ApplicationArea = all;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(SetCustomerCredentials)
            {
                Caption = 'Set Customer Credentials';
                ApplicationArea = All;
                Image = EncryptionKeys;
                ToolTip = 'Executes the Set Customer Credentials action.';

                trigger OnAction()
                var
                    Dlg: Page "NuORDER Credentials Dialog";
                begin
                    Dlg.SetDefaults(Rec."Consumer Key", Rec."Consumer Secret");
                    if Dlg.RunModal() <> Action::OK then
                        exit;

                    Rec."Consumer Key" := Dlg.GetConsumerKey();
                    Rec."Consumer Secret" := Dlg.GetConsumerSecret();

                    // reset auth when credentials change
                    Rec.Token := '';
                    Rec."Token Secret" := '';
                    Rec."Auth Status" := Rec."Auth Status"::NotConnected;

                    Rec.Modify(true);
                end;
            }

            action(Initiate)
            {
                Caption = 'Initiate';
                ApplicationArea = All;
                Image = Start;
                ToolTip = 'Executes the Initiate action.';

                trigger OnAction()
                var
                    Auth: Codeunit "NuORDER Auth Mgt";
                begin
                    Auth.Initiate(Rec);
                end;
            }

            action(Token)
            {
                Caption = 'Token';
                ApplicationArea = All;
                Image = Approve;
                ToolTip = 'Executes the Token action.';

                trigger OnAction()
                var
                    Auth: Codeunit "NuORDER Auth Mgt";
                    VerDlg: Page "NuORDER Verifier Dialog";
                begin
                    if VerDlg.RunModal() <> Action::OK then
                        exit;

                    Auth.ExchangeToken(Rec, VerDlg.GetVerifier());
                end;
            }

            action(ClearAuth)
            {
                Caption = 'Clear Token';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Executes the Clear Token action.';

                trigger OnAction()
                begin
                    Rec."Application Name" := '';
                    Rec."Consumer Key" := '';
                    Rec."Consumer Secret" := '';
                    Rec.Token := '';
                    Rec."Token Secret" := '';
                    Rec."Auth Status" := Rec."Auth Status"::NotConnected;
                    Rec.Modify(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.EnsureSingleRecord();
    end;
}