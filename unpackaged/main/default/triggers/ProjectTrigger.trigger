trigger ProjectTrigger on Project__c(before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            ProjectHandler.setCloseDate(Trigger.new, Trigger.oldMap);
            if (ApexBypassUtility.shouldRun('Project_setCurrentStageStartDate')) {
                ProjectHandler.setCurrentStageStartDate(Trigger.new, Trigger.oldMap);
            }
        }

        if (Trigger.isUpdate) {
            ProjectHandler.checkForCwOppInClosedProject(Trigger.new);
            ProjectHandler.checkKeepProjOwner(Trigger.new, Trigger.oldMap);
            ProjectHandler.setCloseDate(Trigger.new, Trigger.oldMap);
            ProjectHandler.setAmountOnCloseWon(Trigger.new, Trigger.newMap, Trigger.oldMap);
            if (ApexBypassUtility.shouldRun('Project_setCurrentStageStartDate')) {
                ProjectHandler.setCurrentStageStartDate(Trigger.new, Trigger.oldMap);
            }

        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ProjectHandler.createJunction(Trigger.new);
        }
        if (Trigger.isUpdate) {
            ProjectHandler.closeOppsinClosedProjects(Trigger.new, Trigger.oldMap);
            ProjectHandler.updateJunction(Trigger.new, Trigger.oldMap);
            ProjectHandler.projectDownstream(Trigger.new, Trigger.oldMap);
        }
    }
}