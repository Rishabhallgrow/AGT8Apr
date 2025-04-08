codeunit 50106 "Set Default Salesperson Code"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Sell-to Customer No.', true, true)]
    local procedure OnAfterValidateSellToCustomerNo(var Rec: Record "Sales Header")
    var
        Salesperson: Record "Salesperson/Purchaser";
        SalesHeader: Record "Sales Header";
        MinOrders: Integer;
        SelectedSalesperson: Code[20];
    begin
        MinOrders := 999999;
        if Salesperson.FindSet() then
            repeat
                SalesHeader.Reset();
                SalesHeader.SetRange("Salesperson Code", Salesperson.Code);
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
                if SalesHeader.Count() < MinOrders then begin
                    SelectedSalesperson := Salesperson.Code;
                    Rec."Salesperson Code" := SelectedSalesperson;
                    exit;
                end;
            until Salesperson.Next() = 0;

    end;
}