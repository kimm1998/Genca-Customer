page 80105 "NuOrder Order Lines Subform"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "NuOrder Order Line Buffer";
    Caption = 'Lines';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line Item ID"; Rec."Line Item ID")
                {
                    ToolTip = 'Specifies the NuOrder line item ID.', Comment = '%';
                }
                field("Style Number"; Rec."Style Number")
                {
                    ToolTip = 'Specifies the style number.', Comment = '%';
                }
                field("Color Code"; Rec."Color Code")
                {
                    ToolTip = 'Specifies the color code.', Comment = '%';
                }
                field(Size; Rec.Size)
                {
                    ToolTip = 'Specifies the size.', Comment = '%';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the quantity.', Comment = '%';
                }
                field(Price; Rec.Price)
                {
                    ToolTip = 'Specifies the price.', Comment = '%';
                }
                field(Retail; Rec.Retail)
                {
                    ToolTip = 'Specifies the retail amount.', Comment = '%';
                }
                field("Original Price"; Rec."Original Price")
                {
                    ToolTip = 'Specifies the original price.', Comment = '%';
                }
                field("Units Per Pack"; Rec."Units Per Pack")
                {
                    ToolTip = 'Specifies the units per pack.', Comment = '%';
                }
                field(Color; Rec.Color)
                {
                    ToolTip = 'Specifies the color.', Comment = '%';
                }
                field("Brand ID"; Rec."Brand ID")
                {
                    ToolTip = 'Specifies the brand ID.', Comment = '%';
                }
                field(Season; Rec.Season)
                {
                    ToolTip = 'Specifies the season.', Comment = '%';
                }
                field(Department; Rec.Department)
                {
                    ToolTip = 'Specifies the department.', Comment = '%';
                }
                field("Ship Start"; Rec."Ship Start")
                {
                    ToolTip = 'Specifies the ship start.', Comment = '%';
                }
                field("Ship End"; Rec."Ship End")
                {
                    ToolTip = 'Specifies the ship end.', Comment = '%';
                }
                field(Warehouse; Rec.Warehouse)
                {
                    ToolTip = 'Specifies the warehouse.', Comment = '%';
                }
                field(Prebook; Rec.Prebook)
                {
                    ToolTip = 'Specifies whether the line is prebook.', Comment = '%';
                }
                field("Buffer Status"; Rec."Buffer Status")
                {
                    ToolTip = 'Specifies the buffer status.', Comment = '%';
                }
            }
        }
    }
}