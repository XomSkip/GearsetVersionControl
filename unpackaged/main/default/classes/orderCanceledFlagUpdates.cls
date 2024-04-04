public class orderCanceledFlagUpdates implements Queueable {
    List<Opportunity> oppsToUpdateList = new List<Opportunity>();
    public orderCanceledFlagUpdates(List<Opportunity> inOpportunityList) {
        oppsToUpdateList = inOpportunityList;
    }
    //Async Update
    public void execute(QueueableContext context) {
        // Audit
        System.debug('About to start the Opportunity Updates for Order Cancellations');
        System.debug('The Opportunities to be updated are ' + oppsToUpdateList);
        DatabaseUtilities.saveToDatabase(
            oppsToUpdateList,
            'orderCanceledFlagUpdates',
            'Opportunity Updates for Cancellations'
        );

        // Opps stage has been switched, now make sure the project stage is correct
        Set<Id> cancelledOppSet = new Set<Id>();
        for (Opportunity opp : oppsToUpdateList) {
            cancelledOppSet.add(opp.Id);
        }

        // Get list of canceled Opps in CW Projects
        List<Opportunity> canceledOppsinCwProjectsList = [
            SELECT Id, Project__c, StageName
            FROM Opportunity
            WHERE Id IN :cancelledOppSet AND Project__r.Stage__c = 'Closed Won' AND StageName = 'Closed Lost'
        ];

        // Create a set of CW Project Ids for Opps that were just Canceled
        Set<Id> cwProjectsWithCanceledOppSet = new Set<Id>();
        for (Opportunity o : canceledOppsinCwProjectsList) {
            cwProjectsWithCanceledOppSet.add(o.Project__c);
        }

        List<Opportunity> otherCwOppsInProjectsWithCanceledOpp = [
            SELECT Id, Project__c
            FROM Opportunity
            WHERE
                Project__c IN :cwProjectsWithCanceledOppSet
                AND Id NOT IN :cancelledOppSet
                AND StageName = 'Closed Won'
        ];

        //Get a set of all project Ids for projects that still have a CW opp
        Set<Id> projectWithCwOppSet = new Set<Id>();
        for (Opportunity opp : otherCwOppsInProjectsWithCanceledOpp) {
            projectWithCwOppSet.add(opp.Project__c);
        }

        //If a project still has a CW Opp, the stage can remain CW. Otherwise, Project stage needs to change
        List<Project__c> needToChangeProjectStatusList = new List<Project__c>();
        Date todayDate = date.today();

        for (Opportunity opp : canceledOppsinCwProjectsList) {
            if (!projectWithCwOppSet.contains(opp.Project__c)) {
                Project__c p = new Project__c();
                p.Id = opp.Project__c;
                p.Stage__c = 'Closed Lost';
                p.Close_Date__c = todayDate;
                needToChangeProjectStatusList.add(p);
            }
        }

        System.debug('About to start the Project Updates for Order Cancelations');
        System.debug('The Projects to be updated are ' + needToChangeProjectStatusList);
        DatabaseUtilities.saveToDatabase(
            needToChangeProjectStatusList,
            'orderCanceledFlagUpdates',
            'Project Updates for Order Cancelations'
        );
    }
}