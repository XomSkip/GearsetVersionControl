public with sharing class DatabaseUtilities {
    static final String SUCCESS_LOG = 'The successful update id was: ';
    static final String ERROR_LOG = 'The following error occurred: ';
    static final String ERROR_FIELDS = 'Fields affected by that error: ';
    static final String DELETION_LOG = 'The delete id was: ';

    // TODO: Create a method in DatabaseUtilities to handle single object updates

    /**
     * @description generic function to save a list of custom objects to the database
     * @param updateList List of SObjects to be saved to the database
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     */
    public static void saveToDatabase(List<SObject> updateList, String methodCalled, String devAuditNote) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        checkMethodAndNote(methodCalled, devAuditNote);

        if (!updateList.isEmpty()) {
            Database.SaveResult[] srList = Database.update(updateList, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(SUCCESS_LOG + sr.getID());
                } else {
                    auditErrorList.addall(logErrors(sr.getId(), sr.getErrors(), methodCalled, devAuditNote));
                }
            }
            insert auditErrorList;
        }
    }

    /**
     * @description generic function to save a list of custom objects to the database
     * @param updateList List of SObjects to be saved to the database
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     * @returns audit error list
     **/
    public static List<Audit_Trail_Error__c> updateToDatabase(List<SObject> updateList, String methodCalled, String devAuditNote) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();
        checkMethodAndNote(methodCalled,devAuditNote);
        if (!updateList.isEmpty()) {
            Database.SaveResult[] srList = Database.update(updateList, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    auditErrorList.addall(logErrors(sr.getId(), sr.getErrors(), methodCalled, devAuditNote));
                }
                System.debug(SUCCESS_LOG + sr.getID());
            }
            insert auditErrorList;
        }
        return auditErrorList;
    }


    /**
     * @description generic function to save a list of custom objects to the database
     * @param updateList List of SObjects to be upserted to the database
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     */
    public static Database.UpsertResult[] upsertToDatabase(
        List<SObject> updateList,
        String methodCalled,
        String devAuditNote
    ) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        Database.UpsertResult[] srList = new List<Database.UpsertResult>();

        checkMethodAndNote(methodCalled, devAuditNote);

        if (!updateList.isEmpty()) {
            srList = Database.upsert(updateList, false);
            for (Database.UpsertResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(SUCCESS_LOG + sr.getID());
                } else {
                    System.debug('====> PROBLEM: ' + sr.getErrors());
                    auditErrorList.addall(logErrors(sr.getId(), sr.getErrors(), methodCalled, devAuditNote));
                }
            }
            insert auditErrorList;
        }

        return srList;
    }

    /**
     * @description generic function to insert a list of custom objects to the database
     * @param updateList List of SObjects to be saved to the database
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     */
    public static void insertToDatabase(List<SObject> updateList, String methodCalled, String devAuditNote) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        checkMethodAndNote(methodCalled, devAuditNote);

        if (!updateList.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(updateList, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(SUCCESS_LOG + sr.getID());
                } else {
                    auditErrorList.addall(logErrors(sr.getId(), sr.getErrors(), methodCalled, devAuditNote));
                }
            }
            //ToDo refactor this with a pass back and a final insert call
            insert auditErrorList;
        }
    }

    public static List<Audit_Trail_Error__c> insertToDatabase2(
        List<SObject> insertList,
        String methodCalled,
        String devAuditNote
    )
    {
        return DatabaseUtilities.insertToDatabase2(
            insertList,
            methodCalled,
            devAuditNote,
            new List<Audit_Trail_Error__c>());
    }

    //Apex CPU timeout speedUp which commits the Audit Error Table at the End
    public static List<Audit_Trail_Error__c> insertToDatabase2(
        List<SObject> updateList,
        String methodCalled,
        String devAuditNote,
        List<Audit_Trail_Error__c> inAuditList
    ) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        checkMethodAndNote(methodCalled, devAuditNote);

        if (!updateList.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(updateList, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(SUCCESS_LOG + sr.getID());
                } else {
                    auditErrorList.addall(logErrors(sr.getId(), sr.getErrors(), methodCalled, devAuditNote));
                }
            }
            //ToDo refactor this with a pass back and a final insert call
            if (!auditErrorList.isEmpty()) {
                inAuditList.addAll(auditErrorList);
            }
        }
        return inAuditList;
    }
    /**
     * @description generic function to save a list of custom objects to the database
     * @param updateList List of SObjects to be saved to the database
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     * @return updateTracker integer representing the number of rows that were successfully updated
     */
    public static Integer saveToDatabaseTracking(List<SObject> updateList, String methodCalled, String devAuditNote) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        Integer updateTracker = 0;

        checkMethodAndNote(methodCalled, devAuditNote);

        if (!updateList.isEmpty()) {
            Database.SaveResult[] srList = Database.update(updateList, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    updateTracker = updateTracker + 1;
                } else {
                    auditErrorList.addall(logErrors(sr.getId(), sr.getErrors(), methodCalled, devAuditNote));
                }
            }
            insert auditErrorList;
        }
        return updateTracker;
    }
    /**
     * @description generic function to delete a list of custom objects to the database
     * @param deleteList List of SObjects to be removed from the database
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     */
    public static void deleteFromDatabase(List<SObject> deleteList, String methodCalled, String devAuditNote) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        checkMethodAndNote(methodCalled, devAuditNote);

        if (!deleteList.isEmpty()) {
            Database.DeleteResult[] srList = Database.delete(deleteList, false);
            for (Database.DeleteResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(DELETION_LOG + sr.getID());
                } else {
                    auditErrorList.addall(logErrors(sr.getId(), sr.getErrors(), methodCalled, devAuditNote));
                }
            }
            insert auditErrorList;
        }
    }

    /**
     * @description generic function to convert a list of Leads
     * @param convertList List of SObjects to be converted
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     */
    public static void leadConvert(List<Database.LeadConvert> convertList, String methodCalled, String devAuditNote) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        checkMethodAndNote(methodCalled, devAuditNote);

        if (!convertList.isEmpty()) {
            Database.LeadConvertResult[] srList = Database.convertLead(convertList, false);
            for (Database.LeadConvertResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(SUCCESS_LOG + sr.getContactId());
                } else {
                    auditErrorList.addall(logErrors(sr.getLeadId(), sr.getErrors(), methodCalled, devAuditNote));
                }
            }
            insert auditErrorList;
        }
    }

    /**
     * @description generic function to log errors and insert audit error list
     * @param ErrorList List of Errors from save result
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     */

    public static List<Audit_Trail_Error__c> logErrors(
        Id sourceId,
        List<Database.Error> errors,
        String methodCalled,
        String devAuditNote
    ) {
        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

        for (Database.Error err : errors) {
            System.debug(ERROR_LOG);
            System.debug(err.getStatusCode() + ' : ' + err.getMessage());
            System.debug(ERROR_FIELDS + err.getFields());
            Audit_Trail_Error__c auditError = new Audit_Trail_Error__c();
            auditError.Module__c = methodCalled;
            auditError.SourceId__c = sourceId;
            auditError.Dev_Audit_Notes__c = devAuditNote;
            auditError.StatusCode__c = err.getStatusCode().name();
            auditError.errorMessage__c = err.getMessage().abbreviate(250);
            auditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
            auditErrorList.add(auditError);
        }
        return auditErrorList;
    }

    /**
     * @description generic function to throw Argument if method or dev note is blank
     * @param methodCalled String representation of the associated method for logging purposes
     * @param devAuditNote Useful message for developers to debug errors for log audits
     */
    public static void checkMethodAndNote(String methodCalled, String devAuditNote) {
        if (String.isBlank(methodCalled) || String.isBlank(devAuditNote)) {
            throw new IllegalArgumentException();
        }
    }
}