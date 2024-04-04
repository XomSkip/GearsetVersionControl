global class DailyEUDEmailBatch implements Database.Batchable<sObject>, Database.Stateful, schedulable {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    EUD_Work_Stage__c,
                    Category__c,
                    ShadowXometryOrderID__c,
                    Account.EUD_EmailOptOut__c,
                    Contact.EUD_EmailOptOut__c
                FROM Case
                WHERE
                    Category__c = 'End-use definition'
                    AND EUD_Work_Stage__c = 'No Reach Out Yet'
                    AND isClosed = FALSE
                    AND Account.EUD_EmailOptOut__c = FALSE
                    AND Contact.EUD_EmailOptOut__c = FALSE
                    AND EUD_Email_Count__c < 2
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        Map<ID, String> eudCaseToOrderMap = new Map<ID, String>();
        for (Case c : scope) {
            eudCaseToOrderMap.put(c.Id, c.ShadowXometryOrderID__c);
        }

        OrderERPHandler.sendEUDEmail(eudCaseToOrderMap.keySet());
    }

    global void finish(Database.BatchableContext bc) {
    }

    global void execute(SchedulableContext sc) {
        Database.executebatch(new DailyEUDEmailBatch(), 5);
    }
}