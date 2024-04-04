global with sharing class AccountReassignBatchSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        AccountReassignBatch b = new AccountReassignBatch();
        id batchId = Database.executeBatch(b, 50);
    }
}