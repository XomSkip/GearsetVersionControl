global class OrderOverdueBatch implements Database.Batchable<sObject>, Database.Stateful, schedulable {
    Integer orderShipTminus = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        for (Admin_Ref_Variable__mdt orderShipTminusRecord : [
            SELECT Number_Ref_Value__c
            FROM Admin_Ref_Variable__mdt
            WHERE Label = 'orderShipTminus'
        ]) {
            orderShipTminus = Integer.valueOf(orderShipTminusRecord.Number_Ref_Value__c) * -1;
        }

        return Database.getQueryLocator(
            [
                SELECT OrderDueDate__c, Order_Close_to_Ship__c, Order_OverDue_Flag__c
                FROM Ops_Order__c
                WHERE ERPStatus__c NOT IN :AppConstants.OPS_ORDER_COMPLETED_STATUSES AND OrderDueDate__c != NULL
            ]
        );
    }

    global void execute(Database.BatchableContext BC, list<Ops_Order__c> scope) {
        Date dToday = System.today();

        for (Ops_Order__c order : scope) {
            if (order.OrderDueDate__c != null) {
                order.Order_OverDue_Flag__c = order.OrderDueDate__c.daysBetween(dToday);
                if (!order.Order_Close_to_Ship__c && (order.Order_OverDue_Flag__c >= orderShipTminus)) {
                    order.Order_Close_to_Ship__c = true;
                }
            }
        }

        DatabaseUtilities.saveToDatabase(scope, 'OrderOverdueBatch.execute', 'Order Overdue Flag update');
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext sc) {
        Database.executebatch(new OrderOverdueBatch());
    }
}