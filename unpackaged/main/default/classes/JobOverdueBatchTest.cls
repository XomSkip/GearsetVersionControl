@isTest
private class JobOverdueBatchTest {
    @isTest(seeAllData=false)
    static void executeOverdueTest() {
        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.DueDate__c = Date.today() - 7;
        insert testJob;

        Test.startTest();
        Database.executeBatch(new JobOverdueBatch());
        Test.stopTest();

        List<Job__c> jobList = [SELECT Job_OverDue_Flag__c, Job_is_Past_Due__c FROM Job__c];

        System.assertEquals(7, jobList[0].Job_OverDue_Flag__c, 'Job OverDue should be updated');
    }

    @isTest(seeAllData=false)
    static void executeNotOverdueTest() {
        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.DueDate__c = Date.today() + 7;
        insert testJob;

        Test.startTest();
        Database.executeBatch(new JobOverdueBatch());
        Test.stopTest();

        List<Job__c> jobList = [SELECT Job_OverDue_Flag__c, Job_is_Past_Due__c FROM Job__c];

        System.assertEquals(-7, jobList[0].Job_OverDue_Flag__c, 'Job OverDue should be updated');
    }

    @isTest(seeAllData=false)
    static void executeShippedOnCreateDayTest() {
        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.DueDate__c = Date.today() - 7;
        testJob.Stage__c = 'Completed';
        insert testJob;

        Test.startTest();
        Database.executeBatch(new JobOverdueBatch());
        Test.stopTest();

        List<Job__c> jobList = [SELECT Job_OverDue_Flag__c, Job_is_Past_Due__c FROM Job__c];

        System.assertEquals(7, jobList[0].Job_OverDue_Flag__c, 'Job OverDue shouldnt be updated');
    }

    @isTest(seeAllData=false)
    static void executeShippedTest() {
        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.DueDate__c = Date.today().addDays(7);
        insert testJob;

        Database.executeBatch(new JobOverdueBatch());

        testJob.Stage__c = 'Vendor Completed';
        update testJob;

        Test.startTest();
        Database.executeBatch(new JobOverdueBatch());
        Test.stopTest();

        List<Job__c> jobList = [SELECT Job_OverDue_Flag__c, Job_is_Past_Due__c FROM Job__c];

        System.assertEquals(-7, jobList[0].Job_OverDue_Flag__c, 'Job OverDue shouldnt be updated');
    }

    @isTest(seeAllData=false)
    static void executeDateNull() {
        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.DueDate__c = null;
        insert testJob;

        Test.startTest();
        Database.executeBatch(new JobOverdueBatch());
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
        String jobID = System.schedule('scheduleTest', CRON_EXP, new JobOverdueBatch());
        Test.stopTest();

        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}