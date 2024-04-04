trigger AccountTrigger on Account(before insert, before update, after update) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('Account_setClasification')) {
                AccountHandler.setClasification(Trigger.new);
            }

            if (ApexBypassUtility.shouldRun('Account_updateDriftDomain')) {
                AccountHandler.updateDriftDomain(Trigger.new, Trigger.oldMap);
            }

            if (ApexBypassUtility.shouldRun('Account_cleanDomain')) {
                AccountHandler.cleanDomain(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Account_setHouseRetainer')) {
                AccountHandler.setHouseRetainer(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Account_updateSLASegment')) {
                AccountHandler.updateSLASegment(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Account_updateDriftDomain')) {
                AccountHandler.updateDriftDomain(Trigger.new, Trigger.oldMap);
            }

            if (ApexBypassUtility.shouldRun('Account_cleanDomain')) {
                AccountHandler.cleanDomain(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Account_setHouseRetainer')) {
                AccountHandler.setHouseRetainer(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Account_updateSLASegment')) {
                AccountHandler.updateSLASegment(Trigger.new, Trigger.oldMap);
            }
        }
    }

    if (Trigger.isUpdate) {
        if (Trigger.isAfter) {
            if (ApexBypassUtility.shouldRun('Account_accountDownstream')) {
                AccountHandler.accountDownstream(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Account_updateSLASegment')) {
                AccountHandler.updateSLASegment(Trigger.new, Trigger.oldMap);
            }
        }
    }
}