trigger CaseOpportunityTrigger on CaseOpportunity__c(before insert, before update, after insert, after delete, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('CaseOppHandler_renameOnCreate')) {
                CaseOpportunityHandler.renameOnCreate(Trigger.New);
            }

            if (ApexBypassUtility.shouldRun('CaseOppHandler_keepRelationsUpdated')) {
                CaseOpportunityHandler.keepRelationsUpdated(Trigger.New);
            }

            if (ApexBypassUtility.shouldRun('CaseOppHandler_findRelatedOpportunity')) {
                CaseOpportunityHandler.findRelatedOpportunity(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('CaseOppHandler_findRelatedOpportunity')) {
                CaseOpportunityHandler.findRelatedOpportunity(Trigger.new, Trigger.oldMap);
            }
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('CaseOppHandler_keepTotalFieldsCaseUpdated')) {
                OpportunityHandler.sumOppsValuesInCasesRecords(null, null, Trigger.NewMap.KeySet());
            }
            if (ApexBypassUtility.shouldRun('CaseOppHandler_processPrimaryOppOnCase')) {
                CaseOpportunityHandler.processPrimaryOppOnCase(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('CaseOppHandler_processPrimaryOppOnCase')) {
                CaseOpportunityHandler.processPrimaryOppOnCase(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isDelete) {
            if (ApexBypassUtility.shouldRun('CaseOppHandler_keepTotalFieldsCaseUpdated')) {
                OpportunityHandler.sumOppsValuesInCasesRecords(null, null, Trigger.oldMap.KeySet());
            }
        }
    }
}