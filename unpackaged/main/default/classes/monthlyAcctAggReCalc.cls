global class monthlyAcctAggReCalc implements Database.Batchable<sObject>, Database.Stateful {
    global Integer recordsProcessed = 0;

    static ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    
    static ID oppSupplierRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Supplies')
        .getRecordTypeID();

    String strQuery = 'SELECT Id FROM Account ORDER BY Id';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext bc, List<Account> accountsList) {
        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>(accountsList);
        calcNumberOfContacts(accountsToUpdateMap);
        calcOppRecords(accountsToUpdateMap);
        processRecords(accountsToUpdateMap);
        recordsProcessed += accountsToUpdateMap.values().size();
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(recordsProcessed + ' records processed. Shazam!');
    }

    @TestVisible
    private static void calcOppRecords(Map<Id, Account> accountsToUpdateMap) {
        Integer thisYear = Date.today().year();
        Integer previousYear = thisYear - 1;
        Integer yearBeforeLast = thisYear - 2;
        Integer rollingMonth, rollingYear;
        if (Date.today().month() == 12) {
            rollingMonth = 1;
            rollingYear = thisYear;
        } else {
            rollingMonth = Date.today().month() + 1;
            rollingYear = previousYear;
        }
        Date rollingDate = Date.newInstance(rollingYear, rollingMonth, 1);

        List<Opportunity> lstOpp = [
            SELECT RecordTypeId, AccountID, StageName, Amount, Order_ERP_Xom_ID__c, CloseDate
            FROM Opportunity
            WHERE AccountId IN :accountsToUpdateMap.keySet() 
                AND stageName = 'Closed Won'
                AND (
                    RecordTypeId = :oppManufacturingServRTypeID OR 
                    RecordTypeId = :oppSupplierRTypeID
                )
                AND (
                    CALENDAR_YEAR(CloseDate) = :thisYear OR
                    CALENDAR_YEAR(CloseDate) = :previousYear OR
                    CALENDAR_YEAR(CloseDate) = :yearBeforeLast OR 
                    CloseDate >= :rollingDate
                )
        ];

        Map<Id, List<Opportunity>> mapAccwithOpp = new Map<Id, List<Opportunity>>();
        for(Opportunity thisOpp : lstOpp)
        {
            if(!mapAccwithOpp.containskey(thisOpp.AccountId)){
                mapAccwithOpp.put(thisOpp.AccountId, new List<Opportunity>());
            }
            mapAccwithOpp.get(thisOpp.AccountId).add(thisOpp);
        }

        for(Account thisAccount : accountsToUpdateMap.values())
        {
            thisAccount.Rolling_12_Spend__c = 0;
            thisAccount.YTDSpend__c = 0;
            thisAccount.Lifetime_Spend__c = 0;
            thisAccount.This_Year_Account_Spend__c = 0;
            thisAccount.Last_Year_Account_Spend__c = 0;
            thisAccount.Year_Before_Last_Account_Spend__c = 0;
            thisAccount.Sup_Lifetime_Spend__c = 0;
            thisAccount.Sup_This_Year_Account_Spend__c = 0;
            thisAccount.Sup_Last_Year_Account_Spend__c = 0;
            thisAccount.Sup_Year_Before_Last_Account_Spend__c = 0;

            Set<String> setOrderERPXomID_ManufacturingServ = new Set<String>();
            Set<String> setOrderERPXomID_Supplier = new Set<String>();

            if(mapAccwithOpp.containsKey(thisAccount.Id))
            {
                for(Opportunity thisOpp : mapAccwithOpp.get(thisAccount.Id))
                {
                    if(thisOpp.RecordTypeId == oppManufacturingServRTypeID)
                    {
                        //calcRolling12Spend
                        if(thisOpp.CloseDate >= rollingDate && thisOpp.Amount != null)
                        {
                            thisAccount.Rolling_12_Spend__c += thisOpp.Amount;
                        }
                
                        //calcYTDSpend
                        if(thisOpp.CloseDate.year() == thisYear && thisOpp.Amount != null)
                        {
                            thisAccount.YTDSpend__c += thisOpp.Amount;
                        }
    
                        //calcLifetimeSpendAndNumberOfOrders_ManufacturingServ
                        if(thisOpp.Order_ERP_Xom_ID__c != null)
                        {
                            setOrderERPXomID_ManufacturingServ.add(thisOpp.Order_ERP_Xom_ID__c);
                            thisAccount.Number_Orders__c = setOrderERPXomID_ManufacturingServ.size();
                        }
                        if(thisOpp.Amount != null)
                        {
                            thisAccount.Lifetime_Spend__c += thisOpp.Amount;
                            
                            //calcThisYearAccountSpend_ManufacturingServ
                            if(thisOpp.CloseDate.year() == thisYear)
                            {
                                thisAccount.This_Year_Account_Spend__c += thisOpp.Amount;
                            }
                            //calcLastYearAccountSpend_ManufacturingServ
                            else if(thisOpp.CloseDate.year() == previousYear)            
                            {
                                thisAccount.Last_Year_Account_Spend__c += thisOpp.Amount;
                            }
                            //calcYearBeforeLastAccountSpend_ManufacturingServ
                            else if(thisOpp.CloseDate.year() == yearBeforeLast)            
                            {
                                thisAccount.Year_Before_Last_Account_Spend__c += thisOpp.Amount;
                            }
                        }
                    }
                    else{
                        //calcLifetimeSpendAndNumberOfOrders_Supplier
                        if(thisOpp.Order_ERP_Xom_ID__c != null)
                        {
                            setOrderERPXomID_Supplier.add(thisOpp.Order_ERP_Xom_ID__c);
                            thisAccount.Sup_NumberOfOrderers__c = setOrderERPXomID_Supplier.size();
                        }
                        if(thisOpp.Amount != null)
                        {
                            thisAccount.Sup_Lifetime_Spend__c += thisOpp.Amount;
    
                            //calcThisYearAccountSpend_Supplier
                            if(thisOpp.CloseDate.year() == thisYear)
                            {
                                thisAccount.Sup_This_Year_Account_Spend__c += thisOpp.Amount;
                            }
                            //calcLastYearAccountSpend_Supplier
                            else if(thisOpp.CloseDate.year() == previousYear)            
                            {
                                thisAccount.Sup_Last_Year_Account_Spend__c += thisOpp.Amount;
                            }
                            //calcYearBeforeLastAccountSpend_Supplier
                            else if(thisOpp.CloseDate.year() == yearBeforeLast)            
                            {
                                thisAccount.Sup_Year_Before_Last_Account_Spend__c += thisOpp.Amount;
                            }
                        }
                    }
                }
            }            
        }
    }
        
    @TestVisible
    private static void calcNumberOfContacts(Map<Id, Account> accountsToUpdateMap) {
        List<AggregateResult> myAggResNumCont = [
            SELECT AccountId, Count_Distinct(Id) NumContact
            FROM Contact
            WHERE AccountId IN :accountsToUpdateMap.keySet()
            GROUP BY AccountId
        ];
        if (!myAggResNumCont.isEmpty()) {
            for (AggregateResult aggRes : myAggResNumCont) {
                Id lID = Id.valueOf(String.valueOf(aggRes.get('AccountID')));
                Integer lNumContact = 0;
                if (aggRes.get('NumContact') != null) {
                    lNumContact = Integer.valueOf(String.valueOf(aggRes.get('NumContact')));
                }
                if (accountsToUpdateMap.containsKey(lID)) {
                    Account a = accountsToUpdateMap.get(lId);
                    a.Number_Contacts__c = lNumContact;
                    accountsToUpdateMap.put(a.Id, a);
                }
            }
        }
    }
    
    @TestVisible
    private static void processRecords(Map<Id, Account> accountsToUpdateMap) {
        Integer updateTracker = DatabaseUtilities.saveToDatabaseTracking(
            accountsToUpdateMap.values(),
            'monthlyAcctAggReCalc.execute',
            'Batch Account Updates in Execution Queue'
        );
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }
}