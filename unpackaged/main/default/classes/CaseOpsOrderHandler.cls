public with sharing class CaseOpsOrderHandler {
    /**
     * @description changes the Name in the junction record to a more readeable identifier
     * @param newCaseOpsOrderList - list of new CaseOpsOrder__c
     */
    public static void renameOnCreate(List<CaseOpsOrder__c> newCaseOpsOrderList) {

        Map<Id, List<CaseOpsOrder__c>> caseOpsOrderMap = new Map<Id, List<CaseOpsOrder__c>>();
        for (CaseOpsOrder__c caseOpsOrder : newCaseOpsOrderList) {

            if( caseOpsOrder.CaseOpsOrderKey__c == null ){
                if (!caseOpsOrderMap.containsKey(caseOpsOrder.Case__c)) {
                    caseOpsOrderMap.put(caseOpsOrder.Case__c, new List<CaseOpsOrder__c>());
                }
                caseOpsOrderMap.get(caseOpsOrder.Case__c).add(caseOpsOrder);
            }

        }

        if(!caseOpsOrderMap.isEmpty()){
            for (Case c : [SELECT Id, CaseNumber FROM Case WHERE Id IN :caseOpsOrderMap.keySet()]) {

                for (CaseOpsOrder__c caseOpsOrder : caseOpsOrderMap.get(c.Id)) {
                    caseOpsOrder.CaseOpsOrderKey__c = caseOpsOrder.Xometry_Order_ID__c + ' : ' + c.CaseNumber;
                }

            }
        }

        for (CaseOpsOrder__c caseOpsOrder : newCaseOpsOrderList) {
            caseOpsOrder.Name = caseOpsOrder.CaseOpsOrderKey__c;
        }

    }
}