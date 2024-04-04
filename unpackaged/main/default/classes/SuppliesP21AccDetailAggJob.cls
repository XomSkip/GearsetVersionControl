global class SuppliesP21AccDetailAggJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        id batchId = Database.executeBatch(new SuppliesP21AccDetailsAggBatch());
    }
}