global class ValidationLostClosedProjectsBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT ID, CloseDate, Order_ERP_Xom_ID__c, Project__c 
                FROM Opportunity 
                WHERE Project__c != null AND Project__r.Stage__c = 'Closed Lost' AND Stagename ='Closed Won' 
                ORDER BY Project__c, CloseDate desc
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> opportunityList) {

        Map<Id, Project__c> mapProject = new Map<Id, Project__c>();
        for(Opportunity opportunityWon : opportunityList)
        {
            if(!mapProject.containsKey(opportunityWon.Project__c))
            {
                mapProject.put(opportunityWon.Project__c, new Project__c(Id = opportunityWon.Project__c, Stage__c = 'Pending Payment'));
            }
        }
        
        DatabaseUtilities.saveToDatabase(mapProject.values(), 'ValidationLostClosedProjectsBatch', 'ValidationLostClosedProjectsBatch update Failed');
    }

    global void finish(Database.BatchableContext bc) {
    }
}