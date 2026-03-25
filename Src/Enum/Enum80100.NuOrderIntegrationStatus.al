enum 80100 "NuOrder Integration Status"
{
    Extensible = true;

    value(0; New)
    {
        Caption = 'New';
    }

    value(1; "Needs Sync")
    {
        Caption = 'Needs Sync';
    }

    value(2; Synced)
    {
        Caption = 'Synced';
    }

    value(3; Error)
    {
        Caption = 'Error';
    }
}