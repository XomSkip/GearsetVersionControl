@isTest
private class updateAccountQuoteERPInfoBatch_Test {
    
    @isTest
    static void scheduleJob() {
        //Call job
        Test.startTest();
        String CRON_EXP = '0 0 0 1 1 ? *';
        String jobID = System.schedule('updateAccountQuoteERPInfoBatchJob', CRON_EXP, new updateAccountQuoteERPInfoBatchJob());
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
        
        // Create a Quote
        Quote_ERP__C quote2 = new Quote_ERP__C();
        quote2.Account_Domain__c = testAccount.Email_Domain__c;
        quote2.Quote_ERP_Created_Date__C = Date.newInstance(2019, 10, 23);
        quote2.Quote_ERP_Created_Time__c = DateTime.newInstance(2019, 10, 23, 11, 15, 0);
        quote2.ERP_User_Company_Name__c = testAccount.name;
        quote2.ERP_Contact__C = 'AAAAA';
        quote2.ERP_Contact_First_Name__c = myretContact.FirstName;
        quote2.ERP_Contact_Last_Name__C = myretContact.LastName;
        quote2.Quote_Email__c = myretContact.Email;
        quote2.Xometry_ERP_ID__c = 'AAAAA-00005';
        quote2.ERP_PartPK__c = '44444';
        quote2.process_isSLS__c = true;
        quote2.Quote_Price__c = 15000;
        insert quote2;

        //Call job
        Test.startTest();
        updateAccountQuoteERPInfoBatch uAQI = new updateAccountQuoteERPInfoBatch();
        ID batchID = Database.executeBatch(uAQI, 200);
        Test.stopTest();

        Account myAccount = [
            SELECT
                ID,
                Name,
                Number_Quoters__c,
                Date_of_First_Quote__c,
                Date_of_Last_Quote__c
            FROM Account
            WHERE ID = :testAccountID
        ];
        
        System.assertEquals(
            date.newInstance(2019, 10, 23),
            myAccount.Date_of_First_Quote__c,
            'Account should have supplies first quote date'
        );
    }
}