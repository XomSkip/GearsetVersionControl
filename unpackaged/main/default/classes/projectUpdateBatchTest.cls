@isTest
public class projectUpdateBatchTest {
    @TestSetup
    static void makeProjects() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c project = new Project__c();
        project.Primary_Contact__c = c.Id;
        project.accountId__c = a.Id;
        project.Project__c = 'Project';
        project.Stage__c = 'Open';
        project.Last_Opp_Created_Date__c = Datetime.newInstance(1999, 1, 1);
        project.Last_Quote_Mod_Date__c = Datetime.newInstance(1999, 1, 1);
        insert project;

        Opportunity opp1 = new Opportunity();
        opp1.StageName = 'New';
        opp1.AccountId = a.Id;
        opp1.Primary_Contact__C = c.Id;
        opp1.CloseDate = Date.newInstance(2019, 6, 14);
        opp1.Name = 'TestOpp1';
        opp1.Project__c = project.Id;
        opp1.Last_Quote_Xometry_Create_Time__c = Datetime.newInstance(1999, 1, 1);
        insert opp1;

        Opportunity opp2 = new Opportunity();
        opp2.StageName = 'New';
        opp2.AccountId = a.Id;
        opp2.Primary_Contact__C = c.Id;
        opp2.CloseDate = Date.newInstance(2019, 6, 14);
        opp2.Name = 'TestOpp2';
        opp2.Project__c = project.Id;
        opp2.Last_Quote_Xometry_Create_Time__c = Datetime.newInstance(2019, 3, 3);
        insert opp2;
    }

    @isTest
    static void projectUpdateBatchTest_replaceDates() {
        Datetime lastQuoteCreateTime = Datetime.newInstance(1800, 5, 5);

        List<Opportunity> testOpps = [
            SELECT Id, Opportunity_Create_Date__c, Last_Quote_Xometry_Create_Time__c
            FROM Opportunity
            LIMIT 2
        ];
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity o : testOpps) {
            oppIds.add(o.Id);
            if (o.Last_Quote_Xometry_Create_Time__c > lastQuoteCreateTime) {
                lastQuoteCreateTime = o.Last_Quote_Xometry_Create_Time__c;
            }
        }

        Test.startTest();
        System.enqueueJob(new projectUpdateBatch(oppIds));
        Test.stopTest();

        Project__c modifiedProject = [
            SELECT Id, Last_Opp_Created_Date__c, Last_Quote_Mod_Date__c
            FROM Project__c
            WHERE Id = :project.Id
        ];

        System.assertEquals(Date.today(), modifiedProject.Last_Opp_Created_Date__c.date(), 'Last Opp Created Date not set');
        System.assertEquals(lastQuoteCreateTime, modifiedProject.Last_Quote_Mod_Date__c, 'Last Quote Mod Date not set');
    }


    @isTest
    static void projectUpdateBatchTest_saveToDatabaseNullMethod() {
        boolean exceptionEncountered = false;

        Test.startTest();
        try {
            projectUpdateBatch.saveToDatabase(new List<SObject>(), '', 'Sample note');
        } catch (IllegalArgumentException caughtException) {
            exceptionEncountered = true;
        }
        Test.stopTest();

        System.assert(exceptionEncountered, 'Exception not encountered.');
    }

    @isTest
    private static void projectUpdateBatchTest_saveToDatabaseNullDevNote() {
        boolean exceptionEncountered = false;

        Test.startTest();
        try {
            projectUpdateBatch.saveToDatabase(new List<SObject>(), 'Sample Method', '');
        } catch (IllegalArgumentException caughtException) {
            exceptionEncountered = true;
        }
        Test.stopTest();

        System.assert(exceptionEncountered, 'Exception not encountered.');
    }
}