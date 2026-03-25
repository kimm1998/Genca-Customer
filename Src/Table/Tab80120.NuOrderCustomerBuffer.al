table 80120 "NuOrder Customer Buffer"
{
    Caption = 'NuOrder Customer Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer."No.";
        }

        field(2; "Status"; enum "NuOrder Integration Status")
        {
            Caption = 'Status';
        }

        field(3; "Last Error"; Text[500])
        {
            Caption = 'Last Error';
        }
        field(4; "Last Status Code"; Text[20])
        {
            Caption = 'Last Status Code';
        }
        field(5; "Last Http Status"; Text[100])
        {
            Caption = 'Last Http Status';
        }
        field(6; "Last Http Response"; Text[500])
        {
            Caption = 'Last Response';
        }
    }

    keys
    {
        key(PK; "Customer No.")
        {
            Clustered = true;
        }
    }
}
