@isTest
public with sharing class ProjectBatchTest {
    @TestSetup
    private static void setup() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c project1 = new Project__c();
        project1.Primary_Contact__c = c.Id;
        project1.accountId__c = a.Id;
        project1.Project__c = 'PreInserted Project 1';
        project1.Stage__c = 'New';

        Project__c project2 = new Project__c();
        project2.Primary_Contact__c = c.Id;
        project2.accountId__c = a.Id;
        project2.Project__c = 'PreInserted Project 2';
        project2.Stage__c = 'New';

        Project__c project3 = new Project__c();
        project3.Primary_Contact__c = c.Id;
        project3.accountId__c = a.Id;
        project3.Project__c = 'PreInserted Project 3';
        project3.Stage__c = 'Closed Won';

        insert project1;
        insert project2;
        insert project3;

        Opportunity opp = new Opportunity();
        opp.StageName = 'Open';
        opp.AccountId = a.Id;
        opp.Primary_Contact__C = c.Id;
        opp.CloseDate = Date.newInstance(2019, 6, 14);
        opp.Name = 'TestOppOne';
        opp.Project__c = project1.Id;

        insert opp;
    }

    @isTest
    private static void projectBatchTest() {
        Test.startTest();
        ProjectBatch batch = new ProjectBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Project__c> projectList = [SELECT id, Stage__c, Closed_Lost_Reason__c FROM Project__c ORDER BY Project__c];

        System.assertEquals('New', projectList[0].Stage__c, 'First Project should be Open');
        System.assertEquals('Closed Lost', projectList[1].Stage__c, 'Second Project should be Closed Lost');
        System.assertEquals(
            'No Opportunities associated -- Closed automatically weekly',
            projectList[1].Closed_Lost_Reason__c,
            'Second Project should be Closed Lost'
        );
        System.assertEquals('Closed Won', projectList[2].Stage__c, 'Third Project should be Closed Won');
    }
}