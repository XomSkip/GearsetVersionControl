@isTest
private class updateLeadQuoteDateTest {
    @isTest
    static void updateLeadQuoteDateTest1() {
        // Create the Test Quote
        List<Quote_ERP__C> testQuoteList = TestDataFactory.createTestQuotesToLeads(3, 2);

        String CRON_EXP = '0 0 0 1 1 ? *';
        //Call job
        Test.startTest();
        //Start the batch
        updateLeadQuoteDates uLQD = new updateLeadQuoteDates();
        id batchID = Database.executeBatch(uLQD);
        Test.stopTest();
    }
}