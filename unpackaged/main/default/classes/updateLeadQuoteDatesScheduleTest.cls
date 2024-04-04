@isTest
private class updateLeadQuoteDatesScheduleTest {
    @isTest
    static void updateLeadQuoteDatesScheduleTest1() {
        // Create the Test Quote
        List<Quote_ERP__C> testQuoteList = TestDataFactory.createTestQuotesToLeads(3, 2);

        String CRON_EXP = '0 0 0 1 1 ? *';
        //Call job
        Test.startTest();
        String jobID = System.schedule('UpdateLeadQuoteDateSchedule', CRON_EXP, new updateLeadQuoteDateSchedule());
        Test.stopTest();
    }
}