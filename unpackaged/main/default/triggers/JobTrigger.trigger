trigger JobTrigger on Job__c(before insert, before update, after insert, after update, after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            JobHandler.associateOpsOrder(Trigger.New);
            JobHandler.associateSupplier(Trigger.New);
            JobHandler.setTechnicalReviewStatus(Trigger.New, null);
            if (ApexBypassUtility.shouldRun('Job_setOverdueFlag')) {
                JobHandler.setOverdueFlag(Trigger.New, Trigger.oldMap);
            }
        }
        if (Trigger.isUpdate) {
            JobHandler.associateSupplier(Trigger.New);
            JobHandler.setTechnicalReviewStatus(Trigger.New, Trigger.oldMap);
            if (ApexBypassUtility.shouldRun('Job_setOverdueFlag')) {
                JobHandler.setOverdueFlag(Trigger.New, Trigger.oldMap);
            }
            JobHandler.stampTopQuality(Trigger.New, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        System.debug('--After--');
        //System.debug('About to summarize (before setLargeOrderBypass): ' + EventBusBypass.triggerNameBypassed.keySet());
        largeOrderHelper.setLargeOrderbyPass(largeOrderHelper.jobByPass);
        //System.debug('About to summarize (after setLargeOrderBypass): ' + EventBusBypass.triggerNameBypassed.keySet());
        if (Trigger.isInsert) {
            System.debug('--AFTER INSERT--');
            JobHandler.createSuppliesOpps(Trigger.new, null);
            if (ApexBypassUtility.shouldRun('Job_createJobOrderJunction')) {
                JobHandler.upsertJobOrderJunction(Trigger.new, null);
                //System.debug('About to summarize (after insert upsertJobOrderJunction): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_createTechnicalReviewCase')) {
                JobHandler.createTechnicalReviewCase(Trigger.new, null);
                //System.debug('About to summarize (after insert createTechnicalReviewCase): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_associateJunctions')) {
                JobHandler.associateJunctions(Trigger.New, null);
                //System.debug('About to summarize (after insert associateJunctions): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_jobEventConditionals')) {
                JobHandler.jobEventConditionals(Trigger.New, null);
                //System.debug('About to summarize (after insert jobEventConditionals): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_checkForLargeOrderSummary')) {
                //System.debug('About to summarize (after insert): ' + EventBusBypass.triggerNameBypassed.keySet());
                JobHandler.checkForLargeOrderSummary(Trigger.new, Trigger.oldMap);
                //System.debug('About to summarize (after insert checkForLargeOrderSummary): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_updateSourcingCases')) {
                //System.debug('About to summarize (after insert): ' + EventBusBypass.triggerNameBypassed.keySet());
                JobHandler.updateSourcingCases(Trigger.new);
                //System.debug('About to summarize (after insert updateSourcingCases): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
        }
        if (Trigger.isUpdate) {
            System.debug('--AFTER UPDATE--');
            JobHandler.createSuppliesOpps(Trigger.new, Trigger.oldMap);
            if (ApexBypassUtility.shouldRun('Job_createJobOrderJunction')) {
                JobHandler.upsertJobOrderJunction(Trigger.new, Trigger.oldMap);
                //System.debug('About to summarize (after update upsertJobOrderJunction): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_createTechnicalReviewCase')) {
                JobHandler.createTechnicalReviewCase(Trigger.new, Trigger.oldMap);
                //System.debug('About to summarize (after update createTechnicalReviewCase): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_associateJunctions')) {
                JobHandler.associateJunctions(Trigger.New, Trigger.oldMap);
                //System.debug('About to summarize (after update associateJunctions): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_jobEventConditionals')) {
                JobHandler.jobEventConditionals(Trigger.New, Trigger.oldMap);
                //System.debug('About to summarize (after update jobEventConditionals): ' + EventBusBypass.triggerNameBypassed.keySet());
            }
            if (ApexBypassUtility.shouldRun('Job_checkForLargeOrderSummary')) {
                //System.debug('About to summarize (after update): ' + EventBusBypass.triggerNameBypassed.keySet());
                JobHandler.checkForLargeOrderSummary(Trigger.new, Trigger.oldMap);
            }
        }
    }
}