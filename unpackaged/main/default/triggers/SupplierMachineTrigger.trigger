trigger SupplierMachineTrigger on Supplier_Machine__c(before insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            SupplierMachineHandler.associateSupplier(Trigger.new);
        }
    }
}