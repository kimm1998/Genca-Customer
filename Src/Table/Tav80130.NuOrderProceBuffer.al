table 80130 "NuOrder Price Buffer"
{
    Caption = 'NuOrder Price Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Price List Code"; Code[20]) { Caption = 'Price List Code'; }
        field(3; "Item No."; Code[20]) { Caption = 'Item No.'; TableRelation = Item."No."; }
        field(4; "Color Code"; Code[20]) { Caption = 'Color Code'; }
        field(5; "Season Code"; Code[20]) { Caption = 'Season Code'; }
        field(6; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(7; Status; Enum "NuOrder Integration Status") { Caption = 'Status'; }
        field(8; "Last Error"; Text[500]) { Caption = 'Last Error'; }
        field(9; "Last Http Status"; Text[100]) { Caption = 'Last Http Status'; }
        field(10; "Last Http Response"; Text[500]) { Caption = 'Last Http Response'; }
        field(11; "Created At"; DateTime) { Caption = 'Created At'; }
        field(12; "Modified At"; DateTime) { Caption = 'Modified At'; }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Key2; "Price List Code", "Item No.", "Color Code", "Season Code", "Currency Code") { }
        key(Key3; Status) { }
    }
}