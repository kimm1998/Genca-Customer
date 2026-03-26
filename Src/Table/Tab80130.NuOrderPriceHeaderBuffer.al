table 80130 "NuOrder Price Header Buffer"
{
    Caption = 'NuOrder Price Header Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            NotBlank = true;
            TableRelation = "Price List Header".Code;
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
            Caption = 'Last Http Response';
        }
        field(7; "Processed"; Boolean)
        {
            Caption = 'Processed';
            InitValue = false;
        }
    }

    keys
    {
        key(PK; "Price List Code")
        {
            Clustered = true;
        }
    }
}
