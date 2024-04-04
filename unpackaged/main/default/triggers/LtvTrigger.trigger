/**
 * LtvTrigger
 *  after insert: associates inserted value to a contact
 */
trigger LtvTrigger on LTV__c(before insert, after insert) {
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            LtvHandler.associateRecordType(Trigger.new);
        }
        if (Trigger.isAfter) {
            if (ApexBypassUtility.shouldRun('LTV_associateContact')) {
                LtvHandler.associateContact(Trigger.new);
            }
            LtvHandler.associateAccount(Trigger.new);
        }
    }
}