/**
 * Batch job to backfill the old cases with the businesshour
 */
global class OpsOrderPopulateBusinessHoursBatch implements Database.Batchable<sObject> {
    public String query = 'SELECT Id FROM Ops_Order__c WHERE Is_Large_Order__c = TRUE';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Ops_Order__c> scope) {

        Set<Id> opsIds = new Set<Id>();
        for(Ops_Order__c ops : scope){
            opsIds.add(ops.Id);
        }

        Map<String, BusinessHours> hoursMap = new Map<String, BusinessHours>();
        for (BusinessHours bHours : [SELECT Id, Name FROM BusinessHours]) {
            hoursMap.put(bHours.Name, bHours);
        }

        List<Case> casesToUpdate = new List<Case>();
        for(Case oneCase : [SELECT Id FROM Case WHERE GNOOrder__c IN :opsIds AND Type IN ('Technical Review', 'Large Order Review', 'Large Order Approval')]){
            oneCase.BusinessHoursId = hoursMap.get('POD Business Hours - EST').Id;
            casesToUpdate.add(oneCase);
        }

        DatabaseUtilities.saveToDatabase(casesToUpdate, 'OpsOrderPopulateBusinessHoursBatch', 'Case populate Business Hours');

    }

    global void finish(Database.BatchableContext BC) {

    }
}