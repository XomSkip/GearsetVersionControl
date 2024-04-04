public with sharing class CaseOpportunityHandler {

    //avoid reentering method processPrimaryOppOnCase during Primary update on Junction CaseOpportunity__c 
    public static boolean processingPrimaryOppOnCase = false;

    public static void renameOnCreate(List<CaseOpportunity__c> newCaseOppList) {
        /**
         * @description changes the Name in the junction record to a more readeable identifier
         */
        Map<Id, List<CaseOpportunity__c>> quoteCaseOppMap = new Map<Id, List<CaseOpportunity__c>>();
        for (CaseOpportunity__c caseOpp : newCaseOppList) {
            if (!quoteCaseOppMap.containsKey(caseOpp.Case__c)) {
                quoteCaseOppMap.put(caseOpp.Case__c, new List<CaseOpportunity__c>());
            }
            quoteCaseOppMap.get(caseOpp.Case__c).add(caseOpp);
        }

        for (Case c : [
            SELECT Id, CaseNumber, Shadow_Xometry_ERP_ID__c
            FROM Case
            WHERE Id IN :quoteCaseOppMap.keySet()
        ]) {
            for (CaseOpportunity__c caseOpp : quoteCaseOppMap.get(c.Id)) {
                caseOpp.Name = c.CaseNumber;
                if (caseOpp.Xometry_ERP_ID__c != null) {
                    caseOpp.Name += '-' + caseOpp.Xometry_ERP_ID__c;
                }
            }
        }
    }
    /**
     * @description keeps junction object relations updated, using ERP Id for search opportunities related
     */
    public static void keepRelationsUpdated(List<CaseOpportunity__c> newCaseOppList) {
        Map<String, CaseOpportunity__c> quoteCaseOppMap = new Map<String, CaseOpportunity__c>();
        for (CaseOpportunity__c caseOpp : newCaseOppList) {
            Boolean cond = Trigger.isInsert && String.isNotBlank(caseOpp.Xometry_ERP_ID__c);
            if (cond) {
                quoteCaseOppMap.put(caseOpp.Xometry_ERP_ID__c, caseOpp);
            }
        }

        if (!quoteCaseOppMap.isEmpty()) {
            //looking for related Opportunities and link them in the junction
            for (Opportunity opp : [
                SELECT Quote_ERP_XOM_CREATE_ID__c
                FROM Opportunity
                WHERE Quote_ERP_XOM_CREATE_ID__c IN :quoteCaseOppMap.keySet()
            ]) {
                if (
                    String.isNotBlank(opp.Quote_ERP_XOM_CREATE_ID__c) &&
                    quoteCaseOppMap.containsKey(opp.Quote_ERP_XOM_CREATE_ID__c)
                ) {
                    quoteCaseOppMap.get(opp.Quote_ERP_XOM_CREATE_ID__c).Opportunity__c = opp.Id;
                }
            }
        }
    }

    /**
     * @description On new Primary records Looks for a matching Opportunity and updates Junction with data from the system
     * @param oldCaseOppMap - map of old CaseOpps
     */
    public static void findRelatedOpportunity(
        List<CaseOpportunity__c> newCaseOppList,
        Map<Id, CaseOpportunity__c> oldCaseOppMap
    ) {
        List<CaseOpportunity__c> newPrimaryCasesOppList = new List<CaseOpportunity__c>();

        Map<String,Opportunity> oppByQuoteIdMap = new Map<String,Opportunity>();
        Map<String,Opportunity> oppByIdMap = new Map<String,Opportunity>();

        //collecting junctions with new or updated data
        for (CaseOpportunity__c caseOpp : newCaseOppList) {

            Boolean cond = caseOpp.Case__c != null && caseOpp.IsPrimaryOppOnCase__c;
            cond &= Trigger.isInsert || ( Trigger.isUpdate && 
            (
                !oldCaseOppMap.get(caseOpp.Id).IsPrimaryOppOnCase__c ||
                oldCaseOppMap.get(caseOpp.Id).Opportunity__c != caseOpp.Opportunity__c ||
                oldCaseOppMap.get(caseOpp.Id).Xometry_ERP_ID__c != caseOpp.Xometry_ERP_ID__c
            ));

            if (cond) {
                newPrimaryCasesOppList.add(caseOpp);
                if(caseOpp.Xometry_ERP_ID__c!=null){
                    oppByQuoteIdMap.put(caseOpp.Xometry_ERP_ID__c,null);
                }
                if(caseOpp.Opportunity__c!=null){
                    oppByIdMap.put(caseOpp.Opportunity__c,null);
                }
            }

        }

        if (!newPrimaryCasesOppList.isEmpty()) {

            //getting Opp related to new QuoteId
            if(!oppByQuoteIdMap.isEmpty()){
                for(Opportunity opp : [
                    SELECT Last_Quote_Xometry_ERP_ID__c
                    FROM Opportunity 
                    WHERE Last_Quote_Xometry_ERP_ID__c IN :oppByQuoteIdMap.keySet()
                    OR Id IN :oppByIdMap.keySet()
                ]){
                    if(opp.Last_Quote_Xometry_ERP_ID__c!=null){
                        oppByQuoteIdMap.put(opp.Last_Quote_Xometry_ERP_ID__c, opp);
                        oppByIdMap.put(opp.Id, opp);
                    }
                }

                for (CaseOpportunity__c newPrimaryCaseOpp : newPrimaryCasesOppList) {
                    if( newPrimaryCaseOpp.Xometry_ERP_ID__c != null && oppByQuoteIdMap.containsKey(newPrimaryCaseOpp.Xometry_ERP_ID__c) && oppByQuoteIdMap.get(newPrimaryCaseOpp.Xometry_ERP_ID__c) != null ){
                        newPrimaryCaseOpp.Opportunity__c = oppByQuoteIdMap.get(newPrimaryCaseOpp.Xometry_ERP_ID__c).Id;
                    }
                    if( newPrimaryCaseOpp.Opportunity__c != null && oppByIdMap.containsKey(newPrimaryCaseOpp.Opportunity__c) && oppByIdMap.get(newPrimaryCaseOpp.Opportunity__c) != null ){
                        newPrimaryCaseOpp.Xometry_ERP_ID__c = oppByIdMap.get(newPrimaryCaseOpp.Opportunity__c).Last_Quote_Xometry_ERP_ID__c;
                    }
                }
            }
        }

    }

    /**
     * @description Looks for a matching case and updates with data from the new Junction
     * @param newCaseOppList - list of new CaseOpps
     * @param oldCaseOppMap - map of old CaseOpps
     */
    public static void processPrimaryOppOnCase(
        List<CaseOpportunity__c> newCaseOppList,
        Map<Id, CaseOpportunity__c> oldCaseOppMap
    ) {

        Map<Id, CaseOpportunity__c> newPrimaryCasesOppMap = new Map<Id, CaseOpportunity__c>();
        Set<Id> newPrimaryCasesOppIds = new Set<Id>();
        //collecting junctions with new or updated data
        for (CaseOpportunity__c caseOpp : newCaseOppList) {

            Boolean cond = caseOpp.Case__c != null && caseOpp.IsPrimaryOppOnCase__c;
            cond &= Trigger.isInsert || ( Trigger.isUpdate && 
            (
                !oldCaseOppMap.get(caseOpp.Id).IsPrimaryOppOnCase__c ||
                oldCaseOppMap.get(caseOpp.Id).Opportunity__c != caseOpp.Opportunity__c ||
                oldCaseOppMap.get(caseOpp.Id).Xometry_ERP_ID__c != caseOpp.Xometry_ERP_ID__c
            ));

            if (cond) {
                newPrimaryCasesOppMap.put(caseOpp.Case__c, caseOpp);
                newPrimaryCasesOppIds.add(caseOpp.Id);
            }
        }


        if (!newPrimaryCasesOppMap.isEmpty() && processingPrimaryOppOnCase != true) {

            processingPrimaryOppOnCase = true;
            
            //Reseting old primary junctions
            List<CaseOpportunity__c> caseOppToUpdate = new List<CaseOpportunity__c>();
            for (CaseOpportunity__c caseOpp : [
                SELECT Id, Opportunity__c, Case__c, Xometry_ERP_ID__c
                FROM CaseOpportunity__c
                WHERE Case__c IN :newPrimaryCasesOppMap.keySet() AND Id NOT IN :newPrimaryCasesOppIds
            ]) {

                if (
                    newPrimaryCasesOppMap.get(caseOpp.Case__c).Opportunity__c == caseOpp.Opportunity__c &&
                    newPrimaryCasesOppMap.get(caseOpp.Case__c).Xometry_ERP_ID__c == caseOpp.Xometry_ERP_ID__c
                ) {

                    newPrimaryCasesOppMap.get(caseOpp.Case__c).addError('Duplicated CaseOpportunity.');
                
                }else{

                    caseOpp.IsPrimaryOppOnCase__c = false;
                    caseOppToUpdate.add(caseOpp);

                }

            }

            //Validating before update Cases with primary CaseOpp data
            List<Case> casesToUpdateList = new List<Case>();
            for (Case checkCase : [
                SELECT Id, Shadow_Xometry_ERP_ID__c, Opportunity__c, Origin
                FROM Case
                WHERE Id IN :newPrimaryCasesOppMap.keySet()
            ]) {

                if( newPrimaryCasesOppMap.get(checkCase.Id).hasErrors() ){
                    continue;
                }

                Boolean updateCase = false;
                Case caseToUp = new Case(Id = checkCase.Id);

                //checking differences with DataBase
                if (
                    checkCase.Shadow_Xometry_ERP_ID__c != newPrimaryCasesOppMap.get(checkCase.Id).Xometry_ERP_ID__c
                ){
                    caseToUp.Shadow_Xometry_ERP_ID__c = newPrimaryCasesOppMap.get(checkCase.Id).Xometry_ERP_ID__c;
                    updateCase = true;
                }

                if( checkCase.Opportunity__c != newPrimaryCasesOppMap.get(checkCase.Id).Opportunity__c) {
                    caseToUp.Opportunity__c = newPrimaryCasesOppMap.get(checkCase.Id).Opportunity__c;
                    updateCase = true;
                }

                //Email Cases should not be related to Opp
                if( checkCase.Origin != null && (checkCase.Origin.contains('Email:') || checkCase.Origin.contains('Web')) && caseToUp.Opportunity__c != null){
                    caseToUp.Opportunity__c = null;
                    updateCase = true;
                }

                if(updateCase){

                    casesToUpdateList.add(caseToUp);
                }
            }

            DatabaseUtilities.saveToDatabase(
                caseOppToUpdate,
                'CaseOpportunityHandler.processPrimaryOppOnCase',
                'Update CaseOpp to remove primary on all'
            );

            DatabaseUtilities.saveToDatabase(
                casesToUpdateList,
                'CaseOpportunityHandler.processPrimaryOppOnCase',
                'Update Case with new Primary Opp'
            );
        
            processingPrimaryOppOnCase = false;
            
        }


    }
}