page 80102 "NuORDER Verifier Dialog"
{
    PageType = StandardDialog;
    Caption = 'NuORDER Verifier';

    layout
    {
        area(content)
        {
            field(Verifier; VerifierTxt)
            {
                ApplicationArea = All;
                Caption = 'Verifier';
                ExtendedDatatype = Masked;
            }
        }
    }

    var
        VerifierTxt: Text[250];

    procedure GetVerifier(): Text[250]
    begin
        exit(VerifierTxt);
    end;
}
