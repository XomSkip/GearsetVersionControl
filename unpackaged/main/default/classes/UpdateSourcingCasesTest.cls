@isTest
private class UpdateSourcingCasesTest {

    @isTest(seeAllData=false)
    static void executeTest() {

        String firstXomJobID = 'J0000001';
        String secondXomJobID = 'J0000002';
        String opsOrderID = '00000-00001';

        Job__c firstJob = new Job__c();
        firstJob.XometryJobID__c = firstXomJobID;
        firstJob.XometryOpsOrderID__c = opsOrderID;
        insert firstJob;

        Case c = new Case();
        c.RecordTypeID = AppConstants.caseSourcingRTypeId;
        c.AcceptedJobID__c = firstXomJobID;
        c.Job__c = firstJob.Id;
        insert c;

        Job__c secondJob = new Job__c();
        secondJob.XometryOpsOrderID__c = opsOrderID;
        secondJob.XometryJobID__c = secondXomJobID;
        insert secondJob;

        c.PreviousJobsList__c = firstXomJobID + ', ' + secondXomJobID;
        update c;

        Test.startTest();

        Database.executeBatch( new UpdateSourcingCasesBatch() );

        Test.stopTest();

        Case resultCase = [SELECT ID, AcceptedJobID__c, Job__c FROM Case WHERE Id = :c.Id];

        System.assertEquals(secondJob.Id, resultCase.Job__c, 'The old job is still associated to the case');

    }

    @isTest(seeAllData=false)
    static void scheduleTest() {
        // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        String CRON_EXP = '0 0 1 * * ?';

        Test.startTest();
        String jobID = System.schedule('UpdateSourcingCasesScheduleTest', CRON_EXP, new UpdateSourcingCasesSchedule());
        Test.stopTest();

        System.assertNotEquals(null, jobID, 'Job id is null');

    }

}