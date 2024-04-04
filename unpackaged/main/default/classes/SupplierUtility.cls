public with sharing class SupplierUtility {
    /**
     * @description creates a map of Suppliers from an id set
     * @param partnerIdSet set of Partner Id's
     * @return existingSupplierMap map of orders with primary email as key
     */
    public static Map<String, Supplier__c> fetchSuppliers(Set<String> partnerIdSet) {
        Map<String, Supplier__c> existingSupplierMap = new Map<String, Supplier__c>();
        if (!partnerIdSet.isEmpty()) {
            for (Supplier__c s : [
                SELECT
                    ID,
                    AccountId__c,
                    PartnerID__c,
                    AccountId__r.OwnerId,
                    AccountId__r.Email_Domain__C,
                    AccountId__r.Generic_Account__C,
                    AccountId__r.Physical_Zip_Code__c,
                    P21_Account_Details__c,
                    P21_Account_Details__r.OwnerID,
                    ZipCode__c,
                    Sup_Owner_Stamp__c
                FROM Supplier__c
                WHERE PartnerID__c IN :partnerIdSet AND AccountId__c != NULL
            ]) {
                existingSupplierMap.put(s.PartnerId__c, s);
            }
        }
        return existingSupplierMap;
    }

    /**
     * @description creates a map of Suppliers from an id set
     * @param partnerIdSet set of Salesforce IDs
     * @return existingSupplierMap map of orders with SF ID as the key
     */
    public static Map<ID, Supplier__c> fetchSuppliersbySFID(Set<ID> supIdSet) {
        Map<ID, Supplier__c> existingSupplierMap = new Map<ID, Supplier__c>();
        if (!supIdSet.isEmpty()) {
            for (Supplier__c s : [
                SELECT
                    ID,
                    AccountId__c,
                    PartnerID__c,
                    AccountId__r.OwnerId,
                    AccountId__r.Email_Domain__C,
                    AccountId__r.Generic_Account__C,
                    AccountId__r.Physical_Zip_Code__c,
                    P21_Account_Details__c,
                    P21_Account_Details__r.OwnerID,
                    ZipCode__c,
                    Sup_Owner_Stamp__c
                FROM Supplier__c
                WHERE ID IN :supIdSet AND AccountId__c != NULL
            ]) {
                existingSupplierMap.put(s.ID, s);
            }
        }
        return existingSupplierMap;
    }
}