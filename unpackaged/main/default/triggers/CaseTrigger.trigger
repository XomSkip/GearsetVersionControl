trigger CaseTrigger on Case(before insert, before update, after insert, after update, before delete, after delete) {
    Id pseCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('PSE_Case')
        .getRecordTypeId();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('Case_populateProjectFromOpp')) {
                List<Case> pseCaseList = new List<Case>();
                for (Case thisCase : Trigger.new) {
                    if (thisCase.RecordTypeId == pseCaseRecordTypeId) {
                        pseCaseList.add(thisCase);
                    }
                }
                if (pseCaseList.size() > 0) {
                    CaseHandler.populateProjectFromOpp(pseCaseList, null);
                }
            }
            if (ApexBypassUtility.shouldRun('Case_assignSuppliesOppToCase')) {
                CaseHandler.assignSuppliesOppToCase(Trigger.New);
            }
            if (ApexBypassUtility.shouldRun('Case_assignOwnerByUser')) {
                CaseHandler.assignOwnerByUser(Trigger.New);
            }
            if (ApexBypassUtility.shouldRun('Case_Contact_Assignment')) {
                CaseHandler.caseContactAssignment(Trigger.New);
            }
            if (ApexBypassUtility.shouldRun('Case_closeCaseOnCreation')) {
                CaseHandler.closeCaseOnCreation(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Case_noSystemOwner')) {
                CaseHandler.noSystemOwner(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_checkAccountVIP')) {
                CaseHandler.checkAccountVIP(Trigger.new, null);
            }
            if (ApexBypassUtility.shouldRun('Case_nyopCaseLink')) {
                CaseHandler.nyopCaseLink(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Case_creditAppToPO')) {
                CaseHandler.creditAppToPO(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Case_populateOppAccount')) {
                CaseHandler.populateOppAccount(Trigger.new, null);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Case_populateProjectFromOpp')) {
                List<Case> pseCaseList = new List<Case>();
                Map<Id, Case> oldPseCaseMap = new Map<Id, Case>();
                for (Case thisCase : Trigger.new) {
                    if (thisCase.RecordTypeId == pseCaseRecordTypeId) {
                        pseCaseList.add(thisCase);
                        oldPseCaseMap.put(thisCase.Id, Trigger.oldMap.get(thisCase.Id));
                    }
                }
                if (pseCaseList.size() > 0) {
                    CaseHandler.populateProjectFromOpp(pseCaseList, oldPseCaseMap);
                    CaseHandler.populateLastOwnerChangeDate(pseCaseList, oldPseCaseMap);
                }
            }
            if (ApexBypassUtility.shouldRun('Case_noSystemOwner')) {
                CaseHandler.noSystemOwner(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_restrictRecordTypeSwitching')) {
                CaseHandler.restrictRecordTypeSwitching(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_setRecordTypeOnOwnerChange')) {
                CaseHandler.setRecordTypeOnOwnerChange(Trigger.New, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_checkAccountVIP')) {
                CaseHandler.checkAccountVIP(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_restrictDuplicateCases')) {
                CaseHandler.restrictDuplicateCases(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_populateOppAccount')) {
                CaseHandler.populateOppAccount(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isDelete) {
            if (ApexBypassUtility.shouldRun('Case_syncCaseJunctions')) {
                CaseHandler.syncCaseJunctions(Trigger.new, Trigger.oldMap);
            }
        }
    }
    if (Trigger.isAfter) {
        largeOrderHelper.setLargeOrderbyPass(largeOrderHelper.caseByPass);
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('Case_linkAccountAndContactByEmail')) {
                List<Case> pseCaseList = new List<Case>();
                for (Case thisCase : Trigger.new) {
                    if (thisCase.RecordTypeId == pseCaseRecordTypeId) {
                        pseCaseList.add(thisCase);
                    }
                }
                if (pseCaseList.size() > 0) {
                    CaseHandler.linkAccountAndContactByEmail(pseCaseList);
                }
            }
            if (ApexBypassUtility.shouldRun('Case_syncCaseJunctions')) {
                CaseHandler.syncCaseJunctions(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_updateJobRollUp')) {
                CaseHandler.updateJobRollUp(Trigger.new, Trigger.oldMap);
            }

            if (ApexBypassUtility.shouldRun('Case_createTeamMember')) {
                CaseHandler.createTeamMember(Trigger.new, Trigger.oldMap);
            }

            if (ApexBypassUtility.shouldRun('Case_createOutcomeRecordHistory')) {
                CaseHandler.createOutcomeRecordHistory(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_closeCollectionsCases')) {
                CaseHandler.closeCollectionsCases(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_restrictDuplicateCases')) {
                CaseHandler.restrictDuplicateCases(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_updateStatusRollUpOnOrder')) {
                CaseHandler.checkLargeOrderSummary(Trigger.new, Trigger.oldMap);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Case_syncCaseJunctions')) {
                CaseHandler.syncCaseJunctions(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_updateJobRollUp')) {
                CaseHandler.updateJobRollUp(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_createRecordHistory')) {
                CaseHandler.createRecordHistory(Trigger.new, Trigger.oldMap);
            }

            if (ApexBypassUtility.shouldRun('Case_createTeamMember')) {
                CaseHandler.createTeamMember(Trigger.new, Trigger.oldMap);
            }

            if (ApexBypassUtility.shouldRun('Case_createOutcomeRecordHistory')) {
                CaseHandler.createOutcomeRecordHistory(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_closeCollectionsCases')) {
                CaseHandler.closeCollectionsCases(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_updateStatusRollUpOnOrder')) {
                CaseHandler.checkLargeOrderSummary(Trigger.new, Trigger.oldMap);
            }
        }

        if (Trigger.isDelete) {
            if (ApexBypassUtility.shouldRun('Case_updateJobRollUp')) {
                CaseHandler.updateJobRollUp(Trigger.new, Trigger.oldMap);
            }
            if (ApexBypassUtility.shouldRun('Case_updateStatusRollUpOnOrder')) {
                CaseHandler.checkLargeOrderSummary(Trigger.old, Trigger.oldMap);
            }
        }
    }
}