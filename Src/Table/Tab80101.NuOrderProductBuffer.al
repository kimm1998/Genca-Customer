table 80101 "NuOrder Product Buffer"
{
    Caption = 'NuOrder Product Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Environment Code"; Code[50])
        {
            Caption = 'Environment Code';
            TableRelation = "NuORDER Environment Setup".Code;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item."No.";
        }

        field(3; "Color Code"; Code[10])
        {
            Caption = 'Color Code';
            NotBlank = true;
            TableRelation = "K3PF Item Color"."Color Code" where("Item No." = field("Item No."));
        }

        field(4; "Season Code"; Code[20])
        {
            Caption = 'Season Code';
            NotBlank = true;
            TableRelation = "K3PF Season".Code;
        }
        field(5; "Status"; enum "NuOrder Integration Status")
        {
            Caption = 'Product Name';
        }

        field(6; "Last Error"; Text[500])
        {
            Caption = 'Last Error';
        }
        field(7; "Last Status Code"; Text[20])
        {
            Caption = 'Last Status Code';
        }
        field(8; "Last Http Status"; Text[100])
        {
            Caption = 'Last Http Status';
        }
        field(9; "Last Http Response"; Text[500])
        {
            Caption = 'Last Response';
        }
    }

    keys
    {
        key(PK; "Environment Code", "Item No.", "Color Code", "Season Code")
        {
            Clustered = true;
        }
    }
}