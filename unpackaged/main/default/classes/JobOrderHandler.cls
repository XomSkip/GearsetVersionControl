public with sharing class JobOrderHandler {
    public static void renameOnCreate(List<Job_Order__c> newJoOrderList) {
        /**
         * @description changes the Name in the junction record to a more readeable identifier
         */
        Map<Id, List<Job_Order__c>> jobOrderMap = new Map<Id, List<Job_Order__c>>();
        for (Job_Order__c jobOrder : newJoOrderList) {
            jobOrder.Name = jobOrder.XometryOpsOrderID__c + '-' + jobOrder.XometryJobID__c;
        }
    }

    /**
     * @description Listens for status updates and send changes to Parent Orders
     * @param jobOrderList list of JobsOrder being created/updated/deleted
     * @param oldJobOrderMap - map of old JobOrders values
     */
    public static void updateStatusRollUpOnOrder(
        List<Job_Order__c> jobOrderList,
        Map<ID, Job_Order__c> oldJobOrderMap
    ) {
        Set<Id> orderIds = new Set<Id>();
        //Checking JobsOrders with updated Relations
        //and collecting Ids Orders to reset
        for (Job_Order__c oneJobOrder : jobOrderList) {
            Boolean cond = Trigger.isDelete;

            if (Trigger.isUpdate && ((oldJobOrderMap.get(oneJobOrder.Id).Ops_Order__c != oneJobOrder.Ops_Order__c))) {
                cond = true;

                if (oldJobOrderMap.get(oneJobOrder.Id).Ops_Order__c != null) {
                    //reset old order too
                    orderIds.add(oldJobOrderMap.get(oneJobOrder.Id).Ops_Order__c);
                }
            }

            if (cond && oneJobOrder.Ops_Order__c != null) {
                orderIds.add(oneJobOrder.Ops_Order__c);
            }
            //Get all OrderIds affected by looking at the junction Object
        }

        if (!orderIds.isEmpty()) {
            OpsOrderHandler.updateLargeOrderSummary(orderIds);
        }
    }
}