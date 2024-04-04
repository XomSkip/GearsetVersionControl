global class updateAccountQuoteSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        updateAccountQuoteDates uAQD = new updateAccountQuoteDates();
        ID batchID = Database.executeBatch(uAQD, 100);
        System.debug('The batchID is : ' + batchID);
    }
}