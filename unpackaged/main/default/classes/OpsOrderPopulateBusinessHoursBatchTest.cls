@isTest
private class OpsOrderPopulateBusinessHoursBatchTest {
    
    @isTest(seeAllData=false)
    static void executeTest() {

        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];

        Map<String, BusinessHours> hoursMap = new Map<String, BusinessHours>();
        for (BusinessHours bHours : [SELECT Id, Name FROM BusinessHours]) {
            hoursMap.put(bHours.Name, bHours);
        }

        Ops_Order__c testOpsOrder = new Ops_Order__c();
        testOpsOrder.XometryOpsOrderID__c = 'AAAAA-00001';
        testOpsOrder.Order_Date__c = Date.today();
        testOpsOrder.AllOrdersTotal__c = largeOrderAmountRecord.number_ref_Value__c + 1;
        insert testOpsOrder;

        System.assertEquals(
            true,
            [SELECT Is_Large_Order__c FROM Ops_Order__c WHERE Id = :testOpsOrder.Id]
            .Is_Large_Order__c,
            'Record is Large Order'
        );

        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = 'AAAAA-00001';
        testJob.OrderDueDate__c = Date.today() + 7;
        insert testJob;

        Case testCase = new Case(Job__c = testJob.Id, GNOOrder__c = testOpsOrder.Id, Type = 'Technical Review');
        Case testCase2 = new Case(Job__c = testJob.Id, GNOOrder__c = testOpsOrder.Id, Type = 'Large Order Approval');
        Case testCase3 = new Case(Job__c = testJob.Id, GNOOrder__c = testOpsOrder.Id, Type = 'Technical Questions');
        insert new List<Case>{testCase,testCase2,testCase3};

        System.assertNotEquals(
            hoursMap.get('POD Business Hours - EST').Id,
            [SELECT BusinessHoursId FROM Case WHERE Id = :testCase.Id]
            .BusinessHoursId,
            'BusinessHoursId should not be default'
        );

        Test.startTest();

        Database.executeBatch( new OpsOrderPopulateBusinessHoursBatch() );

        Test.stopTest();

        Map<Id,Case> testResultMap = new Map<Id,Case>([SELECT BusinessHoursId FROM Case]);

        System.assertEquals(
            hoursMap.get('POD Business Hours - EST').Id,
            testResultMap.get(testCase.Id).BusinessHoursId,
            'BusinessHoursId should be updated'
        );

        System.assertEquals(
            hoursMap.get('POD Business Hours - EST').Id,
            testResultMap.get(testCase2.Id).BusinessHoursId,
            'BusinessHoursId should be updated'
        );

        System.assertNotEquals(
            hoursMap.get('POD Business Hours - EST').Id,
            testResultMap.get(testCase3.Id).BusinessHoursId,
            'BusinessHoursId should not be updated'
        );

    }
}