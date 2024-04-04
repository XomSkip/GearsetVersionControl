@isTest
private class monthlyContAggReCalcTest {
    @TestSetup
    private static void setup() {
        ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Manufacturing_Services')
            .getRecordTypeID();
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 3);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        List<Order_ERP__C> newOrdersList = new List<Order_ERP__C>();
        List<Contact> myretContactList = [
            SELECT Id, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        Date myDate = Date.today();
        Datetime myDateTime = Datetime.now();
        Contact contact1 = myretContactList[0];
        Contact contact2 = myretContactList[1];
        Opportunity testOpp = new Opportunity();
        testOpp.RecordTypeId = oppManufacturingServRTypeID;
        testOpp.Name = 'Test';
        testOpp.Primary_Contact__c = contact1.Id;
        testOpp.AccountId = testAccount.Id;
        testOpp.Amount = 10000;
        testOpp.StageName = 'Open';
        testOpp.CloseDate = Date.today();
        insert testOpp;

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
        newOrdersList.add(order1);

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
        newOrdersList.add(order2);
        insert newOrdersList;
    }

    @isTest
    private static void monthlyAggTest() {
        Test.startTest();
        monthlyContAggReCalc batch = new monthlyContAggReCalc();
        Database.executeBatch(batch);
        Test.stopTest();
        Contact testContact = [
            SELECT
                Id,
                YTD_Spend__c,
                Rolling_12_Spend__c,
                Number_of_Open_Opportunities__c,
                Lifetime_Spend__c,
                Number_Orders__c
            FROM Contact
            LIMIT 1
        ];
        System.assertEquals(10000, testContact.YTD_Spend__c, 'YTD_Spend__c was wrong');
        System.assertEquals(10000, testContact.Rolling_12_Spend__c, 'Rolling_12_Spend__c was wrong');
        System.assertEquals(10000, testContact.Lifetime_Spend__c, 'Lifetime_Spend__c was wrong');
        System.assertEquals(2, testContact.Number_Orders__c, 'Number_Orders__c was wrong');
        System.assertEquals(
            1,
            testContact.Number_of_Open_Opportunities__c,
            'Number_of_Open_Opportunities__c was wrong'
        );
    }
}