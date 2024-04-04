public with sharing class UpdateJobReviewStatus implements Queueable {
    Map<Id, Ops_Order__c> newLargeOrdersMap = new Map<Id, Ops_Order__c>();
    public UpdateJobReviewStatus(Map<Id, Ops_Order__c> inNewLargeOrdersMap) {
        newLargeOrdersMap = inNewLargeOrdersMap;
    }
    public void execute(QueueableContext context) {
        System.debug('In Queuable execute');
        if (!newLargeOrdersMap.isEmpty()) {
            List<Job__c> jobsToUpdate = new List<Job__c>();
            for (Job_Order__c jobOrd : [
                SELECT Id, Job__c, Job__r.Technical_Review_Status__c
                FROM Job_Order__c
                WHERE
                    Ops_Order__c IN :newLargeOrdersMap.keySet()
                    AND Job__r.RiskFactor__c = 'High'
                    AND Job__r.Technical_Review_Status__c = 'No Technical Review Required'
                    AND Job__r.Stage__c NOT IN :AppConstants.jobClosedStringSet
            ]) {
                Job__c thisJob = new Job__c(
                    Id = jobOrd.Job__c,
                    Technical_Review_Status__c = 'Pending Technical Review'
                );
                jobsToUpdate.add(thisJob);
            }
            if (!jobsToUpdate.isEmpty()) {
                DatabaseUtilities.saveToDatabase(
                    jobsToUpdate,
                    'OpsOrderHandler.updateJobTechReviewStatus',
                    'Updating Job Tech Review Status'
                );
            }
        }
    }
}