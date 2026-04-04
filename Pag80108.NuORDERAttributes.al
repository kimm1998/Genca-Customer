page 80108 "NuORDER Attributes"
{
    PageType = List;
    SourceTable = "NuORDER Attribute";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'NuORDER Attributes';
    CardPageId = "NuORDER Attribute Card";

    layout
    {
        area(content)
        {
            repeater(General)
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