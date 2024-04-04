global class ProjectBatch implements Database.Batchable<sObject>, Database.Stateful {
    static final String PROJECT_BATCH_METHOD_NAME = 'ProjectBatch.execute';
    static final String PROJECT_BATCH_DEV_NOTE = 'Project Batch update';
    static final Id enterpriseOfferingId = Schema.SObjectType.Project__c.getRecordTypeInfosByDeveloperName()
        .get('Enterprise_Offering')
        .getRecordTypeID();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, Stage__c, Closed_Lost_Reason__c
                FROM Project__c
                WHERE
                    Id NOT IN (SELECT Project__c FROM Opportunity)
                    AND Stage__c = 'New'
                    AND RecordTypeId != :enterpriseOfferingId
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<Project__c> projectList) {
        List<Project__c> projectsToClose = new List<Project__c>();
        for (Project__c proj : projectList) {
            proj.Stage__c = 'Closed Lost';
            proj.Closed_Lost_Reason__c = 'No Opportunities associated -- Closed automatically weekly';
            projectsToClose.add(proj);
        }

        DatabaseUtilities.saveToDatabase(projectsToClose, PROJECT_BATCH_METHOD_NAME, PROJECT_BATCH_DEV_NOTE);
    }

    global void finish(Database.BatchableContext bc) {
    }
}