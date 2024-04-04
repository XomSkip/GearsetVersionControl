/**
 * @description simple batch to reduce flow cpu work
 * scan for accounts flagged with Batch_Reassign__c and update the owner with the value
 */

global class AccountReassignBatch implements Database.Batchable<sObject>, Database.Stateful {
    static final String BATCH_METHOD_NAME = 'AccountReassignBatch.execute';
    Set<Id> queueAndactiveUserIds = new Set<Id>();
    Set<Id> adminRefPoolIds = new Set<Id>();

    public AccountReassignBatch() {
        for (Group g : [SELECT Id, Type, Name FROM Group WHERE Type = 'Queue']) {
            queueAndactiveUserIds.add(g.Id);
        }

        for (User u : [SELECT Id FROM User WHERE IsActive = TRUE]) {
            queueAndactiveUserIds.add(u.Id);
        }

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
            [SELECT Id, Batch_Reassign__c FROM Account WHERE Batch_Reassign__c IN :queueAndactiveUserIds]
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> accList) {
        List<Account> accountsToReassign = new List<Account>();
        List<Id> accountsToClose = new List<Id>();
        for (Account acc : accList) {
            if (adminRefPoolIds.contains(acc.Batch_Reassign__c)) {
                accountsToClose.add(acc.Id);
            }
            acc.OwnerId = acc.Batch_Reassign__c;
            acc.Batch_Reassign__c = null;
            accountsToReassign.add(acc);
        }

        Map<Id, Project__c> projectsToCloseMap = new Map<Id, Project__c>();
        for (Project__c project : [
            SELECT Id
            FROM Project__c
            WHERE AccountId__c IN :accountsToClose AND Stage__c NOT IN ('Closed Lost', 'Closed Won')
        ]) {

            projectsToCloseMap.put(project.Id, project);

        }

        //Get a list of cw opps that are in Closed Projects
        Set<Id> projectsWithCwOppsSet = new Set<Id>();
        for (Opportunity opp : [
            SELECT ID, StageName, Project__c
            FROM Opportunity
            WHERE StageName = 'Closed Won' AND Project__c IN :projectsToCloseMap.keySet()
        ]) {

            projectsWithCwOppsSet.add(opp.Project__c);

        }

        for( Project__c project : projectsToCloseMap.values() ){

            if( !projectsWithCwOppsSet.contains(project.Id) ){
                project.Stage__c = 'Closed Lost';
                project.Sub_Stage__c = 'Auto-Closed';
                project.Closed_Lost_Reason__c = 'Auto-closed due to reassignment back to the Pool User';
            }else{
                project.Stage__c = 'Closed Won';
            }

        }

        DatabaseUtilities.saveToDatabase(projectsToCloseMap.values(), BATCH_METHOD_NAME, 'Project Close Batch update');

        DatabaseUtilities.saveToDatabase(accountsToReassign, BATCH_METHOD_NAME, 'Account Reassign Batch update');
    }

    global void finish(Database.BatchableContext bc) {
    }
}