codeunit 80130 "NuOrder Price Buffer Mgt."
{
    procedure EnqueuePriceList(PriceListCode: Code[20])
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        HeaderBuffer: Record "NuOrder Price Header Buffer";
        LineBuffer: Record "NuOrder Price Line Buffer";
        ItemVariant: Record "Item Variant";
        Item: Record Item;
    begin
        if not PriceListHeader.Get(PriceListCode) then
            exit;

        if PriceListHeader.Status <> PriceListHeader.Status::Active then
            exit;

        // Insert or update header buffer record
        if not HeaderBuffer.Get(PriceListCode) then begin
            HeaderBuffer.Init();
            HeaderBuffer."Price List Code" := PriceListCode;
            HeaderBuffer.Insert();
        end else begin
            HeaderBuffer.Processed := false;
            HeaderBuffer.Modify();
        end;

        // Delete existing line buffer records for this price list to re-enqueue
        LineBuffer.SetRange("Price List Code", PriceListCode);
        LineBuffer.DeleteAll();

        // Loop through active price list lines
        PriceListLine.SetRange("Price List Code", PriceListCode);
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.SetFilter("Starting Date", '<=%1', WorkDate());
        if PriceListLine.FindSet() then
            repeat
                if (PriceListLine."Ending Date" >= WorkDate()) or (PriceListLine."Ending Date" = 0D) then begin
                    Clear(LineBuffer);
                    LineBuffer.Init();
                    LineBuffer."Price List Code" := PriceListCode;
                    LineBuffer."Price List Line No." := PriceListLine."Line No.";
                    LineBuffer."Item No." := PriceListLine."Asset No.";
                    LineBuffer."Variant Code" := PriceListLine."Variant Code";
                    LineBuffer."Unit Price" := PriceListLine."Unit Price";

                    // Look up Item Variant for Color and Size
                    if (PriceListLine."Variant Code" <> '') and (PriceListLine."Asset No." <> '') then begin
                        if ItemVariant.Get(PriceListLine."Asset No.", PriceListLine."Variant Code") then begin
                            LineBuffer."Color Code" := ItemVariant."K3PFColor Code";
                            LineBuffer."Size Code" := ItemVariant."K3PFSize Code";
                        end;
                    end;

                    // Look up Item for Season
                    if PriceListLine."Asset No." <> '' then begin
                        if Item.Get(PriceListLine."Asset No.") then
                            LineBuffer."Season Code" := Item."K3PFSeason Code";
                    end;

                    LineBuffer.Insert();
                end;
            until PriceListLine.Next() = 0;
    end;

    procedure EnqueueAllActivePriceLists()
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListHeader.SetRange(Status, PriceListHeader.Status::Active);
        if PriceListHeader.FindSet() then
            repeat
                EnqueuePriceList(PriceListHeader.Code);
            until PriceListHeader.Next() = 0;
    end;

    //===========================================
    // Event Subscribers
    //===========================================

    [EventSubscriber(ObjectType::Table, Database::"Price List Header", OnAfterModifyEvent, '', false, false)]
    local procedure PriceListHeader_OnAfterModify(var Rec: Record "Price List Header"; var xRec: Record "Price List Header"; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Price Buffer Mgt.";
    begin
        if Rec.Status = Rec.Status::Active then
            Mgt.EnqueuePriceList(Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Price List Line", OnAfterInsertEvent, '', false, false)]
    local procedure PriceListLine_OnAfterInsert(var Rec: Record "Price List Line"; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Price Buffer Mgt.";
    begin
        Mgt.EnqueuePriceList(Rec."Price List Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Price List Line", OnAfterModifyEvent, '', false, false)]
    local procedure PriceListLine_OnAfterModify(var Rec: Record "Price List Line"; var xRec: Record "Price List Line"; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Price Buffer Mgt.";
        FieldValidationMgt: Codeunit "Field Validation Mgt.";
    begin
        if not FieldValidationMgt.CheckPriceListLineField(Rec, xRec) then
            exit;
        Mgt.EnqueuePriceList(Rec."Price List Code");
    end;
}
