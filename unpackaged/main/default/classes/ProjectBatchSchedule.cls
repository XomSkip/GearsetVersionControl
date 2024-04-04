global class ProjectBatchSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Call the project batch
        ProjectBatch projectBatch = new ProjectBatch();
        id batchId = Database.executeBatch(projectBatch);
    }
}