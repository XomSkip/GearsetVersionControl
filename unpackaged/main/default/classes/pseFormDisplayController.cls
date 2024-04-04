public with sharing class pseFormDisplayController {
    public class PSEFormFoundResult {
        @AuraEnabled
        public List<String> pseFormFieldNames { get;set; }
        
        @AuraEnabled
        public Id pseFormId { get;set; }

        public PSEFormFoundResult(List<String> pseFormFieldNames, Id pseFormId) {
            this.pseFormFieldNames = pseFormFieldNames;
            this.pseFormId = pseFormId;
        }
    }
    
    @AuraEnabled
    public static PSEFormFoundResult getPSEQuestionsForCaseId(Id caseId) {
        
        List<String> pseFormDashboardFieldNames = PSEFormFieldMapper.getAllPSEFormDashboardFieldNames();
        
        List<PSE_Form__c> pseFormCheck = Database.query(
            'SELECT Id, ' +
            String.join(pseFormDashboardFieldNames, ', ') +
            ' FROM PSE_Form__c where Case__c=:caseId LIMIT 1'
        );

        if (pseFormCheck.isEmpty()) {
            return null;
        }

        PSE_Form__c pseForm = pseFormCheck[0];

        List<String> populatedPseFormFieldNames = new List<String>{};
        
        for (String fieldName : pseFormDashboardFieldNames) {
            Object value = pseForm.get(fieldName);

            if (value != null) {
                populatedPseFormFieldNames.add(fieldName);
            }
        }

        return new PSEFormFoundResult(
            populatedPseFormFieldNames, pseForm.Id
        );
    }
}