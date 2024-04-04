trigger QuoteERPTrigger on Quote_ERP__C(before insert, after insert, before update, after update) {
    //Call the handler to process logic. In future more
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            //Call the handler to process logic. In future more methods may be added
            //Create a version of the handler
            if (ApexBypassUtility.shouldRun('QuoteERP_LOBToRecordTypes')) {
                QuoteERPHandler.LOBToRecordTypes(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('QuoteERP_updateQuoterUser')) {
                QuoteERPHandler.updateQuoterUser(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('QuoteERP_processERPQuotes2')) {
                QuoteERPHandler.processERPQuotes2(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('QuoteERP_reassignWestCoast')) {
                QuoteERPHandler.reassignWestCoast(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('QuoteERP_processQuoteContactManuProc')) {
                QuoteERPHandler.processQuoteContactManuProc(Trigger.new);
            }
            // QuoteERPHandler.createLeadAndOpt(trigger.new);
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('QuoteERP_updateQuoterUser')) {
                QuoteERPHandler.updateQuoterUser(Trigger.new);
            }
            // Create Opportunities when there is none, Lead is Null, and Price changes above Custom Metadata value
            if (ApexBypassUtility.shouldRun('QuoteERP_processCheckforPricePostQuoteCreation')) {
                QuoteERPHandler.processCheckforPricePostQuoteCreation(Trigger.new, Trigger.oldmap, Trigger.newmap);
            }
            if (ApexBypassUtility.shouldRun('QuoteERP_processQuoteContactManuProc')) {
                QuoteERPHandler.processQuoteContactManuProc(Trigger.new);
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('QuoteERP_createCase')) {
                QuoteERPHandler.createCases(Trigger.new, null);
            }
            if (ApexBypassUtility.shouldRun('QuoteERP_QuoteDateofFirstQuotePop')) {
                QuoteERPHandler.QuoteDateofFirstQuotePop(Trigger.new);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('QuoteERP_updateOpp')) {
                QuoteERPHandler.updateOpp(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('QuoteERP_createCase')) {
                QuoteERPHandler.createCases(Trigger.new, Trigger.oldMap);
            }

            if (ApexBypassUtility.shouldRun('QuoteERP_updateContactLastQuote')) {
                QuoteERPHandler.updateContactLastQuote(Trigger.newMap, Trigger.oldMap);
            }
        }
        if (ApexBypassUtility.shouldRun('QuoteERP_updateNYOPCases')) {
            QuoteERPHandler.updateNYOPCases(Trigger.new);
        }
    }
}