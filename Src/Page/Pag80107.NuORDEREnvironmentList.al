page 80107 "NuORDER Environment List"
{
    PageType = List;
    SourceTable = "NuORDER Environment Setup";
    Caption = 'NuORDER Environments';
    UsageCategory = Administration;
    ApplicationArea = All;
    Editable = false;
    CardPageId = "NuORDER Setup Card";


    AccessByPermission = tabledata "NuORDER Environment Setup" = RIMD;

    layout
    {
        area(content)
        {
            repeater(control1)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Code field.';
                }
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

                field(Environment; Rec.Environment)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Env field.';
                }
                field(application_name; Rec."Application Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Application Name field.';
                }


                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specifies the value of the Base URL field.';
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

}