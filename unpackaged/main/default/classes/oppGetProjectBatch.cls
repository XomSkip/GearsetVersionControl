public class oppGetProjectBatch implements Database.Batchable<sObject>, Database.Stateful {
    static final ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    public Integer recordsProcessed = 0;
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID FROM OPPORTUNITY WHERE RecordTypeId = \'' +
            oppManufacturingServRTypeID +
            '\' and Primary_Contact__c != null ' +
            ' and Project__C = null and createdDate > 2022-01-01T00:00:00.000+0000'
        );
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        Set<ID> oppNeedProjectIDSet = new Set<ID>();
        for (Opportunity opp : scope) {
            oppNeedProjectIDSet.add(opp.ID);
        }
        OpportunityHandler.associateToProjectAdHoc(oppNeedProjectIDSet);
        recordsProcessed += oppNeedProjectIDSet.size();
    }
    public void finish(Database.BatchableContext bc) {
        System.debug(recordsProcessed + ' records processed. Giving Opps Projects!');
    }
}