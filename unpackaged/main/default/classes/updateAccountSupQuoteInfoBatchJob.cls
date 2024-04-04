global class updateAccountSupQuoteInfoBatchJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        updateAccountSupQuoteInfoBatch uASQI = new updateAccountSupQuoteInfoBatch();
        ID batchID = Database.executeBatch(uASQI, 200);
        System.debug('The batchID is : ' + batchID);
    }
}