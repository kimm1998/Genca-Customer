enum 80110 "NuORDER Sync Status"
{
    Extensible = true;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Ready)
    {
        Caption = 'Ready';
    }
    value(2; Sent)
    {
        Caption = 'Sent';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
    value(4; Skipped)
    {
        Caption = 'Skipped';
    }
}
