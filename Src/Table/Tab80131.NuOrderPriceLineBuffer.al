table 80131 "NuOrder Price Line Buffer"
{
    Caption = 'NuOrder Price Line Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            NotBlank = true;
            TableRelation = "Price List Header".Code;
        }
        field(2; "Price List Line No."; Integer)
        {
            Caption = 'Price List Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
        }
        field(4; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(5; "Color Code"; Code[10])
        {
            Caption = 'Color Code';
        }
        field(6; "Size Code"; Code[20])
        {
            Caption = 'Size Code';
        }
        field(7; "Season Code"; Code[20])
        {
            Caption = 'Season Code';
        }
        field(8; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
        }
        field(9; "Processed"; Boolean)
        {
            Caption = 'Processed';
            InitValue = false;
        }
        field(10; "Status"; enum "NuOrder Integration Status")
        {
            Caption = 'Status';
        }
        field(11; "Last Error"; Text[500])
        {
            Caption = 'Last Error';
        }
    }

    keys
    {
        key(PK; "Price List Code", "Price List Line No.")
        {
            Clustered = true;
        }
        key(GroupKey; "Price List Code", "Item No.", "Color Code", "Season Code")
        {
        }
    }
}
