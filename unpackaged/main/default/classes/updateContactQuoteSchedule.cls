global class updateContactQuoteSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        updateContactQuoteDates uCQD = new updateContactQuoteDates();
        ID batchID = Database.executeBatch(uCQD);
        System.debug('The batchID is : ' + batchID);
    }
}