/**
 * @description handler for Project updates
 */
public with sharing class PSEFormHandler {

    static List<Case> caseRelatedList;

    /**
     * @description Populates quote lookup field on PSE Form Object based on Xometry ERP ID
     * Finds existing cases for corresponding quotes and updates the Case lookup to the Form
     * @param newFormList list of Form records new values
     */
    public static void populateLookups(List<PSE_Form__c> newFormList) {
        Map<String, PSE_Form__c> quoteIdToPSEFormMap = new Map<String, PSE_Form__c>();

        for (PSE_Form__c f : newFormList) {
            // Old forms can come into the system without a Quote Id
            if (!String.isBlank(f.Quote_ID__c)) {
                quoteIdToPSEFormMap.put(f.Quote_ID__c, f);
            }
        }

        if ( !quoteIdToPSEFormMap.isEmpty() ) {

            if(caseRelatedList == null){
                caseRelatedList = [
                    SELECT Id, PSE_Form__c, Opportunity__r.Last_Quote_Xometry_ERP_ID__c
                    FROM Case
                    WHERE
                        PSE_Form__c = NULL
                        AND Opportunity__r.Last_Quote_Xometry_ERP_ID__c IN :quoteIdToPSEFormMap.keySet()
                    ORDER BY Createddate ASC
                ];
            }

            if(Trigger.isBefore){

                // Quotes should already be in the system. Otherwise, we want to populate this field
                // later via a batch job.
                for (Quote_ERP__C q : [
                    SELECT Id, Xometry_ERP_ID__c
                    FROM Quote_ERP__C
                    WHERE Xometry_ERP_ID__c IN :quoteIdToPSEFormMap.keySet()
                ]) {
                    quoteIdToPSEFormMap.get(q.Xometry_ERP_ID__c).Quote_ERP__c = q.Id;
                }

                for (Case c : caseRelatedList) {

                    if( quoteIdToPSEFormMap.get(c.Opportunity__r.Last_Quote_Xometry_ERP_ID__c).Case__c == null ){
                        quoteIdToPSEFormMap.get(c.Opportunity__r.Last_Quote_Xometry_ERP_ID__c).Case__c = c.Id;
                    }


                }

            }

            if(Trigger.isAfter){
                List<Case> caseUpdateList = new List<Case>();
                for (Case c : caseRelatedList) {

                    c.PSE_Form__c = quoteIdToPSEFormMap.get(c.Opportunity__r.Last_Quote_Xometry_ERP_ID__c).Id;
                    caseUpdateList.add(c);

                }

                DatabaseUtilities.saveToDatabase(
                    caseUpdateList,
                    'PSEFormHandler.updateAssociatedCase',
                    'Failed to update Case lookup to PSE Form'
                );

            }

        }
    }

}