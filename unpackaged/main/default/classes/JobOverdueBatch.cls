global class JobOverdueBatch implements Database.Batchable<sObject>, schedulable {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT DueDate__c
                FROM Job__c
                WHERE Stage__c NOT IN ('Completed', 'Vendor Completed') AND DueDate__c != NULL
            ]
        );
    }

    global void execute(Database.BatchableContext BC, list<Job__c> scope) {
        Date dToday = System.today();

        for (Job__c job : scope) {
            if (job.DueDate__c != null) {
                job.Job_OverDue_Flag__c = job.DueDate__c.daysBetween(dToday);
            }
        }

        DatabaseUtilities.saveToDatabase(scope, 'JobOverdueBatch.execute', 'Job Overdue Flag update');
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext sc) {
        Database.executebatch(new JobOverdueBatch());
    }
}