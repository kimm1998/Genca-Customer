table 80103 "NuORDER Attribute"
{
    Caption = 'NuORDER Attribute';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "NuORDER Attribute Type")
        {
            Caption = 'Type';
        }
        field(2; Code; Code[20])
        {
            Caption = 'Code';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Description EN"; Text[100])
        {
            Caption = 'Description EN';
        }
    }

    keys
    {
        key(PK; Type, Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Description EN")
        {
        }
    }
}