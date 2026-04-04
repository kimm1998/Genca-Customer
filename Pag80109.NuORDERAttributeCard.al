page 80109 "NuORDER Attribute Card"
{
    PageType = Card;
    SourceTable = "NuORDER Attribute";
    ApplicationArea = All;
    Caption = 'NuORDER Attribute';

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Description EN"; Rec."Description EN")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}