page 80130 "NuOrder Price Header Buffer"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "NuOrder Price Header Buffer";
    Caption = 'NuOrder Price Header Buffer';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Price List Code"; Rec."Price List Code")
                {
                    ToolTip = 'Specifies the value of the Price List Code field.', Comment = '%';
                }
                field(Processed; Rec.Processed)
                {
                    ToolTip = 'Specifies whether this price list has been successfully synced to NuORDER.', Comment = '%';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.', Comment = '%';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ToolTip = 'Specifies the value of the Last Error field.', Comment = '%';
                }
                field("Last Status Code"; Rec."Last Status Code")
                {
                    ToolTip = 'Specifies the value of the Last Status Code field.', Comment = '%';
                }
                field("Last Http Status"; Rec."Last Http Status")
                {
                    ToolTip = 'Specifies the value of the Last Http Status field.', Comment = '%';
                }
                field("Last Http Response"; Rec."Last Http Response")
                {
                    ToolTip = 'Specifies the value of the Last Http Response field.', Comment = '%';
                }
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
                ToolTip = 'Builds the NuORDER price sheet payload for the current buffer row and downloads it as a .txt file.';

                trigger OnAction()
                begin
                    ExportCurrentPayloadToTxt();
                end;
            }

            action(SyncToNuOrder)
            {
                Caption = 'Sync to NuORDER';
                ApplicationArea = All;
                Image = Export;
                ToolTip = 'Sync to NuORDER the price sheet corresponding to the current buffer row. This will build the NuORDER price sheet payload and push it to NuORDER API. If the operation is successful, the buffer record will be marked as processed.';

                trigger OnAction()
                var
                    NuOrderPriceAPIMgt: Codeunit "NuOrder Price API Mgt.";
                begin
                    NuOrderPriceAPIMgt.ProcessBufferedEntry(Rec);
                end;
            }

            action(EnqueueAllActivePriceLists)
            {
                Caption = 'Enqueue All Active Price Lists';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Enqueues all active price lists into the buffer for syncing to NuORDER.';

                trigger OnAction()
                var
                    NuOrderPriceBufferMgt: Codeunit "NuOrder Price Buffer Mgt.";
                begin
                    NuOrderPriceBufferMgt.EnqueueAllActivePriceLists();
                    CurrPage.Update(false);
                end;
            }
        }
    }


    local procedure ExportCurrentPayloadToTxt()
    var
        PayloadMgt: Codeunit "NuOrder Price Payload Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        PayloadTxt: Text;
        FileName: Text;
    begin
        Rec.TestField("Price List Code");

        PayloadTxt := PayloadMgt.BuildPriceSheetPayload(Rec);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadTxt);

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);

        FileName :=
          StrSubstNo(
            'NuOrder_PriceSheet_%1.txt',
            Rec."Price List Code");

        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
