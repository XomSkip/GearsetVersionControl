global class JobRollUpOpenCasesBatch implements Database.Batchable<sObject> {
    static final String PROJECT_BATCH_METHOD_NAME = 'JobRollUpOpenCasesBatch.execute';
    static final String PROJECT_BATCH_DEV_NOTE = 'Keep Job__c in sync with the amount of Cases';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Job__c]);
    }

    global void execute(Database.BatchableContext BC, List<Job__c> scope) {
        Map<Id, Job__c> jobsMap = new Map<Id, Job__c>();
        for (Job__c j : scope) {
            j.Open_Cases__c = 0;
            jobsMap.put(j.Id, j);
        }

        for (AggregateResult aggRes : [
            SELECT Job__c, count(Id) OpenCases
            FROM Case
            WHERE RecordType.Name = 'Sourcing' AND Status != 'Closed' AND Job__c IN :jobsMap.keySet()
            GROUP BY Job__c
            HAVING count(Id) > 0
        ]) {
            jobsMap.get((Id) aggRes.get('Job__c')).Open_Cases__c = (Integer) aggRes.get('OpenCases');
        }

        DatabaseUtilities.upsertToDatabase(jobsMap.values(), PROJECT_BATCH_METHOD_NAME, PROJECT_BATCH_DEV_NOTE);
    }

    global void finish(Database.BatchableContext BC) {
    }
}