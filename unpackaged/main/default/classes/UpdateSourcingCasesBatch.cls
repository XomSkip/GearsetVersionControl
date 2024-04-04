global class UpdateSourcingCasesBatch implements Database.Batchable<sObject> {
    public Datetime startDate;

    global UpdateSourcingCasesBatch() {
        startDate = Date.today().addDays(-1);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {

        Id caseSourcingRTypeId = AppConstants.caseSourcingRTypeId;

        String query = ' SELECT Id, Job__c, PreviousJobsList__c FROM Case WHERE RecordTypeID = :caseSourcingRTypeId AND LastModifiedDate >= :startDate ORDER BY LastModifiedDate ASC';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<Case> scope) {
        
        Map<String, List<Case>> jobXomIdCaseMap = new Map<String, List<Case>>();

        for (Case oneCase : scope) {

            if( !String.isBlank(oneCase.PreviousJobsList__c) ){

                List<String> prevJobsList = oneCase.PreviousJobsList__c.split(', ');

                if( !prevJobsList.isEmpty() ){
                    String lastJobXomId = prevJobsList.get( prevJobsList.size() - 1 );
                    if( !jobXomIdCaseMap.containsKey(lastJobXomId) ){
                        jobXomIdCaseMap.put( lastJobXomId, new List<Case>() );
                    }
                    jobXomIdCaseMap.get( lastJobXomId ).add( oneCase );
                }

            }

        }

        List<Case> casesToUpdate = new List<Case>();
        for (Job__c oneJob : [
            SELECT Id, XometryJobID__c
            FROM Job__c
            WHERE XometryJobID__c IN :jobXomIdCaseMap.keySet()
        ]) {

            for( Case oneCase : jobXomIdCaseMap.get( oneJob.XometryJobID__c ) ){
                if( oneCase.Job__c != oneJob.Id ){
                    oneCase.Job__c = oneJob.Id;
                    casesToUpdate.add(oneCase);
                }
            }

        }

        if (!casesToUpdate.isEmpty()) {
            DatabaseUtilities.saveToDatabase(
                casesToUpdate,
                'UpdateSourcingCasesBatch.execute',
                'Updating sourcing cases with latest Job ID from PreviousJobsList__c'
            );
        }

    }

    global void finish(Database.BatchableContext BC) {

    }
}