public with sharing class SplitProjectController {
    static final String ERROR_LOG = 'The following error occurred: ';
    static final String ERROR_FIELDS = 'Fields affected by that error: ';
    static final String UPDATE_OPP_DEV_NOTE = 'Opportunity Updates reassigning Projects';
    static final String UPDATE_OPP_METHOD_NAME = 'SplitProjectController.reassignOpps';
    static final String UPDATE_TASK_DEV_NOTE = 'Tasks updates to merged project';
    static final String UPDATE_TASK_METHOD_NAME = 'SplitProjectController.reassignTasks';
    static final String DELETE_JUNCTION_DEV_NOTE = 'Project Junctions failed to be removed';
    static final String DELETE_JUNCTION_METHOD_NAME = 'SplitProjectController.mergeProject';
    static final String DELETE_PROJECT_DEV_NOTE = 'Project failed to be removed';
    static final String DELETE_PROJECT_METHOD_NAME = 'SplitProjectController.mergeProject';

    /**
     * @description method to fetch projects
     * @param contactId id of contact to search for projects
     * @param projectId id of project to exclude
     * @return List of Project objects for a given contact excluding parameter project
     */
    @AuraEnabled
    public static List<Project__c> getProjectList(Id contactId, Id projectId) {
        return [SELECT Id, Name FROM Project__c WHERE Primary_Contact__c = :contactId AND Id != :projectId];
    }

    /**
     * @description method to fetch all open opportunities
     * @param projectId id of project to get the opportunities for
     * @return List of non-Closed opportunity objects
     */
    @AuraEnabled
    public static List<Opportunity> getOppList(Id projectId) {
        return [
            SELECT Id, Name, Project__c
            FROM Opportunity
            WHERE Project__c = :projectId AND StageName NOT IN ('Closed Won', 'Closed Lost')
        ];
    }

    /**
     * @description method to return fields from a project
     * @param projectId id of project to get the details of
     * @return single project with details
     */
    @AuraEnabled
    public static Project__c getProjectDetails(Id projectId) {
        return [
            SELECT Id, Name, Line_of_Business__c, Primary_Contact__c, AccountId__c, Stage__c, AccountId__r.Name
            FROM Project__c
            WHERE Id = :projectId
        ][0];
    }

    /**
     * @description method to reassign opportunities
     * @param projectId id of project
     * @param oppIds List of Opportunity ids
     * @return String indicating status of new project
     */
    @AuraEnabled
    public static string reassignOpps(Id projectId, List<Id> oppIds) {
        try {
            Set<Opportunity> updatedOppSet = new Set<Opportunity>();
            List<Opportunity> updatedOppsList = new List<Opportunity>();

            for (Id opp : oppIds) {
                Opportunity newOpp = new Opportunity();
                newOpp.Id = opp;
                newOpp.Project__c = projectId;
                updatedOppSet.add(newOpp);
            }
            updatedOppsList.addAll(updatedOppSet);

            DatabaseUtilities.upsertToDatabase(updatedOppsList, UPDATE_OPP_METHOD_NAME, UPDATE_OPP_DEV_NOTE);
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description method to merge projects
     * @param projectId id of project
     * @param mergeProjectId id of project to merge into
     * @return String indicating success of project merge
     */
    @AuraEnabled
    public static string mergeProject(Id projectId, Id mergeProjectId) {
        try {
            List<Opportunity> oppFetchList = [
                SELECT Id, Name, Project__c
                FROM Opportunity
                WHERE Project__c = :projectId
            ];

            // move all opps
            Set<Opportunity> updatedOppSet = new Set<Opportunity>();
            List<Opportunity> updatedOppsList = new List<Opportunity>();

            for (Opportunity opp : oppFetchList) {
                opp.Project__c = mergeProjectId;
                updatedOppSet.add(opp);
            }
            updatedOppsList.addAll(updatedOppSet);

            DatabaseUtilities.upsertToDatabase(updatedOppsList, UPDATE_OPP_METHOD_NAME, UPDATE_OPP_DEV_NOTE);

            // update tasks relations to merged project
            Set<Task> updatedTaskSet = new Set<Task>();
            List<Task> updatedTaskList = new List<Task>();

            List<Task> taskFetchList = [SELECT WhatId, Subject FROM Task WHERE WhatId = :projectId];

            for (Task t : taskFetchList) {
                t.WhatId = mergeProjectId;
                updatedTaskSet.add(t);
            }
            updatedTaskList.addAll(updatedTaskSet);

            DatabaseUtilities.upsertToDatabase(updatedTaskList, UPDATE_TASK_METHOD_NAME, UPDATE_TASK_DEV_NOTE);

            // delete all junctions
            List<Project_Contact__c> originalProjectContactJunctions = [
                SELECT Id
                FROM Project_Contact__c
                WHERE Project__c = :projectId
            ];
            List<Project_Account__c> originalProjectAccountJunction = [
                SELECT Id
                FROM Project_Account__c
                WHERE Project__c = :projectId
            ];
            DatabaseUtilities.deleteFromDatabase(
                originalProjectContactJunctions,
                DELETE_JUNCTION_METHOD_NAME,
                DELETE_JUNCTION_DEV_NOTE
            );
            DatabaseUtilities.deleteFromDatabase(
                originalProjectAccountJunction,
                DELETE_JUNCTION_METHOD_NAME,
                DELETE_JUNCTION_DEV_NOTE
            );

            // delete original project
            //List<Project__c> originalProject = [SELECT Id FROM Project__c WHERE Id = :projectId];
            // deleteFromDatabase(originalProject, DELETE_PROJECT_METHOD_NAME, DELETE_PROJECT_DEV_NOTE);

            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}