@isTest
private class ValidationLostClosedProjectsBatch_Test {
   
    @isTest
    static void validateLostClosedProjects() {
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
            Stage__c = 'Closed Lost',
            Primary_Contact__c = testContact.Id
        );
        insert testProject;

        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'Test';
        testOpp.CloseDate = System.today().addDays(2);
        testOpp.Project__c = testProject.Id;
        testOpp.StageName = 'Closed Won';
        insert testOpp;

        Project__c testProject2 = new Project__c(
            AccountId__c = testAccount.Id,
            Name = 'Test Project',
            Stage__c = 'Closed Lost',
            Primary_Contact__c = testContact.Id
        );
        insert testProject2;

        Opportunity testOpp2 = new Opportunity();
        testOpp2.Name = 'Test';
        testOpp2.CloseDate = System.today().addDays(2);
        testOpp2.Project__c = testProject2.Id;
        testOpp2.StageName = 'Closed Lost';
        insert testOpp2;

        Test.startTest();
        ValidationLostClosedProjectsBatch batch = new ValidationLostClosedProjectsBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Project__c> lstProjects = [SELECT Id, Stage__c FROM Project__c];

        System.assertNotEquals(
            'Closed Lost',
            lstProjects[0].Stage__c,
            'The project remained closed.'
        );

        System.assertEquals(
            'Closed Lost',
            lstProjects[1].Stage__c,
            'The project was opened.'
        );
    }
}