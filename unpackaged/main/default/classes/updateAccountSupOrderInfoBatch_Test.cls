@isTest
private class updateAccountSupOrderInfoBatch_Test {
    @isTest
    static void scheduleJob() {
        //Call job
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String jobID = System.schedule('updateAccountSupOrderInfoBatchJob', CRON_EXP, new updateAccountSupOrderInfoBatchJob());
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
                
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = myretContact.Email;
        sOrderTest.Account_Domain__c = testAccount.Email_Domain__c;
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = myretContact.FirstName;
        sOrderTest.P21_Contact_Last_Name__c = myretContact.LastName;
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Processing';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 500.50;
        insert sOrderTest;

        Test.startTest();
        updateAccountSupOrderInfoBatch uAQD = new updateAccountSupOrderInfoBatch();
        ID batchID = Database.executeBatch(uAQD);
        System.debug('The batchID is : ' + batchID);
        Test.stopTest();
        Account myAccount = [
            SELECT
                ID,
                Name,
                Sup_NumberOfOrderers__c,
                Sup_DateOfFirstOrder__c,
                Sup_DateOfLastOrder__c
            FROM Account
            Limit 1
        ];
        
        System.assertEquals(
            date.newInstance(2021, 10, 28),
            myAccount.Sup_DateOfFirstOrder__c,
            'Account should have supplies first quote date'
        );
    }
}