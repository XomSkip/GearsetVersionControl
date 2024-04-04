global with sharing class ProjectCloseInactiveBatchSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        ProjectCloseInactiveBatch b = new ProjectCloseInactiveBatch();
        id batchId = Database.executeBatch(b);
    }
}