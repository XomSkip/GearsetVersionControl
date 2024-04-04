public with sharing class orderedPartHandler {
    /**
     * @description Populates the Ops Order SFID on Ordered Parts
     * @param newOrderedPartList List of Ordered Parts to be inserted
     */
    public static void processOrderedParts(List<Ordered_Part__c> newOrderedPartList) {
        set<String> xomOrderIDSet = new Set<String>();
        //Unique_Ordered_Part_ID__c
        for (Ordered_Part__c op : newOrderedPartList) {
            xomOrderIDSet.add(op.Xometry_Order_ID__c);
        }

        Map<String, Ops_Order__c> existingOpsOrderMap = new Map<String, Ops_Order__c>();
        for (Ops_Order__c opsOrd : [
            SELECT ID, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c IN :xomOrderIDSet
        ]) {
            existingOpsOrderMap.put(opsOrd.XometryOpsOrderID__c, opsOrd);
        }

        List<Ordered_Part__c> needOpsOrderOPartList = new List<Ordered_Part__c>();
        Set<String> opsOrderCreateSet = new Set<String>();
        for (Ordered_Part__c op : newOrderedPartList) {
            if (existingOpsOrderMap.containskey(op.Xometry_Order_ID__c)) {
                op.Ops_Order__c = existingOpsOrderMap.get(op.Xometry_Order_ID__c).ID;
            } else {
                needOpsOrderOPartList.add(op);
                opsOrderCreateSet.add(op.Xometry_Order_ID__C);
            }
        }
        Map<String, Ops_Order__c> opsOrdersToCreateMap = new Map<String, Ops_Order__c>();
        for (String xomOrderID : opsOrderCreateSet) {
            Ops_Order__c newOpsOrder = new Ops_Order__c();
            newOpsOrder.Name = xomOrderID;
            newOpsOrder.XometryOpsOrderID__c = xomOrderID;
            opsOrdersToCreateMap.put(xomOrderID, newOpsOrder);
        }

        DatabaseUtilities.insertToDatabase(
            opsOrdersToCreateMap.values(),
            'orderedPartHandler.processOrderedParts',
            'Did not create Ops Orders for Ordered Parts'
        );

        for (Ordered_Part__c op : needOpsOrderOPartList) {
            if (opsOrdersToCreateMap.containsKey(op.Xometry_Order_ID__c)) {
                op.Ops_Order__c = opsOrdersToCreateMap.get(op.Xometry_Order_ID__c).ID;
            }
        }
    }
    public static void checkOrderedPartsForLargeOrderSummary(List<Ordered_Part__C> newOrderedPartList) {
        if (!EventBusBypass.isByPassed(largeOrderHelper.ordPartByPass)) {
            Set<ID> orderedPartIDSet = new Set<ID>();
            for (Ordered_Part__C ordPart : newOrderedPartList) {
                orderedPartIDSet.add(ordPart.Id);
            }
            Set<Id> opsOrderToSumIdSet = JobOrderedPartHandler.orderedPartPartofLargeOrderandOnJob(orderedPartIDSet);
            //If we are coming from the JobHandler then the bypass should be on and we can skip this as the jobhandler will handle the summary update
            OpsOrderHandler.updateLargeOrderSummary(opsOrderToSumIdSet);
        }
    }

    /**
     * @description Populates the Ordered Part Production Type(s) on Cases related to Ordered Parts
     * @param newOrderedPartList List of Ordered Parts to be inserted
     */
    public static void fillProductTypes(List<Ordered_Part__C> newOrderedPartList) {
        Map<String, Set<String>> orderedPartsMap = new Map<String, Set<String>>();
        for (Ordered_Part__c ordPart : newOrderedPartList) {
            if (ordPart.EUD_ProductionType__c != null) {
                if (!orderedPartsMap.containskey(ordPart.Xometry_Order_ID__c)) {
                    orderedPartsMap.put(ordPart.Xometry_Order_ID__c, new Set<String>());
                }
                orderedPartsMap.get(ordPart.Xometry_Order_ID__c).add(ordPart.EUD_ProductionType__c.toLowerCase());
            }
        }

        if (!orderedPartsMap.isEmpty()) {
            List<Case> casesToUpdate = new List<Case>();
            for (Case oneCase : [
                SELECT ShadowXometryOrderID__c, EUD_ProductionType__c
                FROM Case
                WHERE Category__c = 'End-use definition' AND ShadowXometryOrderID__c IN :orderedPartsMap.keySet()
            ]) {
                List<String> newProductionTypeList = new List<String>();
                //keep current EUD_ProductionType__c value on case
                //the result always use same order : Production, Prototype
                if (
                    orderedPartsMap.get(oneCase.ShadowXometryOrderID__c).contains('production') ||
                    (oneCase.EUD_ProductionType__c != null &&
                    oneCase.EUD_ProductionType__c.containsIgnoreCase('Production'))
                ) {
                    newProductionTypeList.add('Production');
                }

                if (
                    orderedPartsMap.get(oneCase.ShadowXometryOrderID__c).contains('prototype') ||
                    (oneCase.EUD_ProductionType__c != null &&
                    oneCase.EUD_ProductionType__c.containsIgnoreCase('Prototype'))
                ) {
                    newProductionTypeList.add('Prototype');
                }

                String newProductionType = String.join(newProductionTypeList, ', ');
                if (oneCase.EUD_ProductionType__c != newProductionType) {
                    oneCase.EUD_ProductionType__c = newProductionType;
                    casesToUpdate.add(oneCase);
                }
            }

            DatabaseUtilities.saveToDatabase(
                casesToUpdate,
                'orderedPartHandler.fillProductTypes',
                'Update EUD_ProductionType__c for Cases related to Ordered Parts'
            );
        }
    }
    /**
     * @description Stamp Ops Orders when a part expired
     * @param newOrderedPartList List of Ordered Parts that were just inserted or updated
     * @param oldOrderedPartMap Map of Ordered Parts changed by the update
     */
    public static void updateOrderedParts(
        List<Ordered_Part__c> newOrderedPartList,
        Map<Id, Ordered_Part__c> oldOrderedPartMap
    ) {
        Set<String> expiredPartStatusSet = new Set<String>{ 'All Offers Expired' };
        Set<ID> opsOrdersToUpdate = new Set<ID>();

        for (Ordered_Part__c op : newOrderedPartList) {
            if (op.PartStatus__c != null) {
                Boolean justExpired = false;
                Boolean hasEverExpired = false;
                if (expiredPartStatusSet.contains(op.PartStatus__c)) {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate && !expiredPartStatusSet.contains(oldOrderedPartMap.get(op.ID).PartStatus__c))
                    ) {
                        op.CurrentlyExpired__c = true;
                        justExpired = true;
                    }
                } else {
                    if (op.HasEverExpired__c) {
                        if (Trigger.isInsert || (Trigger.isUpdate && !oldOrderedPartMap.get(op.ID).HasEverExpired__c)) {
                            hasEverExpired = true;
                        }
                    }
                }

                if (justExpired || hasEverExpired) {
                    opsOrdersToUpdate.add(op.Ops_Order__c);
                } else {
                    Boolean noLongerExpired =
                        Trigger.isUpdate &&
                        !expiredPartStatusSet.contains(op.PartStatus__c) &&
                        expiredPartStatusSet.contains(oldOrderedPartMap.get(op.ID).PartStatus__c);

                    if (noLongerExpired) {
                        op.CurrentlyExpired__c = false;
                    }
                }
            }
        }

        if (!opsOrdersToUpdate.isEmpty()) {
            List<Ops_Order__c> opsOrdersToUpdateList = new List<Ops_Order__c>();
            for (Ops_Order__c oo : [
                SELECT ID, ExpiredPart__c
                FROM Ops_Order__c
                WHERE ID IN :opsOrdersToUpdate AND ExpiredPart__c = FALSE
            ]) {
                oo.ExpiredPart__c = true;
                opsOrdersToUpdateList.add(oo);
            }

            DatabaseUtilities.saveToDatabase(
                opsOrdersToUpdateList,
                'orderedPartHandler.updateOrderedParts',
                'The Ordered Part and/or Ops Order was not updated'
            );
        }
    }

    /**
     * @description Create an Ordered Part Event Junction, Job Event and Order Event record when Asana criteria are met
     * @param newOrderedPartList List of Ordered Parts that were just inserted or updated
     * @param oldOrderedPartMap Map of Ordered Parts changed by the update
     */
    public static void orderedPartEventConditionals(
        List<Ordered_Part__c> newOrderedPartList,
        Map<Id, Ordered_Part__c> oldOrderedPartMap
    ) {
        if (!EventBusBypass.isByPassed('orderedPartShell')) {
            Map<ID, ID> orderedPartToOpsOrderIDMap = new Map<ID, ID>();
            Map<ID, String> orderedPartToOpsOrderIDStringMap = new Map<ID, String>();
            Map<ID, String> opsOrderMap = new Map<ID, String>();
            Map<ID, String> orderedPartToXomJobIDMap = new Map<ID, String>();
            Map<ID, String> orderedPartRecordToXomPartIDMap = new Map<ID, String>();
            //Map of Ordered Part ID to the Criteria and Critieria value (if applicable)
            Map<ID, Map<String, String>> orderedPartToCriteriaMetMap = new Map<ID, Map<String, String>>();

            // String lateMdtName = 'part_BadOutcomeLateWorstPart';
            // Decimal lateBOThreshold = 0;

            // String rejectedMdtName = 'part_BadOutcomeRejectedWorstPart';
            // Decimal rejectedBOThreshold = 0;

            // Set<String> eventThresholdMdtSet = new Set<String>{ lateMdtName, rejectedMdtName };

            // for (Event_Threshold__mdt record : [
            //     SELECT ID, DeveloperName, Number_Ref_Value__c, Currency_Ref_Value__c
            //     FROM Event_Threshold__mdt
            //     WHERE DeveloperName IN :eventThresholdMdtSet
            // ]) {
            //     if (record.DeveloperName == lateMdtName) {
            //         lateBOThreshold = record.Number_Ref_Value__c;
            //     }
            //     if (record.DeveloperName == rejectedMdtName) {
            //         rejectedBOThreshold = record.Number_Ref_Value__c;
            //     }
            // }

            for (Ordered_Part__c op : newOrderedPartList) {
                String currentEventType = '';

                Boolean mfgProcess = false;
                if (
                    op.Process__c != null && OpsEventsHelper.EVENT_CRITERIA_PROCESS_INCLUSIONS.contains(op.Process__c)
                ) {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate &&
                        (oldOrderedPartMap.get(op.ID).Process__c == null ||
                        !OpsEventsHelper.EVENT_CRITERIA_PROCESS_INCLUSIONS.contains(
                            oldOrderedPartMap.get(op.ID).Process__c
                        )))
                    ) {
                        mfgProcess = true;
                    }
                }

                Boolean nonStandardInspection = false;
                if (
                    op.InspectionType__c != null &&
                    !OpsEventsHelper.EVENT_CRITERIA_INSPECTION_TYPE_EXCLUSIONS.contains(op.InspectionType__c)
                ) {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate &&
                        (oldOrderedPartMap.get(op.ID).InspectionType__c == null ||
                        OpsEventsHelper.EVENT_CRITERIA_INSPECTION_TYPE_EXCLUSIONS.contains(
                            oldOrderedPartMap.get(op.ID).InspectionType__c
                        )))
                    ) {
                        nonStandardInspection = true;
                    }
                }

                // Boolean lateBadOutcome = false;
                // if (op.Bad_Outcome_Late_Probability__c != null && op.Bad_Outcome_Late_Probability__c > lateBOThreshold) {
                //     if (
                //         Trigger.isInsert ||
                //         (Trigger.isUpdate &&
                //         (oldOrderedPartMap.get(op.ID).Bad_Outcome_Late_Probability__c == null ||
                //         oldOrderedPartMap.get(op.ID).Bad_Outcome_Late_Probability__c <= lateBOThreshold))
                //     ) {
                //         lateBadOutcome = true;
                //     }
                // }

                // Boolean rejectedBadOutcome = false;
                // if (
                //     op.Bad_Outcome_Reject_Probability__c != null &&
                //     op.Bad_Outcome_Reject_Probability__c > rejectedBOThreshold
                // ) {
                //     if (
                //         Trigger.isInsert ||
                //         (Trigger.isUpdate &&
                //         (oldOrderedPartMap.get(op.ID).Bad_Outcome_Reject_Probability__c == null ||
                //         oldOrderedPartMap.get(op.ID).Bad_Outcome_Reject_Probability__c <= rejectedBOThreshold))
                //     ) {
                //         rejectedBadOutcome = true;
                //     }
                // }

                Boolean expiredPart = false;
                if (op.CurrentlyExpired__c) {
                    if (Trigger.isInsert || (Trigger.isUpdate && !oldOrderedPartMap.get(op.ID).CurrentlyExpired__c)) {
                        expiredPart = true;
                    }
                }

                Boolean rejectedPart = false;
                if (op.CurrentlyRejected__c) {
                    if (Trigger.isInsert || (Trigger.isUpdate && !oldOrderedPartMap.get(op.ID).CurrentlyRejected__c)) {
                        rejectedPart = true;
                    }
                }

                if (
                    mfgProcess ||
                    nonStandardInspection ||
                    //lateBadOutcome ||
                    //rejectedBadOutcome ||
                    expiredPart ||
                    rejectedPart
                ) {
                    ID orderedPartID = op.ID;
                    orderedPartToOpsOrderIDMap.put(orderedPartID, op.Ops_Order__c);
                    orderedPartToOpsOrderIDStringMap.put(orderedPartID, op.Xometry_Order_ID__c);
                    opsOrderMap.put(op.Ops_Order__c, op.Xometry_Order_ID__c);

                    if (op.CurrentJobID__c != null) {
                        orderedPartToXomJobIDMap.put(orderedPartID, op.CurrentJobID__c);
                    }
                    orderedPartRecordToXomPartIDMap.put(orderedPartID, op.Xometry_Ordered_Part_ID__c);

                    orderedPartToCriteriaMetMap.put(orderedPartID, new Map<String, String>());
                    if (mfgProcess) {
                        currentEventType = 'Manufacturing Process';
                        orderedPartToCriteriaMetMap.get(orderedPartID).put(currentEventType, op.Process__c);
                    }
                    if (nonStandardInspection) {
                        currentEventType = 'Non-Standard Inspection';
                        orderedPartToCriteriaMetMap.get(orderedPartID).put(currentEventType, op.InspectionType__c);
                    }
                    // if (lateBadOutcome) {
                    //     currentEventType = 'Part Late Bad Outcome';
                    //     orderedPartToCriteriaMetMap.get(orderedPartID)
                    //         .put(currentEventType, String.valueOf(op.Bad_Outcome_Late_Probability__c));
                    // }
                    // if (rejectedBadOutcome) {
                    //     currentEventType = 'Part Reject Bad Outcome';
                    //     orderedPartToCriteriaMetMap.get(orderedPartID)
                    //         .put(currentEventType, String.valueOf(op.Bad_Outcome_Reject_Probability__c));
                    // }
                    if (expiredPart) {
                        currentEventType = 'Expired';
                        orderedPartToCriteriaMetMap.get(orderedPartID).put(currentEventType, null);
                    }
                    if (rejectedPart) {
                        currentEventType = 'Rejected';
                        orderedPartToCriteriaMetMap.get(orderedPartID).put(currentEventType, null);
                    }
                }
            }

            if (!orderedPartToCriteriaMetMap.isEmpty()) {
                Map<String, ID> jobIDToRecordIDMap = new Map<String, ID>();

                for (Job__c job : [
                    SELECT ID, XometryJobID__c
                    FROM Job__c
                    WHERE XometryJobID__c IN :orderedPartToXomJobIDMap.values()
                ]) {
                    jobIDToRecordIDMap.put(job.XometryJobID__c, job.ID);
                }

                List<Order_Event__c> orderEventsList = new List<Order_Event__c>();
                Map<String, Order_Event__c> orderEventsWithInitialCriteria = new Map<String, Order_Event__c>();
                Set<String> opsOrderIdsWithNewEvents = new Set<String>();
                List<Job_Event__c> jobEventsList = new List<Job_Event__c>();
                List<Ordered_Part_Event__c> orderedPartEventsList = new List<Ordered_Part_Event__c>();

                for (ID orderedPartRecordID : orderedPartToCriteriaMetMap.keySet()) {
                    String xomOrderedPartID = orderedPartRecordToXomPartIDMap.get(orderedPartRecordID);

                    ID opsOrderRecordID = orderedPartToOpsOrderIDMap.get(orderedPartRecordID);
                    String opsOrderStringID = orderedPartToOpsOrderIDStringMap.get(orderedPartRecordID);
                    opsOrderIdsWithNewEvents.add(opsOrderStringID);
                    String xomOpsOrderID = opsOrderMap.get(opsOrderRecordID);

                    String xomJobID = orderedPartToXomJobIDMap.get(orderedPartRecordID);
                    ID jobRecordID = jobIDToRecordIDMap.get(xomJobID);

                    for (String eventType : orderedPartToCriteriaMetMap.get(orderedPartRecordID).keySet()) {
                        String additionalInfo = orderedPartToCriteriaMetMap.get(orderedPartRecordID).get(eventType);
                        Map<Ordered_Part_Event__c, Map<Order_Event__c, Job_Event__c>> eventsToInsertMap = createOrderedPartEventJunction(
                            orderedPartRecordID,
                            xomOrderedPartID,
                            opsOrderRecordID,
                            xomOpsOrderID,
                            jobRecordID,
                            xomJobID,
                            eventType,
                            additionalInfo
                        );

                        for (Ordered_Part_Event__c opEvent : eventsToInsertMap.keySet()) {
                            orderedPartEventsList.add(opEvent);
                            for (Order_Event__c ordEvent : eventsToInsertMap.get(opEvent).keySet()) {
                                orderEventsList.add(ordEvent);
                                if (ordEvent.InitialCriteria__c) {
                                    orderEventsWithInitialCriteria.put(ordEvent.OrderID__c, ordEvent);
                                }
                                if (jobRecordID != null) {
                                    jobEventsList.add(eventsToInsertMap.get(opEvent).get(ordEvent));
                                }
                            }
                        }
                    }
                }
                Map<String, Map<String, ID>> orderEventsMap = new Map<String, Map<String, ID>>();
                Map<String, Map<String, ID>> jobEventsMap = new Map<String, Map<String, ID>>();

                if (!orderEventsList.isEmpty()) {
                    List<Order_Event__c> existingOrdEvents = new List<Order_Event__c>();
                    DatabaseUtilities.insertToDatabase(
                        orderEventsList,
                        'OrderedPartHandler.orderedPartEventConditionals',
                        'Order Events were not inserted'
                    );

                    for (Order_Event__c ordEvent : orderEventsList) {
                        String orderedPartID = ordEvent.Xometry_Part_ID__c;
                        if (!orderEventsMap.containsKey(orderedPartID)) {
                            orderEventsMap.put(orderedPartID, new Map<String, ID>());
                        }
                        orderEventsMap.get(orderedPartID).put(ordEvent.Type__c, ordEvent.ID);
                        System.debug(orderEventsMap);
                    }
                    OpsEventsHelper.readyToEvaluate(opsOrderIdsWithNewEvents);
                }

                if (!jobEventsList.isEmpty()) {
                    DatabaseUtilities.insertToDatabase(
                        jobEventsList,
                        'OrderedPartHandler.orderedPartEventConditionals',
                        'Job Events were not inserted'
                    );

                    for (Job_Event__c jobEvent : jobEventsList) {
                        String orderedPartID = jobEvent.Xometry_Part_ID__c;
                        if (!jobEventsMap.containsKey(orderedPartID)) {
                            jobEventsMap.put(orderedPartID, new Map<String, ID>());
                        }
                        jobEventsMap.get(orderedPartID).put(jobEvent.Type__c, jobEvent.ID);
                    }
                }

                if (!orderedPartEventsList.isEmpty()) {
                    for (Ordered_Part_Event__c opEvent : orderedPartEventsList) {
                        String orderedPartID = opEvent.Xometry_Part_ID__c;
                        String orderedPartEvent = opEvent.Type__c;

                        if (orderEventsMap.containsKey(orderedPartID)) {
                            opEvent.Order_Event__c = orderEventsMap.get(orderedPartID).get(orderedPartEvent);
                        }

                        if (jobEventsMap.containsKey(orderedPartID)) {
                            opEvent.Job_Event__c = jobEventsMap.get(orderedPartID).get(orderedPartEvent);
                        }
                    }

                    DatabaseUtilities.insertToDatabase(
                        orderedPartEventsList,
                        'OrderedPartHandler.orderedPartEventConditionals',
                        'Ordered Part Junction Events were not inserted'
                    );
                }
            }
        }
    }

    /**
     * @description createOrderedPartEvent
     * @param ID orderedPartRecordID
     * @param String xomOrderedPartID,
     * @param ID opsOrderRecordID,
     * @param String xomOpsOrderID
     * @param ID jobRecordID
     * @param String xomJobID
     * @param String eventType
     * @param String additionalInformation
     */
    public static Map<Ordered_Part_Event__c, Map<Order_Event__c, Job_Event__c>> createOrderedPartEventJunction(
        ID orderedPartRecordID,
        String xomOrderedPartID,
        ID opsOrderRecordID,
        String xomOpsOrderID,
        ID jobRecordID,
        String xomJobID,
        String eventType,
        String additionalInformation
    ) {
        Map<Ordered_Part_Event__c, Map<Order_Event__c, Job_Event__c>> OrderedPartToJobOrderEventsReturnMap = new Map<Ordered_Part_Event__c, Map<Order_Event__c, Job_Event__c>>();

        Order_Event__c oe = createOrderEvent(
            xomOrderedPartID,
            opsOrderRecordID,
            xomOpsOrderID,
            eventType,
            additionalInformation
        );

        ID orderEvent = oe.ID;

        Job_Event__c je = createJobEvent(xomOrderedPartID, jobRecordID, xomJobID, eventType, additionalInformation);

        ID jobEvent = null;
        if (jobRecordID != null) {
            jobEvent = je.ID;
        }

        Ordered_Part_Event__c ope = new Ordered_Part_Event__c();
        ope.Name = xomJobID == null
            ? xomOpsOrderID + ' - ' + xomOrderedPartID + ' - ' + eventType
            : xomOpsOrderID + ' - ' + xomJobID + ' - ' + xomOrderedPartID + ' - ' + eventType;
        ope.Ordered_Part__c = orderedPartRecordID;
        ope.Xometry_Part_ID__c = xomOrderedPartID;
        ope.Type__c = eventType;
        ope.Criteria__c = true;
        ope.Xometry_Order_ID__c = xomOpsOrderID;
        ope.Xometry_Job_ID__c = xomJobID;
        OrderedPartToJobOrderEventsReturnMap.put(ope, new Map<Order_Event__c, Job_Event__c>());
        OrderedPartToJobOrderEventsReturnMap.get(ope).put(oe, je);

        return OrderedPartToJobOrderEventsReturnMap;
    }

    /**
     * @description createOrderEvents
     * @param  String xomOrderedPartID
     * @param  ID opsOrderRecordID
     * @param  String xomOrderID
     * @param  String qualObjEventType
     * @param  String additionalInformation
     */
    public static Order_Event__c createOrderEvent(
        String xomOrderedPartID,
        ID opsOrderRecordID,
        String xomOrderID,
        String qualObjEventType,
        String additionalInformation
    ) {
        Order_Event__c oe = new Order_Event__c();
        oe.Name = xomOrderID + ' - ' + qualObjEventType;
        oe.Ops_Order__c = opsOrderRecordID;
        oe.OrderID__c = xomOrderID;
        oe.Xometry_Part_ID__c = xomOrderedPartID;
        oe.Type__c = qualObjEventType;
        oe.Qualifying_Object__c = 'Part';
        oe.Process_Group__c = 'All';
        oe.Criteria__c = OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(qualObjEventType);
        oe.AdditionalInformation__c = additionalInformation;

        return oe;
    }

    /**
     * @description createJobEvent
     * @param String xomOrderedPartID
     * @param ID jobRecordID
     * @param String xomJobID
     * @param String eventType
     * @param String additionalInformation
     */
    public static Job_Event__c createJobEvent(
        String xomOrderedPartID,
        ID jobRecordID,
        String xomJobID,
        String qualObjEventType,
        String additionalInformation
    ) {
        Job_Event__c je = new Job_Event__c();
        je.Name = xomJobID + ' - ' + qualObjEventType;
        je.Job__c = jobRecordID;
        je.JobID__c = xomJobID;
        je.Xometry_Part_ID__c = xomOrderedPartID;
        je.Type__c = qualObjEventType;
        je.Qualifying_Object__c = 'Part';
        je.Process_Group__c = 'All';
        je.Criteria__c = OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(qualObjEventType);
        je.AdditionalInformation__c = additionalInformation;

        return je;
    }
}