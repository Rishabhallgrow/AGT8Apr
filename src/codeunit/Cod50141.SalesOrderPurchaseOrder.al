codeunit 50141 "Sales Order Purchase Order"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterModifyEvent', '', true, true)]
    local procedure OnSalesLineAfterInsert(var Rec: Record "Sales Line")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        MissingQty: Decimal;
        CreatedPO: Boolean;
        PurchaseDocNo: Code[20];
        VendorNo: Code[20];
        MLineNo: Integer;

    begin
        if Rec.Type <> Rec.Type::Item then
            exit;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."Document No.");

        if SalesLine.FindSet() then begin
            repeat
                if SalesLine.Type = SalesLine.Type::Item then begin
                    if Item.Get(SalesLine."No.") then begin
                        Item.CalcFields("Inventory");

                        if Item.Inventory < SalesLine.Quantity then begin
                            MissingQty := SalesLine.Quantity - Item.Inventory;
                            VendorNo := Item."Vendor No.";
                            if VendorNo = '' then begin
                                Message('Not Found %1 ', Item."No.");
                            end else begin
                                if not CreatedPO then begin
                                    PurchaseHeader.Init();
                                    PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
                                    PurchaseHeader.Insert(true);
                                    PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
                                    PurchaseHeader."Vendor Invoice No." := 'PO-' + Rec."Document No.";
                                    PurchaseHeader.Modify(true);
                                    CreatedPO := true;
                                    PurchaseDocNo := PurchaseHeader."No.";
                                end;
                                MLineNo := 0;
                                PurchaseLine.Reset();
                                PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                                PurchaseLine.SetRange("Document No.", PurchaseDocNo);
                                if PurchaseLine.FindLast() then
                                    MLineNo := PurchaseLine."Line No.";
                                PurchaseLine.Init();
                                PurchaseLine."Document Type" := PurchaseHeader."Document Type";
                                PurchaseLine."Document No." := PurchaseDocNo;
                                PurchaseLine."Line No." := MLineNo + 10000;
                                PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
                                PurchaseLine.Validate("No.", SalesLine."No.");
                                PurchaseLine.Validate(Quantity, MissingQty);
                                PurchaseLine."Sales Order No." := SalesLine."Document No.";
                                PurchaseLine."Sales Order Line No." := SalesLine."Line No.";
                                PurchaseLine.Insert(true);
                            end;
                        end;
                    end;
                end;
            until SalesLine.Next() = 0;
        end;
    end;
}