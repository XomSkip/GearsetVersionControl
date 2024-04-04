global class acctFYHierarchyCalc implements Database.Batchable<sObject>, Database.Stateful {
    global Integer recordsProcessed = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    Name,
                    This_Year_Account_Spend__c,
                    Last_Year_Account_Spend__c,
                    Year_Before_Last_Account_Spend__c,
                    This_Year_Corporate_Hierarchy_Spend__c,
                    Last_Year_Corporate_Hierarchy_Spend__c,
                    Year_Before_Last_Corp_Hierarchy_Spend__c,
                    Corporate_Hierarchy_Lifetime_Spend__c,
                    Corporate_Hierarchy_Lifetime_N_of_Orders__c,
                    Lifetime_Spend__c,
                    Number_Orders__c,
                    Sup_Lifetime_Spend__c,
                    Sup_NumberOfOrderers__c,
                    Sup_This_Year_Account_Spend__c,
                    Sup_Last_Year_Account_Spend__c,
                    Sup_Year_Before_Last_Account_Spend__c,
                    Sup_This_Year_Corporate_Hierarchy_Spend__c,
                    Sup_Last_Year_Corporate_Hierarchy_Spend__c,
                    Sup_YearBeforeLast_Corp_Hierarchy_Spend__c,
                    Sup_Corporate_Hierarchy_Lifetime_Spend__c,
                    Sup_Corporate_Hierarchy_Lifetime_NOrders__c,
                    (
                        SELECT
                            Name,
                            ParentId,
                            This_Year_Account_Spend__c,
                            Last_Year_Account_Spend__c,
                            Year_Before_Last_Account_Spend__c,
                            Lifetime_Spend__c,
                            Number_Orders__c,
                            Sup_Lifetime_Spend__c,
                            Sup_NumberOfOrderers__c,
                            Sup_This_Year_Account_Spend__c,
                            Sup_Last_Year_Account_Spend__c,
                            Sup_Year_Before_Last_Account_Spend__c
                        FROM ChildAccounts
                    )
                FROM Account
                WHERE ParentId = NULL
                ORDER BY Id
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> parentAccountList) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account thisParentAccount : parentAccountList) {
            thisParentAccount.This_Year_Corporate_Hierarchy_Spend__c = thisParentAccount.This_Year_Account_Spend__c ==
                null
                ? 0
                : thisParentAccount.This_Year_Account_Spend__c;
            thisParentAccount.Last_Year_Corporate_Hierarchy_Spend__c = thisParentAccount.Last_Year_Account_Spend__c ==
                null
                ? 0
                : thisParentAccount.Last_Year_Account_Spend__c;
            thisParentAccount.Year_Before_Last_Corp_Hierarchy_Spend__c = thisParentAccount.Year_Before_Last_Account_Spend__c ==
                null
                ? 0
                : thisParentAccount.Year_Before_Last_Account_Spend__c;
            thisParentAccount.Corporate_Hierarchy_Lifetime_Spend__c = thisParentAccount.Lifetime_Spend__c == null
                ? 0
                : thisParentAccount.Lifetime_Spend__c;
            thisParentAccount.Corporate_Hierarchy_Lifetime_N_of_Orders__c = thisParentAccount.Number_Orders__c == null
                ? 0
                : thisParentAccount.Number_Orders__c;
            thisParentAccount.Sup_Corporate_Hierarchy_Lifetime_Spend__c = thisParentAccount.Sup_Lifetime_Spend__c == null
                ? 0
                : thisParentAccount.Sup_Lifetime_Spend__c;
            thisParentAccount.Sup_Corporate_Hierarchy_Lifetime_NOrders__c = thisParentAccount.Sup_NumberOfOrderers__c == null
                ? 0
                : thisParentAccount.Sup_NumberOfOrderers__c;
            thisParentAccount.Sup_This_Year_Corporate_Hierarchy_Spend__c = thisParentAccount.Sup_This_Year_Account_Spend__c ==
                null
                ? 0
                : thisParentAccount.Sup_This_Year_Account_Spend__c;
            thisParentAccount.Sup_Last_Year_Corporate_Hierarchy_Spend__c = thisParentAccount.Sup_Last_Year_Account_Spend__c ==
                null
                ? 0
                : thisParentAccount.Sup_Last_Year_Account_Spend__c;
            thisParentAccount.Sup_YearBeforeLast_Corp_Hierarchy_Spend__c = thisParentAccount.Sup_Year_Before_Last_Account_Spend__c ==
                null
                ? 0
                : thisParentAccount.Sup_Year_Before_Last_Account_Spend__c;            
            if (thisParentAccount.ChildAccounts != null) {
                for (Account aChild : thisParentAccount.ChildAccounts) {
                    if (aChild.This_Year_Account_Spend__c != null) {
                        thisParentAccount.This_Year_Corporate_Hierarchy_Spend__c += aChild.This_Year_Account_Spend__c;
                    }
                    if (aChild.Last_Year_Account_Spend__c != null) {
                        thisParentAccount.Last_Year_Corporate_Hierarchy_Spend__c += aChild.Last_Year_Account_Spend__c;
                    }
                    if (aChild.Year_Before_Last_Account_Spend__c != null) {
                        thisParentAccount.Year_Before_Last_Corp_Hierarchy_Spend__c += aChild.Year_Before_Last_Account_Spend__c;
                    }
                    if (aChild.Lifetime_Spend__c != null) {
                        thisParentAccount.Corporate_Hierarchy_Lifetime_Spend__c += aChild.Lifetime_Spend__c;
                    }
                    if (aChild.Number_Orders__c != null) {
                        thisParentAccount.Corporate_Hierarchy_Lifetime_N_of_Orders__c += aChild.Number_Orders__c;
                    }
                    if (aChild.Sup_Lifetime_Spend__c != null) {
                        thisParentAccount.Sup_Corporate_Hierarchy_Lifetime_Spend__c += aChild.Sup_Lifetime_Spend__c;
                    }
                    if (aChild.Sup_NumberOfOrderers__c != null) {
                        thisParentAccount.Sup_Corporate_Hierarchy_Lifetime_NOrders__c += aChild.Sup_NumberOfOrderers__c;
                    }
                    if (aChild.Sup_This_Year_Account_Spend__c != null) {
                        thisParentAccount.Sup_This_Year_Corporate_Hierarchy_Spend__c += aChild.Sup_This_Year_Account_Spend__c;
                    }
                    if (aChild.Sup_Last_Year_Account_Spend__c != null) {
                        thisParentAccount.Sup_Last_Year_Corporate_Hierarchy_Spend__c += aChild.Sup_Last_Year_Account_Spend__c;
                    }
                    if (aChild.Sup_Year_Before_Last_Account_Spend__c != null) {
                        thisParentAccount.Sup_YearBeforeLast_Corp_Hierarchy_Spend__c += aChild.Sup_Year_Before_Last_Account_Spend__c;
                    }
                }
                for (Account aChild : thisParentAccount.ChildAccounts) {
                    aChild.This_Year_Corporate_Hierarchy_Spend__c = thisParentAccount.This_Year_Corporate_Hierarchy_Spend__c;
                    aChild.Last_Year_Corporate_Hierarchy_Spend__c = thisParentAccount.Last_Year_Corporate_Hierarchy_Spend__c;
                    aChild.Year_Before_Last_Corp_Hierarchy_Spend__c = thisParentAccount.Year_Before_Last_Corp_Hierarchy_Spend__c;
                    aChild.Corporate_Hierarchy_Lifetime_Spend__c = thisParentAccount.Corporate_Hierarchy_Lifetime_Spend__c;
                    aChild.Corporate_Hierarchy_Lifetime_N_of_Orders__c = thisParentAccount.Corporate_Hierarchy_Lifetime_N_of_Orders__c;
                    aChild.Sup_This_Year_Corporate_Hierarchy_Spend__c = thisParentAccount.Sup_This_Year_Corporate_Hierarchy_Spend__c;
                    aChild.Sup_Last_Year_Corporate_Hierarchy_Spend__c = thisParentAccount.Sup_Last_Year_Corporate_Hierarchy_Spend__c;
                    aChild.Sup_YearBeforeLast_Corp_Hierarchy_Spend__c = thisParentAccount.Sup_YearBeforeLast_Corp_Hierarchy_Spend__c;
                    aChild.Sup_Corporate_Hierarchy_Lifetime_Spend__c = thisParentAccount.Sup_Corporate_Hierarchy_Lifetime_Spend__c;
                    aChild.Sup_Corporate_Hierarchy_Lifetime_NOrders__c = thisParentAccount.Sup_Corporate_Hierarchy_Lifetime_NOrders__c;
                    accountsToUpdate.add(aChild);
                }
            }
            accountsToUpdate.add(thisParentAccount);
        }
        if (accountsToUpdate.size() > 0) {
            recordsProcessed += accountsToUpdate.size();
            Integer updateTracker = DatabaseUtilities.saveToDatabaseTracking(
                accountsToUpdate,
                'acctFYHierarchyCalc.execute',
                'Batch Corporate Hierarchy Spend Updates'
            );

            System.debug('Current Records Processed' + recordsProcessed);
            System.debug('The update tracker records for this batch are ' + updateTracker);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(recordsProcessed + ' records processed. Shazam!');
    }
}