page 80130 "NuOrder Price Buffer"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "NuOrder Price Buffer";
    Caption = 'NuOrder Price Buffer';

    layout
    {
        area(Content)
        {
            repeater(Rep)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Price List Code"; Rec."Price List Code") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Color Code"; Rec."Color Code") { ApplicationArea = All; }
                field("Season Code"; Rec."Season Code") { ApplicationArea = All; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Last Error"; Rec."Last Error") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncSelectedTemplate)
            {
                Caption = 'Sync Template';
                ApplicationArea = All;
                Image = Export;

                trigger OnAction()
                var
                    ApiMgt: Codeunit "NuOrder Price API Mgt.";
                begin
                    Rec.TestField("Price List Code");
                    ApiMgt.ProcessTemplate(Rec."Price List Code");
                end;
            }

            action(SyncAllPending)
            {
                Caption = 'Sync All Pending';
                ApplicationArea = All;
                Image = Export;

                trigger OnAction()
                var
                    ApiMgt: Codeunit "NuOrder Price API Mgt.";
                begin
                    ApiMgt.ProcessAllPending();
                end;
            }
        }
    }
}