codeunit 80130 "NuOrder Price Buffer Mgt."
{
    procedure EnqueueFromPriceListLine(var PriceListLine: Record "Price List Line")
    var
        ItemVariant: Record "Item Variant";
        Item: Record Item;
        Header: Record "Price List Header";
        CurrCode: code[10];
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.get;
        if PriceListLine."Asset Type" <> PriceListLine."Asset Type"::Item then
            exit;
        if PriceListLine."Asset No." = '' then
            exit;
        if PriceListLine."Variant Code" = '' then
            exit;
        if PriceListLine."Price List Code" = '' then
            exit;
        if PriceListLine."Currency Code" = '' then
            CurrCode := GLSetup."LCY Code"
        else
            CurrCode := PriceListLine."Currency Code";
 
        if not Item.Get(PriceListLine."Asset No.") then
            exit;
        if not ItemVariant.Get(PriceListLine."Asset No.", PriceListLine."Variant Code") then
            exit;
        if not Header.Get(PriceListLine."Price List Code") then
            exit;
 
        UpsertBuffer(
            PriceListLine."Price List Code",
            PriceListLine."Asset No.",
            ItemVariant."K3PFColor Code",
            Item."K3PFSeason Code",
            CurrCode);
    end;
 
    procedure EnqueueFromItemVariant(var ItemVariant: Record "Item Variant")
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", ItemVariant."Item No.");
        PriceListLine.SetRange("Variant Code", ItemVariant.Code);
        if PriceListLine.FindSet() then
            repeat
                EnqueueFromPriceListLine(PriceListLine);
            until PriceListLine.Next() = 0;
    end;
 
    local procedure UpsertBuffer(PriceListCode: Code[20]; ItemNo: Code[20]; ColorCode: Code[20]; SeasonCode: Code[20]; CurrencyCode: Code[10])
    var
        Buffer: Record "NuOrder Price Buffer";
    begin
        Buffer.SetRange("Price List Code", PriceListCode);
        Buffer.SetRange("Item No.", ItemNo);
        Buffer.SetRange("Color Code", ColorCode);
        Buffer.SetRange("Season Code", SeasonCode);
        Buffer.SetRange("Currency Code", CurrencyCode);
 
        if Buffer.FindFirst() then begin
            Buffer.Status := Buffer.Status::"Needs Sync";
            Buffer."Modified At" := CurrentDateTime;
            Buffer.Modify();
        end else begin
            Buffer.Init();
            Buffer."Price List Code" := PriceListCode;
            Buffer."Item No." := ItemNo;
            Buffer."Color Code" := ColorCode;
            Buffer."Season Code" := SeasonCode;
            Buffer."Currency Code" := CurrencyCode;
            Buffer.Status := Buffer.Status::New;
            Buffer."Created At" := CurrentDateTime;
            Buffer."Modified At" := CurrentDateTime;
            Buffer.Insert();
        end;
    end;
 
    [EventSubscriber(ObjectType::Table, Database::"Price List Line", OnAfterInsertEvent, '', false, false)]
    local procedure PriceListLine_OnAfterInsert(var Rec: Record "Price List Line"; RunTrigger: Boolean)
    begin
        EnqueueFromPriceListLine(Rec);
    end;
 
    [EventSubscriber(ObjectType::Table, Database::"Price List Line", OnAfterModifyEvent, '', false, false)]
    local procedure PriceListLine_OnAfterModify(var Rec: Record "Price List Line"; var xRec: Record "Price List Line"; RunTrigger: Boolean)
    begin
        EnqueueFromPriceListLine(Rec);
    end;
}