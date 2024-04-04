@isTest
private class projectInfoUpdateBatch_Test {
    @TestSetup
    private static void setup() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c project = TestDataFactory.createProject(false, c.ID, a.Id, null, 'Project', 'Open');
        project.Last_Opp_Created_Date__c = Datetime.newInstance(1999, 1, 1);
        project.Last_Quote_Mod_Date__c = Datetime.newInstance(1999, 1, 1);
        insert project;

        Opportunity opp1 = TestDataFactory.createOpportunity(false, c.Id, a.Id, null, Date.newInstance(2019, 6, 14));
        opp1.Name = 'TestOpp1';
        opp1.Amount = 500;
        opp1.Primary__c = true;
        opp1.Project__c = project.Id;
        opp1.Last_Quote_Xometry_Create_Time__c = Datetime.newInstance(1999, 1, 1);
        insert opp1;

        Opportunity opp2 = TestDataFactory.createOpportunity(false, c.Id, a.Id, null, Date.newInstance(2019, 6, 14));
        opp2.Name = 'TestOpp2';
        opp2.Amount = 300;
        opp2.Project__c = project.Id;
        opp2.Last_Quote_Xometry_Create_Time__c = Datetime.newInstance(2019, 3, 3);
        insert opp2;

        Project__c project2 = TestDataFactory.createProject(false, c.ID, a.Id, null, 'Project', 'Open');
        project2.Last_Opp_Created_Date__c = Datetime.newInstance(1999, 1, 1);
        project2.Last_Quote_Mod_Date__c = Datetime.newInstance(1999, 1, 1);
        insert project2;

        Opportunity opp3 = TestDataFactory.createOpportunity(false, c.Id, a.Id, null, Date.newInstance(2019, 6, 14));
        opp3.Name = 'TestOpp3';
        opp3.Amount = 500;
        opp3.Primary__c = true;
        opp3.Project__c = project2.Id;        
        opp3.Last_Quote_Xometry_Create_Time__c = Datetime.newInstance(2019, 3, 3);
        insert opp3;

        Opportunity opp4 = TestDataFactory.createOpportunity(false, c.Id, a.Id, null, Date.newInstance(2019, 6, 14));
        opp4.Name = 'TestOpp4';
        opp4.Amount = 300;
        opp4.Primary__c = true;
        opp4.Project__c = project2.Id;
        opp4.Last_Quote_Xometry_Create_Time__c = Datetime.newInstance(1999, 1, 1);
        insert opp4;

        Project__c project3 = TestDataFactory.createProject(false, c.ID, a.Id, null, 'Project', 'Open');
        project3.Last_Opp_Created_Date__c = Datetime.newInstance(1999, 1, 1);
        project3.Last_Quote_Mod_Date__c = Datetime.newInstance(1999, 1, 1);
        insert project3;
        
        List<Opportunity> lstOpportunity = [SELECT Primary__c, Amount FROM Opportunity];
        System.debug(lstOpportunity);
    }

    @isTest
    private static void executeBatch() {
        Test.startTest();
            Database.executeBatch(new projectInfoUpdateBatch());
        Test.stopTest();

        List<Project__c> lstProjects = [SELECT Id, Last_Opp_Created_Date__c, Last_Quote_Mod_Date__c, Amount__c FROM Project__c];
        List<Opportunity> lstOpportunity = [SELECT Id, Last_Quote_Xometry_Create_Time__c, Opportunity_Create_Date__c, Primary__c FROM Opportunity];

        System.assertEquals(lstProjects[0].Last_Opp_Created_Date__c, lstOpportunity[1].Opportunity_Create_Date__c, 'The Last_Opp_Created_Date__c is wrong in the first project record');
        System.assertEquals(lstProjects[1].Last_Opp_Created_Date__c, lstOpportunity[3].Opportunity_Create_Date__c, 'The Last_Opp_Created_Date__c is wrong in the second project record');

        System.assertEquals(lstProjects[0].Last_Quote_Mod_Date__c, lstOpportunity[1].Last_Quote_Xometry_Create_Time__c, 'The Last_Quote_Mod_Date__c is wrong in the first project record');
        System.assertEquals(lstProjects[1].Last_Quote_Mod_Date__c, lstOpportunity[2].Last_Quote_Xometry_Create_Time__c, 'The Last_Quote_Mod_Date__c is wrong in the second project record');

        System.assertEquals(lstProjects[0].Amount__c, 500, 'The Amount__c is wrong in the first project record');
        System.assertEquals(lstProjects[1].Amount__c, 800, 'The Amount__c is wrong in the second project record');
    }
}