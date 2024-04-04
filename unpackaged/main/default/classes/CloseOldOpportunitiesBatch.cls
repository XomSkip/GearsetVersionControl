global with sharing class CloseOldOpportunitiesBatch implements Database.Batchable<sObject>
{
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Id rtOppSupplies = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Supplies').getRecordTypeId();
        Datetime dtLast60Days = System.now().addDays(-60);
        return Database.getQueryLocator(
            [
                SELECT Id FROM Opportunity WHERE StageName = 'New' AND Sup_Source_Category__c != 'SFP' AND RecordTypeId = :rtOppSupplies AND CreatedDate < :dtLast60Days
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> opportunityList) {
        for(Opportunity opportunityObj : opportunityList)
        {
            opportunityObj.StageName = 'Closed Lost';
        }

        update opportunityList;
    }

    global void finish(Database.BatchableContext bc) {
    }
}