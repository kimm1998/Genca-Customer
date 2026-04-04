page 80106 "NuOrder Order Buffer Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "NuOrder Order Buffer";
    Caption = 'NuOrder Order Buffer';
   

    layout
    {
        area(Content)
        {
            group(Internal)
            {
                Caption = 'Internal';
                field("Environment Code"; Rec."Environment Code")
                {
                    ToolTip = 'Specifies the NuORDER environment code.', Comment = '%';
                }
                field("Buffer Status"; Rec."Buffer Status")
                {
                    ToolTip = 'Specifies the internal processing status.', Comment = '%';
                    StyleExpr = BufferStatusStyle;
                }
                field("Retrieved At"; Rec."Retrieved At")
                {
                    ToolTip = 'Specifies when the record was retrieved.', Comment = '%';
                }
                field("Processed At"; Rec."Processed At")
                {
                    ToolTip = 'Specifies when the record was processed.', Comment = '%';
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ToolTip = 'Specifies the linked sales order number.', Comment = '%';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ToolTip = 'Specifies the last internal error.', Comment = '%';
                    MultiLine = true;
                }
            }
            group(General)
            {
                Caption = 'General';

                field("NuOrder ID"; Rec."NuOrder ID")
                {
                    ToolTip = 'Specifies the NuOrder ID.', Comment = '%';
                }
                field("Order No."; Rec."Order No.")
                {
                    ToolTip = 'Specifies the NuOrder order number.', Comment = '%';
                }
                field("External ID"; Rec."External ID")
                {
                    ToolTip = 'Specifies the external ID.', Comment = '%';
                }
                field("Customer PO No."; Rec."Customer PO No.")
                {
                    ToolTip = 'Specifies the customer PO number.', Comment = '%';
                }
                field("NuOrder Status"; Rec."NuOrder Status")
                {
                    ToolTip = 'Specifies the NuOrder status.', Comment = '%';
                }
                field("Payment Status"; Rec."Payment Status")
                {
                    ToolTip = 'Specifies the payment status.', Comment = '%';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ToolTip = 'Specifies the currency code.', Comment = '%';
                }
                field(Total; Rec.Total)
                {
                    ToolTip = 'Specifies the total.', Comment = '%';
                }
                field(Discount; Rec.Discount)
                {
                    ToolTip = 'Specifies the discount.', Comment = '%';
                }
                field("Additional Percentage"; Rec."Additional Percentage")
                {
                    ToolTip = 'Specifies the additional percentage.', Comment = '%';
                }
                field("Additional Percentage Label"; Rec."Additional Percentage Label")
                {
                    ToolTip = 'Specifies the additional percentage label.', Comment = '%';
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ToolTip = 'Specifies the total quantity.', Comment = '%';
                }
            }

            group(Product)
            {
                Caption = 'Product';

                field("Top Style Number"; Rec."Top Style Number")
                {
                    ToolTip = 'Specifies the top style number.', Comment = '%';
                }
                field("Product Style No."; Rec."Product Style No.")
                {
                    ToolTip = 'Specifies the product style number.', Comment = '%';
                }
                field("Product Color"; Rec."Product Color")
                {
                    ToolTip = 'Specifies the product color.', Comment = '%';
                }
                field("Product Season"; Rec."Product Season")
                {
                    ToolTip = 'Specifies the product season.', Comment = '%';
                }
                field("Product Brand ID"; Rec."Product Brand ID")
                {
                    ToolTip = 'Specifies the product brand ID.', Comment = '%';
                }
                field("Schema ID"; Rec."Schema ID")
                {
                    ToolTip = 'Specifies the schema ID.', Comment = '%';
                }
                field("Order Group ID"; Rec."Order Group ID")
                {
                    ToolTip = 'Specifies the order group ID.', Comment = '%';
                }
            }

            group(Retailer)
            {
                Caption = 'Retailer';

                field("Retailer ID"; Rec."Retailer ID")
                {
                    ToolTip = 'Specifies the retailer ID.', Comment = '%';
                }
                field("Retailer Name"; Rec."Retailer Name")
                {
                    ToolTip = 'Specifies the retailer name.', Comment = '%';
                }
                field("Retailer Code"; Rec."Retailer Code")
                {
                    ToolTip = 'Specifies the retailer code.', Comment = '%';
                }
                field("Buyer Name"; Rec."Buyer Name")
                {
                    ToolTip = 'Specifies the buyer name.', Comment = '%';
                }
                field("Buyer Email"; Rec."Buyer Email")
                {
                    ToolTip = 'Specifies the buyer email.', Comment = '%';
                }
                field("Submitted By"; Rec."Submitted By")
                {
                    ToolTip = 'Specifies who submitted the order.', Comment = '%';
                }
                field("Creator Name"; Rec."Creator Name")
                {
                    ToolTip = 'Specifies the creator name.', Comment = '%';
                }
            }

            group(Representative)
            {
                Caption = 'Representative';

                field("Rep Name"; Rec."Rep Name")
                {
                    ToolTip = 'Specifies the rep name.', Comment = '%';
                }
                field("Rep Code"; Rec."Rep Code")
                {
                    ToolTip = 'Specifies the rep code.', Comment = '%';
                }
                field("Rep Email"; Rec."Rep Email")
                {
                    ToolTip = 'Specifies the rep email.', Comment = '%';
                }
            }

            group(Dates)
            {
                Caption = 'Dates';

                field("Created On"; Rec."Created On")
                {
                    ToolTip = 'Specifies the created on value from NuOrder.', Comment = '%';
                }
                field("Modified On"; Rec."Modified On")
                {
                    ToolTip = 'Specifies the modified on value from NuOrder.', Comment = '%';
                }
                field("Start Ship"; Rec."Start Ship")
                {
                    ToolTip = 'Specifies the start ship value.', Comment = '%';
                }
                field("End Ship"; Rec."End Ship")
                {
                    ToolTip = 'Specifies the end ship value.', Comment = '%';
                }
            }

            group(Flags)
            {
                Caption = 'Flags';

                field(Split; Rec.Split)
                {
                    ToolTip = 'Specifies whether the order is split.', Comment = '%';
                }
                field("Buyer Submitted"; Rec."Buyer Submitted")
                {
                    ToolTip = 'Specifies whether the order was buyer submitted.', Comment = '%';
                }
                field(Edited; Rec.Edited)
                {
                    ToolTip = 'Specifies whether the order was edited.', Comment = '%';
                }
                field(Locked; Rec.Locked)
                {
                    ToolTip = 'Specifies whether the order is locked.', Comment = '%';
                }
            }

            group("Billing Address")
            {
                Caption = 'Billing Address';

                field("Bill-to Line 1"; Rec."Bill-to Line 1")
                {
                    ToolTip = 'Specifies the bill-to line 1.', Comment = '%';
                }
                field("Bill-to City"; Rec."Bill-to City")
                {
                    ToolTip = 'Specifies the bill-to city.', Comment = '%';
                }
                field("Bill-to State"; Rec."Bill-to State")
                {
                    ToolTip = 'Specifies the bill-to state.', Comment = '%';
                }
                field("Bill-to Zip"; Rec."Bill-to Zip")
                {
                    ToolTip = 'Specifies the bill-to zip.', Comment = '%';
                }
                field("Bill-to Country"; Rec."Bill-to Country")
                {
                    ToolTip = 'Specifies the bill-to country.', Comment = '%';
                }
                field("Bill-to Ref"; Rec."Bill-to Ref")
                {
                    ToolTip = 'Specifies the bill-to reference.', Comment = '%';
                }
                field("Bill-to Code"; Rec."Bill-to Code")
                {
                    ToolTip = 'Specifies the bill-to code.', Comment = '%';
                }
            }

            group("Shipping Address")
            {
                Caption = 'Shipping Address';

                field("Ship-to Line 1"; Rec."Ship-to Line 1")
                {
                    ToolTip = 'Specifies the ship-to line 1.', Comment = '%';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ToolTip = 'Specifies the ship-to city.', Comment = '%';
                }
                field("Ship-to State"; Rec."Ship-to State")
                {
                    ToolTip = 'Specifies the ship-to state.', Comment = '%';
                }
                field("Ship-to Zip"; Rec."Ship-to Zip")
                {
                    ToolTip = 'Specifies the ship-to zip.', Comment = '%';
                }
                field("Ship-to Country"; Rec."Ship-to Country")
                {
                    ToolTip = 'Specifies the ship-to country.', Comment = '%';
                }
                field("Ship-to Ref"; Rec."Ship-to Ref")
                {
                    ToolTip = 'Specifies the ship-to reference.', Comment = '%';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ToolTip = 'Specifies the ship-to code.', Comment = '%';
                }
            }



            part(Lines; "NuOrder Order Lines Subform")
            {
                ApplicationArea = All;
                SubPageLink = "Environment Code" = field("Environment Code"), "Order ID" = field("NuOrder ID");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncOrders)
            {
                Caption = 'Sync Orders';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Synchronize orders from NuORDER into the buffer tables.';

                trigger OnAction()
                var
                    NuOrderOrderAPIMgt: Codeunit "NuOrder Order API Mgt.";
                begin
                    NuOrderOrderAPIMgt.SyncOrdersToBuffer();
                    CurrPage.Update(false);
                end;
            }

            action(CreateSalesOrder)
            {
                Caption = 'Create Sales Orders';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Synchronize orders from NuORDER into the buffer tables.';

                trigger OnAction()
                var
                    NuOrderOrderAPIMgt: Codeunit "NuOrder Sales Order Mgt.";
                begin
                    NuOrderOrderAPIMgt.CreateSingleSalesOrder(Rec);
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