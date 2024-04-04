global class acctFYHierarchyCalcSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        //Call the batch
        acctFYHierarchyCalc acctCalcBatch = new acctFYHierarchyCalc();
        id batchId = Database.executeBatch(acctCalcBatch);
    }
}