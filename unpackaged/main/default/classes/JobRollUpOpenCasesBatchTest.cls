@isTest
private class JobRollUpOpenCasesBatchTest {
    @isTest(seeAllData=false)
    static void JobRollUpOpenCasesBatchTest() {
        RecordType sourcingCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'Sourcing'
            LIMIT 1
        ];

        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.OrderDueDate__c = Date.today() + 7;
        insert testJob;

        Case testCase = new Case(Job__c = testJob.Id);
        insert testCase;

        testCase.RecordTypeId = sourcingCaseRecordType.Id;
        update testCase;

        System.assertEquals(
            0,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be 0 before the Batch'
        );

        Test.startTest();

        JobRollUpOpenCasesBatch jb = new JobRollUpOpenCasesBatch();
        Database.executeBatch(jb);

        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated after the Batch run.'
        );
    }
}