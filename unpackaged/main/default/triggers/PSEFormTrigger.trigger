trigger PSEFormTrigger on PSE_Form__c(before insert, after insert) {
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            PSEFormHandler.populateLookups(Trigger.new);
        }

        if (Trigger.isAfter) {
            PSEFormHandler.populateLookups(Trigger.new);
        }
    }
}