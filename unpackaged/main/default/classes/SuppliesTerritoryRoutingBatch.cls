global class SuppliesTerritoryRoutingBatch implements Database.Batchable<sObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, Primary_Zip_Code__c, P21_CustomerID__C
                FROM P21_Account_Details__C
                WHERE Override_Zipcode_Routing__c = FALSE
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<P21_Account_Details__C> p21AccountsToUpdate) {
        Map<String, P21_Account_Details__c> p21AccountsToUpdateMap = new Map<String, P21_Account_Details__c>();
        List<routingAddress> p21AccountsToRoute = new List<routingAddress>();
        for (P21_Account_Details__C p21Acct : p21AccountsToUpdate) {
            p21AccountsToUpdateMap.put(p21Acct.P21_CustomerID__C, p21Acct);
            routingAddress myRoutingAddress = new routingAddress(
                p21Acct.Primary_Zip_Code__c,
                null,
                null,
                null,
                p21Acct.P21_CustomerID__C
            );
            p21AccountsToRoute.add(myRoutingAddress);
        }
        p21AccountsToRoute = routingHelper.suppliesTerritoryRouting(p21AccountsToRoute, 'Supplies');

        for (routingAddress rAddr : p21AccountsToRoute) {
            if (p21AccountsToUpdateMap.containsKey(rAddr.sourceID)) {
                p21AccountsToUpdateMap.get(rAddr.sourceID).OwnerID = rAddr.routedOwnerID;
            }
        }

        if (!p21AccountsToUpdateMap.values().isEmpty()) {
            DatabaseUtilities.saveToDatabase(
                p21AccountsToUpdateMap.values(),
                'SuppliesTerritoryRountingBatch',
                'Updating P21 Account Owners'
            );
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}