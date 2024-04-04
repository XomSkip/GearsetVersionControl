@isTest
public class SuppliesOppAggSchedule_Test {
    public SuppliesOppAggSchedule_Test() {
        String CRON_EXP = '0 5 * * *';
        Test.startTest();
        String jobID = System.schedule('SuppliesOppAggSchedule_Test', CRON_EXP, new SuppliesOppAggSchedule());
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}