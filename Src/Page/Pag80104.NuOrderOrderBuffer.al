page 80104 "NuOrder Order Buffer"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "NuOrder Order Buffer";
    Caption = 'NuOrder Order Buffer';
    CardPageId = "NuOrder Order Buffer Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {

                field("Environment Code"; Rec."Environment Code")
                {
                }
                field("Buffer Status"; Rec."Buffer Status")
                {
                    ToolTip = 'Specifies the internal processing status.', Comment = '%';
                    StyleExpr = BufferStatusStyle;
                }

                field("NuOrder ID"; Rec."NuOrder ID")
                {
                    ToolTip = 'Specifies the value of the NuOrder ID field.', Comment = '%';
                }
                field("Order No."; Rec."Order No.")
                {
                    ToolTip = 'Specifies the value of the Order No. field.', Comment = '%';
                }
                field("External ID"; Rec."External ID")
                {
                    ToolTip = 'Specifies the value of the External ID field.', Comment = '%';
                }
                field("Customer PO No."; Rec."Customer PO No.")
                {
                    ToolTip = 'Specifies the value of the Customer PO No. field.', Comment = '%';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the value of the Currency Code field.', Comment = '%';
                }
                field("NuOrder Status"; Rec."NuOrder Status")
                {
                    ToolTip = 'Specifies the value of the NuOrder Status field.', Comment = '%';
                }
                field("Product Brand ID"; Rec."Product Brand ID")
                {
                    ToolTip = 'Specifies the value of the Product Brand ID field.', Comment = '%';
                }
                field("Product Season"; Rec."Product Season")
                {
                    ToolTip = 'Specifies the value of the Product Season field.', Comment = '%';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {


            action(SyncOrders)
            {
                Caption = 'Sync to NuORDER';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Sync to NuORDER the product corresponding to the current buffer row. This will build the NuORDER product payload and push it to NuORDER API. If the operation is successful, the buffer record will be deleted.';

                trigger OnAction()
                var
                    NuOrderProductAPIMgt: Codeunit "NuOrder Order API Mgt.";
                begin
                    NuOrderProductAPIMgt.SyncOrdersToBuffer();
                end;
            }
            action(CreateSalesOrders)
            {
                Caption = 'Create Sales Orders';
                ApplicationArea = All;
                Image = NewDocument;
                ToolTip = 'Create sales orders from the buffer records that are in Ready status. This will attempt to create a sales order for each Ready record, and if successful, mark the buffer record as Processed.';

                trigger OnAction()
                var
                    NuOrderOrderMgt: Codeunit "NuOrder Sales Order Mgt.";
                    CreatedCount: Integer;
                begin
                    NuOrderOrderMgt.CreateSingleSalesOrder(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        BufferStatusStyle := Rec.SetBufferStatusStyle();
    end;

    var
        BufferStatusStyle: Text;

}