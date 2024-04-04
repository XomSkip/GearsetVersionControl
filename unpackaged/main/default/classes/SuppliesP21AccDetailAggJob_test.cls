@isTest
private class SuppliesP21AccDetailAggJob_test {
    @isTest
    static void SuppliesP21AccDetailAggJob_test() {
        String CRON_EXP = '0 0 0 1 1 ? *';
        Test.startTest();
        String jobID = System.schedule('SuppliesP21AccDetailAggJob_Test', CRON_EXP, new SuppliesP21AccDetailAggJob());
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}