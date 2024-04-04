global class UpdateSourcingCasesSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        UpdateSourcingCasesBatch sourcingCasesBatch = new UpdateSourcingCasesBatch();
        id batchId = Database.executeBatch(sourcingCasesBatch);
    }
}