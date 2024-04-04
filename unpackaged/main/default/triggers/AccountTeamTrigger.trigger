/*
This Trigger is for the custom Account_Team__c object
This object replaces the default object of accountTeamMember
*/
trigger AccountTeamTrigger on Account_Team__c(before insert, before update, after update, after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            accountTeamHandler.setUK(Trigger.new);
            if (ApexBypassUtility.shouldRun('ATM_acctTeamValidation')) {
                accountTeamHandler.acctTeamValidation(Trigger.new);
            }
        }
        if (Trigger.isUpdate) {
            accountTeamHandler.setUK(Trigger.new);
            if (ApexBypassUtility.shouldRun('ATM_acctTeamValidation')) {
                accountTeamHandler.acctTeamValidation(Trigger.new);
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('aTeamOwnerChange')) {
                accountTeamHandler.aTeamOwnerChange(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isDelete) {
            accountTeamHandler.acctDeleteDownstream(Trigger.old);
        }
    }
}