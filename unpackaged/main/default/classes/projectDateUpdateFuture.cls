public inherited sharing class projectDateUpdateFuture {
    static final String PROJECT_UPDATE_METHOD_NOTE = 'projectDateUpdateFuture.updateProjectDates';
    static final String PROJECT_UPDATE_DEV_NOTE = 'Failed to update Project Objects';

    public static void updateProjectDatesNow(Set<Id> projectIdSet) {
        projectIdSet.remove(null);

        if (projectIdSet.size() > 0) {
            Map<Id, Datetime> projectOppCreatedDateMap = new Map<Id, Date>();
            Map<Id, Datetime> projectLastQuoteModDateMap = new Map<Id, Datetime>();

            // TODO: replace Last_Quote_Xometry_Create_Time__c with field indicating
            List<Opportunity> opps = [
                SELECT Project__c, Opportunity_Create_Date__c, Last_Quote_Xometry_Create_Time__c
                FROM Opportunity
                WHERE Project__c IN :projectIdSet
            ];

            for (Opportunity o : opps) {
                if (!projectOppCreatedDateMap.containsKey(o.Project__c)) {
                    projectOppCreatedDateMap.put(o.Project__c, o.Opportunity_Create_Date__c);
                } else if (projectOppCreatedDateMap.get(o.Project__c) < o.Opportunity_Create_Date__c) {
                    projectOppCreatedDateMap.put(o.Project__c, o.Opportunity_Create_Date__c);
                }

                if (!projectLastQuoteModDateMap.containsKey(o.Project__c)) {
                    projectLastQuoteModDateMap.put(o.Project__c, o.Last_Quote_Xometry_Create_Time__c);
                } else if (projectLastQuoteModDateMap.get(o.Project__c) < o.Last_Quote_Xometry_Create_Time__c) {
                    projectLastQuoteModDateMap.put(o.Project__c, o.Last_Quote_Xometry_Create_Time__c);
                }
            }

            List<Project__c> projectToUpdateList = new List<Project__c>();

            for (Id projId : projectIdSet) {
                Project__c proj = new Project__c(Id = projId);
                if (projectOppCreatedDateMap.containsKey(projId)) {
                    proj.Last_Opp_Created_Date__c = projectOppCreatedDateMap.get(projId);
                } else {
                    proj.Last_Opp_Created_Date__c = null;
                }
                if (projectLastQuoteModDateMap.containsKey(projId)) {
                    proj.Last_Quote_Mod_Date__c = projectLastQuoteModDateMap.get(projId);
                } else {
                    proj.Last_Quote_Mod_Date__c = null;
                }
                projectToUpdateList.add(proj);
            }

            DatabaseUtilities.saveToDatabase(projectToUpdateList, PROJECT_UPDATE_METHOD_NOTE, PROJECT_UPDATE_DEV_NOTE);
        }
    }

    @future
    public static void updateProjectDatesFuture(Set<Id> projectIdSet) {
        updateProjectDatesNow(projectIdSet);
    }

    public static void updateProjectDates(Set<Id> projectIdSet) {
        if (!System.isFuture() && !System.isBatch() && !System.isQueueable()) {
            updateProjectDatesFuture(projectIdSet);
        } else {
            updateProjectDatesNow(projectIdSet);
        }
    }
}