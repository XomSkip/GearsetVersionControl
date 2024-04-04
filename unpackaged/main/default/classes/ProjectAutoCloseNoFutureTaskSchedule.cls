global class ProjectAutoCloseNoFutureTaskSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Call the project batch
        ProjectAutoCloseNoFutureTaskBatch batch = new ProjectAutoCloseNoFutureTaskBatch();
        id batchId = Database.executeBatch(batch, 50);
    }
}