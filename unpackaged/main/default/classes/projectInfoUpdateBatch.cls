global class projectInfoUpdateBatch implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Project__c]);
    }

    global void execute(Database.BatchableContext bc, List<Project__c> projectList) {
        Map<Id, Datetime> projectOppCreatedDateMap = new Map<Id, Date>();
        Map<Id, Datetime> projectLastQuoteModDateMap = new Map<Id, Datetime>();
        Map<Id, Decimal> projectAmountMap = new Map<Id, Decimal>();

        Set<String> lstProjectsIds = new Map<String, Project__c>(projectList).keySet();

        List<Opportunity> opps = [
                SELECT Project__c, Opportunity_Create_Date__c, Last_Quote_Xometry_Create_Time__c, Primary__c, Amount
                FROM Opportunity
                WHERE Project__c IN: lstProjectsIds
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

            if(o.Primary__c && o.Amount != null)
            {
                Decimal decAmount = projectAmountMap.containsKey(o.Project__c) ? projectAmountMap.get(o.Project__c) : 0;
                decAmount += o.Amount;
                projectAmountMap.put(o.Project__c, decAmount);
            }
        }

        for (Project__c proj : projectList) {
            if (projectOppCreatedDateMap.containsKey(proj.Id)) {
                proj.Last_Opp_Created_Date__c = projectOppCreatedDateMap.get(proj.Id);
            } else {
                proj.Last_Opp_Created_Date__c = null;
            }

            if (projectLastQuoteModDateMap.containsKey(proj.Id)) {
                proj.Last_Quote_Mod_Date__c = projectLastQuoteModDateMap.get(proj.Id);
            } else {
                proj.Last_Quote_Mod_Date__c = null;
            }

            if (projectAmountMap.containsKey(proj.Id)) {
                proj.Amount__c = projectAmountMap.get(proj.Id);
            } else {
                proj.Amount__c = null;
            }
        }

        DatabaseUtilities.saveToDatabase(projectList, 'projectInfoUpdate_Batch.execute', 'Update the Last_Opp_Created_Date__c, Last_Quote_Mod_Date__c and Amount of the Projects');
    }

    global void finish(Database.BatchableContext bc) {
    }
}