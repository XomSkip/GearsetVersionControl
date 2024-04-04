@isTest
public class oppGetProjectBatchTest {
    @isTest
    static void testBatch() {
        //Create an Opp through quote
        Set<ID> testOppIDSet = new Set<ID>();
        testDataFactory.createQuoteWithAcc(true, 'AM');
        Opportunity testOpp = [SELECT Id, Project__c FROM Opportunity][0];
        testOppIDSet.add(testOpp.ID);
        //Delete the project
        Project__c testProject = new Project__c();
        testProject.ID = testOpp.Project__c;
        delete testProject;
        test.StartTest();
        Opportunity testOppSetup = [SELECT Id, Project__c FROM Opportunity WHERE ID = :testOpp.ID];
        List<Project__c> projectSize = [SELECT ID FROM Project__c];
        System.assertEquals(null, testOppSetup.Project__c, 'A project existed');
        System.assertEquals(0, projectSize.size(), 'The opp had a project');
        oppGetProjectBatch b = new oppGetProjectBatch();
        ID jobid = Database.executeBatch(b);
        test.StopTest();
        Opportunity testOppPost = [SELECT Id, Project__c FROM Opportunity WHERE ID = :testOpp.ID];
        System.assertEquals(true, String.isNotBlank(testOppPost.Project__c), 'The opp did not get a project');
        List<Project__c> projectPost = [SELECT ID FROM Project__c];
        System.assertEquals(1, projectPost.size(), 'There was no project');
    }
}