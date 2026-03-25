enum 80111 "NuORDER Address Type"
{
    Extensible = true;

    value(0; Billing)
    {
        Caption = 'billing';
    }
    value(1; Shipping)
    {
        Caption = 'shipping';
    }
    value(2; Both)
    {
        Caption = 'both';
    }
}
