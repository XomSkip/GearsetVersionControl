public with sharing class largeOrderHelper {
    public static final String caseByPass = 'largeOrderSummary_Case';
    public static final String jobByPass = 'largeOrderSummary_Job';
    public static final String ordPartByPass = 'largeOrderSummary_OrderedPart';
    public static final Set<String> largeOrderBypassSet = new Set<String>{ caseByPass, jobByPass, ordPartByPass };

    static final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('DFM_Case')
        .getRecordTypeId();

    static final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('CaseMgmt')
        .getRecordTypeId();

    public static void setLargeOrderbyPass(String inTriggerRule) {
        // System.debug('In setLargeOrderbyPass, inTriggerRule: ' + inTriggerRule);
        //either load all Values onto the bypass or set specific bypasses based on what started the execution chain
        //If anybyPass is already set then do not add or remove anybyPasses just continue the trigger execution.

        // HYPOTHESIS: Using an initialized variable will stop inconsistency
        Boolean callLargeOrderCheck = largeOrderHelper.byPassLargeOrderCheck();
        if (callLargeOrderCheck == false) {
            // The All string is not in use anywhere but is a string so a trigger can stop itself from triggering the summary again
            if (inTriggerRule == 'All') {
                for (String triggerName : largeOrderBypassSet) {
                    EventBusBypass.ByPass(triggerName);
                }
            } else {
                System.debug('Confirming this met else logic in largeOrderHelper');
                for (String triggerName : largeOrderBypassSet) {
                    // System.debug('triggerName being evaluated: ' + triggerName);
                    if (triggerName != inTriggerRule) {
                        System.debug('Trigger we are bypassing: ' + triggerName);
                        EventBusBypass.ByPass(triggerName);
                    }
                }
            }
        }
        // System.debug('Summarizing from the large order helper: ' + EventBusBypass.triggerNameBypassed.keySet());
    }

    /**
     *
     * @description this method is used to set check and set a bypass for LargeOrderSummary Information
     *  returns true if any LargeOrderbypass has been set
     *
     */
    public static boolean byPassLargeOrderCheck() {
        boolean LargeOrderSummarybyPass = false;
        for (String triggerName : largeOrderBypassSet) {
            if (
                EventBusBypass.triggerNameBypassed.containsKey(triggerName) &&
                EventBusBypass.triggerNameBypassed.get(triggerName)
            ) {
                LargeOrderSummarybyPass = true;
                break;
            }
        }
        return LargeOrderSummarybyPass;
    }
    public static void updateLargeOrderSummaryRT(Set<Id> opsOrderIdSet) {
        Map<Id, Set<Id>> inProgressCasesMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> inProgressJobsMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> completedCasesMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> completedJobsMap = new Map<Id, Set<Id>>();
        Set<Id> recordTypeSet = new Set<Id>{ caseManagementRTypeId, caseDFMRTypeId };
        if (opsOrderIdSet.contains(null)) {
            opsOrderIdSet.remove(null);
        }
        Set<ID> allOrdParentAndChildIDSet = new Set<ID>();
        //Need to get all Parent if one of the children was given without their parent in the set above
        Set<ID> opsOrderIdPlusParentSet = new Set<ID>();
        List<Ops_Order__c> getallOpsOrders = [
            SELECT ID, ParentOpsOrder__c
            FROM Ops_Order__c
            WHERE ID IN :opsOrderIdSet
        ];
        for (Ops_Order__c ord : getallOpsOrders) {
            opsOrderIdPlusParentSet.add(ord.Id);
            if (ord.ParentOpsOrder__c != null) {
                opsOrderIdPlusParentSet.add(ord.ParentOpsOrder__c);
            }
        }

        System.debug('opsOrderIDPLusParentSet: ' + opsOrderIdPlusParentSet);

        //This query will all parents with all their children to work with for the rest of the method
        Map<Id, Ops_Order__c> opsOrderMap = new Map<ID, Ops_Order__C>(
            [
                SELECT ID, LargeOrderStatus__c, is_Large_Order__c, XometryOpsOrderId__C, ParentOpsOrder__c, ERPStatus__c
                FROM Ops_Order__c
                WHERE
                    (ID IN :opsOrderIdPlusParentSet
                    OR ParentOpsOrder__c IN :opsOrderIdPlusParentSet)
                    AND is_Large_Order__c = TRUE
            ]
        );
        Map<ID, ID> opsOrderToParentMap = new Map<ID, ID>();
        for (Ops_Order__c opsOrd : opsOrderMap.values()) {
            allOrdParentAndChildIDSet.add(opsOrd.ID);
            //reset all rollups at this point
            opsOrd.Jobs_Completed__c = 0;
            opsOrd.Cases_Completed__c = 0;
            opsOrd.Jobs_In_Progress__c = 0;
            opsOrd.Cases_In_Progress__c = 0;
            if (opsOrd.ParentOpsOrder__c != null) {
                //If the tier is more then 2 layers and we are triggered from the bottom layer then exclude the top parent update
                if (opsOrderIdPlusParentSet.contains(opsOrd.ParentOpsOrder__c)) {
                    opsOrderToParentMap.put(opsOrd.ID, opsOrd.ParentOpsOrder__c);
                    allOrdParentAndChildIDSet.add(opsOrd.ParentOpsOrder__c);
                }
            }
        }

        System.debug('Everything has been set to 0');

        // We want to fetch all Ops Orders where the ID is itself or the parent is part of the set
        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY Label ASC
        ];
        Map<Integer, String> largeOrderStatusRankMap = new Map<Integer, String>();
        Map<String, Decimal> largeOrderRankMap = new Map<String, Decimal>();
        Decimal topRank = largeOrderRankMtd[largeOrderRankMtd.size() - 1].StatusRank__c;
        for (Large_Order_Status_Rank__mdt lor : largeOrderRankMtd) {
            largeOrderRankMap.put(lor.Label, lor.StatusRank__c);
            largeOrderStatusRankMap.put(lor.StatusRank__c.intValue(), lor.Label);
        }

        Map<Id, Decimal> parentIdToLowestCase = new Map<Id, Decimal>();
        Map<Id, String> lowestStatus = new Map<Id, String>();
        Map<Id, Decimal> ordCaseStatusRank = new Map<Id, Decimal>();

        for (Case c : [
            SELECT
                GNOOrder__c,
                RecordTypeId,
                Status,
                Type,
                isClosed,
                ParentOpsOrder__c,
                GNOOrder__r.ParentOpsOrder__c,
                GNOOrder__r.ERPStatus__c
            FROM Case
            WHERE
                (GNOOrder__c IN :allOrdParentAndChildIDSet
                OR GNOOrder__r.ParentOpsOrder__c IN :allOrdParentAndChildIDSet)
                AND RecordTypeId IN :recordTypeSet
        ]) {
            Decimal thisCaseRank = OpsOrderHandler.largeOrdercaseRankCalculator(c, topRank);
            //For each Order store the worst status based on the Case
            //largeOrderRankMap.get(c.Status);
            if (ordCaseStatusRank.containsKey(c.GNOOrder__c)) {
                if (thisCaseRank < ordCaseStatusRank.get(c.GNOOrder__c)) {
                    ordCaseStatusRank.put(c.GNOOrder__c, thisCaseRank);
                }
            } else {
                ordCaseStatusRank.put(c.GNOOrder__c, thisCaseRank);
            }

            if (c.isClosed == false) {
                if (!inProgressCasesMap.containsKey(c.GNOOrder__c)) {
                    inProgressCasesMap.put(c.GNOOrder__c, new Set<Id>());
                }
                inProgressCasesMap.get(c.GNOOrder__c).add(c.Id);
            }

            if (c.isClosed) {
                if (!completedCasesMap.containsKey(c.GNOOrder__c)) {
                    completedCasesMap.put(c.GNOOrder__c, new Set<Id>());
                }
                completedCasesMap.get(c.GNOOrder__c).add(c.Id);
            }
        }

        //Jobs
        Map<Id, Decimal> ordJobStatusRank = new Map<Id, Decimal>();
        for (Job_Order__c jobOrder : [
            SELECT Ops_Order__c, Job__r.Technical_Review_Status__c, Job__r.DFM_Complete__c, Ops_Order__r.ERPStatus__c
            FROM Job_Order__c
            WHERE Ops_Order__c IN :allOrdParentAndChildIDSet
        ]) {
            Decimal thisJobRank = OpsOrderHandler.largeOrderJobRankCalculator(jobOrder, topRank);
            //For each Order store the worst status based on the Jobs
            //largeOrderRankMap.get(c.Status);
            System.debug('In Job order loop for summary rollup');
            System.debug('thisJobRank: ' + thisJobRank);
            if (ordJobStatusRank.containsKey(jobOrder.Ops_Order__c)) {
                if (thisJobRank < ordJobStatusRank.get(jobOrder.Ops_Order__c)) {
                    ordJobStatusRank.put(jobOrder.Ops_Order__c, thisJobRank);
                }
            } else {
                ordJobStatusRank.put(jobOrder.Ops_Order__c, thisJobRank);
            }

            System.debug('ordJobStatusRank: ' + ordJobStatusRank);

            System.debug('Jobs actual technical review status: ' + jobOrder.Job__r.Technical_Review_Status__c);
            if (jobOrder.Job__r.Technical_Review_Status__c == 'Pending Technical Review') {
                System.debug('Job is pending technical review');
                if (!inProgressJobsMap.containsKey(jobOrder.Ops_Order__c)) {
                    inProgressJobsMap.put(jobOrder.Ops_Order__c, new Set<Id>());
                }
                inProgressJobsMap.get(jobOrder.Ops_Order__c).add(jobOrder.Job__c);
            }

            if (
                jobOrder.Job__r.Technical_Review_Status__c == 'No Technical Review Required' ||
                (jobOrder.Job__r.DFM_Complete__c &&
                jobOrder.Job__r.Technical_Review_Status__c == 'Technical Review Complete')
            ) {
                if (!completedJobsMap.containsKey(jobOrder.Ops_Order__c)) {
                    completedJobsMap.put(jobOrder.Ops_Order__c, new Set<Id>());
                }
                completedJobsMap.get(jobOrder.Ops_Order__c).add(jobOrder.Job__c);
            }
            // Jobs expired canceled.
        }

        Map<Id, Decimal> jobOrdPartStatusRank = new Map<Id, Decimal>();
        // Get the OrderedPart of Large Orders through the JobOrder Junction
        for (JobOrderedPart__c jobOrdPart : [
            SELECT Id, Jobid__r.Stage__c, OrderedPartId__r.Ops_Order__c, OrderedPartId__r.Ops_Order__r.ERPStatus__c
            FROM JobOrderedPart__c
            WHERE OrderedPartId__r.Ops_Order__c IN :allOrdParentAndChildIDSet
        ]) {
            Decimal thisjobOrdPartRank = OpsOrderHandler.largeOrderOrderedPartRankCalculator(jobOrdPart, topRank);
            if (jobOrdPartStatusRank.containsKey(jobOrdPart.OrderedPartId__r.Ops_Order__c)) {
                if (thisjobOrdPartRank < jobOrdPartStatusRank.get(jobOrdPart.OrderedPartId__r.Ops_Order__c)) {
                    jobOrdPartStatusRank.put(jobOrdPart.OrderedPartId__r.Ops_Order__c, thisjobOrdPartRank);
                }
            } else {
                jobOrdPartStatusRank.put(jobOrdPart.OrderedPartId__r.Ops_Order__c, thisjobOrdPartRank);
            }
        }

        //Assign new values to all the OpsOrders - both children and parents.
        Map<Id, Integer> opsOrderIdToWorstStatusRank = new Map<Id, Integer>();
        for (Ops_Order__c opsOrd : opsOrderMap.values()) {
            boolean hasParent = false;
            Ops_Order__c parentOrder = null;
            //Transform the Status to Decimal Rankings for Comparison
            System.debug('Time to determine the worstStatus');
            //Null safety check
            Decimal currentOrdStatus = largeOrderRankMap.get(opsOrd.LargeOrderStatus__c);
            Decimal ordWorstStatusRank = (currentOrdStatus != null) ? currentOrdStatus : 1;
            //Safety check the null value to 1 allow no null references
            System.debug('Start of Loop Worst StatusRank: ' + ordWorstStatusRank);
            Decimal parentOrdWorstStatusRank = 1;
            if (opsOrderToParentMap.containsKey(opsOrd.Id)) {
                parentOrder = opsOrderMap.get(opsOrderToParentMap.get(opsOrd.ID));
                parentOrdWorstStatusRank = largeOrderRankMap.get(parentOrder.LargeOrderStatus__c);
                hasParent = true;
            }
            //Check the cases for the Summary Rollup
            if (inProgressCasesMap.containsKey(opsOrd.Id)) {
                Integer caseInProgressSize = inProgressCasesMap.get(opsOrd.ID).size();
                opsOrd.Cases_In_Progress__c += caseInProgressSize;
                if (hasParent == true) {
                    parentOrder.Cases_In_Progress__c += caseInProgressSize;
                }
            }
            if (completedCasesMap.containsKey(opsOrd.Id)) {
                Integer completedCaseInt = completedCasesMap.get(opsOrd.ID).size();
                opsOrd.Cases_Completed__c += completedCaseInt;
                if (hasParent == true) {
                    parentOrder.Cases_Completed__c += completedCaseInt;
                }
            }
            if (inProgressJobsMap.containsKey(opsOrd.Id)) {
                System.debug('InProgressJobsMap contains the Ops Order');
                Integer JobsInProgressSize = inProgressJobsMap.get(opsOrd.ID).size();
                System.debug('Jobs in Progress Size: ' + JobsInProgressSize);
                opsOrd.Jobs_In_Progress__c += JobsInProgressSize;
                if (hasParent == true) {
                    parentOrder.Jobs_In_Progress__c += JobsInProgressSize;
                }
            }
            if (completedJobsMap.containsKey(opsOrd.Id)) {
                Integer completedJobInt = completedJobsMap.get(opsOrd.ID).size();
                opsOrd.Jobs_Completed__c += completedJobInt;
                if (hasParent == true) {
                    parentOrder.Jobs_Completed__c += completedJobInt;
                }
            }
            //Worst of Worst status check
            if (ordCaseStatusRank.containsKey(opsOrd.Id)) {
                Decimal worstCaseRank = ordCaseStatusRank.get(opsOrd.Id);
                if (worstCaseRank < ordWorstStatusRank || (ordWorstStatusRank.intValue() == 1)) {
                    ordWorstStatusRank = worstCaseRank;
                }
                if (hasParent == true) {
                    if (worstCaseRank <= parentOrdWorstStatusRank) {
                        parentOrdWorstStatusRank = worstCaseRank;
                        System.debug('Assigned worst value to map: ' + parentOrdWorstStatusRank);
                        opsOrderIdToWorstStatusRank.put(parentOrder.Id, parentOrdWorstStatusRank.intValue());
                    }
                }
            }
            System.debug('Ord worse status rank (1st time): ' + ordWorstStatusRank);
            if (ordJobStatusRank.containsKey(opsOrd.Id)) {
                Decimal worstJobRank = ordJobStatusRank.get(opsOrd.Id);
                System.debug('Before conditional in job rank');
                System.debug('worstJobRank: ' + worstJobRank);
                //When the DFM case is complete it moves to 2. All Job activity is on 3 and 4 so there was no way to jump beyond 2 without this specific check
                System.debug('Job worst status rank: ' + worstJobRank);
                System.debug('ordWorstStatusRank: ' + ordWorstStatusRank);
                if ((worstJobRank < ordWorstStatusRank) || (ordWorstStatusRank.intValue() == 2)) {
                    ordWorstStatusRank = worstJobRank;
                }
                if (hasParent == true) {
                    if ((worstJobRank <= parentOrdWorstStatusRank) || (ordWorstStatusRank.intValue() >= 3)) {
                        if (parentOrdWorstStatusRank.intValue() >= 2) {
                            System.debug('Lets move higher for the parent');
                            parentOrdWorstStatusRank = worstJobRank;
                        }
                        System.debug('Are we updated parent Order worst status rank?');
                        Integer worstIntheMap = opsOrderIdToWorstStatusRank.get(parentOrder.Id);
                        if (worstJobRank.intValue() < worstIntheMap || worstIntheMap == 2) {
                            opsOrderIdToWorstStatusRank.put(parentOrder.Id, worstJobRank.intValue());
                        }
                    }
                }
            }
            System.debug('Ord worse status rank (2nd time): ' + ordWorstStatusRank);
            if (jobOrdPartStatusRank.containsKey(opsOrd.Id)) {
                Decimal worstJobOrdPartRank = jobOrdPartStatusRank.get(opsOrd.Id);
                System.debug('Ordered Part worst status rank: ' + worstJobOrdPartRank);
                if (worstJobOrdPartRank < ordWorstStatusRank) {
                    ordWorstStatusRank = worstJobOrdPartRank;
                }
                if (hasParent == true) {
                    if (worstJobOrdPartRank <= parentOrdWorstStatusRank) {
                        parentOrdWorstStatusRank = worstJobOrdPartRank;
                        Integer worstIntheMap = opsOrderIdToWorstStatusRank.get(parentOrder.Id);
                        if (parentOrdWorstStatusRank < worstIntheMap) {
                            opsOrderIdToWorstStatusRank.put(parentOrder.Id, parentOrdWorstStatusRank.intValue());
                        }
                    }
                }
            } else {
                //Safety check for OrderedParts-If the map is empty then assume no jobs have made it through the ETL and cap the status at 3 or lower
                //Transform the Decimal Rankings back to Status Values for Ops Order update
                if (3 < ordWorstStatusRank) {
                    ordWorstStatusRank = 3;
                }
                if (hasParent == true) {
                    if (3 < parentOrdWorstStatusRank) {
                        parentOrdWorstStatusRank = 3;
                    }
                }
            }
            if (opsOrd.ERPStatus__c == 'Order Cancelled') {
                ordWorstStatusRank = 4;
                if (hasParent == true) {
                    if (4 < parentOrdWorstStatusRank) {
                        parentOrdWorstStatusRank = 4;
                    }
                }
            }
            //Transform the Decimal to an integer to deal with precision scale errors that were occuring.
            Integer ordWorstStatusRankInteger = ordWorstStatusRank.intValue();
            System.debug('ordWorstStatusRankInteger: ' + ordWorstStatusRankInteger);
            opsOrd.LargeOrderStatus__c = largeOrderStatusRankMap.get(ordWorstStatusRankInteger);
            System.debug('Order Status: ' + opsOrd.LargeOrderStatus__c);
            opsOrderMap.put(opsOrd.Id, opsOrd);
            //System.debug(opsOrd.Id);
            if (hasParent == true) {
                Integer parentOrdWorstStatusRankInteger = parentOrdWorstStatusRank.intValue();
                parentOrder.LargeOrderStatus__c = largeOrderStatusRankMap.get(parentOrdWorstStatusRankInteger);
                System.debug('Parent Order Status: ' + parentOrder.LargeOrderStatus__c);
                opsOrderMap.put(parentOrder.Id, parentOrder);
            }
        }

        System.debug('Ops Order Map before final loop: ' + opsOrderMap.values());
        for (Ops_Order__c oo : opsOrderMap.values()) {
            System.debug('Ops Order in final loop: ' + oo);
            if (opsOrderIdToWorstStatusRank.containsKey(oo.Id)) {
                Integer worstRankFromMap = opsOrderIdToWorstStatusRank.get(oo.Id);
                System.debug('Worst Rank From Map: ' + worstRankFromMap);
                if (worstRankFromMap < largeOrderRankMap.get(oo.LargeOrderStatus__c).intValue()) {
                    System.debug('The worst map had a match');
                    oo.LargeOrderStatus__c = largeOrderStatusRankMap.get(worstRankFromMap);
                    opsOrderMap.put(oo.Id, oo);
                }
                //If the worstrank of all children is a 4 and the current Parent is 2 or greater and has not Jobs then set to the 4
                if (
                    worstRankFromMap == 4 &&
                    largeOrderRankMap.get(oo.LargeOrderStatus__c).intValue() >= 2 &&
                    !ordJobStatusRank.containsKey(oo.Id)
                ) {
                    System.debug('We are in our new logic section');
                    oo.LargeOrderStatus__c = largeOrderStatusRankMap.get(worstRankFromMap);
                    opsOrderMap.put(oo.Id, oo);
                }
            }
        }
        DatabaseUtilities.saveToDatabase(
            opsOrderMap.values(),
            'OpsOrder.updateLargeOrderSummary',
            'Ops Order Status/Rollups did not update'
        );
    }
    /**
     * @description creates a map of new Large Orders
     * @param newOpsOrdersList List of Ops Orders to be inserted
     * @param oldOpsOrderMap Map of Ops Orders values before update
     */
    public static Map<Id, Ops_Order__c> getLargeOrderMap(
        List<Ops_Order__c> newOpsOrderList,
        Map<Id, Ops_Order__c> oldOpsOrderMap
    ) {
        Map<Id, Ops_Order__c> newLargeOrdersMap = new Map<Id, Ops_Order__c>();
        for (Ops_Order__c oo : newOpsOrderList) {
            Boolean cond1 = Trigger.isInsert && oo.Is_Large_Order__c;
            Boolean cond2 =
                Trigger.isUpdate &&
                oo.Is_Large_Order__c &&
                (oo.Is_Large_Order__c != oldOpsOrderMap.get(oo.Id).Is_Large_Order__c);
            if (cond1 || cond2) {
                newLargeOrdersMap.put(oo.Id, oo);
            }
        }
        return newLargeOrdersMap;
    }
}