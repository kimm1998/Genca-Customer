table 80100 "NuORDER Setup"
{
    Caption = 'NuORDER Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }

        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'If disabled, no NuORDER calls should run.';
        }

        field(3; Env; Option)
        {
            Caption = 'Env';
            ToolTip = 'NuORDER environment host prefix. Example: sandbox1 or next.';
            OptionMembers = sandbox1,next;
        }

        field(4; "Application Name"; Text[100])
        {
            Caption = 'Application Name';
            ToolTip = 'Used during Initiate so NuORDER shows this app in API Management.';
        }

        field(5; "Consumer Key"; Text[200])
        {
            Caption = 'Consumer Key';
        }
        field(6; "Consumer Secret"; Text[300])
        {
            DataClassification = ToBeClassified;
        }
        field(7; "Auth Status"; Option)
        {
            Caption = 'Auth Status';
            OptionMembers = NotConnected,Initiated,Connected;
            OptionCaption = 'Not Connected,Initiated,Connected';
        }
        field(8; "Token"; Text[300])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Token Secret"; Text[300])
        {
            DataClassification = ToBeClassified;
        }

        field(100; "Base URL"; text[250])
        {
            DataClassification = ToBeClassified;
        }
        field(101; "Initiate URL"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(102; "Token URL"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(103; "Product API URL"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(104; "Customer API URL"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure EnsureSingleRecord()
    begin

        if not Get() then begin
            Init();
            Enabled := false;
            Env := Env::sandbox1;
            "Auth Status" := "Auth Status"::NotConnected;
            Insert();
        end;
    end;

    procedure GetBaseUrl(): Text
    begin
        exit(StrSubstNo(Rec."Base URL", Env));
    end;

    // trigger OnModify()
    // begin
    //     If not (Rec."Auth Status" = Rec."Auth Status"::NotConnected) then
    //         Error('To modify on the Setup, the Auth Status should be Not Connected.');
    // end;
}
