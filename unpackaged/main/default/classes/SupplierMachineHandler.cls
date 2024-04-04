public with sharing class SupplierMachineHandler {
    /**
     * @description associates Supplier Machines to Suppliers
     * @param newSupplierMachinesList
     */
    public static void associateSupplier(List<Supplier_Machine__c> newSupplierMachinesList) {
        Set<String> supplierIdSet = new Set<String>();
        for (Supplier_Machine__c mach : newSupplierMachinesList) {
            if (!String.isBlank(mach.PartnerID__c))
                supplierIdSet.add(mach.PartnerID__c);
        }

        if (!supplierIdSet.isEmpty()) {
            Map<String, Id> supplierIdToMachineMap = new Map<String, Id>();
            for (Supplier__c sup : [SELECT Id, PartnerID__c FROM Supplier__c WHERE PartnerID__c IN :supplierIdSet]) {
                supplierIdToMachineMap.put(sup.PartnerID__c, sup.Id);
            }

            for (Supplier_Machine__C mach : newSupplierMachinesList) {
                if (supplierIdToMachineMap.keySet().contains(mach.PartnerID__c)) {
                    mach.Supplier__c = supplierIdToMachineMap.get(mach.PartnerID__c);
                }
            }
        }
    }
}