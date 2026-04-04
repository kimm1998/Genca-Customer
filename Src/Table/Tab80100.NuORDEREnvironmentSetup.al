table 80100 "NuORDER Environment Setup"
{
    Caption = 'NuORDER Environment Setup';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }

        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'If disabled, no NuORDER calls should run.';
        }
        field(3; "Base URL"; text[250])
        {
            DataClassification = ToBeClassified;
        }

        field(4; "Application Name"; Text[100])
        {
            Caption = 'Application Name';
            ToolTip = 'Used during Initiate so NuORDER shows this app in API Management.';
        }


        field(5; "Auth Status"; Option)
        {
            Caption = 'Auth Status';
            OptionMembers = NotConnected,Initiated,Connected;
            OptionCaption = 'Not Connected,Initiated,Connected';
        }


        field(6; "Environment"; Text[50])
        {
            Caption = 'Environment';
            ToolTip = 'NuORDER environment host prefix. Example: sandbox1 or next.';
        }

        field(7; "Consumer Key"; Text[200])
        {
            Caption = 'Consumer Key';
        }
        field(8; "Consumer Secret"; Text[300])
        {
            DataClassification = ToBeClassified;
        }

        field(9; "Token"; Text[300])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Token Secret"; Text[300])
        {
            DataClassification = ToBeClassified;
        }


        field(100; "Enable Order Sync"; Boolean)
        {
            Caption = 'Enable Order Sync';
            ToolTip = 'If enabled, orders will be synced from NuORDER to Business Central.';
        }
        field(101; "Enable Product Sync"; Boolean)
        {
            Caption = 'Enable Product Sync';
            ToolTip = 'If enabled, products will be synced from NuORDER to Business Central.';
        }
        field(102; "Enable Customer Sync"; Boolean)
        {
            Caption = 'Enable Customer Sync';
            ToolTip = 'If enabled, customers will be synced from NuORDER to Business Central.';
        }
        field(105; "Price Sheet API URL"; Text[50])//TODO : to be removed and hardcoded
        {
            DataClassification = ToBeClassified;
        }
        field(103; "Language"; Code[10])
        {
            Caption = 'Language';
            TableRelation = Language.Code;
        }


        field(200; "Last Order Sync Date"; Date)
        {
            Caption = 'Last Order Sync Date';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }


    procedure GetBaseUrl(): Text
    begin
        exit(StrSubstNo(Rec."Base URL", Environment));
    end;

    // trigger OnModify()
    // begin
    //     If not (Rec."Auth Status" = Rec."Auth Status"::NotConnected) then
    //         Error('To modify on the Setup, the Auth Status should be Not Connected.');
    // end;
}
