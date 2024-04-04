@isTest
private class updateAccountOrderERPInfoBatch_Test {
    
    @isTest
    static void scheduleJob() {
        //Call job
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String jobID = System.schedule('updateAccountOrderERPInfoBatchJob', CRON_EXP, new updateAccountOrderERPInfoBatchJob());
        Test.stopTest();
    }

    @isTest
    static void excecuteBatch() {
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        
        // Create an Order
        Order_ERP__C ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q00-0000-0000',
            'AAAAA-00004',
            '55555',
            testAccount,
            myretContact,
            Date.newInstance(2019, 10, 22),
            DateTime.newInstance(2019, 10, 22, 11, 15, 0)
        );

        ord.ERP_Contact__c = 'AAAAA';
        ord.Payment_Type__c = 'credit_card';
        ord.process_isCNC_Machining__c = true;
        ord.process_isPolyJet_3D__c = false;
        ord.Order_Total__c = 1500;
        ord.Order_Subtotal__c = 1450;
        insert ord;
        
        Test.startTest();
        updateAccountOrderERPInfoBatch uAQI = new updateAccountOrderERPInfoBatch();
        ID batchID = Database.executeBatch(uAQI, 200);
        Test.stopTest();
        Account myAccount = [
            SELECT
                ID,
                Name,
                Number_Orderers__c,
                Number_Quoters__c,
                Date_of_First_Order__c,
                Date_of_Last_Order__c
            FROM Account
            WHERE ID = :testAccountID
        ];
        
        System.assertEquals(
            date.newInstance(2019, 10, 22),
            myAccount.Date_of_First_Order__c,
            'Account should have supplies first quote date'
        );
    }
    
}