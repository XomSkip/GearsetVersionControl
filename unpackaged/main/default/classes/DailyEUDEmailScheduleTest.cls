@isTest
public class DailyEUDEmailScheduleTest {
    @isTest
    static void DailyEUDEmailScheduleTest() {
        String CRON_EXP = '0 0 17 * * ?';
        Test.startTest();
        String jobID = System.schedule('DailyEUDEmailScheduleTest', CRON_EXP, new DailyEUDEmailSchedule());
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}