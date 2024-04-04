global class updateAccountOrderERPInfoBatchJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        updateAccountOrderERPInfoBatch uAOI = new updateAccountOrderERPInfoBatch();
        ID batchID = Database.executeBatch(uAOI, 100);
        System.debug('The batchID is : ' + batchID);
    }
}