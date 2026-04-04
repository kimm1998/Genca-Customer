enum 80107 "NuOrder Buffer Status"
{
    Extensible = true;

    value(0; Ready)
    {
        Caption = 'Ready';
    }

    value(1; Processing)
    {
        Caption = 'Processing';
    }

    value(2; Processed)
    {
        Caption = 'Processed';
    }

    value(3; Error)
    {
        Caption = 'Error';
    }

    value(4; Ignored)
    {
        Caption = 'Ignored';
    }
}