public with sharing class leadConverterCustom {
    static final String DEFAULT_LINE_OF_BUSINESS = 'Instant Quote';
    /**
     * @description When a lead is converted, update the quote of origin
     * @param inConvertedLeadList list of leads converted
     */
    @InvocableMethod(label='Lead Convert Update Quote' description='Update Quotes with Lead Convert Information')
    public static void LeadConvertUpdateQuote(List<Lead> inConvertedLeadList) {
        Set<ID> inConvertedLeadIDSet = new Set<ID>();
        Map<ID, Lead> convertedLeadMap = new Map<Id, Lead>();
        Set<ID> inConvertedOpportunityIDSet = new Set<ID>();
        Set<ID> inConvertedContactIDSet = new Set<ID>();
        Map<ID, ID> oppToContactMap = new Map<ID, ID>();
        Map<ID, String> oppToLOBMap = new Map<ID, String>();
        for (Lead l : inConvertedLeadList) {
            inConvertedLeadIDSet.add(l.id);
            convertedLeadMap.put(l.id, l);
            if (!String.isblank(l.ConvertedContactId) && !String.isblank(l.ConvertedOpportunityId)) {
                oppToContactMap.put(l.ConvertedOpportunityId, l.ConvertedContactId);
                inConvertedOpportunityIDSet.add(l.ConvertedOpportunityId);
            }
        }

        List<Quote_ERP__C> existingQuoteList = [
            SELECT ID, LeadID__C, Xometry_ERP_ID__C, Line_of_Business__c
            FROM Quote_ERP__C
            WHERE LeadID__C IN :inConvertedLeadIDSet
        ];
        SET<Quote_ERP__C> quoteToUpDateSET = new Set<Quote_ERP__C>();
        List<Quote_ERP__C> quoteToUpDateList = new List<Quote_ERP__C>();

        Integer i = 0;
        if (!existingQuoteList.isEmpty()) {
            for (Quote_ERP__C q : existingQuoteList) {
                i = i + 1;
                System.debug('Outside matching quote to opp make : ' + i);
                if (convertedLeadMap.containsKey(q.LeadID__C)) {
                    Lead l = convertedLeadMap.get(q.LeadID__C);
                    q.AccountID__c = l.ConvertedAccountId;
                    System.debug('The Quotes Xom id is : ' + q.Xometry_ERP_ID__C);
                    System.debug('The Leads las Xom id is : ' + l.Last_Quote_Xometry_ERP_ID__C);
                    if (q.Xometry_ERP_ID__C == l.Last_Quote_Xometry_ERP_ID__C) {
                        System.debug('Inside matching quote to opp maker : ' + i);
                        q.OpportunityID__c = l.ConvertedOpportunityId;
                        if (String.isNotBlank(q.Line_of_Business__c)) {
                            oppToLOBMap.put(l.ConvertedOpportunityId, q.Line_of_Business__c);
                        }
                    }

                    q.ContactID__c = l.ConvertedContactId;
                    quoteToUpDateSET.add(q);
                }
            }
        }
        quoteToUpDateList.addAll(quoteToUpDateSET);
        System.debug('Starting the Quote Updates');
        System.debug('The size of the Quotes to Update is ' + quoteToUpDateList.size());
        DatabaseUtilities.saveToDatabase(
            quoteToUpDateList,
            'leadConverterCustom.LeadConvertUpdateQuote',
            'Quote Updates after Lead Conversion'
        );

        List<Opportunity> updateOptList = new List<Opportunity>();
        //Update the Primary Contact
        for (ID mID : inConvertedOpportunityIDSet) {
            Opportunity opp = new Opportunity();
            opp.ID = mID;
            opp.Primary_Contact__c = oppToContactMap.get(mID);
            if (oppToLOBMap.containsKey(mID)) {
                opp.Line_of_Business__c = oppToLOBMap.get(mID);
            } else {
                opp.Line_of_Business__c = DEFAULT_LINE_OF_BUSINESS;
            }
            updateOptList.add(opp);
        }

        System.debug('Starting the Opportunity Updates');
        System.debug('The size of the Opportunity to Update is ' + updateOptList.size());
        DatabaseUtilities.saveToDatabase(
            updateOptList,
            'leadConverterCustom.LeadConvertUpdateQuote',
            'Opportunity Updates after Lead Conversion'
        );
    }
}