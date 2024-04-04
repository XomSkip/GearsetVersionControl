/**
 * @description simple batch to reduce Quote trigger and Contact record block
 * scan for flagged Quote_ERP__C with Processes_Updated__c sync related Contact with new data
 */
global class ContactQuoteProcessUpdatesBatch implements Database.Batchable<sObject> {
    public String query = 'SELECT ContactID__c, process_isCarbon__c, process_isCNC_Machining__c, process_isDie_Casting__c, process_isDMLS__c, process_isDirect_Sourced__c,process_isExtrusion__c, process_isFDM__c, process_isHPMultJetFusion__c, process_isInjection_Molding__c, process_isPolyJet_3D__c, process_isSLS__c, process_isSheet_metal__c, process_isStamping__c, process_isSLA__c, process_isUrethane_Casting__c, process_isBinderJetting__c, process_isSheetCutting__c, process_isTubeBending__c, process_isTubeCutting__c, process_isOther__c, process_isLSPc__c, process_isPlasticExtrusion__c, process_isOther_NotIncluded__c, process_isAssembly__c FROM Quote_ERP__C WHERE ContactID__C != null AND Process_Update__c = TRUE ORDER BY ContactID__C';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Quote_ERP__C> scope) {
        Map<ID, List<Quote_ERP__C>> contactQuoteMap = new Map<ID, List<Quote_ERP__C>>();

        for (Quote_ERP__C q : scope) {
            //Map Quotes to Contacts
            if (!contactQuoteMap.containsKey(q.ContactID__C)) {
                contactQuoteMap.put(q.ContactID__C, new List<Quote_ERP__C>());
            }
            contactQuoteMap.get(q.ContactID__C).add(q);
        }

        List<Contact> contactsToUpdate = QuoteERPHandler.checkQuoteContactDifferences(contactQuoteMap);

        Database.UpsertResult[] contactUpdateResults = DatabaseUtilities.upsertToDatabase(
            contactsToUpdate,
            'ContactQuoteProcessUpdatesBatch.execute',
            'Contact Updates in Scheduled Batch'
        );

        List<Quote_ERP__C> quotesToUpdate = new List<Quote_ERP__C>();
        for (Database.UpsertResult sr : contactUpdateResults) {
            if (sr.isSuccess()) {
                for (Quote_ERP__C q : contactQuoteMap.get(sr.getID())) {
                    q.Process_Update__c = false;
                    quotesToUpdate.add(q);
                }
            }
        }

        DatabaseUtilities.saveToDatabase(
            quotesToUpdate,
            'ContactQuoteProcessUpdatesBatch.execute',
            'Batch done, flag quotes as processed.'
        );
    }

    global void finish(Database.BatchableContext BC) {
    }
}