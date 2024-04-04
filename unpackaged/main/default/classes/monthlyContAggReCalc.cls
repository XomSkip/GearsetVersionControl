global class monthlyContAggReCalc implements Database.Batchable<sObject>, Database.Stateful {
    global Integer recordsProcessed = 0;
    global Integer batchTracker = 0;

    static ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, AccountId FROM Contact ORDER BY AccountId, Id');
    }

    global void execute(Database.BatchableContext bc, List<Contact> contactsList) {
        Map<Id, Contact> contactsToUpdateMap = new Map<Id, Contact>();
        for (Contact c : contactsList) {
            Contact thisContact = new Contact(Id = c.ID, AccountId = c.AccountId);
            contactsToUpdateMap.put(thisContact.Id, thisContact);
        }
        calcYTDSpend(contactsList, contactsToUpdateMap);
        calcRolling12Spend(contactsList, contactsToUpdateMap);
        calcLifetimeSpendAndNumOfOrders(contactsToUpdateMap);
        calcOpenOpps(contactsToUpdateMap);
        for (Contact thisContact : contactsToUpdateMap.values()) {
            if (thisContact.Lifetime_Spend__c == null) {
                thisContact.Lifetime_Spend__c = 0;
            }
            if (thisContact.Number_Orders__c == null) {
                thisContact.Number_Orders__c = 0;
            }
            if (thisContact.Number_of_Open_Opportunities__c == null) {
                thisContact.Number_of_Open_Opportunities__c = 0;
            }
        }
        processRecords(contactsToUpdateMap, batchTracker);
        recordsProcessed += contactsToUpdateMap.values().size();
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(recordsProcessed + ' records processed. Shazam!');
    }

    /**
     * @description Calcs contact YTD Spend
     * @param contactsList list containing queried contacts
     * @param contactsToUpdateMap map containing contacts to update
     */
    private static void calcYTDSpend(List<Contact> contactsList, Map<Id, Contact> contactsToUpdateMap) {
        AggregateResult[] myAggResYTD = [
            SELECT Primary_Contact__c, Sum(Amount) Total
            FROM Opportunity
            WHERE
                StageName = 'Closed Won'
                AND Primary_Contact__c IN :contactsToUpdateMap.keySet()
                AND CALENDAR_YEAR(CloseDate) = :Date.today().year()
                AND RecordTypeId = :oppManufacturingServRTypeID
            GROUP BY Primary_Contact__c
        ];
        Map<Id, Decimal> ytdResultMap = new Map<Id, Decimal>();
        if (!myAggResYTD.isEmpty()) {
            for (AggregateResult aggRes : myAggResYTD) {
                Id lID = Id.valueOf(String.valueOf(aggRes.get('Primary_Contact__c')));
                Decimal lTotal = 0;
                if (aggRes.get('Total') != null) {
                    lTotal = Decimal.valueOf(String.valueOf(aggRes.get('Total')));
                }
                ytdResultMap.put(lID, lTotal);
            }
        }
        for (Contact c : contactsList) {
            if (contactsToUpdateMap.containsKey(c.Id)) {
                Contact thisContact = contactsToUpdateMap.get(c.Id);
                if (ytdResultMap.containsKey(c.Id)) {
                    thisContact.YTD_Spend__c = ytdResultMap.get(c.Id);
                    contactsToUpdateMap.put(thisContact.Id, thisContact);
                } else {
                    thisContact.YTD_Spend__c = 0;
                    contactsToUpdateMap.put(thisContact.Id, thisContact);
                }
            }
        }
    }

    /**
     * @description Calcs contact Rolling 12 Spend
     * @param contactsList list containing queried contacts
     * @param contactsToUpdateMap map containing contacts to update
     */
    private static void calcRolling12Spend(List<Contact> contactsList, Map<Id, Contact> contactsToUpdateMap) {
        Date currentDate = Date.today();
        Integer currentMonth = currentDate.month();
        Integer currentYear = currentDate.year();
        Integer previousYear = currentYear - 1;
        Integer rollingMonth;
        Integer rollingYear;
        Date rollingDate;
        if (currentMonth == 12) {
            rollingMonth = 1;
            rollingYear = currentYear;
        } else {
            rollingMonth = currentMonth + 1;
            rollingYear = previousYear;
        }
        rollingDate = Date.newInstance(rollingYear, rollingMonth, 1);
        AggregateResult[] myAggResRolling = [
            SELECT Primary_Contact__c, Sum(Amount) RollingTotal
            FROM Opportunity
            WHERE
                Stagename = 'Closed Won'
                AND Primary_Contact__c IN :contactsToUpdateMap.keySet()
                AND closeDate >= :rollingDate
                AND RecordTypeId = :oppManufacturingServRTypeID
            GROUP BY Primary_Contact__c
        ];
        Map<Id, Decimal> rolling12ResultMap = new Map<Id, Decimal>();
        if (!myAggResRolling.isEmpty()) {
            for (AggregateResult aggRes : myAggResRolling) {
                Id lID = ID.valueOf(String.valueOf(aggRes.get('Primary_Contact__c')));
                Decimal lRollTotal = 0;
                if (aggRes.get('RollingTotal') != null) {
                    lRollTotal = Decimal.valueOf(String.valueOf(aggRes.get('RollingTotal')));
                }
                rolling12ResultMap.put(lID, lRollTotal);
            }
        }
        for (Contact c : contactsList) {
            if (contactsToUpdateMap.containsKey(c.Id)) {
                Contact thisContact = contactsToUpdateMap.get(c.Id);
                if (rolling12ResultMap.containsKey(c.Id)) {
                    thisContact.Rolling_12_Spend__c = rolling12ResultMap.get(c.Id);
                    contactsToUpdateMap.put(thisContact.Id, thisContact);
                } else {
                    thisContact.Rolling_12_Spend__c = 0;
                    contactsToUpdateMap.put(thisContact.Id, thisContact);
                }
            }
        }
    }

    /**
     * @description Calcs contact lifetime spend and number of orders
     * @param contactsToUpdateMap map containing contacts to update
     */
    private static void calcLifetimeSpendAndNumOfOrders(Map<Id, Contact> contactsToUpdateMap) {
        AggregateResult[] myAggReYTD = [
            SELECT Primary_Contact__c, Sum(Amount) LifeTimeSpend, Count_Distinct(Order_ERP_Xom_ID__c) OrdCount
            FROM Opportunity
            WHERE
                Stagename = 'Closed Won'
                AND Primary_Contact__c IN :contactsToUpdateMap.keySet()
                AND RecordTypeId = :oppManufacturingServRTypeID
            GROUP BY Primary_Contact__c
        ];
        if (!myAggReYTD.isEmpty()) {
            for (AggregateResult aggRes : myAggReYTD) {
                ID lID = ID.valueOf(String.valueOf(aggRes.get('Primary_Contact__c')));
                Decimal lLifeTimeSpend = 0;
                Integer lNumOrders = 0;
                if (aggRes.get('LifeTimeSpend') != null) {
                    lLifeTimeSpend = Decimal.valueOf(String.valueOf(aggRes.get('LifeTimeSpend')));
                }
                if (aggRes.get('OrdCount') != null) {
                    lNumOrders = Integer.valueOf(String.valueOf(aggRes.get('OrdCount')));
                }
                if (contactsToUpdateMap.containsKey(lID)) {
                    Contact thisContact = contactsToUpdateMap.get(lID);
                    thisContact.Lifetime_Spend__c = lLifeTimeSpend;
                    thisContact.Number_Orders__c = lNumOrders;
                    contactsToUpdateMap.put(thisContact.Id, thisContact);
                }
            }
        }
    }

    /**
     * @description Calcs contact Open opportunities
     * @param contactsToUpdateMap map containing contacts to update
     */
    private static void calcOpenOpps(Map<Id, Contact> contactsToUpdateMap) {
        AggregateResult[] myAggReOpenOpps = [
            SELECT Primary_Contact__c, Count_Distinct(ID) OpenOpps
            FROM Opportunity
            WHERE
                Stagename NOT IN ('Closed Won', 'Closed Lost')
                AND Primary_Contact__c IN :contactsToUpdateMap.keySet()
                AND RecordTypeId = :oppManufacturingServRTypeID
            GROUP BY Primary_Contact__c
        ];
        if (!myAggReOpenOpps.isEmpty()) {
            for (AggregateResult aggRes : myAggReOpenOpps) {
                Id lID = Id.valueOf(String.valueOf(aggRes.get('Primary_Contact__c')));
                Integer lOpenOpps = 0;
                if (aggRes.get('OpenOpps') != null) {
                    lOpenOpps = Integer.valueOf(String.valueOf(aggRes.get('OpenOpps')));
                }
                if (contactsToUpdateMap.containsKey(lID)) {
                    Contact thisContact = contactsToUpdateMap.get(lID);
                    thisContact.Number_of_Open_Opportunities__c = lOpenOpps;
                    contactsToUpdateMap.put(thisContact.Id, thisContact);
                }
            }
        }
    }

    /**
     * @description Updates contactsToUpdateMap and records any database errors
     * @param contactsToUpdateMap map containing contacts to update
     * @param batchTracker integer incrementing current batch run
     */
    private static void processRecords(Map<Id, Contact> contactsToUpdateMap, Integer batchTracker) {
        Integer updateTracker = DatabaseUtilities.saveToDatabaseTracking(
            contactsToUpdateMap.values(),
            'monthlyContAggReCalc.execute',
            'Contact Updates in Batch Queue : batch : ' + batchTracker
        );
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }
}