global class monthlyContAggReCalcSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Call the monthlyAcctAggReCalc to recalulate the Accounts YTDSpend and Rolling12
        // batch
        monthlyContAggReCalc mCAC = new monthlyContAggReCalc();
        ID batchID = Database.executeBatch(mCAC);
    }
}