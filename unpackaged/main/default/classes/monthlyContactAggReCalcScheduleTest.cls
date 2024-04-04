@isTest
global class monthlyContactAggReCalcScheduleTest {
    @isTest
    static void monthlyAggSchedTest1() {
        //Integer
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 3);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        //
        List<Order_ERP__C> newOrdersList = new List<Order_ERP__C>();
        List<Contact> myretContactList = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        Date myDate = Date.today();
        Datetime myDateTime = Datetime.now();
        //Create two orders for contact1
        //Create one order for contact2
        //Create zero orders for contact3
        Contact contact1 = myretContactList[0];

        Order_ERP__C order1 = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q00-0000-0001',
            'BBBBB-34567',
            '56564-55667',
            testAccount,
            contact1,
            myDate,
            myDateTime
        );
        Order_ERP__C order2 = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q00-0000-0002',
            'BBBBB-34568',
            '56564-55668',
            testAccount,
            contact1,
            myDate,
            myDateTime
        );
        newOrdersList.add(order1);
        newOrdersList.add(order2);
        insert newOrdersList;

        String CRON_EXP = '0 0 0 1 1 ? *';
        // String jobID = System.schedule('MonthlyConAggCalcSchedTest', CRON_EXP, new monthlyAggCalcSchedule());
        String jobID = System.schedule('MonthlyConAggCalcSchedTest', CRON_EXP, new monthlyContAggReCalcSchedule());
        Test.startTest();
        Test.stopTest();
        Contact retContact = [
            SELECT ID, Lifetime_Spend__c, Rolling_12_Spend__c, YTD_Spend__c
            FROM Contact
            WHERE ID = :contact1.ID
        ];
        System.debug(
            'The total spending for Contact 1 is  LifeTime_Spend__C : ' +
            retContact.LifeTime_Spend__C +
            ' YTD_Spend__C : ' +
            retContact.YTD_Spend__C
        );
    }
}