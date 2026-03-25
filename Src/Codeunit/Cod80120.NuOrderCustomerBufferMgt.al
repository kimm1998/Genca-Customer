codeunit 80120 "NuOrder Customer Buffer Mgt."
{
    procedure EnqueueCustomer(CustomerNo: Code[20])
    var
        Buffer: Record "NuOrder Customer Buffer";
    begin
        if not Buffer.Get(CustomerNo) then begin
            Buffer.Init();
            Buffer."Customer No." := CustomerNo;
            Buffer.Insert();
        end;
    end;

    //===========================================
    // Event Subscribers
    //===========================================

    [EventSubscriber(ObjectType::Table, Database::Customer, OnAfterInsertEvent, '', false, false)]
    local procedure Customer_OnAfterInsert(var Rec: Record Customer; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Customer Buffer Mgt.";
    begin
        Mgt.EnqueueCustomer(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, OnAfterModifyEvent, '', false, false)]
    local procedure Customer_OnAfterModify(var Rec: Record Customer; var xRec: Record Customer; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Customer Buffer Mgt.";
        FieldValidation: Codeunit "Field Validation Mgt.";
    begin
        if not FieldValidation.CheckCustomerField(Rec, xRec) then
            exit;
        Mgt.EnqueueCustomer(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", OnAfterInsertEvent, '', false, false)]
    local procedure ShipToAddress_OnAfterInsert(var Rec: Record "Ship-to Address"; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Customer Buffer Mgt.";
    begin
        Mgt.EnqueueCustomer(Rec."Customer No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Ship-to Address", OnAfterModifyEvent, '', false, false)]
    local procedure ShipToAddress_OnAfterModify(var Rec: Record "Ship-to Address"; var xRec: Record "Ship-to Address"; RunTrigger: Boolean)
    var
        Mgt: Codeunit "NuOrder Customer Buffer Mgt.";
    begin
        Mgt.EnqueueCustomer(Rec."Customer No.");
    end;
}
