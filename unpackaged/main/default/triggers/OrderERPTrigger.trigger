trigger OrderERPTrigger on Order_ERP__C(before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('OrderERP_LOBToRecordTypes')) {
                OrderERPHandler.LOBToRecordTypes(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('OrderERP_processERPOrders2')) {
                OrderERPHandler.processERPOrders2(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('OrderERP_reassignWestCoast')) {
                OrderERPHandler.reassignWestCoast(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('OrderERP_upsertOpsOrder')) {
                OrderERPHandler.upsertOpsOrder(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('OrderERP_checkForMissingEUD')) {
                OrderERPHandler.checkForMissingEUD(Trigger.new);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('QuoteERP_updateOpsOrder')) {
                OrderERPHandler.updateOpsOrder(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('OrderERP_updateEUDCase')) {
                OrderERPHandler.updateEUDCase(Trigger.new, Trigger.oldMap);
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('OrderERP_OrderToQuoteCleanUp')) {
                OrderERPHandler.OrderToQuoteCleanUp(Trigger.new);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('OrderERP_orderCanceledChange')) {
                OrderERPHandler.orderCanceledChange(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('OrderERP_updateOpp')) {
                OrderERPHandler.updateOpp(Trigger.new, Trigger.oldMap);
            }
        }
        OrderERPHandler.setupQueueJobs(Trigger.new, 'trigger');
    }
}