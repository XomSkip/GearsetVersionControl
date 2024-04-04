global class ValidationLostClosedProjectsBatchJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        id batchId = Database.executeBatch(new ValidationLostClosedProjectsBatch());
    }
}