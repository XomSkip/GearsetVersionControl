@isTest
private class AccountSuccessTeamReassignBatch_Test {
    static User objUser = [SELECT Id FROM User WHERE Name = 'Success Team'];

    @TestSetup
    private static void setup() {
        Map<String, Account> accountHierarchyMap = TestDataFactory.createTestAccountHierarchy();

        accountHierarchyMap.get('Dragon Keepers').House_Retainer__c = TRUE;
        accountHierarchyMap.get('Dragon Keepers').Date_of_First_Quote__c = System.Today().addDays(-3);
        update accountHierarchyMap.get('Dragon Keepers');
    }

    @isTest
    private static void PendingPayment() {

        List<Account> lstAcc = [SELECT Id, ParentId, Success_Team__c, Owner.Name FROM Account];

        Project__c project1 = TestDataFactory.createProject(
            true,
            null,
            lstAcc[0].Id,
            null,
            'PreInserted Project',
            'Pending Payment'
        );

        Test.startTest();
            Database.executeBatch(new AccountSuccessTeamReassignBatch());
        Test.stopTest();

        List<Account> lstAcc2 = [SELECT Id, ParentId, Success_Team__c, Owner.Name, Batch_Reassign__c FROM Account WHERE ParentId = null AND Success_Team__c = TRUE AND Owner.Name != 'Success Team'];
        System.assertEquals(lstAcc2[0].Batch_Reassign__c, null, 'The Batch_Reassign__c field was populated');
    }

    @isTest
    private static void closedProjects() {
        List<Account> lstAcc = [SELECT Id, ParentId, Success_Team__c, Owner.Name FROM Account];

        Project__c project1 = TestDataFactory.createProject(
            true,
            null,
            lstAcc[0].Id,
            null,
            'PreInserted Project',
            'Closed won'
        );

        Test.startTest();
            Database.executeBatch(new AccountSuccessTeamReassignBatch());
        Test.stopTest();

        List<Account> lstAcc2 = [SELECT Id, ParentId, Success_Team__c, Owner.Name, Batch_Reassign__c FROM Account WHERE ParentId = null AND Success_Team__c = TRUE AND Owner.Name != 'Success Team'];
        System.assertEquals(lstAcc2[0].Batch_Reassign__c, objUser.Id, 'The Batch_Reassign__c field was not populated');
    }

    @isTest
    private static void open_LastActivityLessThanLast7Days() {
        List<Account> lstAcc = [SELECT Id, ParentId, Success_Team__c, Owner.Name FROM Account];

        Contact objContact = new Contact();
        objContact.FirstName = 'TestMan';
        objContact.LastName = 'LastNamington';
        objContact.Primary_Email__c = 'TestMan@domain.com';
        insert objContact;

        Datetime dtLastDate = Datetime.now().addDays(-15);
        Test.setCreatedDate(objContact.Id, dtLastDate);

        Project__c project1 = TestDataFactory.createProject(
            true,
            objContact.Id,
            lstAcc[0].Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Test.startTest();
            Database.executeBatch(new AccountSuccessTeamReassignBatch());
        Test.stopTest();

        List<Account> lstAcc2 = [SELECT Id, ParentId, Success_Team__c, Owner.Name, Batch_Reassign__c FROM Account WHERE ParentId = null AND Success_Team__c = TRUE AND Owner.Name != 'Success Team'];
        System.assertEquals(lstAcc2[0].Batch_Reassign__c, null, 'The Batch_Reassign__c field was populated');
    }

    @isTest
    private static void open_CreatedDateLessThanLast7Days() {
        List<Account> lstAcc = [SELECT Id, ParentId, Success_Team__c, Owner.Name FROM Account];
        
        Project__c project1 = TestDataFactory.createProject(
            true,
            null,
            lstAcc[0].Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Datetime dtLastDate = Datetime.now().addDays(-15);
        Test.setCreatedDate(project1.Id, dtLastDate);

        Test.startTest();
            Database.executeBatch(new AccountSuccessTeamReassignBatch());
        Test.stopTest();

        List<Account> lstAcc2 = [SELECT Id, ParentId, Success_Team__c, Owner.Name, Batch_Reassign__c FROM Account WHERE ParentId = null AND Success_Team__c = TRUE AND Owner.Name != 'Success Team'];
        System.assertEquals(lstAcc2[0].Batch_Reassign__c, objUser.Id, 'The Batch_Reassign__c field was not populated');
    }

    @isTest
    private static void open_LastActivityGreaterThanLast7Days () {
        List<Account> lstAcc = [SELECT Id, ParentId, Success_Team__c, Owner.Name FROM Account];

        Contact objContact = new Contact();
        objContact.FirstName = 'TestMan';
        objContact.LastName = 'LastNamington';
        objContact.Primary_Email__c = 'TestMan@domain.com';
        insert objContact;

        Project__c project1 = TestDataFactory.createProject(
            true,
            objContact.Id,
            lstAcc[0].Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Test.startTest();
            Database.executeBatch(new AccountSuccessTeamReassignBatch());
        Test.stopTest();

        List<Account> lstAcc2 = [SELECT Id, ParentId, Success_Team__c, Owner.Name, Batch_Reassign__c FROM Account WHERE ParentId = null AND Success_Team__c = TRUE AND Owner.Name != 'Success Team'];
        System.assertEquals(lstAcc2[0].Batch_Reassign__c, null, 'The Batch_Reassign__c field was populated');
    }

    @isTest
    private static void open_CreatedDateGreaterThanLast7Days() {
        List<Account> lstAcc = [SELECT Id, ParentId, Success_Team__c, Owner.Name FROM Account];
        

        Project__c project1 = TestDataFactory.createProject(
            true,
            null,
            lstAcc[0].Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Test.startTest();
            Database.executeBatch(new AccountSuccessTeamReassignBatch());
        Test.stopTest();

        List<Account> lstAcc2 = [SELECT Id, ParentId, Success_Team__c, Owner.Name, Batch_Reassign__c FROM Account WHERE ParentId = null AND Success_Team__c = TRUE AND Owner.Name != 'Success Team'];
        System.assertEquals(lstAcc2[0].Batch_Reassign__c, null, 'The Batch_Reassign__c field was populated');
    }
}