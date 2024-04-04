@isTest
public class AccountSuccessTeamReassignBatchJob_Test {
    @isTest
    static void AccountSuccessTeamReassignBatchJob_Test() {
        String CRON_EXP = '0 0 0 1 1 ? *';
        Test.startTest();
        String jobID = System.schedule(
            'AccountSuccessTeamReassignBatchJob_Test',
            CRON_EXP,
            new AccountSuccessTeamReassignBatchJob()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}