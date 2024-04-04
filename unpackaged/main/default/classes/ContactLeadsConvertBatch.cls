global class ContactLeadsConvertBatch implements Database.Batchable<sObject>, Database.Stateful {
    static final String PROJECT_BATCH_METHOD_NAME = 'ContactLeadsConvertBatch.execute';
    static final String PROJECT_BATCH_DEV_NOTE = 'Convert Contact Leads Batch update';

    String batchQuery = ' SELECT Id, OwnerId, Primary_Email__c, AccountId FROM Contact ';

    public ContactLeadsConvertBatch(String whereClause) {
        if (!String.isEmpty(whereClause)) {
            batchQuery += whereClause;
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(batchQuery);
    }

    global void execute(Database.BatchableContext bc, List<Contact> contactList) {
        HandlerUtil.leadConverter(contactList);
    }

    global void finish(Database.BatchableContext bc) {
    }
}