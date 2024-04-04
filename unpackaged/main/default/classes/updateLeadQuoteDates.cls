global class updateLeadQuoteDates implements Database.Batchable<sObject>, Database.Stateful {
    // instance member to retain state across transactions
    global Integer UCQDrecordsProcessed = 0;
    global Integer batchTracker = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID, Name, First_Quote_Date__c, Date_of_Last_Quote__c, Number_of_Quotes__c from Lead where isConverted=False'
        );
    }
    global void execute(Database.BatchableContext bc, List<Lead> scope) {
        batchTracker = batchTracker++;
        SET<ID> lLeadIDSET = new Set<ID>();
        Map<ID, Lead> lLeadIDMap = new Map<ID, Lead>();
        for (Lead c : scope) {
            lLeadIDSET.add(c.ID);
            lLeadIDMap.put(c.ID, c);
        }
        // Fetch the Quote Dates
        AggregateResult[] quoteAggRes = [
            SELECT
                LeadID__C LeadID,
                Max(Quote_ERP_Created_Date__C) Last_Quote_Date,
                Min(Quote_ERP_Created_Date__C) First_Quote_Date,
                Count_DISTINCT(Xometry_ERP_ID__C) Number_of_Quotes
            FROM Quote_ERP__C
            WHERE LeadID__C IN :lLeadIDSET
            GROUP BY LeadID__C
        ];
        for (AggregateResult laggRes : quoteAggRes) {
            ID lID = ID.valueOf(String.valueOf(laggRes.get('LeadID')));
            Date lLastQuoteDate = Date.valueOf(String.valueOf(laggRes.get('Last_Quote_Date')));
            Date lFirstQuoteDate = Date.valueOf(String.valueOf(laggRes.get('First_Quote_Date')));
            Integer lNumberofQuotes = Integer.valueOf(String.valueOf(laggRes.get('Number_of_Quotes')));
            if (lleadIDMap.containsKey(lID)) {
                lead llead = lleadIDMap.get(lID);
                llead.First_Quote_Date__c = lFirstQuoteDate;
                llead.Date_of_Last_Quote__c = lLastQuoteDate;
                llead.Number_of_Quotes__c = lNumberofQuotes;
                lleadIDMap.put(llead.ID, llead);
            }
        }

        //Update the Leads

        System.debug('About to start the Lead Updates');
        List<Lead> leadUpdateList = new List<Lead>();
        leadUpdateList = lleadIDMap.values();
        System.debug('Lead to Update List is');
        System.debug(leadUpdateList);
        Integer updateTracker = DatabaseUtilities.saveToDatabaseTracking(
            leadUpdateList,
            'updateLeadQuoteDates.execute',
            'Lead Updates in Execution Queu : Batch is : ' + batchTracker
        );
        UCQDrecordsProcessed = UCQDrecordsProcessed + leadUpdateList.size();

        System.debug('Current Records Processed' + UCQDrecordsProcessed);
        System.debug('The update tracker records for this batch are ' + updateTracker);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(UCQDrecordsProcessed + ' Lead records processed. Shazam!');
    }
}