trigger EmailMessageTrigger on EmailMessage(after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('EmailMessage_associateObjectsToEmailCases')) {
                EmailMessageHandler.associateObjectsToEmailCases(Trigger.newMap);
            }
            if (ApexBypassUtility.shouldRun('EmailMessage_updateCases')) {
                EmailMessageHandler.updateCases(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('EmailMessage_detectAutoReply')) {
                EmailMessageHandler.detectAutoReply(Trigger.new);
            }
        }
    }
}