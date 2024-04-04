trigger opportunityTrigger on Opportunity(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            //Create a Commission Owner on Opportunity when Opp is Won and the OrderID is populated
            //Check for the Commission Owner is populated
            if (ApexBypassUtility.shouldRun('Opp_populateCommissionOwner')) {
                OpportunityHandler.populateCommissionOwner(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Opp_populateCurrentStageEntryDate')) {
                OpportunityHandler.populateCurrentStageEntryDate(Trigger.new);
            }
            OpportunityHandler.associateToProject(Trigger.new);
            OpportunityHandler.updateSuppliesContact(Trigger.new, null);
            OpportunityHandler.linkOpptoJob(Trigger.new, null);
            OpportunityHandler.stampOwnershipFields(Trigger.new, null);
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Opp_checkKeepOppOwner')) {
                OpportunityHandler.checkKeepOppOwner(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Opp_populateCommissionOwner')) {
                OpportunityHandler.populateCommissionOwner(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Opp_populateCurrentStageEntryDate')) {
                OpportunityHandler.populateCurrentStageEntryDate(Trigger.new, Trigger.oldMap);
            }
            OpportunityHandler.updatePrimaryInformation(Trigger.new);
            OpportunityHandler.updateSuppliesContact(Trigger.new, Trigger.oldMap);
            OpportunityHandler.linkOpptoJob(Trigger.new, Trigger.oldMap);
            OpportunityHandler.stampOwnershipFields(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            OpportunityHandler.getCasesRelatedIds(Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityHandler.insertedOppChangesProject(Trigger.new);
            if (ApexBypassUtility.shouldRun('Opp_assignOppToCase')) {
                OpportunityHandler.assignOppToCase(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Opp_associateToCaseOpp')) {
                OpportunityHandler.associateToCaseOpp(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isUpdate) {
            OpportunityHandler.updateProjectStatus(Trigger.new, Trigger.oldMap);
            OpportunityHandler.updatedOppChangesProject(Trigger.new, Trigger.oldMap);
            OpportunityHandler.reassignCaseOwner(Trigger.new, Trigger.oldMap);
            if (ApexBypassUtility.shouldRun('Opp_keepTotalFieldsCaseUpdated')) {
                OpportunityHandler.keepTotalFieldsCaseUpdated(Trigger.new, Trigger.oldMap);
            }

            if (ApexBypassUtility.shouldRun('Opp_createTeamMember')) {
                OpportunityHandler.createTeamMember(Trigger.newMap, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Opp_associateToCaseOpp')) {
                OpportunityHandler.associateToCaseOpp(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isDelete) {
            OpportunityHandler.deleteOppChangesProject(Trigger.old);
            OpportunityHandler.keepTotalFieldsCaseDeletedOpps();
        }
    }
}