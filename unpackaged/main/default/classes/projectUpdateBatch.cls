/**
 * Async Queueable class update projects on opp change
 */
public class projectUpdateBatch implements Queueable {
    static final String ERROR_FIELDS = 'Fields affected by that error: ';
    static final String ERROR_LOG = 'The following error occurred: ';
    static final String NULL_PARAM_ERROR = 'Method Called or Dev Audit Note is null.';
    static final String SUCCESS_LOG = 'The succesful update id was: ';

    static final String PROJECT_UPDATE_METHOD_NOTE = 'Updating Project Opp Created Date and Last Quote Mod Date';
    static final String PROJECT_UPDATE_DEV_NOTE = 'Failed to update Project Objects';

    Set<Id> projectIdSet = new Set<Id>();
    Map<Id, Datetime> projectOppCreatedDateMap = new Map<Id, Date>();
    Map<Id, Datetime> projectLastQuoteModDateMap = new Map<Id, Datetime>();

    public projectUpdateBatch(Set<Id> opportunityIdSet) {
        // TODO: replace Last_Quote_Xometry_Create_Time__c
        List<Opportunity> opps = [
            SELECT Project__c, Opportunity_Create_Date__c, Last_Quote_Xometry_Create_Time__c
            FROM Opportunity
            WHERE Id IN :opportunityIdSet
        ];

        for (Opportunity o : opps) {
            projectIdSet.add(o.Project__c);

            if (!projectOppCreatedDateMap.containsKey(o.Project__c)) {
                projectOppCreatedDateMap.put(o.Project__c, o.Opportunity_Create_Date__c);
            } else if (projectOppCreatedDateMap.get(o.Project__c) < o.Opportunity_Create_Date__c) {
                projectOppCreatedDateMap.remove(o.Project__c);
                projectOppCreatedDateMap.put(o.Project__c, o.Opportunity_Create_Date__c);
            }

            if (!projectLastQuoteModDateMap.containsKey(o.Project__c)) {
                projectLastQuoteModDateMap.put(o.Project__c, o.Last_Quote_Xometry_Create_Time__c);
            } else if (projectLastQuoteModDateMap.get(o.Project__c) < o.Last_Quote_Xometry_Create_Time__c) {
                projectLastQuoteModDateMap.remove(o.Project__c);
                projectLastQuoteModDateMap.put(o.Project__c, o.Last_Quote_Xometry_Create_Time__c);
            }
        }
    }

    public void execute(QueueableContext context) {
        List<Project__c> projectToUpdateList = [
            SELECT Id, Last_Opp_Created_Date__c, Last_Quote_Mod_Date__c
            FROM Project__c
            WHERE Id IN :projectIdSet
        ];

        for (Project__c proj : projectToUpdateList) {
            // Optional Chaining can't come soon enough
            // We can replace these with projectOppCreatedDateMap.get(proj.Id)?.Last_Opp_Created_Date__c
            if (projectOppCreatedDateMap.containsKey(proj.Id)) {
                proj.Last_Opp_Created_Date__c = projectOppCreatedDateMap.get(proj.Id);
            }
            if (projectLastQuoteModDateMap.containsKey(proj.Id)) {
                proj.Last_Quote_Mod_Date__c = projectLastQuoteModDateMap.get(proj.Id);
            }
        }

        saveToDatabase(projectToUpdateList, PROJECT_UPDATE_METHOD_NOTE, PROJECT_UPDATE_DEV_NOTE);
    }

    /**
     * @description generic function to save a list of custom objects to the database
     * @param updateList List of SObjects to be saved to the database
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     */
    public static void saveToDatabase(List<SObject> updateList, String methodCalled, String devAuditNote) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        // This has limited functionality as part of this handler class, as it is called by constants.
        // But this would be useful if abstracted to a standalone Database helper class.
        if (String.isBlank(methodCalled) || String.isBlank(devAuditNote)) {
            throw new IllegalArgumentException();
        }

        if (!updateList.isEmpty()) {
            Database.SaveResult[] srList = Database.update(updateList, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(SUCCESS_LOG + sr.getID());
                } else {
                    // Log errors
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(ERROR_LOG);
                        System.debug(err.getStatusCode() + ' : ' + err.getMessage());
                        System.debug(ERROR_FIELDS + err.getFields());
                        Audit_Trail_Error__c auditError = new Audit_Trail_Error__c();
                        auditError.Module__c = methodCalled;
                        auditError.Dev_Audit_Notes__c = devAuditNote;
                        auditError.StatusCode__c = err.getStatusCode().name();
                        auditError.errorMessage__c = err.getMessage().abbreviate(250);
                        auditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
                        auditErrorList.add(auditError);
                    }
                }
            }
        }

        insert auditErrorList;
    }
}