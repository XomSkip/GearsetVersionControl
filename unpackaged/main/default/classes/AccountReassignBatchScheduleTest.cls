@isTest
public class AccountReassignBatchScheduleTest {
    @isTest
    static void AccountReassignBatchScheduleTest() {
        String CRON_EXP = '0 0 0 1 1 ? *';
        Test.startTest();
        String jobID = System.schedule(
            'AccountReassignBatchScheduleTest',
            CRON_EXP,
            new AccountReassignBatchSchedule()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}