/*
Batch class that summarizes in the account record what is the first Order_ERP, the last Order_ERP and the number of different contacts related to the Order_ERP records of the account
*/
global class updateAccountOrderERPInfoBatch implements Database.Batchable<sObject>, Database.Stateful {
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
        
        // Fetch the Orders ERP Dates
        AggregateResult[] orderAggRes = [
            SELECT
                AccountID__C AccountID,
                Max(Order_ERP_CreatedDate__c) Last_Order_Date,
                Min(Order_ERP_CreatedDate__c) First_Order_Date,
                COUNT_DISTINCT(ContactID__c) Num_of_Orderers
            FROM Order_ERP__C
            WHERE AccountID__C IN :lAccountIDSET
            GROUP BY AccountID__C
        ];
        for (AggregateResult laggRes : orderAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('AccountID')));
            Date lLastOrderDate = Date.valueOf(String.valueOf(laggRes.get('Last_Order_Date')));
            Date lFirstOrderDate = Date.valueOf(String.valueOf(laggRes.get('First_Order_Date')));
            Integer lNum_of_Orderers = Integer.valueOf(String.valueOf(laggRes.get('Num_of_Orderers')));
            if (lAccountIDMap.containsKey(lID)) {
                account lAccount = lAccountIDMap.get(lID);
                lAccount.Date_of_First_Order__c = lFirstOrderDate;
                lAccount.Date_of_Last_Order__c = lLastOrderDate;
                lAccount.Number_Orderers__c = lNum_of_Orderers;
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
            'updateAccountOrderERPInfoBatch.execute',
            'Account Updates in Execution updateAccountOrderERPInfoBatch'
        );
        UCQDrecordsProcessed = UCQDrecordsProcessed + accountUpdateList.size();

        System.debug('Account Records Processed ' + UCQDrecordsProcessed);
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(UCQDrecordsProcessed + ' records processed. Shazam!');
    }
}