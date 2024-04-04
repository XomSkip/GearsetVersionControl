public with sharing class JobOrderedPartHandler {
    /**
     * @description changes the Name in the junction record to a more readable identifier
     * @param newJobOrderedPartList list of newly created Job Ordered Part
     */
    public static void renameOnCreate(List<JobOrderedPart__c> newJobOrderedPartList) {
        Map<Id, List<JobOrderedPart__c>> jobJOPMap = new Map<Id, List<JobOrderedPart__c>>();
        for (JobOrderedPart__c jop : newJobOrderedPartList) {
            if (!String.isBlank(jop.JobOrderedPartKey__c)) {
                jop.Name = jop.JobOrderedPartKey__c;
            }
        }
    }

    /**
     * @description determines if the Job Ordered Part has being inserted belongs to a large Order if yes then prepare new summary information
     *
     * @param newJobOrderedPartList list of the insert Job Ordered Part information
     */
    public static void checkJobOrderedPartsForLargeOrderSummary(List<JobOrderedPart__c> newJobOrderedPartList) {
        if (!EventBusBypass.isByPassed(largeOrderHelper.ordPartByPass)) {
            Set<ID> orderedPartIDSet = new Set<ID>();
            for (JobOrderedPart__c jOrdPart : newJobOrderedPartList) {
                if (jOrdPart.JobId__c != null && jOrdPart.OrderedPartId__c != null) {
                    orderedPartIDSet.add(jOrdPart.OrderedPartId__c);
                }
            }
            Set<Id> opsOrderToSumIdSet = JobOrderedPartHandler.orderedPartPartofLargeOrderandOnJob(orderedPartIDSet);
            //If we are coming from the JobHandler then the bypass should be on and we can skip this as the jobhandler will handle the summary update
            OpsOrderHandler.updateLargeOrderSummary(opsOrderToSumIdSet);
        }
    }

    /*
    Determine if an Ordered Part is part of a Large Order and return a Set of OpsOrderIds
    */
    public static Set<ID> orderedPartPartofLargeOrder(Set<Id> OrderedPartIDSet) {
        //Map<ID, ID> orderedPartToLargeOrderMap = new Map<ID, ID>();
        Set<ID> orderIDSet = new Set<ID>();
        for (Ordered_Part__c ordPart : [
            SELECT Id, Ops_Order__c
            FROM Ordered_Part__c
            WHERE ID IN :OrderedPartIDSet AND Ops_Order__r.Is_Large_Order__c = TRUE
        ]) {
            //orderedPartToLargeOrderMap.put(ordPart.Id, ordPart.Ops_Order__C);
            orderIDSet.add(ordPart.Ops_Order__C);
        }
        return orderIDSet;
    }

    /*
     * @description Determines for an Ordered Part if the Ordered Part belongs to a Large Order and is Part of a Job that exists in Salesforce
     */
    public static Set<ID> orderedPartPartofLargeOrderandOnJob(Set<Id> OrderedPartIDSet) {
        Set<Id> OpsLarderOrderIDSet = new Set<ID>();
        for (Ordered_Part__c ordPart : [
            SELECT Id, Ops_Order__c, (SELECT Id, JobId__c, JobId__r.AcceptedPartnerID__c FROM Job_Ordered_Parts__r)
            FROM Ordered_Part__c
            WHERE ID IN :OrderedPartIDSet AND Ops_Order__r.Is_Large_Order__c = TRUE
        ]) {
            for (JobOrderedPart__c jOrdPart : ordPart.Job_Ordered_Parts__r) {
                if (jOrdPart.JobId__c != null && jOrdPart.JobId__r.AcceptedPartnerID__c != null) {
                    OpsLarderOrderIDSet.add(ordPart.Ops_Order__c);
                    break;
                }
            }
        }
        return OpsLarderOrderIDSet;
    }
}