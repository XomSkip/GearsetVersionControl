@isTest
public class ProjectBatchScheduleTest {
    @isTest
    static void ProjectBatchScheduleTest() {
        String CRON_EXP = '0 0 0 1 1 ? *';
        Test.startTest();
        String jobID = System.schedule('ProjectBatchScheduleTest', CRON_EXP, new ProjectBatchSchedule());
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}