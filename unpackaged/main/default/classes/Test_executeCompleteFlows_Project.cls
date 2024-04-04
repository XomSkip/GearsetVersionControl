@IsTest
public class Test_executeCompleteFlows_Project {
    @IsTest
    static void testExecuteCompleteFlows() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];
        Boolean caughtException = false;

        // Create a new record and update
        try {
            Project__c proj = TestDataFactory.createProject(true, c.ID, a.Id, a.OwnerId, 'Traction Test', 'Open');

            Test.startTest();
            update proj;
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());

            caughtException = true;
        }

        System.assertEquals(false, caughtException);
        Test.stopTest();
    }
}