trigger OrderedPartTrigger on Ordered_Part__c(before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            orderedPartHandler.processOrderedParts(Trigger.new);
            orderedPartHandler.updateOrderedParts(Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            orderedPartHandler.updateOrderedParts(Trigger.new, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        //largeOrderHelper.setLargeOrderbyPass(largeOrderHelper.ordPartByPass);
        if (Trigger.isInsert) {
            orderedPartHandler.orderedPartEventConditionals(Trigger.new, null);
            if (ApexBypassUtility.shouldRun('OrderedPart_fillProductTypes')) {
                orderedPartHandler.fillProductTypes(Trigger.New);
            }
        }
        if (Trigger.isUpdate) {
            orderedPartHandler.orderedPartEventConditionals(Trigger.new, Trigger.oldMap);
            //orderedPartHandler.checkOrderedPartsForLargeOrderSummary(Trigger.New);
        }
    }
}