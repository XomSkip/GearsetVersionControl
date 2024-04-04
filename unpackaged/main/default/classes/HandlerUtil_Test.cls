@isTest
public with sharing class HandlerUtil_Test {
    @isTest(seeAllData=false)
    public static void leadConverterFromQuoteTest() {
        Account testAccount = new Account();
        testAccount.Name = 'NewAccount';
        testAccount.Email_Domain__c = 'mydomain.com';
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            Primary_Email__c = 'test@test123.com',
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert testContact;

        Quote_ERP__c myQuote = new Quote_ERP__C();
        myQuote.Account_Domain__C = 'SuperCompany2.com';
        myQuote.ERP_PartPK__c = 'A1234-A5678';
        myQuote.Quote_Price__c = 50.15;
        myQuote.Xometry_ERP_ID__C = 'AAAAA-00001';
        myQuote.ERP_Contact__c = 'AAAAA';
        myQuote.IS_Generic__c = true;
        myQuote.Quote_Email__c = 'johndoe@SuperCompany2.com';
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2019, 6, 14);
        myQuote.ContactID__c = testContact.Id;
        myQuote.AccountId__c = testAccount.Id;
        insert myQuote;

        Lead l = new Lead();
        l.Primary_Email__c = myQuote.Quote_Email__c;
        l.LastName = 'Test';
        l.Company = 'TestCompany';
        insert l;

        System.assertEquals(false, [SELECT isConverted FROM Lead WHERE Id = :l.Id].isConverted);

        Test.startTest();

        List<Database.LeadConvertResult> convertResult = HandlerUtil.leadConverter(new List<Quote_ERP__c>{ myQuote });

        Test.stopTest();

        System.assertEquals(true, convertResult[0].isSuccess());
        System.assertEquals(true, [SELECT isConverted FROM Lead WHERE Id = :l.Id].isConverted);
    }

    @isTest(seeAllData=false)
    public static void leadConverterFromOrderTest() {
        Lead l = new Lead();
        l.Primary_Email__c = 'janedoe@SuperCompany.com';
        l.LastName = 'Test';
        l.Company = 'SuperCompany';
        insert l;

        Quote_ERP__c myQuote = new Quote_ERP__C();
        myQuote.Account_Domain__C = 'SuperCompany2.com';
        myQuote.ERP_PartPK__c = 'A1234-A5678';
        myQuote.Quote_Price__c = 50.15;
        myQuote.Xometry_ERP_ID__C = 'AAAAC-00123';
        myQuote.ERP_Contact__c = 'AAAAA';
        myQuote.IS_Generic__c = true;
        myQuote.Quote_Email__c = 'johndoe@SuperCompany2.com';
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2019, 6, 14);
        insert myQuote;

        Integer thisYear = Date.today().year();
        Order_ERP__C order = new Order_ERP__C();
        order.Account_Domain__C = 'mydomain.com';
        order.ERP_Company_Name__c = 'MyCompanyName';
        order.ERP_Contact_First_Name__c = 'Amy';
        order.ERP_Contact_Last_Name__c = 'Adams';
        order.ERP_Contact__c = 'AAAAC';
        order.ERP_PartPk__c = '44444-555123';
        order.Is_Generic__c = false;
        order.Order_Email__c = 'amyadam@mydomain.com';
        order.Order_ERP_CreatedDate__c = Date.newInstance(thisYear - 2, 12, 5);
        order.Order_ERP_Time__c = Datetime.newInstanceGMT(thisYear - 2, 12, 5, 18, 0, 0);
        order.Order_Subtotal__c = 450.00;
        order.Order_Total__c = 500.00;
        order.process_isCNC_Machining__c = true;
        order.Shipping__c = 50.00;
        order.LeadID__c = l.Id;
        order.Xometry_ERP_ID__c = 'AAAAC-00123';
        insert order;

        myQuote.LeadID__c = l.Id;
        update myQuote;

        System.assertEquals(false, [SELECT isConverted FROM Lead WHERE Id = :l.Id].isConverted);

        Test.startTest();

        List<Database.LeadConvertResult> convertResult = HandlerUtil.leadConverter(new List<Order_Erp__c>{ order });

        Test.stopTest();

        System.assertEquals(true, convertResult[0].isSuccess());
        System.assertEquals(true, [SELECT isConverted FROM Lead WHERE Id = :l.Id].isConverted);
    }

    @isTest(seeAllData=false)
    public static void leadConverterFromContactTest() {
        Account testAccount = new Account();
        testAccount.Name = 'NewAccount';
        testAccount.Email_Domain__c = 'mydomain.com';
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            Primary_Email__c = 'test@test123.com',
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert testContact;

        Lead l = new Lead();
        l.Primary_Email__c = testContact.Primary_Email__c;
        l.LastName = 'Test';
        l.Company = 'TestCompany';
        insert l;

        System.assertEquals(false, [SELECT isConverted FROM Lead WHERE Id = :l.Id].isConverted);

        Test.startTest();

        List<Database.LeadConvertResult> convertResult = HandlerUtil.leadConverter(new List<Contact>{ testContact });

        Test.stopTest();

        System.assertEquals(true, convertResult[0].isSuccess());
        System.assertEquals(true, [SELECT isConverted FROM Lead WHERE Id = :l.Id].isConverted);
    }
}