@isTest
private class AccountReassignBatchTest {
    @isTest(seeAllData=false)
    private static void accountReassignBatchTest() {
        Id currentUserId = UserInfo.getUserId();
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Id oldOwnerId = a.OwnerId;
        a.Batch_Reassign__c = currentUserId;
        update a;

        System.assertNotEquals(oldOwnerId, currentUserId);

        Test.startTest();
        AccountReassignBatch batch = new AccountReassignBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        System.assertEquals(
            currentUserId,
            [SELECT OwnerId FROM Account WHERE Id = :a.Id]
            .OwnerId,
            'Account should be reassigned.'
        );
    }

    @isTest(seeAllData=false)
    private static void accountIgnoreReassignBatchTest() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User oldOwner = new User(Id = a.OwnerId);

        a.Batch_Reassign__c = oldOwner.Id;
        a.OwnerId = currentUser.Id;
        update a;

        System.assertNotEquals(oldOwner.Id, a.OwnerId);

        System.runAs(currentUser) {
            oldOwner.isActive = false;
            update oldOwner;
        }

        Test.startTest();
        AccountReassignBatch batch = new AccountReassignBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        System.assertEquals(currentUser.Id, [SELECT OwnerId FROM Account WHERE Id = :a.Id].OwnerId);
        System.assertEquals(
            oldOwner.Id,
            [SELECT Batch_Reassign__c FROM Account WHERE Id = :a.Id]
            .Batch_Reassign__c,
            'Reassign should be skiped on inactive users'
        );
    }

    @isTest(seeAllData=false)
    private static void accountReassignCLProjectBatchTest() {
        Id adminRefPoolId;
        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c
            FROM Admin_Ref_Variable__mdt
            WHERE DeveloperName = 'ProjectCloseAuto'
        ]) {
            adminRefPoolId = adminRefVarValues.Text_Ref_Var__c.split(';')[0];
        }

        Account testAccount = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        testAccount.Batch_Reassign__c = adminRefPoolId;
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

        Test.startTest();
        AccountReassignBatch batch = new AccountReassignBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        System.assertEquals(
            adminRefPoolId,
            [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id]
            .OwnerId,
            'Account should be reassigned.'
        );
        System.assertEquals(
            'Closed Lost',
            [SELECT Stage__c FROM Project__c WHERE Id = :testProject.Id]
            .Stage__c,
            'Project should be closed.'
        );
    }

    @isTest(seeAllData=false)
    private static void accountReassignCWProjectBatchTest() {
        Id adminRefPoolId;
        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c
            FROM Admin_Ref_Variable__mdt
            WHERE DeveloperName = 'ProjectCloseAuto'
        ]) {
            adminRefPoolId = adminRefVarValues.Text_Ref_Var__c.split(';')[0];
        }

        Account testAccount = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        testAccount.Batch_Reassign__c = adminRefPoolId;
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

        Opportunity testOpp = new Opportunity(
            Name = 'Test',
            Project__c = testProject.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert testOpp;

        Test.startTest();
        AccountReassignBatch batch = new AccountReassignBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        System.assertEquals(
            adminRefPoolId,
            [SELECT OwnerId FROM Account WHERE Id = :testAccount.Id]
            .OwnerId,
            'Account should be reassigned.'
        );
        System.assertEquals(
            'Closed Won',
            [SELECT Stage__c FROM Project__c WHERE Id = :testProject.Id]
            .Stage__c,
            'Project should be closed.'
        );
    }
}