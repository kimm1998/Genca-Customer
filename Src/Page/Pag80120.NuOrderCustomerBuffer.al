page 80120 "NuOrder Customer Buffer"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "NuOrder Customer Buffer";
    Caption = 'NuOrder Customer Buffer';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Customer No."; Rec."Customer No.")
                {
                    ToolTip = 'Specifies the value of the Customer No. field.', Comment = '%';
                }
                field("Status"; Rec."Status")
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
                ToolTip = 'Builds the NuORDER customer payload for the current buffer row and downloads it as a .txt file.';

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
                ToolTip = 'Sync to NuORDER the customer corresponding to the current buffer row. This will build the NuORDER customer payload and push it to NuORDER API. If the operation is successful, the buffer record will be deleted.';

                trigger OnAction()
                var
                    NuOrderCustomerAPIMgt: Codeunit "NuOrder Customer API Mgt.";
                begin
                    NuOrderCustomerAPIMgt.ProcessBufferedEntry(Rec);
                end;
            }
        }
    }


    local procedure ExportCurrentPayloadToTxt()
    var
        PayloadMgt: Codeunit "NuOrder Customer Payload Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        PayloadTxt: Text;
        FileName: Text;
    begin
        Rec.TestField("Customer No.");

        PayloadTxt := PayloadMgt.BuildCreateOrUpdateCustomerPayload(Rec);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(PayloadTxt);

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);

        FileName :=
          StrSubstNo(
            'NuOrder_%1.txt',
            Rec."Customer No.");

        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
