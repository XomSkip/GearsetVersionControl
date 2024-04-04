trigger CaseOpsOrderTrigger on CaseOpsOrder__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('CaseOrders_renameOnCreate')) {
                CaseOpsOrderHandler.renameOnCreate(Trigger.New);
            }
        }
    }
}