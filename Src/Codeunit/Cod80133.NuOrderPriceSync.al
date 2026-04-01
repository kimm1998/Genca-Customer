codeunit 80133 "NuOrder Price Job Queue"
{
    Subtype = Normal;

    trigger OnRun()
    var
        ApiMgt: Codeunit "NuOrder Price API Mgt.";
    begin
        ApiMgt.ProcessAllPending();
    end;
}