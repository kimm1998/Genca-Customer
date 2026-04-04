codeunit 80112 "NuOrder Sales Order Mgt."
{
    trigger OnRun()
    var
        OrderBuffer: Record "NuOrder Order Buffer";
        CreatedCount: Integer;
    begin
        OrderBuffer.SetRange("Buffer Status", OrderBuffer."Buffer Status"::Ready);

        if OrderBuffer.FindSet() then
            repeat
                CreatedCount += CreateSingleSalesOrder(OrderBuffer);
            until OrderBuffer.Next() = 0;

    end;



    procedure CreateSingleSalesOrder(var OrderBuffer: Record "NuOrder Order Buffer"): Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        if OrderBuffer."Buffer Status" = OrderBuffer."Buffer Status"::Processed then
            exit(0);

        CreateSalesHeaderFromBuffer(OrderBuffer, SalesHeader);
        CreateSalesLinesFromBuffer(OrderBuffer, SalesHeader);
        MarkOrderAsProcessed(OrderBuffer, SalesHeader."No.");

        exit(1);
    end;

    local procedure CreateSalesHeaderFromBuffer(OrderBuffer: Record "NuOrder Order Buffer"; var SalesHeader: Record "Sales Header")
    var
        CustomerNo: Code[20];
        GLSetup: Record "General Ledger Setup";
        CurrencyCode: Code[10];
    begin
        CustomerNo := ResolveCustomerNo(OrderBuffer);

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);

        if OrderBuffer."Customer PO No." <> '' then
            SalesHeader.Validate("External Document No.", CopyStr(OrderBuffer."Customer PO No.", 1, MaxStrLen(SalesHeader."External Document No.")));

        if OrderBuffer."Order No." <> '' then
            SalesHeader.Validate("Your Reference", CopyStr(OrderBuffer."Order No.", 1, MaxStrLen(SalesHeader."Your Reference")));

        GLSetup.Get();
        if OrderBuffer."Currency Code" <> GLSetup."LCY Code" then
            CurrencyCode := OrderBuffer."Currency Code"
        else
            CurrencyCode := '';

        if CurrencyCode <> SalesHeader."Currency Code" then
            SalesHeader.Validate("Currency Code", CurrencyCode);


        if OrderBuffer."Bill-to City" <> '' then;
        // TODO: if you want, later map ship-to / bill-to details from the buffer to the BC sales header

        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLinesFromBuffer(OrderBuffer: Record "NuOrder Order Buffer"; SalesHeader: Record "Sales Header")
    var
        LineBuffer: Record "NuOrder Order Line Buffer";
        NextLineNo: Integer;
        CurrentItemNo: Code[20];
        CurrentMatrixLineNo: Integer;
    begin
        LineBuffer.SetRange("Order ID", OrderBuffer."NuOrder ID");
        // LineBuffer.SetRange("Buffer Status", LineBuffer."Buffer Status"::Ready);//TODO uncomment this lines
        LineBuffer.SetCurrentKey("Style Number", "Color Code", Size);

        if not LineBuffer.FindSet() then
            Error('No ready line buffers were found for NuOrder order %1.', OrderBuffer."NuOrder ID");

        NextLineNo := 10000;
        Clear(CurrentItemNo);
        CurrentMatrixLineNo := 0;

        repeat
            if CurrentItemNo <> LineBuffer."Style Number" then begin
                CurrentItemNo := LineBuffer."Style Number";
                CurrentMatrixLineNo := CreateMatrixSalesLine(SalesHeader, CurrentItemNo, NextLineNo);
                NextLineNo += 10000;
            end;

            CreateSingleSalesLine(SalesHeader, LineBuffer, NextLineNo, CurrentMatrixLineNo);
            MarkLineAsProcessed(LineBuffer);
            NextLineNo += 10000;
        until LineBuffer.Next() = 0;
    end;

    local procedure CreateMatrixSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LineNo: Integer): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine.Type::K3PFMatrix);
        SalesLine.Validate("No.", ItemNo);

        SalesLine.Modify(true);

        exit(LineNo);
    end;

    local procedure CreateSingleSalesLine(SalesHeader: Record "Sales Header"; LineBuffer: Record "NuOrder Order Line Buffer"; LineNo: Integer; MatrixLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        VariantCode: Code[20];
        ShipmentDate: Date;
    begin
        VariantCode := ResolveVariantCode(LineBuffer);

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", LineBuffer."Style Number");
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Validate("K3PFMatrix Line No.", MatrixLineNo);
        SalesLine.Validate(Quantity, LineBuffer.Quantity);

        if LineBuffer.Price <> 0 then
            SalesLine.Validate("Unit Price", LineBuffer.Price);

        if TryParseNuOrderDate(LineBuffer."Ship Start", ShipmentDate) then
            SalesLine.Validate("Shipment Date", ShipmentDate);

        SalesLine.Modify(true);
    end;

    local procedure ResolveCustomerNo(OrderBuffer: Record "NuOrder Order Buffer"): Code[20]
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        CustomerNo := CopyStr(OrderBuffer."Retailer Code", 1, MaxStrLen(CustomerNo));

        if CustomerNo = '' then
            Error('Retailer Code is blank on NuOrder order %1.', OrderBuffer."NuOrder ID");

        if not Customer.Get(CustomerNo) then
            Error('Customer %1 was not found for NuOrder order %2.', CustomerNo, OrderBuffer."NuOrder ID");

        exit(CustomerNo);
    end;

    local procedure ResolveVariantCode(LineBuffer: Record "NuOrder Order Line Buffer"): Code[20]
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.Reset();
        ItemVariant.SetRange("Item No.", LineBuffer."Style Number");
        ItemVariant.SetRange("K3PFColor Code", LineBuffer."Color Code");
        ItemVariant.SetRange("K3PFSize Code", LineBuffer.Size);
        if ItemVariant.FindFirst() then
            exit(ItemVariant.Code);

        ItemVariant.Reset();
        ItemVariant.SetRange("Item No.", LineBuffer."Style Number");
        ItemVariant.SetRange("K3PFColor Code", LineBuffer."Color Code");
        ItemVariant.SetRange("K3PF2nd Size Code", LineBuffer.Size);
        if ItemVariant.FindFirst() then
            exit(ItemVariant.Code);

        Error(
            'No variant found for item %1, color %2, size %3.',
            LineBuffer."Style Number",
            LineBuffer."Color Code",
            LineBuffer.Size);
    end;

    local procedure MarkOrderAsProcessed(var OrderBuffer: Record "NuOrder Order Buffer"; SalesOrderNo: Code[20])
    begin
        OrderBuffer."Buffer Status" := OrderBuffer."Buffer Status"::Processed;
        OrderBuffer."Processed At" := CurrentDateTime();
        OrderBuffer."Sales Order No." := SalesOrderNo;
        OrderBuffer."Last Error" := '';
        OrderBuffer.Modify(true);
    end;

    local procedure MarkLineAsProcessed(var LineBuffer: Record "NuOrder Order Line Buffer")
    begin
        LineBuffer."Buffer Status" := LineBuffer."Buffer Status"::Processed;
        LineBuffer."Processed At" := CurrentDateTime();
        LineBuffer."Last Error" := '';
        LineBuffer.Modify(true);
    end;

    local procedure TryParseNuOrderDate(InputTxt: Text; var ParsedDate: Date): Boolean
    var
        DatePart: Text;
        YearNo: Integer;
        MonthNo: Integer;
        DayNo: Integer;
    begin
        Clear(ParsedDate);

        if InputTxt = '' then
            exit(false);

        DatePart := InputTxt;

        if StrPos(DatePart, 'T') > 0 then
            DatePart := CopyStr(DatePart, 1, StrPos(DatePart, 'T') - 1);

        if StrLen(DatePart) < 10 then
            exit(false);

        if not Evaluate(YearNo, CopyStr(DatePart, 1, 4)) then
            exit(false);

        if not Evaluate(MonthNo, CopyStr(DatePart, 6, 2)) then
            exit(false);

        if not Evaluate(DayNo, CopyStr(DatePart, 9, 2)) then
            exit(false);

        ParsedDate := DMY2Date(DayNo, MonthNo, YearNo);
        exit(true);
    end;
}