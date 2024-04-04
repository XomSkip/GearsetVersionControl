global class updateAccountQuoteDates implements Database.Batchable<sObject>, Database.Stateful {
    // instance member to retain state across transactions
    global Integer UCQDrecordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, Name,Number_Quoters__c, Number_Orderers__c, Date_of_First_Order__c, Date_of_First_Quote__c, Date_of_Last_Order__c, Date_of_Last_Quote__c, Sup_DateOfFirstQuote__c, Sup_DateOfLastQuote__c, Sup_NumberQuoters__c, Sup_DateOfFirstOrder__c, Sup_DateOfLastOrder__c, Sup_NumberOfOrderers__c from Account'
        );
    }
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        SET<ID> lAccountIDSET = new Set<ID>();
        Map<ID, Account> lAccountIDMap = new Map<ID, Account>();
        for (Account a : scope) {
            lAccountIDSET.add(a.ID);
            lAccountIDMap.put(a.ID, a);
        }
        // Fetch the Quote Dates
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
        // Fetch the Orders Data
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
            'updateAccountQuoteDates.execute',
            'Account Updates in Execution Queue'
        );
        UCQDrecordsProcessed = UCQDrecordsProcessed + accountUpdateList.size();

        System.debug('Account Records Processed ' + UCQDrecordsProcessed);
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(UCQDrecordsProcessed + ' records processed. Shazam!');
    }
}