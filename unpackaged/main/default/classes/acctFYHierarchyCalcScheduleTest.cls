@isTest
public class acctFYHierarchyCalcScheduleTest {
    @isTest
    static void AccountHierachyCalcScheduleTest() {
        String CRON_EXP = '0 0 0 1 1 ? *';
        Test.startTest();
        String jobID = System.schedule(
            'acctFYHierarchyCalcSchedule Scheduled Test',
            CRON_EXP,
            new acctFYHierarchyCalcSchedule()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}