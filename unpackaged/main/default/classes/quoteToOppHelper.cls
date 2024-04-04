public with sharing class quoteToOppHelper {
    @AuraEnabled
    public static Quote_ERP__C getCurrentQuote(ID currentQuoteID) {
        Quote_ERP__C myQuote = [
            SELECT ID, Xometry_ERP_ID__C, LeadID__C, LeadID__r.Status, OpportunityId__C
            FROM Quote_ERP__C
            WHERE ID = :currentQuoteID
        ];
        return myQuote;
    }

    @AuraEnabled
    public static ID createOppFromQuoteSubmit(ID quoteIDIn) {
        List<Audit_Trail_Error__c> myAuditErrorList = new List<Audit_Trail_Error__c>();
        system.debug('Made it from Lightning');
        //Check no Opportunity exists with quote already
        Quote_ERP__C referenceQuote = [
            SELECT
                ID,
                AccountID__C,
                Xometry_ERP_ID__C,
                Quote_Price__C,
                Quote_ERP_Created_Date__c,
                OwnerID,
                Quote_Email__C,
                ContactID__C,
                Quote_ERP_Created_Time__c,
                ERP_Status__C,
                Line_Of_Business__C,
                process_isCarbon__c,
                process_isCNC_Machining__c,
                process_isDie_Casting__c,
                process_isDirect_Sourced__c,
                process_isDMLS__c,
                process_isExtrusion__c,
                process_isFDM__c,
                process_isHPMultJetFusion__c,
                process_isInjection_Molding__c,
                process_isInjectionMoldingTool__c,
                process_isPolyJet_3D__c,
                process_isSheet_metal__c,
                process_isSLA__c,
                process_isSLS__c,
                process_isStamping__c,
                process_isUrethane_Casting__c,
                process_isBinderJetting__c,
                process_isSheetCutting__c,
                process_isTubeBending__c,
                process_isTubeCutting__c,
                process_isOther__c,
                process_isPlasticExtrusion__c,
                process_isOther_NotIncluded__c,
                process_isLSPc__c,
                process_isAssembly__c,
                Quoted_Total_Amt_Carbon__c,
                Quoted_Total_Amt_CNC__c,
                Quoted_Total_Amt_DieCasting__c,
                Quoted_Total_Amt_DirectSourced__c,
                Quoted_Total_Amt_DMLS__c,
                Quoted_Total_Amt_Extrusion__c,
                Quoted_Total_Amt_FDM__c,
                Quoted_Total_Amt_HPMultJetFusion__c,
                Quoted_Total_Amt_InjectionMolding__c,
                Quoted_Total_Amt_InjectionMoldingTool__c,
                Quoted_Total_Amt_PolyJet3D__c,
                Quoted_Total_Amt_SheetMetal__c,
                Quoted_Total_Amt_SLA__c,
                Quoted_Total_Amt_SLS__c,
                Quoted_Total_Amt_Stamping__c,
                Quoted_Total_Amt_UrethaneCasting__c,
                Quoted_Total_Amt_BinderJetting__c,
                Quoted_Total_Amt_SheetCutting__c,
                Quoted_Total_Amt_Tube_Bending__c,
                Quoted_Total_Amt_Tube_Cutting__c,
                Quoted_Total_Amt_Other__c,
                Quoted_Total_Amt_PlasticExtrusion__c,
                Quoted_Total_Amt_Other_NotIncluded__c,
                Quoted_Total_Amt_LSPc__c,
                Quoted_Total_Amt_Assembly__c,
                Quoted_Total_Qty_Carbon__c,
                Quoted_Total_Qty_CNC__c,
                Quoted_Total_Qty_DieCasting__c,
                Quoted_Total_Qty_DirectSourced__c,
                Quoted_Total_Qty_DMLS__c,
                Quoted_Total_Qty_Extrusion__c,
                Quoted_Total_Qty_FDM__c,
                Quoted_Total_Qty_HPMultJetFusion__c,
                Quoted_Total_Qty_InjectionMolding__c,
                Quoted_Total_Qty_InjectionMoldingTool__c,
                Quoted_Total_Qty_PolyJet3D__c,
                Quoted_Total_Qty_SheetMetal__c,
                Quoted_Total_Qty_SLA__c,
                Quoted_Total_Qty_SLS__c,
                Quoted_Total_Qty_Stamping__c,
                Quoted_Total_Qty_UrethaneCasting__c,
                Quoted_Total_Qty_BinderJetting__c,
                Quoted_Total_Qty_SheetCutting__c,
                Quoted_Total_Qty_Tube_Bending__c,
                Quoted_Total_Qty_Tube_Cutting__c,
                Quoted_Total_Qty_Other__c,
                Quoted_Total_Qty_PlasticExtrusion__c,
                Quoted_Total_Qty_Other_NotIncluded__c,
                Quoted_Total_Qty_LSPc__c,
                Quoted_Total_Qty_Assembly__c,
                Quote_ERP_Last_Updated_Time__c,
                Quote_Type__c,
                OriginatedInFusion360__c,
                FirstQuoterEmail__c,
                ManualQuoterEmail__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c,
                ManualQuoteTime__c,
                ConversionProbability__c,
                ITAR__c,
                Hardware_Cert__c,
                Conformance_Cert__c,
                Material_Traceability_Cert__c,
                Material_Cert__c,
                LineItemCount__c,
                Quote_Discount__c,
                Quote_Redeemed_Points_Value__c,
                Quote_Sub_Total__c,
                Quote_Shipping__c,
                DFM_Description__c,
                Manual_Quote_Prioritization_Score__c,
                Quote_Win_Rate__c,
                Win_Rate_Expected_Value__c,
                QuickTurn__c,
                getSite_Deleted__c,
                Allow_EU_Quoting__c,
                Quote_Source__c
            FROM Quote_ERP__C
            WHERE ID = :quoteIDIn
        ];
        List<Quote_ERP__C> createQuoteERPList = new List<Quote_ERP__C>();
        createQuoteERPList.add(referenceQuote);
        List<Opportunity> returnOppList = QuoteERPHandler.QuoteToNewOpp(createQuoteERPList);
        DatabaseUtilities.insertToDatabase(returnOppList, 'quoteToOppHelper', 'Quote To New Opp from quotes');
        List<OpportunityContactRole> returnOppContactList = QuoteERPHandler.OpportunityContactRoleNew(returnOppList);
        DatabaseUtilities.insertToDatabase(
            returnOppContactList,
            'quoteToOppHelper',
            'Opportunity Contact Role New from opps'
        );
        Opportunity createdOpportunity = returnOppList[0];
        // Populate the OpportunityId on the Quote.
        Quote_ERP__C myQuoteToUpdate = new Quote_ERP__C();
        myQuoteToUpdate.ID = quoteIDIn;
        myQuoteToUpdate.OpportunityId__C = createdOpportunity.ID;
        Database.SaveResult SRUpdate = Database.update(myQuoteToUpdate);
        for (Database.Error err : SRUpdate.getErrors()) {
            System.debug('The following error has occured.');
            System.debug(err.getStatusCode() + ' : ' + err.getMessage());
            System.debug('My LWC Errors: ' + err.getFields());
            Audit_Trail_Error__c myAuditError = new Audit_Trail_Error__c();
            myAuditError.Module__c = 'quoteToOppHelper.createOppFromQuoteSubmit';
            myAuditError.Dev_Audit_Notes__c = 'LWC errors';
            myAuditError.StatusCode__c = err.getStatusCode().name();
            myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
            myAuditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
            myAuditErrorList.add(myAuditError);
        }
        if (!myAuditErrorList.isEmpty()) {
            insert myAuditErrorList;
        }
        return createdOpportunity.ID;
    }
}