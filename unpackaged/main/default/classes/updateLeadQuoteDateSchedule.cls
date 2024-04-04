global class updateLeadQuoteDateSchedule implements schedulable {
    global void execute(SchedulableContext ctx) {
        updateLeadQuoteDates uLQD = new updateLeadQuoteDates();
        ID batchID = Database.executeBatch(uLQD);
    }
}