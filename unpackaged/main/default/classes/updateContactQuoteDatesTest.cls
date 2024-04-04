@isTest
private class updateContactQuoteDatesTest {
    @isTest
    static void updateContactQuoteDatesTestv1() {
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        String lemail = myretContact.Email;
        Date myDate = Date.today();
        Datetime myDateTime = Datetime.now();
        List<Contact> myContactList = [SELECT ID, Name, Email FROM Contact];
        for (contact c : myContactList) {
            System.debug('Start The name is ' + c.Name);
            System.debug('Start The name is ' + c.Email);
        }
        // Create an Order
        // Create a Quote
        String CRON_EXP = '0 0 0 1 1 ? *';
        //Call job
        Test.startTest();
        Order_ERP__C ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
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

        Quote_ERP__C quote2 = new Quote_ERP__C();
        quote2.Account_Domain__c = testAccount.Email_Domain__c;
        quote2.Quote_ERP_Created_Date__C = Date.newInstance(2019, 10, 23);
        quote2.Quote_ERP_Created_Time__c = DateTime.newInstance(2019, 10, 23, 11, 15, 0);
        quote2.ERP_User_Company_Name__c = testAccount.name;
        quote2.ERP_Contact__C = 'AAAAA';
        quote2.ERP_Contact_First_Name__c = myretContact.FirstName;
        quote2.ERP_Contact_Last_Name__C = myretContact.LastName;
        quote2.Quote_Email__c = myretContact.Email;
        quote2.Xometry_ERP_ID__c = 'Q12-333-5555';
        quote2.ERP_PartPK__c = '44444';
        quote2.process_isSLS__c = true;
        quote2.Quote_Price__c = 15000;
        insert quote2;
        String jobID = System.schedule('UpdateContactQuoteScheduleTest', CRON_EXP, new updateContactQuoteSchedule());
        Test.stopTest();
        Contact myContact = [
            SELECT
                ID,
                Name,
                Contact_s_Date_of_First_Order__c,
                First_Quote_Date__c,
                Date_of_Last_Order__c,
                Date_of_Last_Quote__c
            FROM Contact
            WHERE ID = :myretContact.ID
        ];
        System.debug('The First Order Date should be : ' + myContact.Contact_s_Date_of_First_Order__c);
        System.debug('The First Quote Date should be : ' + myContact.First_Quote_Date__c);
        Integer myInt = [SELECT COUNT() FROM Contact];
        List<Contact> myContactList1 = [SELECT ID, Name, Email FROM Contact];
        for (contact c : myContactList1) {
            System.debug('The name is ' + c.Name);
            System.debug('The name is ' + c.Email);
        }
        System.debug('The number of Contacts is : ' + myInt);
    }

    @isTest
    static void updateContactSuppliesQuoteDatesTestv1() {
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        String lemail = myretContact.Email;
        Date myDate = Date.today();
        Datetime myDateTime = Datetime.now();
        List<Contact> myContactList = [SELECT ID, Name, Email FROM Contact];
        for (contact c : myContactList) {
            System.debug('Start The name is ' + c.Name);
            System.debug('Start The name is ' + c.Email);
        }
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
        updateContactQuoteDates uCQD = new updateContactQuoteDates();
        ID batchID = Database.executeBatch(uCQD);
        System.debug('The batchID is : ' + batchID);
        Test.stopTest();
        Contact myContact = [
            SELECT
                ID,
                Name,
                Sup_NumberQuotes__c,
                Sup_DateOfFirstOrder__c,
                Sup_DateOfFirstQuote__c,
                Sup_DateOfLastOrder__c,
                Sup_DateOfLastQuote__c
            FROM Contact
            WHERE ID = :myretContact.ID
        ];
        Integer myInt = [SELECT COUNT() FROM Contact];
        List<Contact> myContactList1 = [SELECT ID, Name, Email FROM Contact];
        for (contact c : myContactList1) {
            System.debug('The name is ' + c.Name);
            System.debug('The name is ' + c.Email);
        }
        System.debug('The number of Contacts is : ' + myInt);

        System.assertEquals(
            date.newInstance(2021, 10, 28),
            myContact.Sup_DateOfFirstQuote__c,
            'Contact should have supplies first quote date'
        );
        System.assertEquals(
            date.newInstance(2021, 10, 28),
            myContact.Sup_DateOfLastOrder__c,
            'Contact should have supplies last order date'
        );
        System.assertEquals(1, myContact.Sup_NumberQuotes__c, 'Contact should have one quote count');
    }
}