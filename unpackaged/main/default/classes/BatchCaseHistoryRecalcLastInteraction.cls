/**
 * Batch job to recalculate duration and fixing all current CaseHistory__c with new user (not queue) and duration 0
 */

global class BatchCaseHistoryRecalcLastInteraction implements Database.Batchable<sObject> {
    public String query =
        'SELECT Case__c, CreatedDate, CloseDate__c, New_Owner__c, Old_Owner__c FROM CaseHistory__c WHERE New_Owner__c != null AND DurationMinutes__c = 0 AND Case__r.RecordTypeId = \'' +
        AppConstants.casePSERecordTypeId +
        '\' AND Case__r.CreatedDate > 2022-04-01T00:00:00Z ORDER BY Case__c, CreatedDate  DESC';
    static Id businessHoursId {
        get {
            if (businessHoursId == null) {
                businessHoursId = [SELECT Id FROM BusinessHours WHERE isdefault = TRUE].id;
            }
            return businessHoursId;
        }
        set;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<CaseHistory__c> scope) {
        Timezone tz = Timezone.getTimeZone('America/New_York');
        Integer hoursToAddForDST = tz.getOffset(DateTime.now()) == 14400000 ? 2 : 1;

        Map<Id, List<CaseHistory__c>> caseHistoryToFixMap = new Map<Id, List<CaseHistory__c>>();
        Map<Id, DateTime> caseIdToCreatedDatetimeMap = new Map<Id, DateTime>();
        for (CaseHistory__c ch : scope) {
            if (ch.New_Owner__c != ch.Old_Owner__c || ch.CloseDate__c != null) {
                if (!caseHistoryToFixMap.containskey(ch.Case__c)) {
                    caseHistoryToFixMap.put(ch.Case__c, new List<CaseHistory__c>());
                }
                caseHistoryToFixMap.get(ch.Case__c).add(ch);
            }
        }

        for (Case c : [SELECT Id, CreatedDate FROM Case WHERE ID IN :caseHistoryToFixMap.keySet()]) {
            caseIdToCreatedDatetimeMap.put(c.Id, c.CreatedDate);
        }

        Map<Id, List<CaseHistory__c>> caseFullHistoryMap = new Map<Id, List<CaseHistory__c>>();
        for (CaseHistory__c ch : [
            SELECT Case__c, CreatedDate
            FROM CaseHistory__c
            WHERE Case__c IN :caseHistoryToFixMap.keySet() AND New_Owner__c != NULL
            ORDER BY Case__c, CreatedDate DESC
        ]) {
            if (!caseFullHistoryMap.containskey(ch.Case__c)) {
                caseFullHistoryMap.put(ch.Case__c, new List<CaseHistory__c>());
            }
            caseFullHistoryMap.get(ch.Case__c).add(ch);
        }

        List<CaseHistory__c> caseHistorytoUpdate = new List<CaseHistory__c>();
        for (Id caseId : caseHistoryToFixMap.keySet()) {
            for (CaseHistory__c chToFix : caseHistoryToFixMap.get(caseId)) {
                Boolean foundPreviousRecord = false;
                for (CaseHistory__c ch : caseFullHistoryMap.get(caseId)) {
                    if (ch.CreatedDate < chToFix.CreatedDate) {
                        DateTime latestHistory = Datetime.valueOf(
                            ch.CreatedDate.addHours(hoursToAddForDST).format('yyyy-MM-dd HH:mm:ss', 'America/New_York')
                        );
                        DateTime needToFixHistory = Datetime.valueOf(
                            chToFix.CreatedDate.addHours(hoursToAddForDST)
                                .format('yyyy-MM-dd HH:mm:ss', 'America/New_York')
                        );

                        ///redoing duration logic same as CaseHandler.createRecordHistory
                        chToFix.DurationMinutes__c = Math.abs(
                            BusinessHours.diff(businessHoursId, latestHistory, needToFixHistory) /
                            1000 /
                            60
                        );
                        caseHistorytoUpdate.add(chToFix);
                        foundPreviousRecord = true;
                        break;
                    }
                }
                if (!foundPreviousRecord) {
                    DateTime caseCreatedDateTime = DateTime.valueOf(
                        caseIdToCreatedDatetimeMap.get(caseId)
                            .addHours(hoursToAddForDST)
                            .format('yyyy-MM-dd HH:mm:ss', 'America/New_York')
                    );
                    DateTime firstOwnerChange = Datetime.valueOf(
                        chToFix.CreatedDate.addHours(hoursToAddForDST).format('yyyy-MM-dd HH:mm:ss', 'America/New_York')
                    );
                    chToFix.DurationMinutes__c = Math.abs(
                        BusinessHours.diff(businessHoursId, caseCreatedDateTime, firstOwnerChange) /
                        1000 /
                        60
                    );
                    caseHistorytoUpdate.add(chToFix);
                }
            }
        }

        DatabaseUtilities.saveToDatabase(
            caseHistorytoUpdate,
            'BatchCaseHistoryRecalcLastInteraction',
            'Recalculate CaseHistory__c duration'
        );
    }

    global void finish(Database.BatchableContext BC) {
    }
}