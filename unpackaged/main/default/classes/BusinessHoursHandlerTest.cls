@IsTest
private class BusinessHoursHandlerTest {
    @isTest
    static void calculateHoursAwaitingCustomerTest() {
        Case caseRecord = new Case();
        Test.startTest();
        insert caseRecord;
        Case insertedCase = [SELECT Id, dateTimeSetToAwaitingCustomer__c, CreatedDate FROM Case LIMIT 1];
        insertedCase.dateTimeSetToAwaitingCustomer__c = DateTime.Now();
        update insertedCase;
        Test.stopTest();
        List<DateTime> dateTimes = new List<DateTime>();
        dateTimes.add(insertedCase.dateTimeSetToAwaitingCustomer__c);
        System.Assert(0 == BusinessHoursHandler.calculateHoursAwaitingCustomer(dateTimes)[0], 'The value returned is different from 0');      
    }
}