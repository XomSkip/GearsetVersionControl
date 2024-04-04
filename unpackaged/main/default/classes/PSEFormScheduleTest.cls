@isTest
public class PSEFormScheduleTest {
    @isTest
    static void PSEFormScheduleTest() {
        String CRON_EXP = '0 0 0 1 1 ? *';
        Test.startTest();
        String jobID = System.schedule('PSEFormScheduleTest', CRON_EXP, new PSEFormSchedule());
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}