global class CloseOldOpportunitiesBatchJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        id batchId = Database.executeBatch(new CloseOldOpportunitiesBatch());
    }
}