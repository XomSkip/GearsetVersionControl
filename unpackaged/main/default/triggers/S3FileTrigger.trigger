trigger S3FileTrigger on NEILON__File__c(before insert, after insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('S3File_populateCreatedDate')) {
                S3FileHandler.populateCreatedDate(Trigger.new);
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('S3File_onAfterInsert')) {
                S3FileHandler.tagS3Files(Trigger.new);
            }
        }
    }
}