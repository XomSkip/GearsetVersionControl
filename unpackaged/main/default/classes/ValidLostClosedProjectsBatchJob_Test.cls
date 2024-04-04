@isTest
private class ValidLostClosedProjectsBatchJob_Test {
    @isTest
    static void ValidLostClosedProjectsBatchJob_Test() {
        String CRON_EXP = '0 0 0 1 1 ? *';
        Test.startTest();
        String jobID = System.schedule(
            'ValidLostClosedProjectsBatchJob_Test',
            CRON_EXP,
            new ValidationLostClosedProjectsBatchJob()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}