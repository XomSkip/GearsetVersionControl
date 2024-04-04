trigger JobOrderedPartTrigger on JobOrderedPart__c(before insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            JobOrderedPartHandler.renameOnCreate(Trigger.New);
        }
    }
    if (Trigger.isAfter) {
        largeOrderHelper.setLargeOrderbyPass(largeOrderHelper.ordPartByPass);
        if (Trigger.isInsert) {
            JobOrderedPartHandler.checkJobOrderedPartsForLargeOrderSummary(Trigger.New);
        }
    }
}