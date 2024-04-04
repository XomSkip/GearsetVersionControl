/**
 *   @description Close the Project when:
 *     All Opps on the Project are closed (CW OR CL)
 *     && Project Created Date > 5 days ago
 *     Project was created by Automation (by created by user)
 *      OR
 *     ALL of the following are true:
 *     The Primary Contact on the Project has no open future tasks
 *     The Primary Contact on the Project has not been contacted in more than X days
 *     All of the Opportunities on the Project are older than X days
 *     None of the Opportunities have been updated from the ERP in more than X days
 **/

global class ProjectAutoCloseNoFutureTaskBatch implements Database.Batchable<sObject>, Database.Stateful {
    static final String BATCH_METHOD_NAME = 'ProjectAutoCloseNoFutureTaskBatch.execute';

    Date dateSinceLastActivity;
    Date dateSinceLastQuote;
    Date dateSinceLastOpp;
    Date dateSinceCreatedProject = Date.newInstance(1, 1, 1);

    Date dateSinceLastActivityNew = Date.newInstance(1, 1, 1);
    Date dateSinceLastQuoteNew = Date.newInstance(1, 1, 1);
    Date dateSinceLastOppNew = Date.newInstance(1, 1, 1);

    Date dateSinceLastActivityRevision = Date.newInstance(1, 1, 1);
    Date dateSinceLastQuoteRevision = Date.newInstance(1, 1, 1);
    Date dateSinceLastOppRevision = Date.newInstance(1, 1, 1);

    String batchQuery = ' SELECT Id, Stage__c, CreatedDate, CreatedById, Last_Opp_Created_Date__c, Last_Quote_Mod_Date__c, Primary_Contact_LAD__c, Primary_Contact__r.Outreach_Actively_Being_Sequenced__c FROM Project__c ';

    public ProjectAutoCloseNoFutureTaskBatch() {
        //storing metadata and date calculations in local vars
        for (Admin_Ref_Variable__mdt adminRefVarValue : [
            SELECT Text_Ref_Var__c, Name__c
            FROM Admin_Ref_Variable__mdt
            WHERE Name__c LIKE 'ProjectAutoCloseNoFutureTaskBatch%'
        ]) {
            Integer rangeInDays = Integer.valueOf(adminRefVarValue.Text_Ref_Var__c) * -1;
            Date dateSince = System.today().addDays(rangeInDays);

            if (adminRefVarValue.Name__c.contains('ProjectAutoCloseNoFutureTaskBatchLastAct') ) {
                if(dateSinceLastActivity == null || dateSince > dateSinceLastActivity){
                    dateSinceLastActivity = dateSince;
                }
                if(adminRefVarValue.Name__c.endsWith('New')){
                    dateSinceLastActivityNew = dateSince;
                }
                if(adminRefVarValue.Name__c.endsWith('Revision')){
                    dateSinceLastActivityRevision = dateSince;
                }
            }
            if (adminRefVarValue.Name__c.contains('ProjectAutoCloseNoFutureTaskBatchLastQuote') ) {
                if(dateSinceLastQuote == null || dateSince > dateSinceLastQuote){
                    dateSinceLastQuote = dateSince;
                }
                if(adminRefVarValue.Name__c.endsWith('New')){
                    dateSinceLastQuoteNew = dateSince;
                }
                if(adminRefVarValue.Name__c.endsWith('Revision')){
                    dateSinceLastQuoteRevision = dateSince;
                }
            }
            if (adminRefVarValue.Name__c.contains('ProjectAutoCloseNoFutureTaskBatchLastOpp') ) {
                if(dateSinceLastOpp == null || dateSince > dateSinceLastOpp){
                    dateSinceLastOpp = dateSince;
                }
                if(adminRefVarValue.Name__c.endsWith('New')){
                    dateSinceLastOppNew = dateSince;
                }
                if(adminRefVarValue.Name__c.endsWith('Revision')){
                    dateSinceLastOppRevision = dateSince;
                }
            }

            if (adminRefVarValue.Name__c == 'ProjectAutoCloseNoFutureTaskBatchLastProject') {
                dateSinceCreatedProject = dateSince;
            }

        }

    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        /**
         * Filling where clauses using metadata admin variables
         */

        //base conditions for all criterias
        String stageConditions = 'Stage__c = \'New\' OR Stage__c = \'System Reopened\' OR Stage__c = \'Initial Engagement\'';
        stageConditions += 'OR Stage__c = \'Negotiation / Revision\' OR Stage__c = \'Pending Payment\'';

        batchQuery += ' WHERE ( (' + stageConditions + ') AND CreatedById = \'' + AppConstants.API_USER + '\')';

        //#Criteria 1
        batchQuery += ' AND ( CreatedDate < :dateSinceCreatedProject ';

        // Criteria #2
        batchQuery += ' OR (';
        batchQuery += '   Primary_Contact__r.Outreach_Actively_Being_Sequenced__c = FALSE ';
        batchQuery += '   AND Primary_Contact_LAD__c < :dateSinceLastActivity ';
        batchQuery += '   AND Last_Opp_Created_Date__c < :dateSinceLastQuote ';
        batchQuery += '   AND Last_Quote_Mod_Date__c < :dateSinceLastOpp ';
        batchQuery += ' ) )';

        return Database.getQueryLocator(batchQuery);
    }

    global void execute(Database.BatchableContext BC, List<Project__c> projectList) {
        Set<Id> projectsOpen = new Set<Id>();
        Set<Id> projectsWithCW = new Set<Id>();
        Set<Id> projectsWithOpps = new Set<Id>();
        Map<Id, Project__c> closeProjectsMap = new Map<Id, Project__c>();

        Map<Id, Project__c> projectsMap = new Map<Id, Project__c>(projectList);

        //checking opportunity status and maping Project Details
        for (Opportunity opp : [
            SELECT StageName, Project__c
            FROM Opportunity
            WHERE Project__c IN :projectsMap.keySet()
        ]) {
            projectsWithOpps.add(opp.Project__c);

            if (opp.StageName == 'Closed Won') {
                projectsWithCW.add(opp.Project__c);
            }

            // Criteria #1
            if (projectsMap.get(opp.Project__c).CreatedDate < dateSinceCreatedProject) {
                //for Projects created before dateSinceCreatedProject check if all Opps are closed.
                if (opp.StageName != 'Closed Lost' && opp.StageName != 'Closed Won') {
                    projectsOpen.add(opp.Project__c);
                    closeProjectsMap.remove(opp.Project__c);
                }

                if (!projectsOpen.contains(opp.Project__c)) {
                    closeProjectsMap.put(opp.Project__c, projectsMap.get(opp.Project__c));
                }
            }
        }

        for (Project__c project : projectList) {
            projectsMap.put(project.Id, project);

            // Criteria #2 
            //Stage of ‘New’, ‘System Reopened’, or “Initial Engagement’,
            if ( 
                (
                    project.Stage__c == 'New' ||
                    project.Stage__c == 'System Reopened' ||
                    project.Stage__c == 'Initial Engagement'
                ) &&
                project.Primary_Contact_LAD__c < dateSinceLastActivityNew &&
                project.Last_Opp_Created_Date__c < dateSinceLastQuoteNew &&
                project.Last_Quote_Mod_Date__c < dateSinceLastOppNew &&
                project.Primary_Contact__r.Outreach_Actively_Being_Sequenced__c == FALSE
            ) {
                closeProjectsMap.put(project.Id, project);
            }

            // Criteria #2
            // Stage of ‘Negotiation/Revision or ‘Pending Payment’
            if (
                (
                    project.Stage__c == 'Negotiation / Revision' ||
                    project.Stage__c == 'Pending Payment'
                ) && 
                project.Primary_Contact_LAD__c < dateSinceLastActivityRevision && 
                project.Last_Opp_Created_Date__c < dateSinceLastQuoteRevision && 
                project.Last_Quote_Mod_Date__c < dateSinceLastOppRevision &&
                project.Primary_Contact__r.Outreach_Actively_Being_Sequenced__c == FALSE
            ) {
                closeProjectsMap.put(project.Id, project);
            }

            // Criteria #3 Empty Projects
            if (!projectsWithOpps.contains(project.Id)) {
                closeProjectsMap.put(project.Id, project);
            }
        }

        List<Project__c> projectsToClose = new List<Project__c>();
        for (Project__c project : closeProjectsMap.values()) {
            project.Stage__c = 'Closed Won';
            if (!projectsWithCW.contains(project.Id)) {
                project.Stage__c = 'Closed Lost';
                project.Sub_Stage__c = 'Auto-Closed';
                project.Closed_Lost_Reason__c = 'Auto-closed due to inactivity';
            }
            projectsToClose.add(project);
        }

        DatabaseUtilities.saveToDatabase(projectsToClose, BATCH_METHOD_NAME, 'Project Close No Future Batch update');
    }

    global void finish(Database.BatchableContext BC) {
    }
}