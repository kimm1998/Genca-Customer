pageextension 80100 "NuOrder Item Ext" extends "Item Card"
{
    layout
    {
        addlast(Item)
        {
            field("NuORDER Category"; Rec."NuORDER Category")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the NuORDER Category field.';
            }
            field("NuORDER Subcategory"; Rec."NuORDER Subcategory")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the NuORDER Subcategory field.';
            }
            field("NuORDER Division"; Rec."NuORDER Division")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the NuORDER Division field.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}