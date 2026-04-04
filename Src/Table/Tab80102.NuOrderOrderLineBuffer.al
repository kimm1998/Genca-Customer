table 80102 "NuOrder Order Line Buffer"
{
    Caption = 'NuOrder Order Line Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(26; "Environment Code"; Code[50])
        {
            Caption = 'Environment Code';
        }
        field(1; "Order ID"; Text[50])
        {
            Caption = 'Order ID';
            NotBlank = true;
            TableRelation = "NuOrder Order Buffer"."NuOrder ID";
        }

        field(2; "Line Item ID"; Text[50])
        {
            Caption = 'Line Item ID';
            NotBlank = true;
        }

        field(3; Size; Text[50])
        {
            Caption = 'Size';
            NotBlank = true;
        }

        field(4; "Product ID"; Text[50])
        {
            Caption = 'Product ID';
        }

        field(5; "Style Number"; Code[50])
        {
            Caption = 'Style Number';
        }

        field(6; Color; Text[100])
        {
            Caption = 'Color';
        }

        field(7; "Color Code"; Code[50])
        {
            Caption = 'Color Code';
        }

        field(8; "Brand ID"; Text[100])
        {
            Caption = 'Brand ID';
        }

        field(9; Season; Text[50])
        {
            Caption = 'Season';
        }

        field(10; Department; Text[50])
        {
            Caption = 'Department';
        }

        field(11; "Ship Start"; Text[50])
        {
            Caption = 'Ship Start';
        }

        field(12; "Ship End"; Text[50])
        {
            Caption = 'Ship End';
        }

        field(13; "Retail String"; Text[30])
        {
            Caption = 'Retail String';
        }

        field(14; Warehouse; Text[50])
        {
            Caption = 'Warehouse';
        }

        field(15; Prebook; Boolean)
        {
            Caption = 'Prebook';
        }

        field(16; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }

        field(17; Price; Decimal)
        {
            Caption = 'Price';
        }

        field(18; Retail; Decimal)
        {
            Caption = 'Retail';
        }

        field(19; "Price Precise"; Text[30])
        {
            Caption = 'Price Precise';
        }

        field(20; "Original Price"; Decimal)
        {
            Caption = 'Original Price';
        }

        field(21; "Units Per Pack"; Integer)
        {
            Caption = 'Units Per Pack';
        }

        field(22; "Buffer Status"; Enum "NuOrder Buffer Status")
        {
            Caption = 'Buffer Status';
        }

        field(23; "Retrieved At"; DateTime)
        {
            Caption = 'Retrieved At';
        }

        field(24; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
        }

        field(25; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
        }
    }

    keys
    {
        key(PK; "Environment Code", "Order ID", "Line Item ID", Size)
        {
            Clustered = true;
        }

        key(OrderKey; "Order ID")
        {
        }

        key(ItemKey; "Style Number", "Color Code", Size)
        {
        }
    }
}