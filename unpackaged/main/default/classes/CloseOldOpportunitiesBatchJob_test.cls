@isTest
public class CloseOldOpportunitiesBatchJob_test {
    @isTest
    static void CloseOldOpportunitiesBatchJob_test() {
        String CRON_EXP = '0 0 0 1 1 ? *';
        Test.startTest();
        String jobID = System.schedule('CloseOldOpportunitiesBatchJob', CRON_EXP, new CloseOldOpportunitiesBatchJob());
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}