/**
 * @description handler for Project updates
 */

public with sharing class ProjectHandler {
    static final String UPDATE_OPP_DEV_NOTE = 'Opportunity Updates post Project Load';
    static final String UPDATE_OPP_IN_CLOSED_PROJECT_METHOD_NAME = 'ProjectHandler.closedOppsinClosedProjects';
    static final String CLOSE_DATE_DEV_NOTE = 'Project Update changes Contact Junction';
    static final String CLOSE_DATE_PROJECT_METHOD_NAME = 'ProjectHandler.setCloseDate';
    static final String CREATE_JUNCTION_METHOD_NAME = 'ProjectHandler.createJunction';

    /**
     * @description Closes all open Opps associated with a Project that has been closed
     * @param updatedProjectsList List of Projects updated in Salesforce
     * @param oldProjectMap Map of projects that have been changed
     */

    public static void closeOppsinClosedProjects(
        List<Project__c> updatedProjectsList,
        Map<Id, Project__c> oldProjectMap
    ) {
        //Set of Projects to look up all associated Opps, Map of Projects to matching
        Map<Id, Project__c> closedProjectMap = new Map<Id, Project__c>();
        Date todayDate = date.today();

        for (Project__c p : updatedProjectsList) {
            Project__c oldProject = oldProjectMap.get(p.ID);
            if (oldProject.Stage__c != p.Stage__c && (p.Stage__c == 'Closed Lost' || p.Stage__c == 'Closed Won')) {
                closedProjectMap.put(p.ID, p);
            }
        }

        if (!closedProjectMap.isEmpty()) {

            List<Opportunity> closeOppList = new List<Opportunity>();

            for (Opportunity opp : [
                SELECT ID, StageName, Project__c
                FROM Opportunity
                WHERE StageName NOT IN ('Closed Won', 'Closed Lost') AND Project__c IN :closedProjectMap.keySet()
            ]) {
                opp.StageName = 'Closed Lost';
                opp.CloseDate = todayDate;
                opp.Loss_Reason__c = closedProjectMap.get(opp.Project__c).Closed_Lost_Reason__c;
                closeOppList.add(opp);
            }

            DatabaseUtilities.upsertToDatabase(
                closeOppList,
                UPDATE_OPP_IN_CLOSED_PROJECT_METHOD_NAME,
                UPDATE_OPP_DEV_NOTE
            );
        }
    }

    /**
     * @description when closing a project check to make sure there is at least one CW opp in a CW project, or no CW opps in a CL project
     * @param updatedProjectsList List of Projects updated in Salesforce
     */
    public static void checkForCwOppInClosedProject(List<Project__c> updatedProjectsList) {
        //Set of all closed Projects
        Set<Id> closedProjectSet = new Set<Id>();

        //Add all closed projects to a set
        for (Project__c p : updatedProjectsList) {
            if(!OpportunityHandler.isAmountUpdatedFromOpp)
            {
                p.isAmountUpdatedFromOpp__c = false;

                if (p.Stage__c == 'Closed Won' || p.Stage__c == 'Closed Lost')
                    closedProjectSet.add(p.ID);
            }
            else {
                p.isAmountUpdatedFromOpp__c = true;
            }
        }

        if (!closedProjectSet.isEmpty()) {
            //Get a list of all opps in Closed Projects
            List<Opportunity> oppFetchList = [
                SELECT ID, Project__c
                FROM Opportunity
                WHERE Project__C IN :closedProjectSet
            ];

            Set<Id> projectWithOppsSet = new Set<Id>();
            //Create a set of closed projects with opps
            //If a project is not in this set, it does not have opps and does not need validation before being closed
            for (Opportunity opp : oppFetchList) {
                projectWithOppsSet.add(opp.Project__c);
            }

            Set<Id> projectsWithCwOppsSet = new Set<Id>();
            if (!projectWithOppsSet.isEmpty()) {
                //Get a list of cw opps that are in Closed Projects
                List<Opportunity> cWOppFetchList = [
                    SELECT ID, StageName, Project__c
                    FROM Opportunity
                    WHERE StageName = 'Closed Won' AND Project__c IN :projectWithOppsSet
                ];
                // Removing all projects that do not have at least 1 CW Opp
                for (Opportunity opp : cwOppFetchList) {
                    if (projectWithOppsSet.contains(opp.Project__c)) {
                        projectsWithCwOppsSet.add(opp.Project__c);
                    }
                }
            }

            for (Project__c p : updatedProjectsList) {
                if (projectWithOppsSet.contains(p.Id)) {
                    if (p.Stage__c == 'Closed Lost' && projectsWithCwOppsSet.contains(p.Id)) {
                        p.addError('Closed Lost Project contains Closed Won Opportunity');
                    } else if (p.Stage__c == 'Closed Won' && !projectsWithCwOppsSet.contains(p.Id)) {
                        p.addError('Closed Won Project must contain Closed Won Opportunity');
                    }
                }
            }
        }
    }

    /**
     * @description when closing a project set close date to today
     * @param inProjectList List of Project__c to be Inserted/Updated
     * @param inOldProjectMap The Old Project__c Map before the Update was triggered.
     */
    public static void setCloseDate(List<Project__c> inProjectList, Map<ID, Project__c> inOldProjectMap) {
        Date todayDate = date.today();

        //Add all closed projects to a set
        for (Project__c p : inProjectList) {

            Boolean cond = (p.Stage__c == 'Closed Won' || p.Stage__c == 'Closed Lost');
            cond &= Trigger.isInsert || (Trigger.isUpdate && p.Stage__c != inOldProjectMap.get(p.Id).Stage__c);
            if ( cond ){
                p.Close_Date__c = todayDate;
            }

        }
    }

    /**
     * @description when creating a new project, create a new Project Junction object
     * @param updatedProjectsList List of Projects updated in Salesforce
     */
    public static void createJunction(List<Project__c> updatedProjectsList) {
        List<Project_Contact__c> newContactJunctionsList = new List<Project_Contact__c>();

        for (Project__c p : updatedProjectsList) {
            if (!String.isBlank(p.Primary_Contact__c)) {
                Project_Contact__c projectContactJunction = new Project_Contact__c();
                projectContactJunction.Project__c = p.Id;
                projectContactJunction.Contact__c = p.Primary_Contact__c;
                projectContactJunction.Primary__c = true;

                newContactJunctionsList.add(projectContactJunction);
            }
        }
        DatabaseUtilities.upsertToDatabase(newContactJunctionsList, CREATE_JUNCTION_METHOD_NAME, CLOSE_DATE_DEV_NOTE);
    }

    /**
     * @description when updating a Project Contact Junction, update appropriate Project Contact Records
     * @param inProjectList List of Project__c to be Updated
     * @param inOldProjectMap The Old Project__c Map before the Update was triggered.
     */
    public static void updateJunction(List<Project__c> inProjectList, Map<ID, Project__c> inOldProjectMap) {
        Map<Id, Id> updatePrimaryContactMap = new Map<Id, Id>();
        Map<Id, Id> newPrimaryContactMap = new Map<Id, Id>();
        List<Project__c> newPrimaryProjectList = new List<Project__c>();
        Set<Id> projectIdSet = new Set<Id>();

        //Add all closed projects to a set
        for (Project__c p : inProjectList) {
            if (p.Primary_Contact__c != inOldProjectMap.get(p.Id).Primary_Contact__c) {
                updatePrimaryContactMap.put(p.Id, inOldProjectMap.get(p.Id).Primary_Contact__c);
                newPrimaryContactMap.put(p.Id, p.Primary_Contact__c);
                projectIdSet.add(p.Id);
            }
        }

        if (!updatePrimaryContactMap.isEmpty()) {
            List<Project_Contact__c> existingJunctionList = new List<Project_Contact__c>();
            List<Project_Contact__c> existingContactJunction = [
                SELECT Id, Project__c, Contact__c, Primary__c
                FROM Project_Contact__c
                WHERE
                    Contact__c IN :updatePrimaryContactMap.values()
                    AND Project__c IN :updatePrimaryContactMap.keySet()
            ];

            for (Project_Contact__c pcc : existingContactJunction) {
                pcc.Primary__c = false;
                existingJunctionList.add(pcc);
            }

            DatabaseUtilities.upsertToDatabase(
                existingJunctionList,
                CLOSE_DATE_PROJECT_METHOD_NAME,
                CLOSE_DATE_DEV_NOTE
            );
        }

        if (!newPrimaryContactMap.isEmpty()) {
            List<Project_Contact__c> newJunctionList = new List<Project_Contact__c>();
            List<Project_Contact__c> newContactJunction = [
                SELECT Id, Project__c, Contact__c, Primary__c
                FROM Project_Contact__c
                WHERE Contact__c IN :newPrimaryContactMap.values() AND Project__c IN :newPrimaryContactMap.keySet()
            ];

            for (Project_Contact__c pcc : newContactJunction) {
                pcc.Primary__c = true;
                newJunctionList.add(pcc);
                projectIdSet.remove(pcc.Project__c);
            }

            DatabaseUtilities.upsertToDatabase(newJunctionList, CLOSE_DATE_PROJECT_METHOD_NAME, CLOSE_DATE_DEV_NOTE);
        }

        if (!inProjectList.isEmpty()) {
            List<Project_Contact__c> newContactJunctionsList = new List<Project_Contact__c>();

            for (Project__c proj : inProjectList) {
                if (projectIdSet.contains(proj.Id)) {
                    Project_Contact__c projectContactJunction = new Project_Contact__c();
                    projectContactJunction.Project__c = proj.Id;
                    projectContactJunction.Contact__c = proj.Primary_Contact__c;
                    projectContactJunction.Primary__c = true;
                    newContactJunctionsList.add(projectContactJunction);
                }
            }
            DatabaseUtilities.upsertToDatabase(
                newContactJunctionsList,
                CLOSE_DATE_PROJECT_METHOD_NAME,
                CLOSE_DATE_DEV_NOTE
            );
        }
    }

    /**
     * @description Before Updating an Project__c check if the Project__c has the Hold_Op_to_Prior_Owner__c
     * set to true and use the OldMap Owner
     * @param inProjectList List of Project__c to be Updated
     * @param inOldProjectMap The Old Project__c Map before the Update was triggered.
     */
    public static void checkKeepProjOwner(List<Project__c> inProjectList, Map<ID, Project__c> inOldProjectMap) {
        for (Project__c proj : inProjectList) {
            if (proj.Hold_Project_to_Prior_Owner__c == true) {
                proj.OwnerID = inOldProjectMap.get(proj.Id).OwnerID;
            }
        }
    }

    /**
     * @description Before Updating an Project__c check if the Project__c is now closed won
     * Update the amount on the projects that are becoming closed won
     * @param inProjectList List of Project__c to be Updated
     * @param inNewProjectMap The New Project__C Map after the Update was triggered before the database commit
     * @param inOldProjectMap The Old Project__c Map before the Update was triggered.
     */

    public static void setAmountOnCloseWon(
        List<Project__c> inProjectList,
        Map<ID, Project__c> inNewProjectMap,
        Map<ID, Project__c> inOldProjectMap
    ) {
        Set<ID> projectCloseWSet = new Set<ID>();
        for (Project__c proj : inProjectList) {
            if (proj.Stage__c == 'Closed Won' && inOldProjectMap.get(proj.id).Stage__c != 'Closed Won') {
                projectCloseWSet.add(proj.ID);
            }
        }
        AggregateResult[] projectOppAggregate = [
            SELECT Project__c, SUM(Amount) amountSum
            FROM Opportunity
            WHERE Primary__c = TRUE AND Project__c IN :projectCloseWSet
            GROUP BY Project__c
        ];

        for (AggregateResult ar : projectOppAggregate) {
            id projectID = (Id) ar.get('Project__c');
            double sumAmount = (Decimal) ar.get('amountSum');
            if (inNewProjectMap.containsKey(projectID)) {
                inNewProjectMap.get(projectID).Amount__c = sumAmount;
            }
        }
    }

    /**
     * @description If the project owner changes independently of downstream inserts downstream event
     * @param newProjectList Updated project List
     * @param oldProjectMap Old project map
     */
    public static void projectDownstream(List<Project__c> newProjectList, Map<Id, Project__c> oldProjectMap) {
        if (!EventBusBypass.isByPassed('projectDownstream')) {
            List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();

            for (Project__c a : newProjectList) {
                Project__c oldProject = oldProjectMap.get(a.Id);
                if (oldProject.OwnerId != a.OwnerId) {
                    Downstream_Event__e e = new Downstream_Event__e();
                    e.SourceId__c = a.Id;
                    e.OldOwner__c = oldProject.OwnerId;
                    e.NewOwner__c = a.OwnerId;
                    e.Object__c = 'Project';
                    downstreamEvents.add(e);
                }
            }
            EventBus.publish(downstreamEvents);
        }
    }


    /**
     * @description when a project changes stage set date to today
     * @param inProjectList List of Project__c to be Inserted/Updated
     * @param inOldProjectMap The Old Project__c Map before the Update was triggered.
     */
    public static void setCurrentStageStartDate(List<Project__c> inProjectList, Map<ID, Project__c> inOldProjectMap) {
        Date todayDate = date.today();

        //Add all closed projects to a set
        for (Project__c p : inProjectList) {

            Boolean cond = Trigger.isInsert || (Trigger.isUpdate && p.Stage__c != inOldProjectMap.get(p.Id).Stage__c);

            if ( cond ){
                p.Current_Stage_Start_Date__c = todayDate;
            }

        }
    }

}