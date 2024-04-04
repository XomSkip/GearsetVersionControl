global class updateContactQuoteDates implements Database.Batchable<sObject>, Database.Stateful {
    // instance member to retain state across transactions
    global Integer UCQDrecordsProcessed = 0;
    global Integer batchTracker = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, Name, Contact_s_Date_of_First_Order__c, First_Quote_Date__c, Date_of_Last_Order__c, Date_of_Last_Quote__c, Sup_DateOfFirstQuote__c, Sup_DateOfLastQuote__c, Sup_NumberQuotes__c, Sup_DateOfFirstOrder__c, Sup_DateOfLastOrder__c from Contact order by AccountID'
        );
    }
    global void execute(Database.BatchableContext bc, List<Contact> scope) {
        batchTracker = batchTracker + 1;
        SET<ID> lContactIDSET = new Set<ID>();
        Map<ID, Contact> lContactIDMap = new Map<ID, Contact>();
        for (Contact c : scope) {
            lContactIDSET.add(c.ID);
            lContactIDMap.put(c.ID, c);
        }
        // Fetch the Quote Dates
        AggregateResult[] quoteAggRes = [
            SELECT
                ContactID__C ContactID,
                Max(Quote_ERP_Created_Date__C) Last_Quote_Date,
                Min(Quote_ERP_Created_Date__C) First_Quote_Date,
                Count_Distinct(Xometry_ERP_ID__C) NumQuotes
            FROM Quote_ERP__C
            WHERE ContactID__C IN :lContactIDSET
            GROUP BY ContactID__C
        ];
        for (AggregateResult laggRes : quoteAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('ContactID')));
            Date lLastQuoteDate = Date.valueOf(String.valueOf(laggRes.get('Last_Quote_Date')));
            Date lFirstQuoteDate = Date.valueOf(String.valueOf(laggRes.get('First_Quote_Date')));
            Integer lNumQuotes = Integer.valueOf(String.valueOf(laggRes.get('NumQuotes')));
            if (lContactIDMap.containsKey(lID)) {
                contact lContact = lContactIDMap.get(lID);
                lContact.First_Quote_Date__c = lFirstQuoteDate;
                lContact.Date_of_Last_Quote__c = lLastQuoteDate;
                lContact.Number_Quotes__c = lNumQuotes;
                lContactIDMap.put(lContact.ID, lContact);
            }
        }
        // Fetch the Orders Data
        AggregateResult[] orderAggRes = [
            SELECT
                ContactID__C ContactID,
                Max(Order_ERP_CreatedDate__c) Last_Order_Date,
                Min(Order_ERP_CreatedDate__c) First_Order_Date
            FROM Order_ERP__C
            WHERE ContactID__C IN :lContactIDSET
            GROUP BY ContactID__C
        ];
        for (AggregateResult laggRes : orderAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('ContactID')));
            Date lLastOrderDate = Date.valueOf(String.valueOf(laggRes.get('Last_Order_Date')));
            Date lFirstOrderDate = Date.valueOf(String.valueOf(laggRes.get('First_Order_Date')));
            if (lContactIDMap.containsKey(lID)) {
                contact lContact = lContactIDMap.get(lID);
                lContact.Contact_s_Date_of_First_Order__c = lFirstOrderDate;
                lContact.Date_of_Last_Order__c = lLastOrderDate;
                lContactIDMap.put(lContact.ID, lContact);
            }
        }

        // Fetch the Supplies Quote Dates
        AggregateResult[] suppliesQuoteAggRes = [
            SELECT
                ContactID__C ContactID,
                Max(Quote_P21_Created_Date__c) Sup_LastQuoteDate,
                Min(Quote_P21_Created_Date__c) Sup_FirstQuoteDate,
                COUNT_DISTINCT(P21_ERP_ID__C) Sup_NumQuotes
            FROM Supplies_Quote__C
            WHERE ContactID__C IN :lContactIDSET
            GROUP BY ContactID__C
        ];
        for (AggregateResult laggRes : suppliesQuoteAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('ContactID')));
            Date lSupLastQuoteDate = Date.valueOf(String.valueOf(laggRes.get('Sup_LastQuoteDate')));
            Date lSupFirstQuoteDate = Date.valueOf(String.valueOf(laggRes.get('Sup_FirstQuoteDate')));
            Integer lSupNumQuotes = Integer.valueOf(String.valueOf(laggRes.get('Sup_NumQuotes')));
            if (lContactIDMap.containsKey(lID)) {
                contact lContact = lContactIDMap.get(lID);
                lContact.Sup_DateOfFirstQuote__c = lSupFirstQuoteDate;
                lContact.Sup_DateOfLastQuote__c = lSupLastQuoteDate;
                lContact.Sup_NumberQuotes__c = lSupNumQuotes;
                lContactIDMap.put(lContact.ID, lContact);
            }
        }
        // Fetch the Supplies Order Dates
        AggregateResult[] suppliesOrderAggRes = [
            SELECT ContactID__C ContactID, Max(Order_Date__c) Sup_LastOrderDate, Min(Order_Date__c) Sup_FirstOrderDate
            FROM Supplies_Order__c
            WHERE ContactID__C IN :lContactIDSET
            GROUP BY ContactID__C
        ];
        for (AggregateResult laggRes : suppliesOrderAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('ContactID')));
            Date lSupLastOrderDate = Date.valueOf(String.valueOf(laggRes.get('Sup_LastOrderDate')));
            Date lSupFirstOrderDate = Date.valueOf(String.valueOf(laggRes.get('Sup_FirstOrderDate')));
            if (lContactIDMap.containsKey(lID)) {
                contact lContact = lContactIDMap.get(lID);
                lContact.Sup_DateOfFirstOrder__c = lSupFirstOrderDate;
                lContact.Sup_DateOfLastOrder__c = lSupLastOrderDate;
                lContactIDMap.put(lContact.ID, lContact);
            }
        }

        //Update the Contacts

        System.debug('About to start the Contact Updates');
        List<Contact> contactUpdateList = new List<Contact>();
        contactUpdateList = lContactIDMap.values();
        System.debug('Contacts to Update List is');
        System.debug('The size of the Contact Update List is : ' + contactUpdateList.size());
        System.debug(contactUpdateList);
        Integer updateTracker = DatabaseUtilities.saveToDatabaseTracking(
            contactUpdateList,
            'updateContactQuoteDates.execute',
            'Contact Updates in Execution Queu'
        );
        UCQDrecordsProcessed = UCQDrecordsProcessed + contactUpdateList.size();

        // To be uncommented when investigating record locking
        // Temporary Custom

        // List<Audit_Trail_Error__c> myAuditErrorList = new List<Audit_Trail_Error__c>();
        // integer localRecord1 = 0;
        // Audit_Trail_Error__c myAuditError = new Audit_Trail_Error__c();
        // myAuditError.Module__c = 'updateContactQuoteDates.Manualexecute';
        // myAuditError.Dev_Audit_Notes__c = 'The size of the Contact Update List is : ' + contactUpdateList.size();
        // myAuditError.StatusCode__c = 'BatchJobUpdate';
        // myAuditError.errorMessage__c =
        //     'The size of successes is : ' +
        //     updatetracker +
        //     ' The numof errors is : ' +
        //     localRecord1;
        // myAuditErrorList.add(myAuditError);

        // if (!myAuditErrorList.isEmpty()) {
        //     insert myAuditErrorList;
        // }

        System.debug('Current Records Processed' + UCQDrecordsProcessed);
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(UCQDrecordsProcessed + ' records processed. Shazam!');
    }
}