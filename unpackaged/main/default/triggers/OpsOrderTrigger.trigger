trigger OpsOrderTrigger on Ops_Order__c(before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('Ops_Order_associateOpportunity')) {
                OpsOrderHandler.associateOpportunity(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('OpsOrderHandler_stampOpsOrder')) {
                OpsOrderHandler.stampOpsOrder(Trigger.new, null);
            }
            if (ApexBypassUtility.shouldRun('Order_setOverdueFlag')) {
                OpsOrderHandler.setOverdueFlag(Trigger.New, Trigger.oldMap);
            }
            OpsOrderHandler.setLargeOrderStatus(Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('OpsOrderHandler_stampOpsOrder')) {
                OpsOrderHandler.stampOpsOrder(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Order_setOverdueFlag')) {
                OpsOrderHandler.setOverdueFlag(Trigger.New, Trigger.oldMap);
            }
            OpsOrderHandler.setLargeOrderStatus(Trigger.new, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('Ops_Order_createPendingDFMCase')) {
                OpsOrderHandler.createPendingDFMCase(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Ops_Order_createCaseOpsOrderJunction')) {
                OpsOrderHandler.createCaseOpsOrderJunction(Trigger.new, null);
            }
            if (ApexBypassUtility.shouldRun('Ops_Order_updateJobTechReviewStatus')) {
                OpsOrderHandler.updateJobTechReviewStatus(Trigger.new, null);
            }
            if (ApexBypassUtility.shouldRun('Ops_Order_orderEventConditionals')) {
                OpsOrderHandler.orderEventConditionals(Trigger.new, null);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Ops_Order_createPendingDFMCase')) {
                OpsOrderHandler.createPendingDFMCase(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Ops_Order_createCaseOpsOrderJunction')) {
                OpsOrderHandler.createCaseOpsOrderJunction(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Ops_Order_updateJobTechReviewStatus')) {
                OpsOrderHandler.updateJobTechReviewStatus(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Ops_Order_orderEventConditionals')) {
                OpsOrderHandler.orderEventConditionals(Trigger.new, Trigger.oldMap);
            }
        }
    }
}