/*
Batch class that summarizes in the account record what is the first Supplies_Quote, the last Supplies_Quote and the number of different contacts related to the Supplies_Quote records of the account
*/
global class updateAccountSupQuoteInfoBatch implements Database.Batchable<sObject>, Database.Stateful {
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
        
        // Fetch the Supplies Quote Dates
        AggregateResult[] suppliesQuoteAggRes = [
            SELECT
                AccountID__C AccountID,
                Max(Quote_P21_Created_Date__c) Sup_LastQuoteDate,
                Min(Quote_P21_Created_Date__c) Sup_FirstQuoteDate,
                COUNT_DISTINCT(ContactID__c) Sup_NumOfQuoters
            FROM Supplies_Quote__C
            WHERE AccountID__C IN :lAccountIDSET
            GROUP BY AccountID__C
        ];
        for (AggregateResult laggRes : suppliesQuoteAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('AccountID')));
            Date lSupLastQuoteDate = Date.valueOf(String.valueOf(laggRes.get('Sup_LastQuoteDate')));
            Date lSupFirstQuoteDate = Date.valueOf(String.valueOf(laggRes.get('Sup_FirstQuoteDate')));
            Integer lSupNumOfQuoters = Integer.valueOf(String.valueOf(laggRes.get('Sup_NumOfQuoters')));
            if (lAccountIDMap.containsKey(lID)) {
                Account lAccount = lAccountIDMap.get(lID);
                lAccount.Sup_DateOfFirstQuote__c = lSupFirstQuoteDate;
                lAccount.Sup_DateOfLastQuote__c = lSupLastQuoteDate;
                lAccount.Sup_NumberQuoters__c = lSupNumOfQuoters;
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
            'updateAccountSupQuoteInfoBatch.execute',
            'Account Updates in Execution updateAccountSupQuoteInfoBatch'
        );
        UCQDrecordsProcessed = UCQDrecordsProcessed + accountUpdateList.size();

        System.debug('Account Records Processed ' + UCQDrecordsProcessed);
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(UCQDrecordsProcessed + ' records processed. Shazam!');
    }
}