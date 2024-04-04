public class OpsEventsHelper {
    public static final Map<String, Boolean> EVENT_TYPE_TO_CRITERIA_FLAG_MAP = new Map<String, Boolean>{
        '> Additive Job Value Threshold' => true,
        'Additive Job Past Due' => true,
        'Additive Only & Past Due' => true,
        'Created in ERP' => true,
        'Estimated Completion Date' => false,
        'Expedited' => false,
        'Expired' => true,
        'Fully Shipped' => false,
        'Job Bad Outcome' => false,
        'Job Late Bad Outcome' => false,
        'Job Reject Bad Outcome' => false,
        'Job Cancelled' => false,
        'Manufacturing Process' => true,
        'MQ > $ Threshold' => true,
        'MQ w/ Custom Finish' => false,
        'Non-Standard Inspection' => false,
        'Part Late Bad Outcome' => true,
        'Part Reject Bad Outcome' => true,
        'Partially Shipped' => false,
        'POD' => false,
        'Rejected' => false,
        'SPOC Supplier' => true,
        'T- Days Out' => false,
        'Top 20 Customer' => true,
        'Top Quality Account' => false,
        'Subtractive & Past Due' => false,
        'Bad Outcomes - Order Bad Outcome' => true //Default to true since majority of Bad Outcomes are a criteria
    };

    public static final List<String> EVENT_CRITERIA_PROCESS_INCLUSIONS = new List<String>{
        'Casting',
        'Die Casting',
        'Injection Molding',
        'Assembly'
    };

    public static final List<String> EVENT_CRITERIA_INSPECTION_TYPE_EXCLUSIONS = new List<String>{
        'std',
        'std-additive'
    };

    public static final Map<String, Integer> EVENT_CRITERIA_IMPORTANCE_ORDER = new Map<String, Integer>{
        'Manufacturing Process' => 1,
        'Top 20 Customer' => 2,
        'MQ > $ Threshold' => 3,
        'Bad Outcomes - Order Bad Outcome' => 4,
        'Created in ERP' => 5,
        'Non-Standard Inspection' => 6,
        'SPOC Supplier' => 7,
        'Top Quality Account' => 8,
        'Estimated Completion Date' => 9,
        '> Additive Job Value Threshold' => 10,
        'Expired' => 11,
        'Subtractive & Past Due' => 12,
        'Additive Only & Past Due' => 13
    };

    public static final Map<String, Boolean> BAD_OUTCOMES_ORDER_SUBTYPE_CRITERIA = new Map<String, Boolean>{
        'Low' => false,
        'Medium' => true,
        'High' => true,
        'Extreme' => true
    };

    public static void readyToEvaluate(Set<String> opsOrdersIdsToEvaluate) {
        List<Ops_Order__c> ordersToEvaluate = [
            SELECT Id, XometryOpsOrderID__c, ERPStatus__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c IN :opsOrdersIdsToEvaluate
        ];
        Set<String> orderIds = new Set<String>();
        for (Ops_Order__c oo : ordersToEvaluate) {
            if (oo.ERPStatus__c != null) {
                orderIds.add(oo.XometryOpsOrderID__c);
            }
        }
        List<Order_Event__c> orderEventsList = [
            SELECT Id, OrderID__c, InitialCriteria__c, Type__c
            FROM Order_Event__c
            WHERE OrderID__c IN :orderIds
        ];
        determineInitialCriteria(orderEventsList);
    }

    /**
     * @description Determine the Order's initial criteria based on when the order is created
     * also handles if the order is created after the job
     * @param List<Order_Event__c> orderEventsList
     */
    public static void determineInitialCriteria(List<Order_Event__c> orderEventsList) {
        Map<String, Order_Event__c> mostImportantOrderEventByOrderId = new Map<String, Order_Event__c>();
        Map<String, List<Order_Event__c>> orderEventsListByOrderId = new Map<String, List<Order_Event__c>>();
        Map<String, Boolean> opsOrderToHasInitialEventMap = new Map<String, Boolean>();
        Map<String, Order_Event__c> orderToExistingInitialEvent = new Map<String, Order_Event__c>();
        Map<Id, Order_Event__c> orderEventsToUpdateMap = new Map<Id, Order_Event__c>();
        for (Order_Event__c orderEvent : orderEventsList) {
            if (orderEventsListByOrderId.get(orderEvent.OrderID__c) == null) {
                orderEventsListByOrderId.put(orderEvent.OrderID__c, new List<Order_Event__c>{ orderEvent });
            } else {
                orderEventsListByOrderId.get(orderEvent.OrderID__c).add(orderEvent);
            }
            if (orderEvent.InitialCriteria__c == true) {
                opsOrderToHasInitialEventMap.put(orderEvent.OrderId__c, true);
                orderToExistingInitialEvent.put(orderEvent.OrderId__c, orderEvent);
            } else if (!opsOrderToHasInitialEventMap.containsKey(orderEvent.OrderId__c)) {
                opsOrderToHasInitialEventMap.put(orderEvent.OrderId__c, false);
            }
        }
        for (String orderId : orderEventsListByOrderId.keySet()) {
            Integer thisOrdersTopImportance = 1000;
            String thisOrderExistingTopType;
            if (opsOrderToHasInitialEventMap.get(orderId)) {
                thisOrderExistingTopType = orderToExistingInitialEvent.get(orderId).Type__c;
                thisOrdersTopImportance = OpsEventsHelper.EVENT_CRITERIA_IMPORTANCE_ORDER.get(thisOrderExistingTopType);
            }
            Integer thisOrdersTopImportanceEventIndex = 0;
            Integer index = 0;
            Boolean orderHasInitialQualifier = false;
            for (Order_Event__c orderEvent : orderEventsListByOrderId.get(orderId)) {
                Integer thisEventImportance = OpsEventsHelper.EVENT_CRITERIA_IMPORTANCE_ORDER.get(orderEvent.Type__c);
                if (thisEventImportance <= thisOrdersTopImportance) {
                    thisOrdersTopImportanceEventIndex = index;
                    thisOrdersTopImportance = thisEventImportance;
                    orderHasInitialQualifier = true;
                }
                if (orderEvent.InitialCriteria__c) {
                    orderEventsListByOrderId.get(orderId)[index].InitialCriteria__c = false;
                    orderEventsToUpdateMap.put(orderEvent.Id, orderEventsListByOrderId.get(orderId)[index]);
                }
                index = index + 1;
            }
            if (orderHasInitialQualifier) {
                orderEventsListByOrderId.get(orderId)[thisOrdersTopImportanceEventIndex].InitialCriteria__c = true;
                orderEventsToUpdateMap.put(
                    orderEventsListByOrderId.get(orderId)[thisOrdersTopImportanceEventIndex].Id,
                    orderEventsListByOrderId.get(orderId)[thisOrdersTopImportanceEventIndex]
                );
            }
        }

        DatabaseUtilities.saveToDatabase(
            orderEventsToUpdateMap.values(),
            'orderEventHelper.determineInitialCriteria',
            'Order Events were not updated to contain initial criteria'
        );
    }
}