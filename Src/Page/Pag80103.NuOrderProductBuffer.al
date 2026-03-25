page 80103 "NuOrder Product Buffer"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "NuOrder Product Buffer";
    Caption = 'NuOrder Product Buffer';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {

                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the value of the Item No. field.', Comment = '%';
                }
                field("Color Code"; Rec."Color Code")
                {
                    ToolTip = 'Specifies the value of the Color Code field.', Comment = '%';
                }
                field("Season Code"; Rec."Season Code")
                {
                    ToolTip = 'Specifies the value of the Season Code field.', Comment = '%';
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
                ToolTip = 'Builds the NuORDER product payload for the current buffer row and downloads it as a .txt file.';

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
                ToolTip = 'Sync to NuORDER the product corresponding to the current buffer row. This will build the NuORDER product payload and push it to NuORDER API. If the operation is successful, the buffer record will be deleted.';

                trigger OnAction()
                var
                    NuOrderProductAPIMgt: Codeunit "NuOrder Product API Mgt.";
                begin
                    NuOrderProductAPIMgt.ProcessBufferedEntry(Rec);
                end;
            }
        }
    }


    local procedure ExportCurrentPayloadToTxt()
    var
        PayloadMgt: Codeunit "NuOrder Product Payload Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        PayloadTxt: Text;
        FileName: Text;
    begin
        Rec.TestField("Item No.");
        Rec.TestField("Color Code");
        Rec.TestField("Season Code");

        PayloadTxt := PayloadMgt.BuildCreateOrUpdateProductPayload(Rec);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadTxt);

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);

        FileName :=
          StrSubstNo(
            'NuOrder_%1_%2_%3.txt',
            Rec."Item No.",
            Rec."Season Code",
            Rec."Color Code");

        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}