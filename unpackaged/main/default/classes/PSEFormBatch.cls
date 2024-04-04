global class PSEFormBatch implements Database.Batchable<sObject>, Database.Stateful {
    static final String PROJECT_BATCH_METHOD_NAME = 'ProjectBatch.execute';
    static final String PROJECT_BATCH_DEV_NOTE = 'Project Batch update';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, Quote_ID__c, Case__c
                FROM PSE_Form__c
                WHERE (Quote_ERP__c = NULL OR (Quote_ERP__c != NULL AND Case__c = NULL)) AND Quote_ID__c != NULL
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<PSE_Form__c> scope) {
        Map<String, PSE_Form__c> quoteIdToPSEFormMap = new Map<String, PSE_Form__c>();
        Map<String, PSE_Form__c> pseFormUpdateMap = new Map<String, PSE_Form__c>();

        for (PSE_Form__c f : scope) {
            quoteIdToPSEFormMap.put(f.Quote_ID__c, f);
        }

        // These quotes may or may not be in the system. They were not during initial load for the Form
        for (Quote_ERP__C q : [
            SELECT Id, Xometry_ERP_ID__c
            FROM Quote_ERP__C
            WHERE Xometry_ERP_ID__c IN :quoteIdToPSEFormMap.keySet()
        ]) {
            PSE_FORM__C lPSEForm = quoteIdToPSEFormMap.get(q.Xometry_ERP_ID__c);

            lPSEForm.Quote_ERP__c = q.Id;
            pseFormUpdateMap.put(q.Xometry_ERP_ID__c, lPSEForm);
        }

        List<Case> casesToUpdate = new List<Case>();
        for (Case c : [
            SELECT Id, PSE_Form__c, Opportunity__r.Last_Quote_Xometry_ERP_ID__c
            FROM Case
            WHERE PSE_Form__c = NULL AND Opportunity__r.Last_Quote_Xometry_ERP_ID__c IN :quoteIdToPSEFormMap.keySet()
            ORDER BY Createddate ASC
        ]) {
            PSE_FORM__C existingPSEForm = quoteIdToPSEFormMap.get(c.Opportunity__r.Last_Quote_Xometry_ERP_ID__c);
            c.PSE_Form__c = existingPSEForm.Id;
            casesToUpdate.add(c);

            if (quoteIdToPSEFormMap.get(c.Opportunity__r.Last_Quote_Xometry_ERP_ID__c).Case__c == null) {
                PSE_Form__c lPSEForm = new PSE_Form__C();
                if (pseFormUpdateMap.containsKey(c.Opportunity__r.Last_Quote_Xometry_ERP_ID__c)) {
                    lPSEForm = pseFormUpdateMap.get(c.Opportunity__r.Last_Quote_Xometry_ERP_ID__c);
                } else {
                    lPSEForm = existingPSEForm;
                }
                lPSEForm.Case__c = c.Id;
                pseFormUpdateMap.put(c.Opportunity__r.Last_Quote_Xometry_ERP_ID__c, lPSEForm);
            }
        }

        DatabaseUtilities.saveToDatabase(
            pseFormUpdateMap.values(),
            'PSEFormBatch',
            'Update PSE Form with Quote Lookup'
        );

        DatabaseUtilities.saveToDatabase(
            casesToUpdate,
            'PSEFormBatch.updateAssociatedCase',
            'Failed to update PSE lookup to Case'
        );
    }

    global void finish(Database.BatchableContext bc) {
    }
}