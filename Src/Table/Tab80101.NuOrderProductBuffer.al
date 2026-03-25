table 80101 "NuOrder Product Buffer"
{
    Caption = 'NuOrder Product Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item."No.";
        }

        field(2; "Color Code"; Code[10])
        {
            Caption = 'Color Code';
            NotBlank = true;
            TableRelation = "K3PF Item Color"."Color Code" where("Item No." = field("Item No."));
        }

        field(3; "Season Code"; Code[20])
        {
            Caption = 'Season Code';
            NotBlank = true;
            TableRelation = "K3PF Season".Code;
        }
        field(4; "Status"; enum "NuOrder Integration Status")
        {
            Caption = 'Product Name';
        }

        field(5; "Last Error"; Text[500])
        {
            Caption = 'Last Error';
        }
        field(6; "Last Status Code"; Text[20])
        {
            Caption = 'Last Status Code';
        }
        field(7; "Last Http Status"; Text[100])
        {
            Caption = 'Last Http Status';
        }
        field(8; "Last Http Response"; Text[500])
        {
            Caption = 'Last Response';
        }
    }

    keys
    {
        key(PK; "Item No.", "Color Code", "Season Code")
        {
            Clustered = true;
        }
    }
}