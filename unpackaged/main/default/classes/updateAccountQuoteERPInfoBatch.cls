/*
Batch class that summarizes in the account record what is the first Quote_ERP, the last Quote_ERP and the number of different contacts related to the Quote_ERP records of the account
*/
global class updateAccountQuoteERPInfoBatch implements Database.Batchable<sObject>, Database.Stateful {
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
        
        // Fetch the Quote ERP Dates
        AggregateResult[] quoteAggRes = [
            SELECT
                AccountID__C AccountID,
                Max(Quote_ERP_Created_Date__C) Last_Quote_Date,
                Min(Quote_ERP_Created_Date__C) First_Quote_Date,
                COUNT_DISTINCT(ContactID__c) Num_of_Quoters
            FROM Quote_ERP__C
            WHERE AccountID__C IN :lAccountIDSET
            GROUP BY AccountID__C
        ];
        for (AggregateResult laggRes : quoteAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('AccountID')));
            Date lLastQuoteDate = Date.valueOf(String.valueOf(laggRes.get('Last_Quote_Date')));
            Date lFirstQuoteDate = Date.valueOf(String.valueOf(laggRes.get('First_Quote_Date')));
            Integer lNum_of_Quoters = Integer.valueOf(String.valueOf(laggRes.get('Num_of_Quoters')));
            if (lAccountIDMap.containsKey(lID)) {
                Account lAccount = lAccountIDMap.get(lID);
                lAccount.Date_of_First_Quote__c = lFirstQuoteDate;
                lAccount.Date_of_Last_Quote__c = lLastQuoteDate;
                lAccount.Number_Quoters__c = lNum_of_Quoters;
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
            'updateAccountQuoteERPInfoBatch.execute',
            'Account Updates in Execution updateAccountQuoteERPInfoBatch'
        );
        UCQDrecordsProcessed = UCQDrecordsProcessed + accountUpdateList.size();

        System.debug('Account Records Processed ' + UCQDrecordsProcessed);
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(UCQDrecordsProcessed + ' records processed. Shazam!');
    }
}