public with sharing class OpsOrderHandler {
    static final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('DFM_Case')
        .getRecordTypeId();

    static final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('CaseMgmt')
        .getRecordTypeId();

    /**
     * @description associates Ops Orders to Opportunities
     * @param newOpsOrderList
     */
    public static void associateOpportunity(List<Ops_Order__c> newOpsOrderList) {
        Set<String> orderIdSet = new Set<String>();
        for (Ops_Order__c oo : newOpsOrderList) {
            if (oo.Opportunity__c == null && !String.isBlank(oo.XometryOpsOrderID__C))
                orderIdSet.add(oo.XometryOpsOrderID__c);
        }

        if (!orderIdSet.isEmpty()) {
            Map<String, Id> orderIdToOppIdMap = new Map<String, Id>();

            for (Opportunity opp : [
                SELECT Id, Order_ERP_Xom_ID__c
                FROM Opportunity
                WHERE Order_ERP_Xom_ID__c IN :orderIdSet
            ]) {
                orderIdToOppIdMap.put(opp.Order_ERP_Xom_ID__c, opp.Id);
            }

            for (Ops_Order__C oo : newOpsOrderList) {
                if (orderIdToOppIdMap.containsKey(oo.XometryOpsOrderID__c)) {
                    oo.Opportunity__c = orderIdToOppIdMap.get(oo.XometryOpsOrderID__c);
                }
            }
        }
    }

    /**
     * @description When an Ops Order is Created. Create the Large Order case if it meets criteria.
     * @param newOpsOrderList
     * @param oldOpsOrderMap map of Ops Orders before update
     */
    public static void createPendingDFMCase(List<Ops_Order__c> newOpsOrderList, Map<Id, Ops_Order__c> oldOpsOrderMap) {
        Map<Id, Ops_Order__c> newLargeOrdersMap = largeOrderHelper.getLargeOrderMap(newOpsOrderList, oldOpsOrderMap);
        if (!newLargeOrdersMap.isEmpty()) {
            //We don’t want this to work if a Large Order Case is already linked to the Opps Order.
            Set<Id> casesWithLargeOrderSet = new Set<Id>();
            for (Case caseLargeOrder : [
                SELECT Id, GNOOrder__c, ParentOpsOrder__c
                FROM Case
                WHERE
                    GNOOrder__c IN :newLargeOrdersMap.keySet()
                    AND Type = 'Large Order Review'
                    AND RecordTypeId = :caseDFMRTypeId
            ]) {
                casesWithLargeOrderSet.add(caseLargeOrder.GNOOrder__c);
            }

            Map<String, Id> queueMap = new Map<String, Id>();

            for (Group queueGroup : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']) {
                queueMap.put(queueGroup.DeveloperName, queueGroup.Id);
            }

            Map<String, BusinessHours> hoursMap = new Map<String, BusinessHours>();
            for (BusinessHours bHours : [SELECT Id, Name, MondayEndTime FROM BusinessHours]) {
                hoursMap.put(bHours.Name, bHours);
            }

            List<Case> caseToInsertList = new List<Case>();

            for (Ops_Order__C oo : newLargeOrdersMap.values()) {
                if (!casesWithLargeOrderSet.contains(oo.Id)) {
                    Case newCase = new Case();
                    newCase.GNOOrder__c = oo.Id;
                    NewCase.Type = 'Large Order Review';
                    if (!String.isBlank(oo.ParentOpsOrder__c)) {
                        newCase.ParentOpsOrder__c = oo.ParentOpsOrder__c;
                    }
                    newCase.Opportunity__c = oo.Opportunity__c;
                    newCase.Subject = oo.XometryOpsOrderID__c + ' Large Order DFM Review';
                    newCase.Status = 'New';
                    newCase.OwnerId = newLargeOrdersMap.get(oo.Id).POD__c != null &&
                        queueMap.containsKey(newLargeOrdersMap.get(oo.Id).POD__c.replace(' ', '_'))
                        ? queueMap.get(newLargeOrdersMap.get(oo.Id).POD__c.replace(' ', '_'))
                        : queueMap.get('First_Impressions');
                    newCase.RecordTypeId = caseDFMRTypeId;
                    newCase.BusinessHoursId = hoursMap.get('POD Business Hours - EST').Id;
                    caseToInsertList.add(newCase);
                }
            }

            DatabaseUtilities.insertToDatabase(
                caseToInsertList,
                'OpsOrderHandler.createLargeOrderCase',
                'Creating Large Order Case'
            );

            /*if(!caseToInsertList.isEmpty()){
                Id jobId = System.enqueueJob(new CaseProcessLargeOrder(caseToInsertList));
            }*/
        }
    }

    public static void createCaseOpsOrderJunction(
        List<Ops_Order__c> newOpsOrderList,
        Map<Id, Ops_order__c> oldOpsOrderMap
    ) {
        Map<String, Ops_Order__c> opsOrderByPONumber = new Map<String, Ops_Order__c>();
        Set<String> orderIdSet = new Set<String>();
        for (Ops_Order__c oo : newOpsOrderList) {
            Boolean cond1 = Trigger.isInsert && !String.isBlank(oo.PONumber__c);
            Boolean cond2 =
                Trigger.isUpdate &&
                !String.isBlank(oo.PONumber__c) &&
                oo.PONumber__c != oldOpsOrderMap.get(oo.Id).PONumber__c;
            if (cond1 || cond2) {
                opsOrderByPONumber.put(oo.PONumber__c, oo);
                orderIdSet.add(oo.XometryOpsOrderID__c);
            }
        }
        if (!opsOrderByPONumber.isEmpty()) {
            Map<String, List<Case>> caseByPONumber = new Map<String, List<Case>>();
            Set<Id> caseIdSet = new Set<Id>();
            for (Case thisCase : [
                SELECT Id, CaseNumber, PO_Number__c
                FROM Case
                WHERE PO_Number__c IN :opsOrderByPONumber.keySet()
            ]) {
                caseIdSet.add(thisCase.Id);
                if (caseByPONumber.containsKey(thisCase.PO_Number__c)) {
                    caseByPONumber.get(thisCase.PO_Number__c).add(thisCase);
                } else {
                    caseByPONumber.put(thisCase.PO_Number__c, new List<Case>{ thisCase });
                }
            }

            Map<String, List<CaseOpsOrder__c>> existingCaseOpsOrderJunction = new Map<String, List<CaseOpsOrder__c>>();
            for (CaseOpsOrder__c coo : [
                SELECT CaseOpsOrderKey__c
                FROM CaseOpsOrder__c
                WHERE (Case__c IN :caseIdSet OR Xometry_Order_ID__c IN :orderIdSet) AND Case__r.PO_Number__c != NULL
            ]) {
                if (!existingCaseOpsOrderJunction.containsKey(coo.CaseOpsOrderKey__c)) {
                    existingCaseOpsOrderJunction.put(coo.CaseOpsOrderKey__c, new List<CaseOpsOrder__c>{ coo });
                } else {
                    existingCaseOpsOrderJunction.get(coo.CaseOpsOrderKey__c).add(coo);
                }
            }

            List<CaseOpsOrder__c> caseOpsOrderToCreateList = new List<CaseOpsOrder__c>();
            for (Ops_Order__c oo : newOpsOrderList) {
                if (!String.isBlank(oo.PONumber__c)) {
                    if (caseByPONumber.containsKey(oo.PONumber__c)) {
                        for (Case thisCase : caseByPONumber.get(oo.PONumber__c)) {
                            String uKey = oo.XometryOpsOrderID__c + ' : ' + thisCase.CaseNumber;
                            if (!existingCaseOpsOrderJunction.containsKey(uKey)) {
                                CaseOpsOrder__c caseOrder = new CaseOpsOrder__c();
                                caseOrder.Case__c = thisCase.Id;
                                caseOrder.CaseOpsOrderKey__c = uKey;
                                caseOrder.Ops_Order__c = oo.Id;
                                caseOpsOrderToCreateList.add(caseOrder);
                            }
                        }
                    }
                }
            }

            DatabaseUtilities.insertToDatabase(
                caseOpsOrderToCreateList,
                'OpsOrder.createCaseOpsOrderJunction',
                'CaseOpsOrder failed to create'
            );
        }
    }

    //Supporting Message to determine how where a Job is in the pipeline affects a large order

    /*
     * @description For a given Case returns the StatusRank of that Case for how it relates to the Large Order Status
     * @param decisionCase the case that is evaluated to determine its rank effect on a Large Order
     * topRank The Highest StatusRank__C value from Large_Order_Status_Rank__mdt  This value is passed into to avoid repeated SOQL calls
     *
     */
    public static Decimal largeOrdercaseRankCalculator(Case decisionCase, Decimal topRank) {
        //Assume the Case Rank is the highest and the revaluate
        Decimal caseRank = topRank;
        if (decisionCase.RecordTypeId == caseDFMRTypeId && decisionCase.Type == 'Large Order Review') {
            if (decisionCase.isClosed == false) {
                caseRank = 1;
            } else {
                caseRank = 2;
            }
        }
        if (decisionCase.RecordTypeId == caseManagementRTypeId && decisionCase.Type == 'Technical Review') {
            if (decisionCase.isClosed == false) {
                caseRank = 3;
            } else {
                caseRank = 4;
            }
        }
        if (decisionCase.GNOOrder__r.ERPStatus__c == 'Order Cancelled') {
            caseRank = 4;
        }
        return caseRank;
    }

    /*
     * @description For a given JobOrder JobOrderedPart__c the StatusRank of that JobOrderedPart for how it relates to the Large Order Status
     * @param decisionJobOrderedPart the JobOrderedPart__c that is evaluated to determine its rank effect on a Large Order
     * topRank The Highest StatusRank__C value from Large_Order_Status_Rank__mdt  This value is passed into to avoid repeated SOQL calls
     *
     */

    public static Decimal largeOrderOrderedPartRankCalculator(
        JobOrderedPart__c decisionJobOrderedPart,
        Decimal topRank
    ) {
        //Assume the Job Rank is the highest and revaluate
        Decimal orderedPartRank = topRank;

        //We need a way to see if the Job is Accepted or
        Set<String> passedJobStatusSet = new Set<String>{
            'Accepted',
            'Vendor Completed',
            'Completed',
            'Cancelled',
            'Expired',
            'Rejected',
            'Rescinded'
        };
        if (passedJobStatusSet.contains(decisionJobOrderedPart.Jobid__r.Stage__c)) {
            orderedPartRank = 4;
        } else {
            orderedPartRank = 3;
        }
        if (decisionJobOrderedPart.OrderedPartId__r.Ops_Order__r.ERPStatus__c == 'Order Cancelled') {
            orderedPartRank = 4;
        }
        return orderedPartRank;
    }

    /*
     * @description For a given JobOrder returns the StatusRank of that JobOrder for how it relates to the Large Order Status
     * @param decisionJob the Job_Order__c that is evaluated to determine its rank effect on a Large Order
     * topRank The Highest StatusRank__C value from Large_Order_Status_Rank__mdt  This value is passed into to avoid repeated SOQL calls
     *
     */

    public static Decimal largeOrderJobRankCalculator(Job_Order__c decisionJob, Decimal topRank) {
        //Assume the Job Rank is the highest and revaluate
        Decimal jobRank = topRank;
        Set<String> passedJobStatusSet = new Set<String>{ 'Technical Review Complete', 'No Technical Review Required' };
        if (passedJobStatusSet.contains(decisionJob.Job__r.Technical_Review_Status__c)) {
            jobRank = 4;
        } else {
            jobRank = 3;
        }
        if (decisionJob.Ops_Order__r.ERPStatus__c == 'Order Cancelled') {
            jobRank = 4;
        }
        return jobRank;
    }

    /**
     *  @param opsOrderIds a Set of Ids for opsOrders that need to be updated
     *
     *
     */
    @future
    public static void updateLargeOrderSummary(Set<Id> opsOrderIdSet) {
        largeOrderHelper.updateLargeOrderSummaryRT(opsOrderIdSet);
    }

    /*
     * @description Updates Job Technical Review Status when the Ops Order
     * Is classified as a large order
     * @param newOpsOrderList list of ops orders being inserted or updated
     * @param oldOpsOrderMap map of ops orders before update
     */
    public static void updateJobTechReviewStatus(
        List<Ops_Order__c> newOpsOrderList,
        Map<Id, Ops_Order__c> oldOpsOrderMap
    ) {
        Map<Id, Ops_Order__c> newLargeOrdersMap = largeOrderHelper.getLargeOrderMap(newOpsOrderList, oldOpsOrderMap);

        if (newLargeOrdersMap.size() > 0) {
            Id jobId = System.enqueueJob(new UpdateJobReviewStatus(newLargeOrdersMap));
        }
    }
    /**
     * @description set's large Order status when and Ops Order is Large Order
     *
     */
    public static void setLargeOrderStatus(List<Ops_Order__c> newOpsOrderList, Map<Id, Ops_Order__c> oldOpsOrderMap) {
        for (Ops_Order__c oo : newOpsOrderList) {
            Boolean isInsert = Trigger.isInsert && oo.Is_Large_Order__c;
            Boolean becomesLargeOrder =
                Trigger.isUpdate &&
                oo.Is_Large_Order__c &&
                oo.Is_Large_Order__c != oldOpsOrderMap.get(oo.Id).Is_Large_Order__c;
            Boolean isCancelled =
                oo.Is_Large_Order__c &&
                oo.ERPStatus__c == 'Order Cancelled' &&
                (Trigger.isInsert || (Trigger.isUpdate && oo.ERPStatus__c != oo.ERPStatus__c));
            System.debug('SET STATUS!');
            System.debug(oo.LargeOrderStatus__c);
            if ((isInsert || becomesLargeOrder) && String.isBlank(oo.LargeOrderStatus__c)) {
                System.debug('Setting the Status');
                oo.LargeOrderStatus__c = 'DFM-Pending Review';
            }
            if (isCancelled) {
                oo.LargeOrderStatus__c = 'Large Order Review Process Complete';
            }
        }
    }

    /**
     * @description Sets the Order_Overdue_Flag__c on insert/update of the OrderDueDate__c
     * so that the Order_is_Past_Due__c is right before the batch runs
     * @param newOrdersList List of Orders to be inserted
     */
    public static void setOverdueFlag(List<Ops_Order__c> newOrdersList, Map<ID, Ops_Order__c> oldOrderMap) {
        List<Ops_Order__c> ordersToUpdateList = new List<Ops_Order__c>();

        for (Ops_Order__c order : newOrdersList) {
            Boolean hasDueDate = order.OrderDueDate__c != null;
            Boolean opsOrderIsInProgress =
                order.ERPStatus__c == null || !AppConstants.OPS_ORDER_COMPLETED_STATUSES.contains(order.ERPStatus__c);
            Boolean newOpsorder = Trigger.isInsert;
            Boolean updatedDueDate =
                Trigger.isUpdate && order.OrderDueDate__c != oldOrderMap.get(order.Id).OrderDueDate__c;

            if (hasDueDate && opsOrderIsInProgress && (newOpsorder || updatedDueDate)) {
                ordersToUpdateList.add(order);
            }
        }

        if (!ordersToUpdateList.isEmpty()) {
            Date dToday = System.today();
            Admin_Ref_Variable__mdt orderShipTminusRecord = [
                SELECT Number_Ref_Value__c
                FROM Admin_Ref_Variable__mdt
                WHERE Label = 'orderShipTminus'
            ];
            Integer orderShipTminus = Integer.valueOf(orderShipTminusRecord.Number_Ref_Value__c) * -1;

            for (Ops_Order__c oo : ordersToUpdateList) {
                oo.Order_OverDue_Flag__c = oo.OrderDueDate__c.daysBetween(dToday);
                if (!oo.Order_Close_to_Ship__c && (oo.Order_OverDue_Flag__c >= orderShipTminus)) {
                    oo.Order_Close_to_Ship__c = true;
                }
            }
        }
    }

    /**
     * @description stamps with Ops Order with attributes from other objects at the time
     * An Ops Order gets its data from the Order ERP object
     * @param newOpsOrderList List of Order objects that were just inserted or updated
     * @param oldOrderMap map of orders changed by the update
     */

    public static void stampOpsOrder(list<Ops_Order__c> newOpsOrderList, Map<Id, Ops_Order__c> oldOpsOrderMap) {
        String top20Account = 'Top 20 Account';
        String topQualityAccount = 'Top Quality Account';
        String accountCustServLevel = 'Account Customer Service Level';

        Set<String> opsOrderIDSet = new Set<String>();
        Map<String, Map<String, Boolean>> accountToOpsFlagsMap = new Map<String, Map<String, Boolean>>();
        Map<String, String> accountToCustServLevelMap = new Map<String, String>();

        for (Ops_Order__c oo : newOpsOrderList) {
            Boolean opOrderCreatedFromOrder = Trigger.isInsert && oo.Account_Domain__c != null;
            Boolean opsOrderJustAssociated =
                Trigger.isUpdate &&
                oo.Account_Domain__c != null &&
                oldOpsOrderMap.get(oo.ID).Account_Domain__c == null;
            if (opOrderCreatedFromOrder || opsOrderJustAssociated) {
                opsOrderIDSet.add(oo.XometryOpsOrderID__c);
                if (!accountToOpsFlagsMap.containsKey(oo.Account_Domain__c)) {
                    accountToOpsFlagsMap.put(oo.Account_Domain__c, new Map<String, Boolean>());
                }
            }
        }

        if (!opsOrderIDSet.isEmpty()) {
            for (Account a : [
                SELECT
                    ID,
                    Email_Domain__c,
                    Ops_Top_20_Customer__c,
                    Ops_Top_Quality_Customer__c,
                    Ops_CustomerServiceLevel__c
                FROM Account
                WHERE Email_Domain__c IN :accountToOpsFlagsMap.keySet()
            ]) {
                if (a.Ops_Top_20_Customer__c || a.Ops_Top_Quality_Customer__c) {
                    accountToOpsFlagsMap.get(a.Email_Domain__c).put(top20Account, a.Ops_Top_20_Customer__c);
                    accountToOpsFlagsMap.get(a.Email_Domain__c).put(topQualityAccount, a.Ops_Top_Quality_Customer__c);
                }
                if (a.Ops_CustomerServiceLevel__c != null) {
                    accountToCustServLevelMap.put(a.Email_Domain__c, a.Ops_CustomerServiceLevel__c);
                }
            }

            for (Ops_Order__c oo : newOpsOrderList) {
                if (oo.Account_Domain__c != null) {
                    Boolean opsAccountFlagUpdate = false;
                    if (accountToOpsFlagsMap.containsKey(oo.Account_Domain__c)) {
                        opsAccountFlagUpdate = !accountToOpsFlagsMap.get(oo.Account_Domain__c).isEmpty();
                    }
                    Boolean opsAccountServiceLevelUpdate = accountToCustServLevelMap.containsKey(oo.Account_Domain__c);
                    if (opsOrderIDSet.contains(oo.XometryOpsOrderID__C)) {
                        if (opsAccountFlagUpdate) {
                            oo.Ops_Top20Customer__c = accountToOpsFlagsMap.get(oo.Account_Domain__c).get(top20Account);
                            oo.Ops_TopQualityCustomer__c = accountToOpsFlagsMap.get(oo.Account_Domain__c)
                                .get(topQualityAccount);
                        }
                        if (opsAccountServiceLevelUpdate) {
                            oo.Ops_AccountCustomerServiceLevel__c = accountToCustServLevelMap.get(oo.Account_Domain__c);
                        }
                    }
                }
            }
        }
    }

    /**
     * @description created an Order Event record when Asana criteria are met
     * @param newOpsOrderList List of Order objects that were just inserted or updated
     * @param oldOrderMap map of orders changed by the update
     */
    public static void orderEventConditionals(
        list<Ops_Order__c> newOpsOrderList,
        Map<Id, Ops_Order__c> oldOpsOrderMap
    ) {
        Set<ID> opsOrderRecordIDSet = new Set<ID>();
        Set<String> ordersToEvaluate = new Set<String>();
        Boolean anyMQOrders = false;

        for (Ops_Order__c oo : newOpsOrderList) {
            if (oo.ERPStatus__c != null) {
                ordersToEvaluate.add(oo.XometryOpsOrderID__c);
            }
            if (oo.QuoteType__c != null && oo.QuoteType__c.toLowercase() == 'manually-quoted') {
                anyMQOrders = true;
            }
        }

        Decimal mqThreshold = 0;
        if (anyMQOrders) {
            mqThreshold = [
                SELECT ID, DeveloperName, Currency_Ref_Value__c
                FROM Event_Threshold__mdt
                WHERE DeveloperName = 'order_MQEventQualAmount'
            ]
            .Currency_Ref_Value__c;
        }

        //Map<OrderID, Map<processGroup, Map<Type, isCriteria?>>>
        //For each order, we first add in the processGroup if the order has any qualifying events for that group
        //Process Groups: All, Subtractive Only or Mixed, Additive Only)
        //For each processGroup, we add in the event types and if that event qualifies as creation criteria
        //Type examples: POD, Last Additive Order, Created in ERP
        Map<String, Map<String, Map<String, Boolean>>> orderIDToCriteriaMap = new Map<String, Map<String, Map<String, Boolean>>>();

        //orderID map to reference by orderID for Bad Outcomes SubTypes
        Map<String, Ops_Order__c> orderIDtoOpsOrderMap = new Map<String, Ops_Order__c>();
        for (Ops_Order__c oo : newOpsOrderList) {
            String orderID = oo.XometryOpsOrderID__c;
            String processGroup = '';
            String currentEventType = '';
            orderIDtoOpsOrderMap.put(orderID, oo);

            orderIDToCriteriaMap.put(orderID, new Map<String, Map<String, Boolean>>());

            Boolean triggeredFromERP = false;
            if (oo.AsanaERPFlag__c) {
                if (Trigger.isInsert || (Trigger.isUpdate && !oldOpsOrderMap.get(oo.Id).AsanaERPFlag__c)) {
                    triggeredFromERP = true;
                }
            }

            Boolean partiallyShipped = false;
            if (oo.ERPStatus__c != null && oo.ERPStatus__c == 'Partially Shipped') {
                if (
                    Trigger.isInsert ||
                    (Trigger.isUpdate &&
                    (oldOpsOrderMap.get(oo.ID).ERPStatus__c == null ||
                    oldOpsOrderMap.get(oo.ID).ERPStatus__c != 'Partially Shipped'))
                ) {
                    partiallyShipped = true;
                }
            }

            Boolean fullyShipped = false;
            if (oo.ERPStatus__c != null && AppConstants.OPS_ORDER_COMPLETED_STATUSES.contains(oo.ERPStatus__c)) {
                if (
                    Trigger.isInsert ||
                    (Trigger.isUpdate &&
                    (oldOpsOrderMap.get(oo.ID).ERPStatus__c == null ||
                    !AppConstants.OPS_ORDER_COMPLETED_STATUSES.contains(oldOpsOrderMap.get(oo.ID).ERPStatus__c)))
                ) {
                    fullyShipped = true;
                }
            }

            Boolean badOutcomes = false;
            if (
                !string.isBlank(oo.bad_Outcomes_Manage_Result__c) &&
                !string.isBlank(oo.Bad_Outcomes_Daily_Tier__c) &&
                oo.bad_Outcomes_Manage_Result__c != 'Daily Score Not Calculated Yet'
            ) {
                if (
                    Trigger.isInsert ||
                    (Trigger.isUpdate &&
                    (oldOpsOrderMap.get(oo.Id).bad_Outcomes_Manage_Result__c == 'Daily Score Not Calculated Yet' ||
                    string.isblank(oldOpsOrderMap.get(oo.Id).bad_Outcomes_Manage_Result__c)))
                ) {
                    badOutcomes = true;
                }
            }

            if (triggeredFromERP || partiallyShipped || fullyShipped || badOutcomes) {
                //All orders qualify for these events, regardless of process group
                processGroup = 'All';
                orderIDToCriteriaMap.get(orderID).put(processGroup, new Map<String, Boolean>());
                if (badOutcomes) {
                    System.debug('We have Bad Outcome record to create');
                    currentEventType = 'Bad Outcomes - Order Bad Outcome';
                    String badOutcomeTier = oo.Bad_Outcomes_Daily_Tier__c;
                    // All bad outcomes create an Order Event even ones that are Low. Low badoutcomes do not qualify initial criteria
                    orderIDToCriteriaMap.get(orderId)
                        .get(processGroup)
                        .put(currentEventType, OpsEventsHelper.BAD_OUTCOMES_ORDER_SUBTYPE_CRITERIA.get(badOutcomeTier));
                }
                if (triggeredFromERP) {
                    currentEventType = 'Created in ERP';
                    orderIDToCriteriaMap.get(orderID)
                        .get(processGroup)
                        .put(currentEventType, OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType));
                }
                if (partiallyShipped) {
                    currentEventType = 'Partially Shipped';
                    orderIDToCriteriaMap.get(orderID)
                        .get(processGroup)
                        .put(currentEventType, OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType));
                }
                if (fullyShipped) {
                    currentEventType = 'Fully Shipped';
                    orderIDToCriteriaMap.get(orderID)
                        .get(processGroup)
                        .put(currentEventType, OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType));
                }
            }

            Boolean containsSubtractivePart = oo.processGroup_isSubtractiveOnly__c || oo.processGroup_isMixed__c;
            Boolean additiveOnly = oo.processGroup_isAdditiveOnly__c;

            if (containsSubtractivePart) {
                processGroup = 'Subtractive Only or Mixed';
                orderIDToCriteriaMap.get(orderID).put(processGroup, new Map<String, Boolean>());

                Boolean podOrder = false;
                if (oo.POD__c != null) {
                    if (Trigger.isInsert || (Trigger.isUpdate && oldOpsOrderMap.get(oo.ID).POD__c == null)) {
                        podOrder = true;
                        currentEventType = 'POD';
                        orderIDToCriteriaMap.get(orderID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }

                Boolean tMinusTracking = false;
                if (oo.Order_Close_to_Ship__c) {
                    if (Trigger.isInsert || (Trigger.isUpdate && !oldOpsOrderMap.get(oo.ID).Order_Close_to_Ship__c)) {
                        tMinusTracking = true;
                        currentEventType = 'T- Days Out';
                        orderIDToCriteriaMap.get(orderID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }

                Boolean lateSubtractiveOrder = false;
                if (oo.Order_OverDue_Flag__c != null && oo.Order_OverDue_Flag__c > 0) {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate &&
                        (oldOpsOrderMap.get(oo.Id).Order_OverDue_Flag__c == null ||
                        oldOpsOrderMap.get(oo.Id).Order_OverDue_Flag__c <= 0))
                    ) {
                        lateSubtractiveOrder = true;
                        currentEventType = 'Subtractive & Past Due';
                        orderIDToCriteriaMap.get(orderID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }

                Boolean customFinishMQ = false;
                if (
                    oo.QuoteType__c != null &&
                    oo.QuoteType__c.toLowerCase() == 'manually-quoted' &&
                    oo.ContainsCustomFinish__c
                ) {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate &&
                        (!oldOpsOrderMap.get(oo.ID).ContainsCustomFinish__c ||
                        oldOpsOrderMap.get(oo.ID).QuoteType__c == null ||
                        oo.QuoteType__c.toLowercase() != 'manually-quoted'))
                    ) {
                        customFinishMQ = true;
                        currentEventType = 'MQ w/ Custom Finish';
                        orderIDToCriteriaMap.get(orderID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }

                Boolean highValueMQ = false;
                if (
                    oo.QuoteType__c != null &&
                    oo.QuoteType__c.toLowercase() == 'manually-quoted' &&
                    oo.OrderTotal__c >= mqThreshold
                ) {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate &&
                        (oldOpsOrderMap.get(oo.ID).OrderTotal__c == null ||
                        oldOpsOrderMap.get(oo.ID).OrderTotal__c < mqThreshold ||
                        oldOpsOrderMap.get(oo.ID).QuoteType__c == null ||
                        oo.QuoteType__c.toLowercase() != 'manually-quoted'))
                    ) {
                        highValueMQ = true;
                        currentEventType = 'MQ > $ Threshold';
                        orderIDToCriteriaMap.get(orderID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }

                Boolean expeditedOrder = false;
                if (oo.PricingTier__c != null && oo.PricingTier__c.toLowerCase() == 'expedited') {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate &&
                        (oldOpsOrderMap.get(oo.ID).PricingTier__c == null ||
                        oldOpsOrderMap.get(oo.ID).PricingTier__c.toLowerCase() != 'expedited'))
                    ) {
                        expeditedOrder = true;
                        currentEventType = 'Expedited';
                        orderIDToCriteriaMap.get(orderID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }

                Boolean top20Customer = false;
                if (oo.Ops_Top20Customer__c) {
                    if (Trigger.isInsert || (Trigger.isUpdate && !oldOpsOrderMap.get(oo.Id).Ops_Top20Customer__c)) {
                        top20Customer = true;
                        currentEventType = 'Top 20 Customer';
                        orderIDToCriteriaMap.get(orderID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }
            } else {
                processGroup = 'Additive Only';
                orderIDToCriteriaMap.get(orderID).put(processGroup, new Map<String, Boolean>());

                Boolean lateAdditiveOrder = false;
                if (oo.Order_OverDue_Flag__c != null && oo.Order_OverDue_Flag__c > 0) {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate &&
                        (oldOpsOrderMap.get(oo.Id).Order_OverDue_Flag__c == null ||
                        oldOpsOrderMap.get(oo.Id).Order_OverDue_Flag__c <= 0))
                    ) {
                        lateAdditiveOrder = true;
                        currentEventType = 'Additive Only & Past Due';
                        orderIDToCriteriaMap.get(orderID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }
            }
        }

        if (!orderIDToCriteriaMap.isEmpty()) {
            List<Order_Event__c> orderEventsList = new List<Order_Event__c>();

            for (Ops_Order__c oo : newOpsOrderList) {
                if (!orderIDToCriteriaMap.get(oo.XometryOpsOrderID__c).isEmpty()) {
                    String orderID = oo.XometryOpsOrderID__c;
                    for (String processGroup : orderIDToCriteriaMap.get(orderID).keySet()) {
                        if (!orderIDToCriteriaMap.get(orderID).get(processGroup).isEmpty()) {
                            for (String criteriaType : orderIDToCriteriaMap.get(orderID).get(processGroup).keySet()) {
                                String subType = null;
                                if (criteriaType == 'Bad Outcomes - Order Bad Outcome') {
                                    String badOutcomeTier = orderIDtoOpsOrderMap.get(orderID)
                                        .Bad_Outcomes_Daily_Tier__c;
                                    subType = !String.isBlank(badOutcomeTier) ? badOutcomeTier : null;
                                }
                                Boolean isCriteria = orderIDToCriteriaMap.get(orderID)
                                    .get(processGroup)
                                    .get(criteriaType);
                                orderEventsList.add(
                                    createOrderEvent(oo.ID, orderId, criteriaType, subType, processGroup, isCriteria)
                                );
                            }
                        }
                    }
                }
            }

            if (!orderEventsList.isEmpty()) {
                DatabaseUtilities.insertToDatabase(
                    orderEventsList,
                    'OpsOrderHandler.orderEventConditionals',
                    'Order Events were not inserted'
                );
            }
            OpsEventsHelper.readyToEvaluate(ordersToEvaluate);
        }
    }

    /**
     * @description createOrderEvents
     * @param  ID opsOrderRecordID
     * @param  String xomOrderID
     * @param  String eventType
     * @param  String processGroup
     * @param  Boolean criteria
     */
    public static Order_Event__c createOrderEvent(
        ID opsOrderRecordID,
        String xomOrderID,
        String eventType,
        String subType,
        String processGroup,
        Boolean criteria
    ) {
        Order_Event__c oe = new Order_Event__c();
        oe.Name = xomOrderID + ' - ' + eventType;
        oe.Ops_Order__c = opsOrderRecordID;
        oe.OrderID__c = xomOrderID;
        oe.Type__c = eventType;
        oe.Sub_Type__c = subType;
        oe.Qualifying_Object__c = 'Order';
        oe.Process_Group__c = processGroup;
        oe.Criteria__c = criteria;

        return oe;
    }
}