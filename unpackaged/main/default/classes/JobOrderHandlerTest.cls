@isTest
private class JobOrderHandlerTest {
    @isTest(seeAllData=false)
    static void renameOnCreateTest() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.POD__c = 'First Impressions';
        opsOrder.XometryOpsOrderID__c = 'Ops-Order';
        opsOrder.OrderTotal__c = 1;
        insert opsOrder;

        // Job_Order__c jobOrder = new Job_Order__c();
        // jobOrder.XometryJobID__c = j.XometryJobID__c;
        // jobOrder.Job__c = j.Id;
        // jobOrder.Ops_Order__c = opsOrder.Id;
        // jobOrder.XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c;

        Test.startTest();
        Job__c j = new Job__c();
        j.Stage__c = 'Accepted';
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.OrderDueDate__c = Date.today() + 7;
        j.ShippingService__C = 'Fedex';
        j.ShippingMethod__c = 'Two Day Air';
        j.XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c;
        insert j;
        Test.stopTest();

        System.debug('How many record are on the Job Order');
        List<Job_Order__c> myJOrderList = [SELECT Name, XometryOpsOrderID__c, XometryJobID__c FROM Job_Order__c];

        System.assertEquals(
            opsOrder.XometryOpsOrderID__c +
            '-' +
            j.XometryJobID__c,
            [SELECT Name FROM Job_Order__c LIMIT 1]
            .Name,
            'Junction should be renamed'
        );
    }

    @isTest(seeAllData=false)
    public static void updateStatusRollUpOnOrderTest() {
        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;
        Date OrderPlacedDate = Date.today();
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.Cases_In_Progress__c = 99;
        opsOrder.Jobs_In_Progress__c = 99;
        opsOrder.Cases_Completed__c = 99;
        opsOrder.Jobs_Completed__c = 99;
        opsOrder.XometryOpsOrderID__c = 'BBBBB-20100';
        opsOrder.AllOrdersTotal__c = largeOrderAmount + 1;
        opsOrder.OrderTotal__c = largeOrderAmount + 1;
        opsOrder.Order_Date__c = OrderPlacedDate;

        Ops_Order__c opsOrder2 = new Ops_Order__c();
        opsOrder2.Cases_In_Progress__c = 99;
        opsOrder2.Jobs_In_Progress__c = 99;
        opsOrder2.Cases_Completed__c = 99;
        opsOrder2.Jobs_Completed__c = 99;
        opsOrder2.XometryOpsOrderID__c = 'BBBBB-20200';
        opsOrder2.AllOrdersTotal__c = largeOrderAmount + 1;
        opsOrder2.OrderTotal__c = largeOrderAmount + 1;
        opsOrder2.Order_Date__c = OrderPlacedDate;

        insert new List<Ops_Order__c>{ opsOrder, opsOrder2 };

        Job__c testJob = new Job__c(
            Technical_Review_Status__c = 'Pending Technical Review',
            Name = 'Test-Job1',
            XometryJobID__c = 'TestJob1',
            XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c
        );
        Job__c testJob2 = new Job__c(
            Technical_Review_Status__c = 'Pending Technical Review',
            Name = 'Test-Job2',
            XometryJobID__c = 'TestJob2',
            XometryOpsOrderID__c = opsOrder2.XometryOpsOrderID__c
        );

        Test.startTest();

        insert new List<Job__c>{ testJob, testJob2 };

        delete [SELECT Id FROM Job_Order__c WHERE Job__c = :testJob2.Id];

        Test.stopTest();

        Map<Id, Ops_Order__c> opsOrderResult = new Map<Id, Ops_Order__c>(
            [SELECT Jobs_In_Progress__c, Jobs_Completed__c FROM Ops_Order__c]
        );

        System.assertEquals(1, opsOrderResult.get(opsOrder.Id).Jobs_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(opsOrder.Id).Jobs_Completed__c, 'Rollup should be updated');

        System.assertEquals(0, opsOrderResult.get(opsOrder2.Id).Jobs_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(opsOrder2.Id).Jobs_Completed__c, 'Rollup should be updated');

        System.assertEquals(
            1,
            [SELECT Id FROM Job__c WHERE OrderID__c = :opsOrder2.Id].size(),
            'Job still relates to order'
        );
    }
}