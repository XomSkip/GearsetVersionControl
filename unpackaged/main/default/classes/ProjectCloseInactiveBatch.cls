/**
 * @description simple batch to reduce flow cpu work
 * Close Projects without Opportunities in the last days
 */
global class ProjectCloseInactiveBatch implements Database.Batchable<sObject>, Database.Stateful {
    static final String BATCH_METHOD_NAME = 'ProjectCloseInactiveBatch.execute';
    Datetime inactivityDate = System.now().addDays(-10);
    Set<Id> adminRefPoolIds = new Set<Id>();

    global ProjectCloseInactiveBatch() {
        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c
            FROM Admin_Ref_Variable__mdt
            WHERE DeveloperName = 'ProjectCloseAuto'
        ]) {
            adminRefPoolIds.addAll((List<Id>) adminRefVarValues.Text_Ref_Var__c.split(';'));
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id
                FROM Project__c
                WHERE
                    Stage__c != 'Closed Lost'
                    AND Last_Opp_Created_Date__c <= :inactivityDate
                    AND OwnerId IN :adminRefPoolIds
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<Project__c> projectList) {
        List<Project__c> projectsToClose = new List<Project__c>();
        for (Project__c project : projectList) {
            project.Stage__c = 'Closed Lost';
            project.Sub_Stage__c = 'Auto-Closed';
            project.Closed_Lost_Reason__c = 'Auto-closed due to inactivity';
            projectsToClose.add(project);
        }

        DatabaseUtilities.saveToDatabase(projectsToClose, BATCH_METHOD_NAME, 'Project Close Batch update');
    }

    global void finish(Database.BatchableContext BC) {
    }
}