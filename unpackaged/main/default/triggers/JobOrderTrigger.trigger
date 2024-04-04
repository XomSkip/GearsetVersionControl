trigger JobOrderTrigger on Job_Order__c(before insert, after insert, after update, after delete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('CaseOppHandler_renameOnCreate')) {
                JobOrderHandler.renameOnCreate(Trigger.New);
            }
        }
    }


    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('JobOrderHandler_updateStatusRollUpOnOrder')) {
                JobOrderHandler.updateStatusRollUpOnOrder(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('JobOrderHandler_updateStatusRollUpOnOrder')) {
                JobOrderHandler.updateStatusRollUpOnOrder(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isDelete) {
            if (ApexBypassUtility.shouldRun('JobOrderHandler_updateStatusRollUpOnOrder')) {
                JobOrderHandler.updateStatusRollUpOnOrder(Trigger.old, Trigger.oldMap);
            }
        }
    }

}