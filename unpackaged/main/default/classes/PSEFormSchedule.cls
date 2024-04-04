global class PSEFormSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Call the pse form batch
        PSEFormBatch pseBatch = new PSEFormBatch();
        id batchId = Database.executeBatch(pseBatch);
    }
}