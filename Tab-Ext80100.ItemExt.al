tableextension 80100 "ItemExt" extends Item
{
    fields
    {
        field(80100; "NuORDER Category"; Code[20])
        {
            Caption = 'NuORDER Category';
            TableRelation = "NuORDER Attribute".Code where(Type = const(Category));
        }

        field(80101; "NuORDER Subcategory"; Code[20])
        {
            Caption = 'NuORDER Subcategory';
            TableRelation = "NuORDER Attribute".Code where(Type = const(Subcategory));
        }

        field(80102; "NuORDER Division"; Code[20])
        {
            Caption = 'NuORDER Division';
            TableRelation = "NuORDER Attribute".Code where(Type = const(Division));
        }
    }
}