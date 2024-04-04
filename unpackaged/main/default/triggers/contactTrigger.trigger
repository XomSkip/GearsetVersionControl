trigger contactTrigger on Contact(before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('Contact_primaryEmailPop')) {
                ContactHandler.primaryEmailPop(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Contact_CpcLeadSource')) {
                ContactHandler.cpcLeadSource(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Contact_newSupplierUser')) {
                ContactHandler.newSupplierUser(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Contact_processContactToNewAccount')) {
                ContactHandler.processContactToNewAccount(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Contact_checkLeadSource')) {
                ContactHandler.checkLeadSource(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Contact_driftContactAccountMatching')) {
                ContactHandler.driftContactAccountMatching(Trigger.new);
            }
            if(ApexBypassUtility.shouldRun('Contact_markIfGenericContact')) {
                ContactHandler.markIfGenericContact(Trigger.new);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Contact_primaryEmailPop')) {
                ContactHandler.primaryEmailPop(Trigger.new);
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('Contact_checkForContactToConvert')) {
                ContactHandler.checkForContactToConvert(Trigger.new);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Contact_contactDownstream')) {
                ContactHandler.contactDownstream(Trigger.new, Trigger.oldMap);
            }
        }
    }
}