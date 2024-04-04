global class LeadConvertToContactBatchJobScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        LeadConvertToContactBatchJob b = new LeadConvertToContactBatchJob('');
        Id jobId = Database.executeBatch(b);
    }
}