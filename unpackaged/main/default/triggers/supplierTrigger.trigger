trigger supplierTrigger on Supplier__c(before insert, after insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            SupplierHandler.processSuppliers(Trigger.new);
        }
        if (Trigger.isUpdate) {
            SupplierHandler.updateActivityStatus(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('Supplier_onboardingParentCaseCreation')) {
                SupplierHandler.onboardingParentCaseCreation(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Supplier_updateContactWithSupplierId')) {
                SupplierHandler.updateContactWithSupplierId(Trigger.new);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Supplier_updateObjectsFromSupplierChanges')) {
                SupplierHandler.updateObjectsFromSupplierChanges(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Supplier_keepSPOCInSync')) {
                SupplierHandler.keepSPOCInSync(Trigger.new, Trigger.oldMap);
            }
        }
    }
}