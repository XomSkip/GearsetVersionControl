trigger ProjectContactTrigger on Project_Contact__c(before insert, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ProjectContactHandler.validateContactRole(Trigger.new);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ProjectContactHandler.insertNewPrimaryJunction(Trigger.new);
        }
        if (Trigger.isUpdate) {
            ProjectContactHandler.updatePrimaryContact(Trigger.new);
        }
    }
}