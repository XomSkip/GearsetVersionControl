@isTest
public class projectDateUpdateFutureTest {
    @TestSetup
    static void makeProjects() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c project = TestDataFactory.createProject(false, c.ID, a.Id, null, 'Project', 'Open');
        project.Last_Opp_Created_Date__c = Datetime.newInstance(1999, 1, 1);
        project.Last_Quote_Mod_Date__c = Datetime.newInstance(1999, 1, 1);
        insert project;

        Opportunity opp1 = TestDataFactory.createOpportunity(false, c.Id, a.Id, null, Date.newInstance(2019, 6, 14));
        opp1.Name = 'TestOpp1';
        opp1.Project__c = project.Id;
        opp1.Last_Quote_Xometry_Create_Time__c = Datetime.newInstance(1999, 1, 1);
        opp1.StageName = 'Open';
        insert opp1;

        Opportunity opp2 = TestDataFactory.createOpportunity(false, c.Id, a.Id, null, Date.newInstance(2019, 6, 14));
        opp2.Name = 'TestOpp2';
        opp2.Amount = null;
        opp2.Project__c = project.Id;
        opp2.Last_Quote_Xometry_Create_Time__c = Datetime.newInstance(2019, 3, 3);
        opp2.StageName = 'Open';
        insert opp2;
    }

    @isTest
    static void projectDateUpdateFutureTest_replaceDates() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Set<Id> projId = new Set<Id>();
        projId.add(project.Id);

        Test.startTest();
        projectDateUpdateFuture.updateProjectDates(projId);
        Test.stopTest();

        Project__c modifiedProject = [SELECT Id, Last_Opp_Created_Date__c FROM Project__c WHERE Id = :project.Id];

        System.assertEquals(
            Date.today(),
            modifiedProject.Last_Opp_Created_Date__c.date(),
            'Last Opp Created Date not set'
        );
    }

    @isTest
    static void projectDateUpdateFutureTest_noErrorOnNull() {
        Set<Id> nullSet = new Set<Id>();
        nullSet.add(null);
        Boolean errored = false;

        Test.startTest();
        try {
            projectDateUpdateFuture.updateProjectDates(nullSet);
        } catch (Exception e) {
            errored = true;
        }

        Test.stopTest();

        System.assertEquals(false, errored, 'Inserting null value caused error');
    }
}