global class SuppliesOppAggSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        SuppliesOppAggBatch sOppBatch = new SuppliesOppAggBatch();
        id batchId = Database.executeBatch(sOppBatch);
    }
}