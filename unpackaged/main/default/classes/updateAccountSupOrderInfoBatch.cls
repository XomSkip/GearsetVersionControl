/*
Batch class that summarizes in the account record what is the first Supplies_Order, the last Supplies_Order and the number of different contacts related to the Supplies_Order records of the account
*/
global class updateAccountSupOrderInfoBatch implements Database.Batchable<sObject>, Database.Stateful {
    // instance member to retain state across transactions
    global Integer UCQDrecordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID from Account'
        );
    }
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        Map<ID, Account> lAccountIDMap = new Map<ID, Account>(scope);
        SET<ID> lAccountIDSET = lAccountIDMap.keySet();
        
        // Fetch the Supplies Order Dates
        AggregateResult[] suppliesOrderAggRes = [
            SELECT
                AccountID__C AccountID,
                Max(Order_Date__c) Sup_LastOrderDate,
                Min(Order_Date__c) Sup_FirstOrderDate,
                COUNT_DISTINCT(ContactID__c) Sup_NumOfOrderers
            FROM Supplies_Order__C
            WHERE AccountID__C IN :lAccountIDSET
            GROUP BY AccountID__C
        ];
        for (AggregateResult laggRes : suppliesOrderAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('AccountID')));
            Date lSupLastOrderDate = Date.valueOf(String.valueOf(laggRes.get('Sup_LastOrderDate')));
            Date lSupFirstOrderDate = Date.valueOf(String.valueOf(laggRes.get('Sup_FirstOrderDate')));
            Integer lSupNumOfOrderers = Integer.valueOf(String.valueOf(laggRes.get('Sup_NumOfOrderers')));
            if (lAccountIDMap.containsKey(lID)) {
                account lAccount = lAccountIDMap.get(lID);
                lAccount.Sup_DateOfFirstOrder__c = lSupFirstOrderDate;
                lAccount.Sup_DateOfLastOrder__c = lSupLastOrderDate;
                lAccount.Sup_NumberOfOrderers__c = lSupNumOfOrderers;
                lAccountIDMap.put(lAccount.ID, lAccount);
            }
        }
        
        //Update the Accounts
        System.debug('About to start the Account Updates');
        List<Account> accountUpdateList = new List<Account>();
        accountUpdateList = lAccountIDMap.values();
        System.debug('Account to Update List is');
        System.debug(accountUpdateList);
        Integer updateTracker = DatabaseUtilities.saveToDatabaseTracking(
            accountUpdateList,
            'updateAccountSupOrderInfoBatch.execute',
            'Account Updates in Execution updateAccountSupOrderInfoBatch'
        );
        UCQDrecordsProcessed = UCQDrecordsProcessed + accountUpdateList.size();

        System.debug('Account Records Processed ' + UCQDrecordsProcessed);
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(UCQDrecordsProcessed + ' records processed. Shazam!');
    }
}