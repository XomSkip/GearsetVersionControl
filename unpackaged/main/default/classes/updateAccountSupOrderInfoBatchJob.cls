global class updateAccountSupOrderInfoBatchJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        updateAccountSupOrderInfoBatch uASOI = new updateAccountSupOrderInfoBatch();
        ID batchID = Database.executeBatch(uASOI, 200);
        System.debug('The batchID is : ' + batchID);
    }
}