codeunit 80101 "NuOrder Item Buffer Mgt."
{
    procedure EnqueueFromItem(ItemNo: Code[20])
    var
        Qry: Query "Item Color Season Query";
    begin
        Qry.SetRange(Item_No, ItemNo);
        InsertQueryResults(Qry);
    end;

    procedure EnqueueFromItemColor(ItemNo: Code[20]; ColorCode: Code[20])
    var
        Qry: Query "Item Color Season Query";
    begin
        Qry.SetRange(Item_No, ItemNo);
        Qry.SetRange(Color_Code, ColorCode);
        InsertQueryResults(Qry);
    end;

    procedure EnqueueFromSeason(SeasonCode: Code[20])
    var
        Qry: Query "Item Color Season Query";
    begin
        Qry.SetRange(Season_Code, SeasonCode);
        InsertQueryResults(Qry);
    end;

    local procedure InsertQueryResults(var Qry: Query "Item Color Season Query")
    var
        Buffer: Record "NuOrder Product Buffer";
    begin
        Qry.Open();

        while Qry.Read() do begin
            if not Buffer.Get(Qry.Item_No, Qry.Color_Code, Qry.Season_Code) then begin
                Buffer.Init();
                Buffer."Item No." := Qry.Item_No;
                Buffer."Color Code" := Qry.Color_Code;
                Buffer."Season Code" := Qry.Season_Code;
                Buffer.Insert();
            end;
        end;

        Qry.Close();
    end;



    //===========================================
    // Event Subscribers - Main Tables
    //===========================================

    [EventSubscriber(ObjectType::Table, Database::Item, OnAfterInsertEvent, '', false, false)]
    local procedure Item_OnAfterInsert(var Rec: Record Item; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Item Buffer Mgt.";
    begin
        Mgt.EnqueueFromItem(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, OnAfterModifyEvent, '', false, false)]
    local procedure Item_OnAfterModify(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Item Buffer Mgt.";
        FieldValidationMgt: Codeunit "Field Validation Mgt.";
    begin
        if not fieldValidationMgt.CheckItemField(Rec, xRec) then
            exit;
        Mgt.EnqueueFromItem(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"K3PF Item Color", OnAfterInsertEvent, '', false, false)]
    local procedure ItemColor_OnAfterInsert(var Rec: Record "K3PF Item Color"; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Item Buffer Mgt.";
    begin
        Mgt.EnqueueFromItemColor(Rec."Item No.", Rec."Color Code");
    end;

    //============================
    // Event Subscribers - Related Tables
    //============================

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", OnAfterInsertEvent, '', false, false)]
    local procedure ItemVariant_OnAfterInsert(var Rec: Record "Item Variant"; RunTrigger: Boolean)
    var
        BufferMgt: Codeunit "NuOrder Item Buffer Mgt.";
        FieldValidationMgt: Codeunit "Field Validation Mgt.";
    begin
        if not FieldValidationMgt.CheckItemVariantFieldInsert(Rec) then
            exit;

        BufferMgt.EnqueueFromItem(Rec."Item No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", OnAfterModifyEvent, '', false, false)]
    local procedure ItemVariant_OnAfterModify(var Rec: Record "Item Variant"; var xRec: Record "Item Variant"; RunTrigger: Boolean)
    var
        BufferMgt: Codeunit "NuOrder Item Buffer Mgt.";
        FieldValidationMgt: Codeunit "Field Validation Mgt.";
    begin
        if not FieldValidationMgt.CheckItemVariantField(Rec, xRec) then
            exit;

        BufferMgt.EnqueueFromItem(Rec."Item No.");
    end;


    [EventSubscriber(ObjectType::Table, Database::"Price List Line", OnAfterModifyEvent, '', false, false)]
    local procedure PriceListLine_OnAfterModify(var Rec: Record "Price List Line"; var xRec: Record "Price List Line"; RunTrigger: Boolean)
    var
        BufferMgt: Codeunit "NuOrder Item Buffer Mgt.";
        FieldValidationMgt: Codeunit "Field Validation Mgt.";
    begin

        BufferMgt.EnqueueFromItem(xRec."Asset No.");
    end;


}