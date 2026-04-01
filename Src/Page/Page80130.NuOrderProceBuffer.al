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
                field("Last Http Status"; Rec."Last Http Status") { ApplicationArea = All; }
                field("Last Error"; Rec."Last Error") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field("Modified At"; Rec."Modified At") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportNuOrderPayloadTxt)
            {
                Caption = 'Export Payload (.txt)';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Builds the NuORDER price sheet payload for the current template and downloads it as a .txt file.';

                trigger OnAction()
                begin
                    ExportCurrentPayloadToTxt();
                end;
            }
            action(SyncSelectedTemplate)
            {
                Caption = 'Sync Template';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Sync the selected price list template to NuOrder';

                trigger OnAction()
                var
                    ApiMgt: Codeunit "NuOrder Price API Mgt.";
                begin
                    Rec.TestField("Price List Code");
                    ApiMgt.ProcessTemplate(Rec."Price List Code");
                    CurrPage.Update(false);
                    Message('Template %1 sync completed.', Rec."Price List Code");
                end;
            }

            action(SyncAllPending)
            {
                Caption = 'Sync All Pending';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Sync all pending price list entries to NuOrder';

                trigger OnAction()
                var
                    ApiMgt: Codeunit "NuOrder Price API Mgt.";
                begin
                    ApiMgt.ProcessAllPending();
                    CurrPage.Update(false);
                    Message('All pending entries have been processed.');
                end;
            }

            action(ResetToNew)
            {
                Caption = 'Reset to New';
                ApplicationArea = All;
                Image = ResetStatus;
                ToolTip = 'Reset selected entries status to New for re-sync';

                trigger OnAction()
                var
                    Buffer: Record "NuOrder Price Buffer";
                begin
                    CurrPage.SetSelectionFilter(Buffer);
                    if Buffer.FindSet() then
                        repeat
                            Buffer.Status := Buffer.Status::New;
                            Buffer."Last Error" := '';
                            Buffer."Modified At" := CurrentDateTime;
                            Buffer.Modify();
                        until Buffer.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
        }
    }
    local procedure ExportCurrentPayloadToTxt()
    var
        ApiMgt: Codeunit "NuOrder Price API Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        PayloadTxt: Text;
        FileName: Text;
    begin
        Rec.TestField("Price List Code");

        PayloadTxt := ApiMgt.BuildPayloadForExport(Rec."Price List Code");

        if PayloadTxt = '' then
            Error('No data found for Price List Code %1', Rec."Price List Code");

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadTxt);

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);

        FileName := StrSubstNo('NuOrder_PriceSheet_%1_%2.txt', Rec."Price List Code", Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2>'));

        DownloadFromStream(InStr, 'Export NuOrder Payload', '', 'Text Files (*.txt)|*.txt', FileName);
    end;
}