global with sharing class AccountSuccessTeamReassignBatchJob implements Schedulable{
    global void execute(SchedulableContext ctx) {
        id batchId = Database.executeBatch(new AccountSuccessTeamReassignBatch(), 200);
    }
}