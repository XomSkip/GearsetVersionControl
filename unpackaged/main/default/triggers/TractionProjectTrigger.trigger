trigger TractionProjectTrigger on Project__c(before insert, before update, after insert, after update) {
    TracRTC.CompleteAPI.triggerHandler();
}