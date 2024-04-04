global class SuppliesOppAggBatch implements Database.Batchable<sObject>, Database.Stateful {
    static final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Supplies')
        .getRecordTypeID();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    Sup_Revenue__c,
                    Sup_TotalQuotedRevenue__c,
                    Sup_TotalPotentialRevenue__c,
                    Sup_TotalRevenueLY__c,
                    Sup_TotalRevenueTY__c
                FROM Supplier__c
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<Supplier__c> supplierList) {
        Map<Id, Supplier__c> supplierMap = new Map<Id, Supplier__c>();
        for (Supplier__c s : supplierList) {
            supplierMap.put(s.Id, s);
        }

        AggregateResult[] oppTotalQuotedAggRes = [
            SELECT Primary_Supplier__c SupplierID, SUM(Amount) TotalQuoted
            FROM Opportunity
            WHERE
                Primary_Supplier__c IN :supplierMap.keySet()
                AND RecordTypeId = :oppSuppliesRecordTypeID
                AND Amount != NULL
            GROUP BY Primary_Supplier__c
        ];
        for (AggregateResult oppQuoteAgg : oppTotalQuotedAggRes) {
            ID SupplierID = ID.valueOf(String.valueOf(oppQuoteAgg.get('SupplierId')));
            Decimal totalQuoteAgg = Decimal.valueOf(String.valueOf(oppQuoteAgg.get('TotalQuoted')));
            if (supplierMap.containsKey(SupplierID)) {
                Supplier__c supplier = supplierMap.get(supplierID);
                supplier.Sup_TotalQuotedRevenue__c = totalQuoteAgg;
                supplierMap.put(supplier.ID, supplier);
            }
        }

        AggregateResult[] oppRevenueAggRes = [
            SELECT Primary_Supplier__c SupplierID, SUM(Amount) TotalRevenue
            FROM Opportunity
            WHERE
                Primary_Supplier__c IN :supplierMap.keySet()
                AND RecordTypeId = :oppSuppliesRecordTypeID
                AND StageName = 'Closed Won'
                AND Amount != NULL
            GROUP BY Primary_Supplier__c
        ];

        for (AggregateResult oppRevenueAgg : oppRevenueAggRes) {
            ID SupplierID = ID.valueOf(String.valueOf(oppRevenueAgg.get('SupplierId')));
            Decimal totalRevenueAgg = Decimal.valueOf(String.valueOf(oppRevenueAgg.get('TotalRevenue')));
            if (supplierMap.containsKey(SupplierID)) {
                Supplier__c supplier = supplierMap.get(supplierID);
                supplier.Sup_Revenue__c = totalRevenueAgg;
                supplierMap.put(supplier.ID, supplier);
            }
        }

        AggregateResult[] oppPotentialRevAggRes = [
            SELECT Primary_Supplier__c SupplierID, SUM(Amount) TotalPotentialRev
            FROM Opportunity
            WHERE
                Primary_Supplier__c IN :supplierMap.keySet()
                AND RecordTypeId = :oppSuppliesRecordTypeID
                AND StageName NOT IN ('Closed Won', 'Closed Lost')
                AND Amount != NULL
            GROUP BY Primary_Supplier__c
        ];

        for (AggregateResult oppPotentialRevAgg : oppPotentialRevAggRes) {
            ID SupplierID = ID.valueOf(String.valueOf(oppPotentialRevAgg.get('SupplierId')));
            Decimal totalPotentialRevAgg = Decimal.valueOf(String.valueOf(oppPotentialRevAgg.get('TotalPotentialRev')));
            if (supplierMap.containsKey(SupplierID)) {
                Supplier__c supplier = supplierMap.get(supplierID);
                supplier.Sup_TotalPotentialRevenue__c = totalPotentialRevAgg;
                supplierMap.put(supplier.ID, supplier);
            }
        }

        List<Opportunity> closedWonOpps = [
            SELECT Primary_Supplier__c, Amount, CloseDate
            FROM Opportunity
            WHERE RecordTypeId = :oppSuppliesRecordTypeID AND StageName = 'Closed Won' AND Amount != NULL
        ];

        Map<Id, Decimal> supplierLYRevenue = new Map<Id, Decimal>();
        Map<Id, Decimal> supplierTYRevenue = new Map<Id, Decimal>();

        for (Opportunity opp : closedWonOpps) {
            if (supplierMap.containsKey(opp.Primary_Supplier__c)) {
                Supplier__c supplier = supplierMap.get(opp.Primary_Supplier__c);
                if (opp.CloseDate.year() == Date.today().year() - 1) {
                    if (supplierLYRevenue.containsKey(supplier.Id)) {
                        supplierLYRevenue.put(supplier.Id, supplierLYRevenue.get(supplier.id) + opp.Amount);
                    } else {
                        supplierLYRevenue.put(supplier.Id, opp.Amount);
                    }
                }
                if (opp.CloseDate.year() == Date.today().year()) {
                    if (supplierTYRevenue.containsKey(supplier.Id)) {
                        supplierTYRevenue.put(supplier.Id, supplierTYRevenue.get(supplier.id) + opp.Amount);
                    } else {
                        supplierTYRevenue.put(supplier.Id, opp.Amount);
                    }
                }
            }
        }

        for (Supplier__c s : supplierMap.values()) {
            if (supplierLYRevenue.containsKey(s.Id)) {
                s.Sup_TotalRevenueLY__c = supplierLYRevenue.get(s.Id);
            } else {
                s.Sup_TotalRevenueLY__c = 0;
            }

            if (supplierTYRevenue.containsKey(s.Id)) {
                s.Sup_TotalRevenueTY__c = supplierTYRevenue.get(s.Id);
            } else {
                s.Sup_TotalRevenueTY__c = 0;
            }
        }

        DatabaseUtilities.saveToDatabase(supplierMap.values(), 'SuppliesOppAggBatch', 'Suppliers Opp Agg Failed');
    }

    global void finish(Database.BatchableContext bc) {
    }
}