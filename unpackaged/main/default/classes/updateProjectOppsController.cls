public with sharing class updateProjectOppsController {
    static final String DELETION_LOG = 'The delete id was: ';
    static final String ERROR_LOG = 'The following error occurred: ';
    static final String ERROR_FIELDS = 'Fields affected by that error: ';
    static final String UPDATE_OPP_DEV_NOTE = 'Opportunity Updates reassigning Projects';
    static final String UPDATE_OPP_METHOD_NAME = 'UpdateProjectOppsController.updateOpps';

    /**
     * @description method to fetch all open opportunities
     * @param projectId id of project to get the opportunities for
     * @return List of non-Closed opportunity objects
     */
    @AuraEnabled
    public static List<Opportunity> getOppList(Id projectId) {
        return [
            SELECT Id, Name, Project__c, Primary__c, StageName, RecordTypeId
            FROM Opportunity
            WHERE Project__c = :projectId AND StageName NOT IN ('Closed Won', 'Closed Lost')
        ];
    }

    /**
     * @description method to change opportunity field values
     * @param projectId id of project
     * @param oppIds List of Opportunity ids
     * @return String indicating status of changed opps
     */
    @AuraEnabled
    public static string updateOpps(List<Id> oppIds) {
        try {
            // Set<Opportunity> updatedOppSet = new Set<Opportunity>();

            List<Opportunity> updatedOppsList = [SELECT Id, Primary__c FROM Opportunity WHERE Id IN :oppIds];

            for (Opportunity opp : updatedOppsList) {
                if (opp.Primary__c == true) {
                    opp.Primary__c = false;
                } else {
                    opp.Primary__c = true;
                }
            }

            DatabaseUtilities.saveToDatabase(updatedOppsList, UPDATE_OPP_METHOD_NAME, UPDATE_OPP_DEV_NOTE);
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}