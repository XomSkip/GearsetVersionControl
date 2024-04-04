@isTest
private class ApexBypassUtilityTest {
    @isTest
    private static void apexShouldRunTest() {

        Boolean returnValue;

        Test.startTest();
        returnValue = ApexBypassUtility.shouldRun('test');
        Test.stopTest();

        System.assertNotEquals(null, returnValue);
        
    }
}