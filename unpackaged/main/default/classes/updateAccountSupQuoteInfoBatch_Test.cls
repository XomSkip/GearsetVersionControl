@isTest
private class updateAccountSupQuoteInfoBatch_Test {

    @isTest
    static void scheduleJob() {
        //Call job
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String jobID = System.schedule('updateAccountSupQuoteInfoBatchJob', CRON_EXP, new updateAccountSupQuoteInfoBatchJob());
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
        
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = myretContact.Email;
        sQuoteTest.Account_Domain__c = testAccount.Email_Domain__c;
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = myretContact.FirstName;
        sQuoteTest.P21_Contact_Last_Name__c = myretContact.LastName;
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Processing';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        insert sQuoteTest;
        
        Test.startTest();
        updateAccountSupQuoteInfoBatch uAQD = new updateAccountSupQuoteInfoBatch();
        ID batchID = Database.executeBatch(uAQD);
        System.debug('The batchID is : ' + batchID);
        Test.stopTest();

        Account myAccount = [
            SELECT
                ID,
                Name,
                Sup_NumberQuoters__c,
                Sup_DateOfFirstQuote__c,
                Sup_DateOfLastQuote__c
            FROM Account
            WHERE ID = :testAccountID
        ];
        
        System.assertEquals(
            date.newInstance(2021, 10, 28),
            myAccount.Sup_DateOfFirstQuote__c,
            'Account should have supplies first quote date'
        );
    }
}