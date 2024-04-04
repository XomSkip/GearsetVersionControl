global class updateAccountQuoteERPInfoBatchJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        updateAccountQuoteERPInfoBatch uAQI = new updateAccountQuoteERPInfoBatch();
        ID batchID = Database.executeBatch(uAQI, 100);
        System.debug('The batchID is : ' + batchID);
    }
}