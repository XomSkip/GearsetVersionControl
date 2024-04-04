@isTest
private class OrderOverdueBatchTest {
    @isTest(seeAllData=false)
    static void executeOverdueTest() {
        Ops_Order__c testOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00001');
        testOrder.OrderDueDate__c = Date.today() - 7;
        insert testOrder;

        Test.startTest();
        Database.executeBatch(new OrderOverdueBatch());
        Test.stopTest();

        List<Ops_Order__c> orderList = [SELECT Order_OverDue_Flag__c, Order_is_Past_Due__c FROM Ops_Order__c];

        System.assertEquals(7, orderList[0].Order_OverDue_Flag__c, 'Order OverDue should be updated');
    }

    @isTest(seeAllData=false)
    static void executeNotOverdueTest() {
        Ops_Order__c testOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00001');
        testOrder.OrderDueDate__c = Date.today() + 7;
        insert testOrder;

        Test.startTest();
        Database.executeBatch(new OrderOverdueBatch());
        Test.stopTest();

        List<Ops_Order__c> orderList = [SELECT Order_OverDue_Flag__c, Order_is_Past_Due__c FROM Ops_Order__c];

        System.assertEquals(-7, orderList[0].Order_OverDue_Flag__c, 'Order OverDue should be updated');
    }

    @isTest(seeAllData=false)
    static void executeShippedTest() {
        Ops_Order__c testOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00001');
        testOrder.ERPStatus__c = 'Shipped';
        testOrder.OrderDueDate__c = Date.today() + 7;
        insert testOrder;

        Test.startTest();
        Database.executeBatch(new OrderOverdueBatch());
        Test.stopTest();

        List<Ops_Order__c> orderList = [SELECT Order_OverDue_Flag__c, Order_is_Past_Due__c FROM Ops_Order__c];

        System.assertEquals(null, orderList[0].Order_OverDue_Flag__c, 'Order OverDue should be updated');
    }

    @isTest(seeAllData=false)
    static void executeDateNull() {
        Ops_Order__c testOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00001');
        testOrder.OrderDueDate__c = null;
        insert testOrder;

        Test.startTest();
        Database.executeBatch(new OrderOverdueBatch());
        Test.stopTest();

        List<Audit_Trail_Error__c> auditTrail = [
            SELECT ID, name, module__C, dev_audit_notes__c, statusCode__c, errorFields__c, errorMessage__c, CreatedDate
            FROM Audit_Trail_Error__c
        ];
        System.assertEquals(0, auditTrail.size(), 'There should not be any errors');
    }

    @isTest
    static void scheduleTest() {
        String CRON_EXP = '0 0 0 1 1 ? *';

        Test.startTest();
        String jobID = System.schedule('scheduleTest', CRON_EXP, new OrderOverdueBatch());
        Test.stopTest();

        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}