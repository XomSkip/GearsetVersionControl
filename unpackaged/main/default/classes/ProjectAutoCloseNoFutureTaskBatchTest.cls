@isTest
private class ProjectAutoCloseNoFutureTaskBatchTest {
    @isTest
    private static void projectAutoCloseNoFutureTaskBatchTestWon() {
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
            CreatedById = AppConstants.API_USER
        );
        insert testProject;

        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c, DeveloperName
            FROM Admin_Ref_Variable__mdt
            WHERE Name__c = 'ProjectAutoCloseNoFutureTaskBatchLastProject'
        ]) {
            Integer rangeInDays = Integer.valueOf(adminRefVarValues.Text_Ref_Var__c) * -1;
            Date dateSince = System.today().addDays(rangeInDays).addDays(-2);

            Test.setCreatedDate(testProject.Id, dateSince);
        }

        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'Test';
        testOpp.CloseDate = System.today().addDays(2);
        testOpp.Project__c = testProject.Id;
        testOpp.StageName = 'Closed Won';
        insert testOpp;

        Test.startTest();
        ProjectAutoCloseNoFutureTaskBatch batch = new ProjectAutoCloseNoFutureTaskBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        System.assertEquals(
            'Closed Won',
            [SELECT Stage__c FROM Project__c WHERE Id = :testProject.Id]
            .Stage__c,
            'Project should be closed.'
        );
    }

    @isTest
    private static void projectAutoCloseNoFutureTaskBatchTestLost() {
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
            CreatedById = AppConstants.API_USER
        );
        insert testProject;

        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c, DeveloperName
            FROM Admin_Ref_Variable__mdt
            WHERE Name__c = 'ProjectAutoCloseNoFutureTaskBatchLastProject'
        ]) {
            Integer rangeInDays = Integer.valueOf(adminRefVarValues.Text_Ref_Var__c) * -1;
            Date dateSince = System.today().addDays(rangeInDays).addDays(-2);

            Test.setCreatedDate(testProject.Id, dateSince);
        }

        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'Test';
        testOpp.CloseDate = System.today().addDays(2);
        testOpp.Project__c = testProject.Id;
        testOpp.StageName = 'Closed Lost';
        insert testOpp;

        Test.startTest();
        ProjectAutoCloseNoFutureTaskBatch batch = new ProjectAutoCloseNoFutureTaskBatch();
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
    private static void projectAutoCloseNoFutureTaskBatchTestSkip() {
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
            Primary_Contact__c = testContact.Id
        );
        insert testProject;

        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c, DeveloperName
            FROM Admin_Ref_Variable__mdt
            WHERE Name__c = 'ProjectAutoCloseNoFutureTaskBatchLastProject'
        ]) {
            Integer rangeInDays = Integer.valueOf(adminRefVarValues.Text_Ref_Var__c) * -1;
            Date dateSince = System.today().addDays(rangeInDays).addDays(-2);

            Test.setCreatedDate(testProject.Id, dateSince);
        }

        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'Test';
        testOpp.CloseDate = System.today().addDays(2);
        testOpp.Project__c = testProject.Id;
        testOpp.StageName = 'Closed Lost';
        insert testOpp;

        Opportunity testOpp2 = new Opportunity();
        testOpp2.Name = 'Test';
        testOpp2.CloseDate = System.today().addDays(2);
        testOpp2.Project__c = testProject.Id;
        testOpp2.StageName = 'Open';
        insert testOpp2;

        Test.startTest();
        ProjectAutoCloseNoFutureTaskBatch batch = new ProjectAutoCloseNoFutureTaskBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        System.assertEquals(
            'New',
            [SELECT Stage__c FROM Project__c WHERE Id = :testProject.Id]
            .Stage__c,
            'Project stage shouldnt be updated.'
        );
    }

    @isTest
    private static void projectAutoCloseNoFutureTaskBatchTestCriteria2() {
        Account testAccount = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            Primary_Email__c = 'test@test123.com',
            FirstName = 'Test',
            LastName = 'Contact',
            Outreach_Actively_Being_Sequenced__c = FALSE
        );
        insert testContact;

        Task callTask = new Task(
            Type = 'Call',
            CallType = 'Internal',
            WhoId = testContact.Id,
            Status = 'Completed'
        );

        Project__c testProject = new Project__c(
            AccountId__c = testAccount.Id,
            Name = 'Test Project',
            Stage__c = 'New',
            Primary_Contact__c = testContact.Id,
            CreatedById = AppConstants.API_USER
        );

        insert testProject;

        Opportunity testOpp = new Opportunity(
            Name = 'Test',
            Project__c = testProject.Id,
            StageName = 'New',
            CloseDate = Date.today().addDays(12)
        );

        Datetime dateSinceCreatedProject;
        Datetime dateSinceCreatedOpp;
        Date dateSinceLastAct;

        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c, Name__c
            FROM Admin_Ref_Variable__mdt
            WHERE Name__c LIKE 'ProjectAutoCloseNoFutureTaskBatch%'
        ]) {
            Integer rangeInDays = Integer.valueOf(adminRefVarValues.Text_Ref_Var__c) * -1;
            Date dateSince = System.today().addDays(rangeInDays).addDays(-1);
            if (adminRefVarValues.Name__c.contains('ProjectAutoCloseNoFutureTaskBatchLastQuoteNew') ) {
                testOpp.Last_Quote_Xometry_Create_Time__c = dateSince;
            }
            if (adminRefVarValues.Name__c.contains('ProjectAutoCloseNoFutureTaskBatchLastOppNew') ) {
                dateSinceCreatedOpp = dateSince;
            }
            if (adminRefVarValues.Name__c.contains('ProjectAutoCloseNoFutureTaskBatchLastAct') ) {
                dateSinceLastAct = dateSince;
            }
        }

        callTask.ActivityDate = dateSinceLastAct;
        insert callTask;

        insert testOpp;

        Test.setCreatedDate(testOpp.Id, dateSinceCreatedOpp);

        Test.startTest();
        ProjectAutoCloseNoFutureTaskBatch batch = new ProjectAutoCloseNoFutureTaskBatch();
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
    static void projectAutoCloseNoFutureTaskScheduleTest() {
        String CRON_EXP = '0 0 1 * * ?';
        Test.startTest();
        String jobID = System.schedule(
            'ProjectCloseInactiveBatchTest',
            CRON_EXP,
            new ProjectAutoCloseNoFutureTaskSchedule()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}