global class ContactLeadsConvertScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        ContactLeadsConvertBatch batch = new ContactLeadsConvertBatch(' WHERE CreatedDate = LAST_N_DAYS:8 ');
        Id batchId = Database.executeBatch(batch);
    }
}