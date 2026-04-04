table 80108 "NuOrder Order Buffer"
{
    Caption = 'NuOrder Order Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(59; "Environment Code"; Code[50])
        {
            Caption = 'Environment Code';
        }
        field(1; "NuOrder ID"; Text[50])
        {
            Caption = 'NuOrder ID';
            NotBlank = true;
        }

        field(2; "Order No."; Text[50])
        {
            Caption = 'Order No.';
        }

        field(3; "External ID"; Text[50])
        {
            Caption = 'External ID';
        }

        field(4; "Customer PO No."; Text[100])
        {
            Caption = 'Customer PO No.';
        }

        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }

        field(6; "NuOrder Status"; Text[30])
        {
            Caption = 'NuOrder Status';
        }

        field(7; "Product Brand ID"; Text[100])
        {
            Caption = 'Product Brand ID';
        }

        field(8; "Product Season"; Text[50])
        {
            Caption = 'Product Season';
        }

        field(9; "Product Style No."; Text[50])
        {
            Caption = 'Product Style No.';
        }

        field(10; "Product Color"; Text[100])
        {
            Caption = 'Product Color';
        }

        field(11; Total; Decimal)
        {
            Caption = 'Total';
        }

        field(12; "Buffer Status"; Enum "NuOrder Buffer Status")
        {
            Caption = 'Buffer Status';
        }

        field(13; "Retrieved At"; DateTime)
        {
            Caption = 'Retrieved At';
        }

        field(14; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
        }

        field(15; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
        }

        field(16; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
        }


        field(18; Discount; Decimal)
        {
            Caption = 'Discount';
        }

        field(19; "Additional Percentage"; Decimal)
        {
            Caption = 'Additional Percentage';
        }

        field(20; "Additional Percentage Label"; Text[100])
        {
            Caption = 'Additional Percentage Label';
        }

        field(21; "Total Quantity"; Decimal)
        {
            Caption = 'Total Quantity';
        }

        field(22; "Created On"; Text[50])
        {
            Caption = 'Created On';
        }

        field(23; "Modified On"; Text[50])
        {
            Caption = 'Modified On';
        }

        field(24; "Start Ship"; Text[50])
        {
            Caption = 'Start Ship';
        }

        field(25; "End Ship"; Text[50])
        {
            Caption = 'End Ship';
        }

        field(26; Notes; Text[2048])
        {
            Caption = 'Notes';
        }

        field(27; "Submitted By"; Text[100])
        {
            Caption = 'Submitted By';
        }

        field(28; "Payment Status"; Text[50])
        {
            Caption = 'Payment Status';
        }

        field(29; "Schema ID"; Text[50])
        {
            Caption = 'Schema ID';
        }

        field(30; "Order Group ID"; Text[50])
        {
            Caption = 'Order Group ID';
        }

        field(31; "Top Style Number"; Code[50])
        {
            Caption = 'Top Style Number';
        }

        field(32; Split; Boolean)
        {
            Caption = 'Split';
        }

        field(33; "Buyer Submitted"; Boolean)
        {
            Caption = 'Buyer Submitted';
        }

        field(34; Edited; Boolean)
        {
            Caption = 'Edited';
        }

        field(35; Locked; Boolean)
        {
            Caption = 'Locked';
        }

        field(36; "Rep Name"; Text[100])
        {
            Caption = 'Rep Name';
        }

        field(37; "Rep Code"; Text[50])
        {
            Caption = 'Rep Code';
        }

        field(38; "Rep Email"; Text[100])
        {
            Caption = 'Rep Email';
        }

        field(39; "Creator Name"; Text[100])
        {
            Caption = 'Creator Name';
        }

        field(40; "Retailer ID"; Text[50])
        {
            Caption = 'Retailer ID';
        }

        field(41; "Retailer Name"; Text[100])
        {
            Caption = 'Retailer Name';
        }

        field(42; "Retailer Code"; Text[50])
        {
            Caption = 'Retailer Code';
        }

        field(43; "Buyer Name"; Text[100])
        {
            Caption = 'Buyer Name';
        }

        field(44; "Buyer Email"; Text[100])
        {
            Caption = 'Buyer Email';
        }

        field(45; "Bill-to Line 1"; Text[100])
        {
            Caption = 'Bill-to Line 1';
        }

        field(46; "Bill-to Country"; Text[50])
        {
            Caption = 'Bill-to Country';
        }

        field(47; "Bill-to City"; Text[50])
        {
            Caption = 'Bill-to City';
        }

        field(48; "Bill-to State"; Text[50])
        {
            Caption = 'Bill-to State';
        }

        field(49; "Bill-to Zip"; Text[30])
        {
            Caption = 'Bill-to Zip';
        }

        field(50; "Bill-to Ref"; Text[50])
        {
            Caption = 'Bill-to Ref';
        }

        field(51; "Bill-to Code"; Text[50])
        {
            Caption = 'Bill-to Code';
        }

        field(52; "Ship-to Line 1"; Text[100])
        {
            Caption = 'Ship-to Line 1';
        }

        field(53; "Ship-to Country"; Text[50])
        {
            Caption = 'Ship-to Country';
        }

        field(54; "Ship-to City"; Text[50])
        {
            Caption = 'Ship-to City';
        }

        field(55; "Ship-to State"; Text[50])
        {
            Caption = 'Ship-to State';
        }

        field(56; "Ship-to Zip"; Text[30])
        {
            Caption = 'Ship-to Zip';
        }

        field(57; "Ship-to Ref"; Text[50])
        {
            Caption = 'Ship-to Ref';
        }

        field(58; "Ship-to Code"; Text[50])
        {
            Caption = 'Ship-to Code';
        }
    }

    keys
    {
        key(PK; "Environment Code", "NuOrder ID")
        {
            Clustered = true;
        }

        key(OrderNo; "Order No.")
        {
        }

        key(Status; "Buffer Status", "Retrieved At")
        {
        }
    }


    var




    procedure SetBufferStatusStyle(): Text
    var
        BufferStatusStyle: Text;
    begin
        case Rec."Buffer Status" of
            Rec."Buffer Status"::Ready:
                BufferStatusStyle := Format(PageStyle::StandardAccent);

            Rec."Buffer Status"::Processing:
                BufferStatusStyle := Format(PageStyle::Ambiguous);

            Rec."Buffer Status"::Processed:
                BufferStatusStyle := Format(PageStyle::Favorable);

            Rec."Buffer Status"::Error:
                BufferStatusStyle := Format(PageStyle::Unfavorable);

            Rec."Buffer Status"::Ignored:
                BufferStatusStyle := Format(PageStyle::Subordinate);

            else
                BufferStatusStyle := Format(PageStyle::Standard);

                exit(BufferStatusStyle);
        end;
    end;

}