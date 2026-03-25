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
    begin
        if not HasRelevantFieldChanged(Rec, xRec) then
            exit;
        Mgt.EnqueueCustomer(Rec."No.");
    end;

    local procedure HasRelevantFieldChanged(Rec: Record Customer; xRec: Record Customer): Boolean
    begin
        if Rec.Name <> xRec.Name then exit(true);
        if Rec."Name 2" <> xRec."Name 2" then exit(true);
        if Rec.Address <> xRec.Address then exit(true);
        if Rec."Address 2" <> xRec."Address 2" then exit(true);
        if Rec.City <> xRec.City then exit(true);
        if Rec.County <> xRec.County then exit(true);
        if Rec."Post Code" <> xRec."Post Code" then exit(true);
        if Rec."Country/Region Code" <> xRec."Country/Region Code" then exit(true);
        if Rec."Phone No." <> xRec."Phone No." then exit(true);
        if Rec."E-Mail" <> xRec."E-Mail" then exit(true);
        if Rec.Contact <> xRec.Contact then exit(true);
        exit(false);
    end;
}
