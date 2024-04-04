global class monthlyAggCalcSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Call the monthlyAcctAggReCalc to recalulate the Accounts YTDSpend and Rolling12
        // batch
        monthlyAcctAggReCalc mac = new monthlyAcctAggReCalc();
        ID batchID = Database.executeBatch(mac, 50);
    }
}