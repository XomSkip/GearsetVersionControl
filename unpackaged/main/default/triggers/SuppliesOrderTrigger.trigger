trigger SuppliesOrderTrigger on Supplies_Order__C(before insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            SuppliesOrderHandler.processSuppliesOrders(Trigger.new);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            SuppliesOrderHandler.updateOpps(Trigger.new, Trigger.oldMap);
        }
    }
}