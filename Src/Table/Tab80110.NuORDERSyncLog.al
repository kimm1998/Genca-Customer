table 80110 "NuORDER Sync Log"
{
    Caption = 'NuORDER Sync Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }
        field(10; "Entity Type"; Enum "NuORDER Entity Type")
        {
        }
        field(20; "Source Table No."; Integer)
        {
        }
        field(30; "Source No."; Code[20])
        {
        }
        field(40; "Source SystemId"; Guid)
        {
        }
        field(50; "Buffer Entry No."; Integer)
        {
        }
        field(60; Status; Enum "NuORDER Sync Status")
        {
        }
        field(70; "Attempt Count"; Integer)
        {
        }
        field(80; "Error Message"; Text[2048])
        {
        }
        field(90; "Request Body"; Blob)
        {
            SubType = Memo;
        }
        field(100; "Response Body"; Blob)
        {
            SubType = Memo;
        }
        field(110; "Created At"; DateTime)
        {
        }
        field(120; "Last Attempt At"; DateTime)
        {
        }
        field(130; "Success At"; DateTime)
        {
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Entity Type", Status)
        {
        }
        key(Key3; "Source Table No.", "Source No.")
        {
        }
    }
}
