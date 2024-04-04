global class SuppliesP21AccDetailsAggBatch implements Database.Batchable<sObject> {
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
                FROM P21_Account_Details__c
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<P21_Account_Details__c> p21AccDetailsList) {
        Map<Id, P21_Account_Details__c> mapRecordsP21AccDetails = new Map<Id, P21_Account_Details__c>(
            p21AccDetailsList
        );

        AggregateResult[] oppTotalQuotedAggRes = [
            SELECT P21_Account_Details__c P21Id, SUM(Amount) TotalQuoted
            FROM Opportunity
            WHERE
                P21_Account_Details__c IN :mapRecordsP21AccDetails.keySet()
                AND RecordTypeId = :oppSuppliesRecordTypeID
                AND Amount != NULL
            GROUP BY P21_Account_Details__c
        ];
        for (AggregateResult oppQuoteAgg : oppTotalQuotedAggRes) {
            ID P21Id = ID.valueOf(String.valueOf(oppQuoteAgg.get('P21Id')));
            Decimal totalQuoteAgg = Decimal.valueOf(String.valueOf(oppQuoteAgg.get('TotalQuoted')));
            if (mapRecordsP21AccDetails.containsKey(P21Id)) {
                P21_Account_Details__c supplier = mapRecordsP21AccDetails.get(P21Id);
                supplier.Sup_TotalQuotedRevenue__c = totalQuoteAgg;
                mapRecordsP21AccDetails.put(supplier.ID, supplier);
            }
        }

        AggregateResult[] oppRevenueAggRes = [
            SELECT P21_Account_Details__c P21Id, SUM(Amount) TotalRevenue
            FROM Opportunity
            WHERE
                P21_Account_Details__c IN :mapRecordsP21AccDetails.keySet()
                AND RecordTypeId = :oppSuppliesRecordTypeID
                AND StageName = 'Closed Won'
                AND Amount != NULL
            GROUP BY P21_Account_Details__c
        ];

        for (AggregateResult oppRevenueAgg : oppRevenueAggRes) {
            ID P21Id = ID.valueOf(String.valueOf(oppRevenueAgg.get('P21Id')));
            Decimal totalRevenueAgg = Decimal.valueOf(String.valueOf(oppRevenueAgg.get('TotalRevenue')));
            if (mapRecordsP21AccDetails.containsKey(P21Id)) {
                P21_Account_Details__c supplier = mapRecordsP21AccDetails.get(P21Id);
                supplier.Sup_Revenue__c = totalRevenueAgg;
                mapRecordsP21AccDetails.put(supplier.ID, supplier);
            }
        }

        AggregateResult[] oppPotentialRevAggRes = [
            SELECT P21_Account_Details__c P21Id, SUM(Amount) TotalPotentialRev
            FROM Opportunity
            WHERE
                P21_Account_Details__c IN :mapRecordsP21AccDetails.keySet()
                AND RecordTypeId = :oppSuppliesRecordTypeID
                AND StageName NOT IN ('Closed Won', 'Closed Lost')
                AND Amount != NULL
            GROUP BY P21_Account_Details__c
        ];

        for (AggregateResult oppPotentialRevAgg : oppPotentialRevAggRes) {
            ID P21Id = ID.valueOf(String.valueOf(oppPotentialRevAgg.get('P21Id')));
            Decimal totalPotentialRevAgg = Decimal.valueOf(String.valueOf(oppPotentialRevAgg.get('TotalPotentialRev')));
            if (mapRecordsP21AccDetails.containsKey(P21Id)) {
                P21_Account_Details__c p21AccDetail = mapRecordsP21AccDetails.get(P21Id);
                p21AccDetail.Sup_TotalPotentialRevenue__c = totalPotentialRevAgg;
                mapRecordsP21AccDetails.put(p21AccDetail.ID, p21AccDetail);
            }
        }

        List<Opportunity> closedWonOpps = [
            SELECT P21_Account_Details__c, Amount, CloseDate
            FROM Opportunity
            WHERE RecordTypeId = :oppSuppliesRecordTypeID AND StageName = 'Closed Won' AND Amount != NULL
        ];

        Map<Id, Decimal> supplierLYRevenue = new Map<Id, Decimal>();
        Map<Id, Decimal> supplierTYRevenue = new Map<Id, Decimal>();

        for (Opportunity opp : closedWonOpps) {
            if (mapRecordsP21AccDetails.containsKey(opp.P21_Account_Details__c)) {
                P21_Account_Details__c p21AccDetail = mapRecordsP21AccDetails.get(opp.P21_Account_Details__c);
                if (opp.CloseDate.year() == Date.today().year() - 1) {
                    if (supplierLYRevenue.containsKey(p21AccDetail.Id)) {
                        supplierLYRevenue.put(p21AccDetail.Id, supplierLYRevenue.get(p21AccDetail.id) + opp.Amount);
                    } else {
                        supplierLYRevenue.put(p21AccDetail.Id, opp.Amount);
                    }
                }
                if (opp.CloseDate.year() == Date.today().year()) {
                    if (supplierTYRevenue.containsKey(p21AccDetail.Id)) {
                        supplierTYRevenue.put(p21AccDetail.Id, supplierTYRevenue.get(p21AccDetail.id) + opp.Amount);
                    } else {
                        supplierTYRevenue.put(p21AccDetail.Id, opp.Amount);
                    }
                }
            }
        }

        for (P21_Account_Details__c p21AccDetail : mapRecordsP21AccDetails.values()) {
            if (supplierLYRevenue.containsKey(p21AccDetail.Id)) {
                p21AccDetail.Sup_TotalRevenueLY__c = supplierLYRevenue.get(p21AccDetail.Id);
            } else {
                p21AccDetail.Sup_TotalRevenueLY__c = 0;
            }

            if (supplierTYRevenue.containsKey(p21AccDetail.Id)) {
                p21AccDetail.Sup_TotalRevenueTY__c = supplierTYRevenue.get(p21AccDetail.Id);
            } else {
                p21AccDetail.Sup_TotalRevenueTY__c = 0;
            }
        }

        List<AggregateResult> lstSuppliesOrders = [
            SELECT P21_Account_DetailsID__c P21Id, MIN(Order_Date__c) minData, MAX(Order_Date__c) maxData
            FROM Supplies_Order__c
            WHERE P21_Account_DetailsID__c IN :mapRecordsP21AccDetails.keySet()
            GROUP BY P21_Account_DetailsID__c
        ];
        for (AggregateResult supOrderAgg : lstSuppliesOrders) {
            ID P21Id = ID.valueOf(String.valueOf(supOrderAgg.get('P21Id')));
            Date dtFirstSupOrder = Date.valueOf(String.valueOf(supOrderAgg.get('minData')));
            Date dtLastSupOrder = Date.valueOf(String.valueOf(supOrderAgg.get('maxData')));
            if (mapRecordsP21AccDetails.containsKey(P21Id)) {
                P21_Account_Details__c supplier = mapRecordsP21AccDetails.get(P21Id);
                supplier.Sup_FirstDateSuppliesOrder__c = dtFirstSupOrder;
                supplier.Sup_LastDateSuppliesOrder__c = dtLastSupOrder;
                mapRecordsP21AccDetails.put(supplier.ID, supplier);
            }
        }

        DatabaseUtilities.saveToDatabase(
            mapRecordsP21AccDetails.values(),
            'SuppliesP21AccDetailsAggBatch',
            'Suppliers P21AccountsDetails Agg Failed'
        );
    }

    global void finish(Database.BatchableContext bc) {
    }
}