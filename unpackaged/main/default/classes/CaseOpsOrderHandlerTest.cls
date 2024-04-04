@isTest
private class CaseOpsOrderHandlerTest {

    @isTest(seeAllData=false)
    static void renameOnCreateTest() {

        Ops_Order__c testOpsOrder = new Ops_Order__c(
            XometryOpsOrderID__c = 'AAAAA-00001'
        );
        insert testOpsOrder;

        Case testCase = new Case(SuppliedEmail = 'test@test.com', RecordTypeId = AppConstants.casePSERecordTypeId);
        insert testCase;

        testCase = [SELECT CaseNumber From Case Where Id =: testCase.Id];
        
        CaseOpsOrder__c objCaseOrder = new CaseOpsOrder__c(Case__c = testCase.Id, Ops_Order__c = testOpsOrder.Id);

        Test.startTest();
        insert objCaseOrder;
        Test.stopTest();

        System.assertEquals(
            testOpsOrder.XometryOpsOrderID__c +
            ' : ' +
            testCase.CaseNumber,
            [SELECT CaseOpsOrderKey__c FROM CaseOpsOrder__c LIMIT 1].CaseOpsOrderKey__c,
            'Junction should be renamed'
        );

    }
}