public with sharing class HandlerUtil {
    /**
     * @description Convert the Lead to Opportunity Account from Quotes and Orders
     * @param convertList list of objects with leads associated for convertion
     *  convertList must not be a Lead for this function to work and Contact list must be after insert
     * @return srLeadConvertResult List of convert result
     */
    public static List<Database.LeadConvertResult> leadConverter(List<sObject> convertList) {
        List<Database.LeadConvert> leadConvertList = new List<Database.LeadConvert>();
        List<Database.LeadConvertResult> srLeadConvertResult = new List<Database.LeadConvertResult>();

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];

        Map<String, Id> leadEmailCheckSet = new Map<String, Id>();
        Map<String, Id> leadERPCheckSet = new Map<String, Id>();
        for (sObject convertObj : convertList) {
            //quote path
            if (convertObj instanceof Quote_ERP__c) {
                Quote_ERP__c q = (Quote_ERP__c) convertObj;
                if (q.Quote_Email__c != null) {
                    leadEmailCheckSet.put(q.Quote_Email__c.toLowercase(), q.Id);
                }
            }
            //contact path
            if (convertObj instanceof Contact) {
                Contact c = (Contact) convertObj;
                if (c.Primary_Email__c != null) {
                    leadEmailCheckSet.put(c.Primary_Email__c.toLowercase(), c.Id);
                }
            }
            //order path
            if (convertObj instanceof Order_Erp__c) {
                Order_Erp__c o = (Order_Erp__c) convertObj;
                if (o.LeadID__c != null && o.Xometry_ERP_ID__c != null) {
                    leadERPCheckSet.put(o.Xometry_ERP_ID__c, o.Id);
                }
            }

            //SuppliesQuote path
            if (convertObj instanceof Supplies_Quote__C) {
                Supplies_Quote__C supQuote = (Supplies_Quote__C) convertObj;
                if (supQuote.Quote_Email__c != null) {
                    leadEmailCheckSet.put(supQuote.Quote_Email__c.toLowercase(), supQuote.Id);
                }
            }

            //SuppliesQuote path
            if (convertObj instanceof Supplies_Order__C) {
                Supplies_Order__C supOrder = (Supplies_Order__C) convertObj;
                if (supOrder.Order_Email__c != null) {
                    leadEmailCheckSet.put(supOrder.Order_Email__C.toLowercase(), supOrder.Id);
                }
            }
        }

        Map<Id, Id> leadConversionMap = new Map<Id, Id>();

        //quote+contact path
        if (!leadEmailCheckSet.isEmpty()) {
            //Fetch Leads to be converted
            //Create the DB converter for Leads
            for (Lead l : [
                SELECT ID, Primary_Email__c
                FROM Lead
                WHERE isConverted = FALSE AND Primary_Email__c IN :leadEmailCheckSet.keySet()
            ]) {
                if (leadEmailCheckSet.containskey(l.Primary_Email__c)) {
                    leadConversionMap.put(leadEmailCheckSet.get(l.Primary_Email__c), l.Id);
                }
            }
        }

        //order path
        if (!leadERPCheckSet.isEmpty()) {
            for (Quote_ERP__C existingQuote : [
                SELECT Xometry_ERP_ID__C, LeadID__C
                FROM Quote_ERP__C
                WHERE Xometry_ERP_ID__C IN :leadERPCheckSet.keySet() AND LeadID__R.IsConverted = FALSE
            ]) {
                leadConversionMap.put(leadERPCheckSet.get(existingQuote.Xometry_ERP_ID__C), existingQuote.LeadID__c);
            }
        }

        Set<Id> finalLeadIdSet = new Set<Id>();
        for (sObject convertObj : convertList) {
            if (
                leadConversionMap.containsKey((Id) convertObj.get('Id')) &&
                !finalLeadIdSet.contains(leadConversionMap.get((Id) convertObj.get('Id')))
            ) {
                //database Converter
                Database.LeadConvert l_dbLeadConvert = new Database.LeadConvert();
                l_dbLeadConvert.setConvertedStatus(convertStatus.MasterLabel);
                l_dbLeadConvert.setLeadID(leadConversionMap.get((Id) convertObj.get('Id')));
                finalLeadIdSet.add(leadConversionMap.get((Id) convertObj.get('Id')));
                l_dbLeadConvert.setOwnerID((Id) convertObj.get('OwnerID'));

                if (convertObj instanceof Contact) {
                    l_dbLeadConvert.setAccountID((Id) convertObj.get('AccountId'));
                    l_dbLeadConvert.setContactID((Id) convertObj.get('Id'));
                } else {
                    l_dbLeadConvert.setAccountID((Id) convertObj.get('AccountID__c'));
                    l_dbLeadConvert.setContactID((Id) convertObj.get('ContactID__c'));
                    l_dbLeadConvert.setOpportunityId((Id) convertObj.get('OpportunityID__c'));
                }
                //One Converter Class Per Lead
                leadConvertList.add(l_dbLeadConvert);
            }
        }

        if (leadConvertList.size() > 0) {
            srLeadConvertResult = Database.convertLead(leadConvertList, false);
        }

        return srLeadConvertResult;
    }
}