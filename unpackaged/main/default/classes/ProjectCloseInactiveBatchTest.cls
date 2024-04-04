@isTest
private class ProjectCloseInactiveBatchTest {
    @isTest(seeAllData=false)
    private static void projectCloseInactiveBatchTest() {
        Id adminRefPoolId;
        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c
            FROM Admin_Ref_Variable__mdt
            WHERE DeveloperName = 'ProjectCloseAuto'
        ]) {
            adminRefPoolId = adminRefVarValues.Text_Ref_Var__c.split(';')[0];
        }

        Account testAccount = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        update testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            Primary_Email__c = 'test@test123.com',
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert testContact;

        Project__c testProject = new Project__c(
            AccountId__c = testAccount.Id,
            Name = 'Test Project',
            Stage__c = 'New',
            Primary_Contact__c = testContact.Id,
            OwnerId = adminRefPoolId,
            Last_Opp_Created_Date__c = System.now().addDays(-10)
        );
        insert testProject;

        Test.startTest();
        ProjectCloseInactiveBatch batch = new ProjectCloseInactiveBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        System.assertEquals(
            'Closed Lost',
            [SELECT Stage__c FROM Project__c WHERE Id = :testProject.Id]
            .Stage__c,
            'Project should be closed.'
        );
    }

    @isTest
    static void projectCloseInactiveBatchScheduleTest() {
        String CRON_EXP = '0 0 1 * * ?';
        Test.startTest();
        String jobID = System.schedule(
            'ProjectCloseInactiveBatchTest',
            CRON_EXP,
            new ProjectCloseInactiveBatchSchedule()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}