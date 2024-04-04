global class DailyEUDEmailSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Call the pse form batch
        DailyEUDEmailBatch eudEmailBatch = new DailyEUDEmailBatch();
        id batchId = Database.executeBatch(eudEmailBatch, 5);
    }
}