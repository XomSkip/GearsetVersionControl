@isTest
public class OrderERPTest {
    static final String WEST_COAST_BDR = '0053u000003HsnBAAS';
    @isTest
    static void orderTest1() {
        // Create two orders on Same Contact to Update Contacts order processes
        System.debug('Starting the Code Coverage');
        List<Quote_ERP__C> newQuotes = TestDataFactory.createTestQuotesToLeads(1, 2);

        Quote_ERP__C convertQuoteEx = newQuotes[0];
        List<Order_ERP__C> newOrderList = new List<Order_ERP__C>();
        //Create an Order
        Order_ERP__C ord = TestDataFactory.createOrderERPFromQuote(false, convertQuoteEx);
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.Order_Canceled_Flag__c = false;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.process_isDMLS__c = true;
        newOrderList.add(ord);

        Quote_ERP__C convertQuoteEx1 = newQuotes[1];
        Order_ERP__C ord1 = TestDataFactory.createOrderERPFromQuote(false, convertQuoteEx1);
        ord1 = TestDataFactory.setTrueProcessFieldsQuote(ord1);
        ord1.Xometry_ERP_ID__c = 'BBBBB-34568';
        ord1.order_Canceled_Flag__c = false;
        ord1.Order_Subtotal__c = 5000.00;
        ord1.Order_Total__c = 6000.50;
        ord1.Payment_Type__c = 'purchase_order';
        newOrderList.add(ord1);

        Test.startTest();
        insert newOrderList;
        Test.stopTest();

        ID createdOrderID = newOrderList[0].ID;
        Order_ERP__C myOrder = [SELECT ID, ContactID__C FROM Order_ERP__C WHERE ID = :createdOrderID LIMIT 1];
        ID myContactID = myOrder.ContactID__C;
        Integer numofContactOrders = [SELECT COUNT() FROM Order_ERP__C WHERE ContactID__C = :myContactID];
        Contact myContactProcesses = [SELECT ID, has_ordered_SLS__c FROM Contact WHERE ID = :myContactID LIMIT 1];
        System.assertequals(2, numofContactOrders, 'We created more then one contact!');
        System.assertequals(true, myContactProcesses.has_ordered_SLS__c, 'SLS did not show up as ordered');
    }
    @isTest
    static void orderPaymentTest1() {
        // Create two orders on Same Contact to Update Contacts order processes
        System.debug('Starting the Code Coverage');
        List<Quote_ERP__C> newQuotes = TestDataFactory.createTestQuotesToLeads(1, 2);

        Quote_ERP__C convertQuoteEx = newQuotes[0];
        Set<String> xomOrderSet = new Set<String>();
        List<Order_ERP__C> newOrderList = new List<Order_ERP__C>();
        //Create an Order
        Order_ERP__C ord = TestDataFactory.createOrderERPFromQuote(false, convertQuoteEx);
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        xomOrderSet.add('BBBBB-34567');
        ord.Order_Canceled_Flag__c = false;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.process_isDMLS__c = true;
        newOrderList.add(ord);

        Quote_ERP__C convertQuoteEx1 = newQuotes[1];
        Order_ERP__C ord1 = TestDataFactory.createOrderERPFromQuote(false, convertQuoteEx1);
        ord1 = TestDataFactory.setTrueProcessFieldsQuote(ord1);
        ord1.Xometry_ERP_ID__c = 'BBBBB-34568';
        xomOrderSet.add('BBBBB-34568');
        ord1.order_Canceled_Flag__c = false;
        ord1.Order_Subtotal__c = 5000.00;
        ord1.Order_Total__c = 6000.50;
        ord1.Payment_Type__c = 'buy_now_pay_later';
        newOrderList.add(ord1);

        Test.startTest();
        insert newOrderList;
        Test.stopTest();

        List<Opportunity> oppList = [
            SELECT ID, Pending_Payment_Type__c, Order_ERP_Xom_ID__c
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__C IN :xomOrderSet
            ORDER BY Order_ERP_Xom_ID__c
        ];
        System.debug('Here are the opportunities');
        System.debug(oppList);
        System.assertEquals(
            'Credit Card',
            oppList[0].Pending_Payment_Type__c,
            'The payment types did not transform correctly'
        );
        System.assertEquals(
            'BNPL',
            oppList[1].Pending_Payment_Type__c,
            'The payment types did not transform correctly'
        );
    }
    @isTest
    static void orderTest2() {
        // Create Existing Account, Contact, Opportunity, That should be close won
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();

        //Different Name Should Create new Opportunity on Existing BDR Account
        Order_ERP__C ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            myTestAccount,
            myretContact,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.Order_Total__c = 5000.50;

        Test.startTest();
        insert ord;
        Test.stopTest();
        Opportunity lnewOpt = [
            SELECT ID, Amount
            FROM Opportunity
            WHERE
                Primary_Contact__c = :myretContactID
                AND Stagename = 'Closed Won'
                AND Order_ERP_Xom_ID__c = :ord.Xometry_ERP_ID__c
            LIMIT 1
        ];
        System.assertequals(5000.50, lnewOpt.Amount);
    }

    // Create no prexisting generic Order
    @isTest
    static void orderTest3() {
        TestDataFactory.createTestUsers();
        Order_ERP__C ord = TestDataFactory.createOrderERP(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            'johndoe@gmail.com',
            '',
            'johndoe@gmail.com',
            false,
            false
        );
        // ord.ERP_Contact_First_Name__c = 'John';
        // ord.ERP_Contact_Last_Name__c = 'Doe';
        // ord.ERP_Contact__C = 'BBBBB';
        // ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = true;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Payment_Type__c = 'credit_card';
        ord.process_isPolyJet_3D__c = true;

        Test.startTest();
        insert ord;
        Test.stopTest();
        //Confirm Account Creation with Generic
        Account myAcct = [
            SELECT ID, name, Email_Domain__c
            FROM Account
            WHERE Email_Domain__C = 'johndoe@gmail.com'
            LIMIT 1
        ];
        System.assertequals(ord.Account_Domain__c, myAcct.name);
    }

    // No prexisting Generic Order Canceled
    @isTest
    static void orderTest4() {
        TestDataFactory.createTestUsers();
        Order_ERP__C ord = TestDataFactory.createOrderERP(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            'johndoe@gmail.com',
            '',
            'johndoe@gmail.com',
            false,
            false
        );
        // ord.ERP_Contact_First_Name__c = 'John';
        // ord.ERP_Contact_Last_Name__c = 'Doe';
        // ord.ERP_Contact__C = 'BBBBB';
        // ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = true;
        ord.Order_Canceled_Flag__c = true;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Payment_Type__c = 'credit_card';
        ord.process_isPolyJet_3D__c = true;
        Test.startTest();
        insert ord;
        Test.stopTest();
        //Confirm Account Creation with Generic
        Account myAcct = [
            SELECT ID, name, Email_Domain__c, Generic_Account__c
            FROM Account
            WHERE Email_Domain__C = 'johndoe@gmail.com'
            LIMIT 1
        ];
        Opportunity myOppt = [
            SELECT ID, Stagename
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :ord.Xometry_ERP_ID__c
            LIMIT 1
        ];
        System.assertequals(ord.Account_Domain__c, myAcct.name);
        //Test for IDEA-299
        System.assertequals(myAcct.Generic_Account__c, true);
        System.assertequals('Closed Lost', myOppt.Stagename);
    }
    // Create Existing Account, Contact, Opportunity, That shoulb be close lost

    // Create Existing Account, Contact, Opportunity, that has order placed by different email on existing opportunity
    @isTest
    static void orderTest5() {
        // Create Existing Account, Contact, Opportunity, Order should be placed by different email same domain
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, OwnerID, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            myTestAccount.Email_Domain__c,
            myretContact.FirstName,
            myretContact.LastName,
            myretContact.email
        );
        //BDR Opps for Days
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote3.IS_Generic__c = false;
        myQuote3.Quote_ERP_Created_Date__c = Date.newInstance(2021, 8, 28);
        myQuote3.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 8, 28, 4, 5, 50);
        myQuote3.process_isCarbon__c = true;
        insert myQuote3;

        Order_ERP__C ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'AAAAA-00003',
            'A1234-A5679',
            myTestAccount,
            myretContact,
            date.newInstance(2021, 8, 29),
            dateTime.newInstance(2021, 8, 29, 10, 0, 30)
        );
        ord.Order_Email__c = 'Nextleveltest@' + myTestAccount.Email_Domain__C;
        ord.ERP_Contact__C = 'AAAAA';
        ord.Order_Total__C = 5000.50;

        Opportunity lnewOpt = [
            SELECT ID, Amount
            FROM Opportunity
            WHERE Primary_Contact__c = :myretContactID AND Last_Quote_Xometry_ERP_ID__c = :myQuote3.Xometry_ERP_ID__C
            LIMIT 1
        ];
        List<OpportunityContactRole> OptContactRoleList = [
            SELECT ContactID, Contact.Name, Role, ISPrimary
            FROM OpportunityContactRole
            WHERE OpportunityID = :lnewOpt.ID
        ];
        System.debug('The OptContact Role List before the Order');
        System.debug(OptContactRoleList);
        OptContactRoleList.clear();

        Test.startTest();
        insert ord;
        Test.stopTest();
        //Close Won Opp should belong to original contact
        lnewOpt = [
            SELECT ID, Amount
            FROM Opportunity
            WHERE
                Primary_Contact__c = :myretContactID
                AND Stagename = 'Closed Won'
                AND Order_ERP_Xom_ID__c = :ord.Xometry_ERP_ID__c
            LIMIT 1
        ];
        Integer optContactRoleCount = [SELECT COUNT() FROM OpportunityContactRole WHERE OpportunityID = :lnewOpt.ID];
        OptContactRoleList = [
            SELECT ContactID, Contact.Name, Role, ISPrimary
            FROM OpportunityContactRole
            WHERE OpportunityID = :lnewOpt.ID
        ];
        System.debug('The OptContact Role List after the Order');
        System.debug(OptContactRoleList);
        System.assertequals(2, optContactRoleCount, 'Opt Contact Role Check');
        System.assertequals(5000.50, lnewOpt.Amount);
        // Create Existing Account, Contact, Opportunity, that has order placed by different email on new domain
    }

    // Create Existing Account, Contact, Opportunity, that has order placed by different email on existing opportunity

    @isTest
    static void orderTest6() {
        // Create Existing Account, Contact, Opportunity, Order should be placed by same email same domain
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, OwnerID, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        //BDR Opps for Days
        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            myTestAccount.Email_Domain__c,
            myretContact.FirstName,
            myretContact.LastName,
            myretContact.email
        );
        //BDR Opps for Days
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote3.IS_Generic__c = false;
        myQuote3.Quote_ERP_Created_Date__c = Date.newInstance(2021, 8, 28);
        myQuote3.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 8, 28, 4, 5, 50);
        myQuote3.process_isCarbon__c = true;
        insert myQuote3;

        Order_ERP__C ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'AAAAA-00003',
            'A1234-A5679',
            myTestAccount,
            myretContact,
            date.newInstance(2021, 8, 29),
            dateTime.newInstance(2021, 8, 29, 10, 0, 30)
        );
        ord.ERP_Contact__C = 'AAAAA';
        ord.Order_Total__C = 5000.50;

        Opportunity lnewOpt = [
            SELECT ID, Amount
            FROM Opportunity
            WHERE Primary_Contact__c = :myretContactID AND Last_Quote_Xometry_ERP_ID__c = :myQuote3.Xometry_ERP_ID__C
            LIMIT 1
        ];
        List<OpportunityContactRole> OptContactRoleList = [
            SELECT ContactID, Contact.Name, Role, ISPrimary
            FROM OpportunityContactRole
            WHERE OpportunityID = :lnewOpt.ID
        ];
        System.debug('The OptContact Role List before the Order');
        System.debug(OptContactRoleList);
        OptContactRoleList.clear();
        Test.startTest();
        insert ord;
        Test.stopTest();
        //Close Won Opp should belong to original contact
        Opportunity jnewOpt = [
            SELECT ID, Amount
            FROM Opportunity
            WHERE
                Primary_Contact__c = :myretContactID
                AND Stagename = 'Closed Won'
                AND Order_ERP_Xom_ID__c = :ord.Xometry_ERP_ID__c
            LIMIT 1
        ];
        Integer optContactRoleCount = [SELECT COUNT() FROM OpportunityContactRole WHERE OpportunityID = :jnewOpt.ID];
        OptContactRoleList = [
            SELECT ContactID, Contact.Name, Role, ISPrimary
            FROM OpportunityContactRole
            WHERE OpportunityID = :jnewOpt.ID
        ];
        System.debug('The OptContact Role List after the Order');
        System.debug(OptContactRoleList);
        System.assertequals(1, optContactRoleCount, 'Opt Contact Role Check');
        System.assertequals(5000.50, jnewOpt.Amount);
    }

    //Bulk deploy 10,000 quotes
    // Then deploy 10,000 orders

    // Create no prexisting non generic Order
    @isTest
    static void orderTest7() {
        TestDataFactory.createTestUsers();
        Order_ERP__C ord = TestDataFactory.createDefaultOrderERP(false);
        ord.ERP_Contact_Phone__c = '+1 (937) 864-7150';

        Test.startTest();
        insert ord;
        Test.stopTest();
        //Confirm Account Creation with Generic
        Account myAcct = [
            SELECT ID, name, Email_Domain__c
            FROM Account
            WHERE Email_Domain__C = 'superaccount.com'
            LIMIT 1
        ];
        System.assertequals(ord.Account_Domain__c, myAcct.name);
    }

    // Create no prexisting non generic Order and then cancel
    @isTest
    static void canceledOrderTest_closeAndRemoveDates() {
        TestDataFactory.createTestUsers();
        Order_ERP__C ord = TestDataFactory.createDefaultOrderERP(true);

        //Confirm Account Creation with Generic
        Account myAcct = [
            SELECT ID, name, Email_Domain__c
            FROM Account
            WHERE Email_Domain__C = 'superaccount.com'
            LIMIT 1
        ];
        Order_ERP__C myOrder = [
            SELECT OpportunityID__C, OpportunityID__R.Stagename, ID
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];
        System.debug('The Opp stage is: ' + myOrder.OpportunityID__R.Stagename);
        Test.startTest();
        ord.Order_Canceled_Flag__c = true;
        update ord;
        Test.stopTest();
        myOrder = [
            SELECT
                OpportunityID__C,
                OpportunityID__R.Stagename,
                ID,
                AccountID__r.Date_of_First_Order__c,
                ContactID__r.contact_s_Date_of_First_Order__c,
                AccountID__r.Date_of_Last_Order__c,
                ContactID__r.Date_of_Last_Order__c
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];
        System.assertequals('Closed Lost', myOrder.OpportunityID__R.Stagename, 'The Opportunity is not Lost');
        System.assertequals(
            null,
            myOrder.AccountID__r.Date_of_First_Order__c,
            'Date of First Order on the Account should be removed'
        );
        System.assertequals(
            null,
            myOrder.ContactID__r.contact_s_Date_of_First_Order__c,
            'Date of First Order on the Contact should be removed'
        );
        System.assertequals(
            null,
            myOrder.AccountID__r.Date_of_Last_Order__c,
            'Date of Last Order on the Account should be removed'
        );
        System.assertequals(
            null,
            myOrder.ContactID__r.Date_of_Last_Order__c,
            'Date of Last Order on the Contact should be removed'
        );
    }

    // Create no prexisting non generic Order and then cancel
    @isTest
    static void canceledOrderTest_replaceCreatedDate() {
        TestDataFactory.createTestUsers();
        Order_ERP__C ord = TestDataFactory.createDefaultOrderERP(true);

        Order_ERP__C ord2 = TestDataFactory.createDefaultOrderERP(false);
        ord2.ERP_PartPk__c = '56564-55668';
        ord2.Xometry_ERP_ID__c = 'BBBBB-34568';
        ord2.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 17);
        insert ord2;

        //Confirm Account Creation with Generic
        Account myAcct = [
            SELECT ID, name, Email_Domain__c
            FROM Account
            WHERE Email_Domain__C = 'superaccount.com'
            LIMIT 1
        ];
        Order_ERP__C myOrder = [
            SELECT OpportunityID__C, OpportunityID__R.Stagename, ID
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];
        System.debug('The Opp stage is: ' + myOrder.OpportunityID__R.Stagename);
        Test.startTest();
        ord.Order_Canceled_Flag__c = true;
        update ord;
        Test.stopTest();
        myOrder = [
            SELECT
                OpportunityID__C,
                OpportunityID__R.Stagename,
                ID,
                AccountID__r.Date_of_First_Order__c,
                ContactID__r.contact_s_Date_of_First_Order__c,
                AccountID__r.Date_of_Last_Order__c,
                ContactID__r.Date_of_Last_Order__c
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];

        System.assertequals('Closed Lost', myOrder.OpportunityID__R.Stagename, 'The Opportunity is not Lost');
        System.assertequals(
            date.newInstance(2019, 8, 17),
            myOrder.AccountID__r.Date_of_First_Order__c,
            'Date of First Order on the Account should be removed'
        );
        System.assertequals(
            date.newInstance(2019, 8, 17),
            myOrder.ContactID__r.contact_s_Date_of_First_Order__c,
            'Date of First Order on the Contact should be removed'
        );
        System.assertequals(
            date.newInstance(2019, 8, 17),
            myOrder.AccountID__r.Date_of_Last_Order__c,
            'Date of Last Order on the Account should be removed'
        );
        System.assertequals(
            date.newInstance(2019, 8, 17),
            myOrder.ContactID__r.Date_of_Last_Order__c,
            'Date of Last Order on the Contact should be removed'
        );
    }

    @isTest
    static void canceledOrderTest() {
        TestDataFactory.createTestUsers();
        Order_ERP__C ord = TestDataFactory.createDefaultOrderERP(true);

        Order_ERP__C ord2 = TestDataFactory.createDefaultOrderERP(false);
        ord2.ERP_PartPk__c = '56564-55668';
        ord2.Xometry_ERP_ID__c = 'BBBBB-34568';
        ord2.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 17);
        insert ord2;

        //Confirm Account Creation with Generic
        Account myAcct = [
            SELECT ID, name, Email_Domain__c
            FROM Account
            WHERE Email_Domain__C = 'superaccount.com'
            LIMIT 1
        ];
        Order_ERP__C myOrder = [
            SELECT OpportunityID__C, OpportunityID__R.Stagename, ID
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];
        System.debug('The Opp stage is: ' + myOrder.OpportunityID__R.Stagename);
        Test.startTest();
        ord.Order_Canceled_Flag__c = true;
        update ord;
        Test.stopTest();
        myOrder = [
            SELECT
                OpportunityID__C,
                OpportunityID__R.Stagename,
                ID,
                AccountID__r.Date_of_First_Order__c,
                ContactID__r.contact_s_Date_of_First_Order__c,
                AccountID__r.Date_of_Last_Order__c,
                ContactID__r.Date_of_Last_Order__c
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];
        System.assertequals('Closed Lost', myOrder.OpportunityID__R.Stagename, 'The Opportunity is not Lost');
        System.assertequals(
            date.newInstance(2019, 8, 17),
            myOrder.AccountID__r.Date_of_First_Order__c,
            'Date of First Order on the Account should be removed'
        );
        System.assertequals(
            date.newInstance(2019, 8, 17),
            myOrder.ContactID__r.contact_s_Date_of_First_Order__c,
            'Date of First Order on the Contact should be removed'
        );
        System.assertequals(
            date.newInstance(2019, 8, 17),
            myOrder.AccountID__r.Date_of_Last_Order__c,
            'Date of Last Order on the Account should be removed'
        );
        System.assertequals(
            date.newInstance(2019, 8, 17),
            myOrder.ContactID__r.Date_of_Last_Order__c,
            'Date of Last Order on the Contact should be removed'
        );
    }

    @isTest
    static void insertERPAddressTest() {
        //Create an account and contact confirm addresses
        List<Account> newAccountList = TestDataFactory.createTestAccountNonGenerics(5, 'BDR', 1);
        Account myTestAccount = newAccountList[0];
        ID testAccountID = newAccountList[0].ID;
        List<Contact> newContactList = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            ORDER BY Account.Name
        ];
        Contact c = newContactList[0];
        ID testConAcctID = c.AccountID;
        ID testContactID = c.ID;
        // Create an Order with a Country
        Order_ERP__C ord = TestDataFactory.createDefaultOrderERP(false);
        ord.ERP_Contact_Phone__c = '2447778889';
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name;
        ord.ERP_Contact_First_Name__c = newContactList[0].FirstName;
        ord.ERP_Contact_Last_Name__c = newContactList[0].LastName;
        ord.Order_Email__c = newContactList[0].Email;
        ord.ERP_Billing_Address__c = '2 Unit E Northway';
        ord.ERP_Billing_City__c = 'Greenbelt';
        ord.ERP_Billing_Country__c = 'United States';
        ord.ERP_Billing_State_or_Province__c = 'Maryland';
        ord.ERP_Billing_Zip_Code__c = '20770';
        ord.ERP_Shipping_Address__c = '2 Unit E Northway';
        ord.ERP_Shipping_City__c = 'Greenbelt';
        ord.ERP_Shipping_Country__c = 'United States';
        ord.ERP_Shipping_State_or_Province__c = 'Maryland';
        ord.ERP_Shipping_Zip_Code__c = '20770';

        Test.startTest();
        insert ord;
        Test.stopTest();
        Contact testContact = [
            SELECT
                ID,
                Name,
                AccountID,
                Xometry_ERP_Contact_ID__c,
                ERP_Shipping_Address__c,
                ERP_Shipping_City__c,
                ERP_Shipping_Country__c,
                ERP_Shipping_State_or_Province__c,
                ERP_Shipping_Zip_Code__c
            FROM Contact
            WHERE ID = :testContactID
        ];
        String retConTest_Shipping_Address = testContact.ERP_Shipping_Address__c;
        String retConTest_Shipping_City = testContact.ERP_Shipping_City__c;
        String retConTest_Shipping_Country = testContact.ERP_Shipping_Country__c;
        String retConTest_Shipping_State = testContact.ERP_Shipping_State_or_Province__c;
        String retConTest_Shipping_Zip_Code = testContact.ERP_Shipping_Zip_Code__c;
        System.assertequals(retConTest_Shipping_Address, ord.ERP_Shipping_Address__c, 'The addresses did not match');
        //Test the Account Updates
        Account testAccountPost = [
            SELECT
                ID,
                Name,
                ERP_Billing_Address__c,
                ERP_Billing_City__c,
                ERP_Billing_Country__c,
                ERP_Billing_State_or_Province__c,
                ERP_Billing_Zip_Code__c
            FROM Account
            WHERE ID = :testConAcctID
        ];
        String retAcctTest_Billing_Address = testAccountPost.ERP_Billing_Address__c;
        String retAcctTest_Billing_City = testAccountPost.ERP_Billing_City__c;
        String retAcctTest_Billing_Country = testAccountPost.ERP_Billing_Country__c;
        String retAcctTest_Billing_State_or_Provinces = testAccountPost.ERP_Billing_State_or_Province__c;
        String retAcctTest_Billing_Zipcode = testAccountPost.ERP_Billing_Zip_Code__c;
        System.assertEquals(retAcctTest_Billing_Address, ord.ERP_Billing_Address__c, 'The addresses did not match');
        System.assertEquals(retAcctTest_Billing_City, ord.ERP_Billing_City__c, 'The cities did not match');
        System.assertEquals(retAcctTest_Billing_Country, ord.ERP_Billing_Country__c, 'The countries did not match');
        System.assertEquals(
            retAcctTest_Billing_State_or_Provinces,
            ord.ERP_Billing_State_or_Province__c,
            'The state or province did not match'
        );
        System.assertEquals(retAcctTest_Billing_Zipcode, ord.ERP_Billing_Zip_Code__c, 'The zipcodes did not match');
    }

    @isTest
    static void updateERPAddressTest() {
        List<Account> newAccountList = TestDataFactory.createTestAccountNonGenerics(5, 'BDR', 1);
        Account myTestAccount = newAccountList[0];
        ID testAccountID = newAccountList[0].ID;
        List<Contact> newContactList = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            ORDER BY Account.Name
        ];
        Contact c = newContactList[0];
        ID testConAcctID = c.AccountID;
        ID testContactID = c.ID;
        // Create an Order with a Country
        Order_ERP__C ord = TestDataFactory.createDefaultOrderERP(false);
        ord.ERP_Contact_Phone__c = '2447778889';
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name;
        ord.ERP_Contact_First_Name__c = newContactList[0].FirstName;
        ord.ERP_Contact_Last_Name__c = newContactList[0].LastName;
        ord.Order_Email__c = newContactList[0].Email;
        ord.ERP_Billing_Address__c = '2 Unit E Northway';
        ord.ERP_Billing_City__c = 'Greenbelt';
        ord.ERP_Billing_Country__c = 'United States';
        ord.ERP_Billing_State_or_Province__c = 'Maryland';
        ord.ERP_Billing_Zip_Code__c = '20770';
        ord.ERP_Shipping_Address__c = '2 Unit E Northway';
        ord.ERP_Shipping_City__c = 'Greenbelt';
        ord.ERP_Shipping_Country__c = 'United States';
        ord.ERP_Shipping_State_or_Province__c = 'Maryland';
        ord.ERP_Shipping_Zip_Code__c = '20770';
        insert ord;
        Test.startTest();

        //New Order should update the address and city
        Order_ERP__C ord1 = new Order_ERP__C();
        ord1.Account_Domain__c = myTestAccount.Email_Domain__c;
        //New Order should update the address and city
        ord1.ERP_Company_Name__C = myTestAccount.Name;
        ord1.ERP_Contact_First_Name__c = newContactList[0].FirstName;
        ord1.ERP_Contact_Last_Name__c = newContactList[0].LastName;
        ord1.ERP_Contact__C = 'BBBBB';
        ord1.ERP_PartPk__c = '56564-55667';
        ord1.ERP_Contact_Phone__c = '2447778889';
        ord1.Is_Generic__c = false;
        ord1.Order_Canceled_Flag__c = false;
        ord1.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord1.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord1.Order_Email__c = newContactList[0].Email;
        ord1.Order_Subtotal__c = 4500.00;
        ord1.Order_Total__c = 6000.50;
        ord1.Payment_Type__c = 'credit_card';
        ord1.Xometry_ERP_ID__c = 'BBBBB-34568';
        ord1.process_isPolyJet_3D__c = true;
        ord1.ERP_Billing_Address__c = '2 Unit F Northway';
        ord1.ERP_Billing_City__c = 'Bowie';
        ord1.ERP_Billing_Country__c = 'Mexico';
        ord1.ERP_Billing_State_or_Province__c = 'Chiapas';
        ord1.ERP_Billing_Zip_Code__c = '20770';
        ord1.ERP_Shipping_Address__c = 'Made Up Avenue';
        ord1.ERP_Shipping_City__c = 'Hollywood';
        ord1.ERP_Shipping_Country__c = 'United States';
        ord1.ERP_Shipping_State_or_Province__c = 'California';
        ord1.ERP_Shipping_Zip_Code__c = '20990';
        insert ord1;
        Test.stopTest();

        Contact testContact = [
            SELECT
                ID,
                Name,
                AccountID,
                Xometry_ERP_Contact_ID__c,
                ERP_Shipping_Address__c,
                ERP_Shipping_City__c,
                ERP_Shipping_Country__c,
                ERP_Shipping_State_or_Province__c,
                ERP_Shipping_Zip_Code__c
            FROM Contact
            WHERE ID = :testContactID
        ];
        String retConTest_Shipping_Address = testContact.ERP_Shipping_Address__c;
        String retConTest_Shipping_City = testContact.ERP_Shipping_City__c;
        String retConTest_Shipping_Country = testContact.ERP_Shipping_Country__c;
        String retConTest_Shipping_State = testContact.ERP_Shipping_State_or_Province__c;
        String retConTest_Shipping_Zip_Code = testContact.ERP_Shipping_Zip_Code__c;
        System.assertequals(retConTest_Shipping_Address, ord1.ERP_Shipping_Address__c, 'The addresses did not match');
        //Test the Account Updates
        Account testAccountPost = [
            SELECT
                ID,
                Name,
                ERP_Billing_Address__c,
                ERP_Billing_City__c,
                ERP_Billing_Country__c,
                ERP_Billing_State_or_Province__c,
                ERP_Billing_Zip_Code__c
            FROM Account
            WHERE ID = :testConAcctID
        ];
        String retAcctTest_Billing_Address = testAccountPost.ERP_Billing_Address__c;
        String retAcctTest_Billing_City = testAccountPost.ERP_Billing_City__c;
        String retAcctTest_Billing_Country = testAccountPost.ERP_Billing_Country__c;
        String retAcctTest_Billing_State_or_Provinces = testAccountPost.ERP_Billing_State_or_Province__c;
        String retAcctTest_Billing_Zipcode = testAccountPost.ERP_Billing_Zip_Code__c;
        System.assertEquals(retAcctTest_Billing_Address, ord1.ERP_Billing_Address__c, 'The addresses did not match');
        System.assertEquals(retAcctTest_Billing_City, ord1.ERP_Billing_City__c, 'The cities did not match');
        System.assertEquals(retAcctTest_Billing_Country, ord1.ERP_Billing_Country__c, 'The countries did not match');
        System.assertEquals(
            retAcctTest_Billing_State_or_Provinces,
            ord1.ERP_Billing_State_or_Province__c,
            'The state or province did not match'
        );
        System.assertEquals(retAcctTest_Billing_Zipcode, ord1.ERP_Billing_Zip_Code__c, 'The zipcodes did not match');
    }

    @isTest
    static void updateERPPhoneTest() {
        List<Account> newAccountList = TestDataFactory.createTestAccountNonGenerics(5, 'BDR', 1);
        Account myTestAccount = newAccountList[0];
        ID testAccountID = newAccountList[0].ID;
        List<Contact> newContactList = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            ORDER BY Account.Name
        ];
        Contact c = newContactList[0];
        ID testContactID = c.ID;
        //
        //Different Name Should Create new Opportunity on Existing BDR Account
        Order_ERP__C ord = TestDataFactory.createDefaultOrderERP(false);
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name;
        ord.ERP_Contact_First_Name__c = newContactList[0].FirstName;
        ord.ERP_Contact_Last_Name__c = newContactList[0].LastName;
        ord.Order_Email__c = newContactList[0].Email;
        ord.ERP_Contact_Phone__c = '2447778889';
        insert ord;

        Test.startTest();

        //Different Name Should Create new Opportunity on Existing BDR Account
        Order_ERP__C ord1 = TestDataFactory.createDefaultOrderERP(false);
        ord1.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord1.ERP_Company_Name__C = myTestAccount.Name;
        ord1.ERP_Contact_First_Name__c = newContactList[0].FirstName;
        ord1.ERP_Contact_Last_Name__c = newContactList[0].LastName;
        ord1.Order_Email__c = newContactList[0].Email;
        ord1.ERP_Contact_Phone__c = '3447778889';
        ord1.Order_Total__c = 6000.50;
        ord1.Xometry_ERP_ID__c = 'BBBBB-34568';
        insert ord1;
        Test.stopTest();

        Contact retTestContact = [SELECT ID, Name, ERP_Contact_Phone__c FROM Contact WHERE ID = :testContactID];
        String retTestPhone = retTestContact.ERP_Contact_Phone__c;
        System.debug('The new phone number for this contact is ' + retTestPhone);
        System.assertequals(ord1.ERP_Contact_Phone__c, retTestPhone);
    }

    @isTest
    static void updateOppUpdateTest() {
        // When a order is updated, corresponding opportunity is updated as well
        List<Account> newAccountList = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1);
        //Empty Opportunity on Contact
        List<Contact> newContactList = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            ORDER BY Account.Name
        ];

        Contact c = newContactList[0];

        //Create a Order and a new Opportunity. Validate OpportunityID is Blank
        Order_ERP__C newOrd = TestDataFactory.createDefaultOrderERP(false);
        newOrd.Account_Domain__c = c.Account.Email_Domain__c;
        newOrd.ERP_Company_Name__C = c.Name + 'Blue';
        newOrd.ERP_Contact_First_Name__c = c.FirstName;
        newOrd.ERP_Contact_Last_Name__c = c.LastName;
        newOrd.Order_Email__c = c.Email;
        newOrd.ERP_Contact__C = 'AAAAA';
        newOrd.ERP_PartPk__c = 'A1234-A5679';
        newOrd.Xometry_ERP_ID__c = 'AAAAA-00003';
        insert newOrd;

        newOrd.Order_Total__c = 10000;

        Test.startTest();
        update newOrd;
        Test.stopTest();

        Opportunity newOpp = [
            SELECT ID, Order_ERP_Xom_ID__c, Amount
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :newOrd.Xometry_ERP_ID__C
        ];

        System.assertEquals(10000, newOpp.Amount, 'Amount field should have changed');
    }

    @isTest
    static void orderOpponHoldTest() {
        //When an Opportunity Hold_Op_to_Prior_Owner__c is set to true then when the Order is placed do change the owner to match the new account owner.
        //Create a Quote
        Quote_ERP__C testQuote = TestDataFactory.createQuoteWithAcc(true, 'BDR');
        String testAccountDomain = testQuote.Account_Domain__C;
        Account myTestAccount = [SELECT id FROM Account WHERE Email_Domain__C = :testAccountDomain];

        Quote_ERP__C testQuoteFetch = [
            SELECT ID, OpportunityID__C, OpportunityID__R.OwnerID
            FROM Quote_ERP__C
            WHERE ID = :testQuote.ID
        ];
        ID testOppOrigOwner = testQuoteFetch.OpportunityID__R.OwnerID;
        ID testOppID = testQuoteFetch.OpportunityID__C;

        //Update the Opp to lock in the owner.
        Opportunity oppToLock = new Opportunity();
        oppToLock.ID = testQuoteFetch.OpportunityID__C;
        oppToLock.Hold_Op_to_Prior_Owner__c = true;
        update oppToLock;

        //Flip the Account to the second owner
        List<User> userList = TestDataFactory.createTestUserSecond();
        User newOwner = userList[0];
        ID newOwnerID = newOwner.ID;
        myTestAccount.OwnerID = newOwnerID;
        update myTestAccount;
        Test.startTest();
        //Place the Order
        Order_ERP__C testOrder = new Order_ERP__C();
        testOrder.Account_Domain__C = testAccountDomain;
        testOrder.Xometry_Quote_ID__c = 'Q12-3333-4444';
        testOrder.Xometry_ERP_ID__C = '333AA-44444';
        testOrder.ERP_PartPK__c = '4444A';
        testOrder.Order_Email__c = 'samSmith@' + testAccountDomain;
        testOrder.process_isSLA__c = true;
        testOrder.Order_ERP_CreatedDate__c = date.newInstance(2020, 8, 3);
        testOrder.Order_ERP_Time__c = dateTime.newInstance(2020, 8, 3, 10, 0, 30);
        testOrder.Order_Subtotal__c = 500;
        testOrder.Order_Total__c = 500;
        insert testOrder;
        Test.stopTest();
        ID testOrderID = testOrder.ID;
        //The OpportunityIDS should match
        Order_ERP__C orderPostTestData = [
            SELECT
                ID,
                OwnerID,
                Xometry_ERP_ID__C,
                OpportunityID__c,
                OpportunityID__R.Commission_Owner_LKP__c,
                OpportunityID__R.OwnerID
            FROM Order_ERP__C
            WHERE ID = :testOrderID
        ];
        //The Opp and Account should be owned by different owners
        ID orderOppID = orderPostTestData.OpportunityID__c;
        ID postOrderOwner = orderPostTestData.OwnerID;
        system.assertEquals(orderOppID, testOppID, 'The Opps were not the same');
        system.assertNotEquals(
            newOwnerID,
            orderPostTestData.OpportunityID__R.OwnerID,
            'The Opp owner matched the new account Owner'
        );
        system.assertEquals(testOppOrigOwner, orderPostTestData.OpportunityID__R.OwnerID, 'The Owner was switched');
        system.assertEquals(
            testOppOrigOwner,
            orderPostTestData.OpportunityID__R.Commission_Owner_LKP__c,
            'The comission did not go to the original opp owner'
        );
    }
    @isTest
    static void systemReOpenOrderTest() {
        //When an Opportunity is closed Lost and the Account Owner changes make sure they become the Owner if an Order Occurs.
        Quote_ERP__C testQuote = TestDataFactory.createQuoteWithAcc(true, 'BDR');
        String testAccountDomain = testQuote.Account_Domain__C;

        ID testQuoteID = testQuote.ID;
        Quote_ERP__C testQuoteFetch = [
            SELECT ID, OwnerID, ContactID__C, ContactID__R.OwnerID, OpportunityID__C, OpportunityID__R.OwnerID
            FROM Quote_ERP__C
            WHERE ID = :testQuote.ID
        ];
        ID testOppOrigOwner = testQuoteFetch.OpportunityID__R.OwnerID;
        ID testOppID = testQuoteFetch.OpportunityID__C;
        //Update the Opp to close lost
        Opportunity testOpp = new Opportunity();
        testOpp.ID = testOppID;
        testOpp.StageName = 'Close Lost';
        testOpp.Loss_Reason__c = 'Price';
        update testOpp;

        ID oldOppOwnerId = [SELECT OwnerId FROM Opportunity WHERE Id = :testOpp.Id].OwnerId;

        //Flip the Contact to the second owner
        List<User> userList = TestDataFactory.createTestUserSecond();
        User newOwner = userList[0];
        ID newOwnerID = newOwner.ID;
        Contact myTestContact = new Contact();
        myTestContact.ID = testQuoteFetch.ContactID__C;
        myTestContact.OwnerID = newOwnerID;
        update myTestContact;
        Test.startTest();
        //Place the Order
        Order_ERP__C testOrder = new Order_ERP__C();
        testOrder.Account_Domain__C = testAccountDomain;
        testOrder.Xometry_Quote_ID__c = 'Q12-3333-4444';
        testOrder.Xometry_ERP_ID__C = '333AA-44444';
        testOrder.ERP_PartPK__c = '4444A';
        testOrder.Order_Email__c = 'samSmith@' + testAccountDomain;
        testOrder.process_isSLA__c = true;
        testOrder.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 3);
        testOrder.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 3, 10, 0, 30);
        testOrder.Order_Subtotal__c = 500;
        testOrder.Order_Total__c = 500;
        insert testOrder;
        Test.stopTest();
        ID testOrderID = testOrder.ID;
        //The OpportunityIDS should match
        Order_ERP__C orderPostTestData = [
            SELECT ID, OwnerID, Xometry_ERP_ID__C, OpportunityID__c, OpportunityID__R.OwnerID
            FROM Order_ERP__C
            WHERE ID = :testOrderID
        ];
        //The Opp and Order should be owned by the new account owner.
        ID orderOppID = orderPostTestData.OpportunityID__c;
        ID postOrderOwner = orderPostTestData.OwnerID;
        system.assertEquals(orderOppID, testOppID, 'The Opps were not the same');
        system.assertEquals(newOwnerID, postOrderOwner, 'The Order did not match the new account Owner');
        system.assertEquals(
            oldOppOwnerId,
            orderPostTestData.OpportunityID__R.OwnerID,
            'The Opp owner did not match the new account Owner'
        );
        system.assertNotEquals(newOwnerID, testOppOrigOwner, 'The Account did not change the owner');

        Opportunity lostOppUpd = [SELECT OwnerId, Owner_Update_Needed__c FROM Opportunity WHERE Id = :testOpp.Id];
        system.assertEquals(false, lostOppUpd.Owner_Update_Needed__c, 'The field Owner_Update_Needed__c should be false');
    }

    @isTest
    static void systemReOpenOrderTest_InactiveUser() {
        //When an Opportunity is closed Lost and the Account Owner changes make sure they become the Owner if an Order Occurs.
        Quote_ERP__C testQuote = TestDataFactory.createQuoteWithAcc(true, 'BDR');
        String testAccountDomain = testQuote.Account_Domain__C;

        ID testQuoteID = testQuote.ID;
        Quote_ERP__C testQuoteFetch = [
            SELECT ID, OwnerID, ContactID__C, ContactID__R.OwnerID, OpportunityID__C, OpportunityID__R.OwnerID
            FROM Quote_ERP__C
            WHERE ID = :testQuote.ID
        ];
        ID testOppOrigOwner = testQuoteFetch.OpportunityID__R.OwnerID;
        ID testOppID = testQuoteFetch.OpportunityID__C;

        User objInactiveUser = [SELECT Id FROM User WHERE IsActive = false LIMIT 1];

        //Update the Opp to close lost
        Opportunity testOpp = new Opportunity();
        testOpp.ID = testOppID;
        testOpp.StageName = 'Close Lost';
        testOpp.Loss_Reason__c = 'Price';
        testOpp.OwnerId = objInactiveUser.Id;
        update testOpp;

        Opportunity lostOpp = [SELECT OwnerId, Owner_Update_Needed__c FROM Opportunity WHERE Id = :testOpp.Id];
        ID oldOppOwnerId = lostOpp.OwnerId;
        
        Test.startTest();
        system.assertEquals(false, lostOpp.Owner_Update_Needed__c, 'The field Owner_Update_Needed__c should be false');

        //Place the Order
        Order_ERP__C testOrder = new Order_ERP__C();
        testOrder.Account_Domain__C = testAccountDomain;
        testOrder.Xometry_Quote_ID__c = 'Q12-3333-4444';
        testOrder.Xometry_ERP_ID__C = '333AA-44444';
        testOrder.ERP_PartPK__c = '4444A';
        testOrder.Order_Email__c = 'samSmith@' + testAccountDomain;
        testOrder.process_isSLA__c = true;
        testOrder.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 3);
        testOrder.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 3, 10, 0, 30);
        testOrder.Order_Subtotal__c = 500;
        testOrder.Order_Total__c = 500;
        insert testOrder;
        Test.stopTest();
        ID testOrderID = testOrder.ID;
        //The OpportunityIDS should match
        Order_ERP__C orderPostTestData = [
            SELECT ID, OwnerID, Xometry_ERP_ID__C, OpportunityID__c, OpportunityID__R.OwnerID
            FROM Order_ERP__C
            WHERE ID = :testOrderID
        ];
        //The Opp and Order should be owned by the new account owner.
        ID orderOppID = orderPostTestData.OpportunityID__c;
        ID postOrderOwner = orderPostTestData.OwnerID;

        system.assertEquals(orderOppID, testOppID, 'The Opps were not the same');        
        system.assertEquals(
            oldOppOwnerId,
            orderPostTestData.OpportunityID__R.OwnerID,
            'The Opp owner did not match the new account Owner'
        );

        Opportunity lostOppUpd = [SELECT OwnerId, Owner_Update_Needed__c FROM Opportunity WHERE Id = :testOpp.Id];
        system.assertEquals(true, lostOppUpd.Owner_Update_Needed__c, 'The field Owner_Update_Needed__c should be true');
    }

    @isTest
    static void systemReOpenOrderTest_FreezerUser() {
        //When an Opportunity is closed Lost and the Account Owner changes make sure they become the Owner if an Order Occurs.
        Quote_ERP__C testQuote = TestDataFactory.createQuoteWithAcc(true, 'BDR');
        String testAccountDomain = testQuote.Account_Domain__C;

        ID testQuoteID = testQuote.ID;
        Quote_ERP__C testQuoteFetch = [
            SELECT ID, OwnerID, ContactID__C, ContactID__R.OwnerID, OpportunityID__C, OpportunityID__R.OwnerID
            FROM Quote_ERP__C
            WHERE ID = :testQuote.ID
        ];
        ID testOppOrigOwner = testQuoteFetch.OpportunityID__R.OwnerID;
        ID testOppID = testQuoteFetch.OpportunityID__C;

        // UserLogin objFreezerUser = [SELECT UserId FROM UserLogin WHERE IsFrozen = true LIMIT 1];

        //Update the Opp to close lost
        Opportunity testOpp = new Opportunity();
        testOpp.ID = testOppID;
        testOpp.StageName = 'Close Lost';
        testOpp.Loss_Reason__c = 'Price';
        // testOpp.OwnerId = objFreezerUser.UserId;
        update testOpp;

        Opportunity lostOpp = [SELECT OwnerId, Owner_Update_Needed__c FROM Opportunity WHERE Id = :testOpp.Id];
        ID oldOppOwnerId = lostOpp.OwnerId;
        
        UserLogin objUserLogin = [SELECT IsFrozen FROM UserLogin WHERE UserId =: oldOppOwnerId];
        objUserLogin.IsFrozen = true;
        update objUserLogin;
        
        Test.startTest();
        system.assertEquals(false, lostOpp.Owner_Update_Needed__c, 'The field Owner_Update_Needed__c should be false');

        //Place the Order
        Order_ERP__C testOrder = new Order_ERP__C();
        testOrder.Account_Domain__C = testAccountDomain;
        testOrder.Xometry_Quote_ID__c = 'Q12-3333-4444';
        testOrder.Xometry_ERP_ID__C = '333AA-44444';
        testOrder.ERP_PartPK__c = '4444A';
        testOrder.Order_Email__c = 'samSmith@' + testAccountDomain;
        testOrder.process_isSLA__c = true;
        testOrder.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 3);
        testOrder.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 3, 10, 0, 30);
        testOrder.Order_Subtotal__c = 500;
        testOrder.Order_Total__c = 500;
        insert testOrder;
        Test.stopTest();
        ID testOrderID = testOrder.ID;
        //The OpportunityIDS should match
        Order_ERP__C orderPostTestData = [
            SELECT ID, OwnerID, Xometry_ERP_ID__C, OpportunityID__c, OpportunityID__R.OwnerID
            FROM Order_ERP__C
            WHERE ID = :testOrderID
        ];
        //The Opp and Order should be owned by the new account owner.
        ID orderOppID = orderPostTestData.OpportunityID__c;
        ID postOrderOwner = orderPostTestData.OwnerID;

        system.assertEquals(orderOppID, testOppID, 'The Opps were not the same');        
        system.assertEquals(
            oldOppOwnerId,
            orderPostTestData.OpportunityID__R.OwnerID,
            'The Opp owner did not match the new account Owner'
        );

        Opportunity lostOppUpd = [SELECT OwnerId, Owner_Update_Needed__c FROM Opportunity WHERE Id = :testOpp.Id];
        system.assertEquals(true, lostOppUpd.Owner_Update_Needed__c, 'The field Owner_Update_Needed__c should be true');
    }

    // @isTest
    // static void reassignWestCoast_switchToWestCoastBDR() {
    //     Account newAccount = TestDataFactory.createTestAccountNonGenerics(5, 'BDR', 1)[0];

    //     Contact newContact = [
    //         SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
    //         FROM Contact
    //         WHERE AccountID = :newAccount.ID
    //         ORDER BY Account.Name
    //      LIMIT 1];

    //     //Create a Quote
    //     Order_ERP__c newOrder = new Order_ERP__c();
    //     newOrder.Account_Domain__C = newContact.Account.Email_Domain__c;
    //     newOrder.ERP_PartPK__c = 'A1234-A5678';
    //     newOrder.Xometry_ERP_ID__C = 'AAAAA-00001';
    //     newOrder.ERP_Contact__c = 'AAAAA';
    //     newOrder.IS_Generic__c = false;
    //     newOrder.ERP_Contact_Last_Name__c = 'Doe';
    //     newOrder.ERP_Contact_First_Name__c = 'John';
    //     newOrder.ERP_Contact_Phone__C = '+1 (419) 532-3121';
    //     newOrder.ERP_Billing_Address__c = '2 Unit E Northway';
    //     newOrder.ERP_Billing_City__c = 'San Diego';
    //     newOrder.ERP_Billing_Country__c = 'United States';
    //     newOrder.ERP_Billing_State_or_Province__c = 'California';
    //     newOrder.Order_Canceled_Flag__c = false;
    //     newOrder.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
    //     newOrder.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
    //     newOrder.Order_Subtotal__c = 4500.00;
    //     newOrder.Order_Total__c = 5000.50;
    //     newOrder.Payment_Type__c = 'credit_card';
    //     newOrder.process_isPolyJet_3D__c = true;
    //     newOrder.ERP_Company_Name__C = newContact.Account.Name + 'Blue';
    //     newOrder.ERP_Contact_First_Name__c = newContact.FirstName;
    //     newOrder.ERP_Contact_Last_Name__c = newContact.LastName;
    //     newOrder.Order_Email__c = newContact.Email;

    //     Test.startTest();
    //     insert newOrder;
    //     Test.stopTest();

    //     Order_ERP__c insertedOrder = [
    //         SELECT ID, OwnerID, ContactID__c, AccountID__c
    //         FROM Order_ERP__c
    //         WHERE ID = :newOrder.ID
    //     ];
    //     System.assertEquals(insertedOrder.OwnerID, WEST_COAST_BDR, 'Order Owner is incorrect!');

    //     Contact orderContact = [SELECT ID, OwnerID, Account_Owner_Type__c FROM Contact WHERE ID = :newContact.ID];
    //     System.assertEquals(orderContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
    //     System.assertEquals(orderContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

    //     Account orderAccount = [
    //         SELECT ID, OwnerID, Account_Owner_Type__c
    //         FROM Account
    //         WHERE ID = :insertedOrder.AccountID__c
    //     ];
    //     System.assertEquals(orderAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
    //     System.assertEquals(orderAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    // }

    @isTest
    static void reassignWestCoast_maintainAMOwners() {
        Account newAccount = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1, 'SAM')[0];

        Contact newContact = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE AccountID = :newAccount.ID
            ORDER BY Account.Name
            LIMIT 1
        ];

        //Create a Quote
        Order_ERP__c newOrder = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'AAAAA-00001',
            'A1234-A5678',
            newAccount,
            newContact,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        newOrder.ERP_Contact__c = 'AAAAA';
        newOrder.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        newOrder.ERP_Billing_Address__c = '2 Unit E Northway';
        newOrder.ERP_Billing_City__c = 'San Diego';
        newOrder.ERP_Billing_Country__c = 'United States';
        newOrder.ERP_Billing_State_or_Province__c = 'California';

        Test.startTest();
        insert newOrder;
        Test.stopTest();

        Order_ERP__c insertedOrder = [
            SELECT ID, OwnerID, ContactID__c, AccountID__c
            FROM Order_ERP__c
            WHERE ID = :newOrder.ID
        ];
        System.assertNotEquals(insertedOrder.OwnerID, WEST_COAST_BDR, 'Order Owner is incorrect!');

        Contact orderContact = [SELECT ID, OwnerID, Account_Owner_Type__c FROM Contact WHERE ID = :newContact.ID];
        System.assertEquals(orderContact.Account_Owner_Type__c, 'AM', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(orderContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account orderAccount = [
            SELECT ID, OwnerID, Account_Owner_Type__c
            FROM Account
            WHERE ID = :insertedOrder.AccountID__c
        ];
        System.assertEquals(orderAccount.Account_Owner_Type__c, 'AM', 'Account Owner Type is incorrect!');
        System.assertNotEquals(orderAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }
    @isTest
    static void reassignWestCoast_skipOverNonWestCoastState() {
        Account newAccount = TestDataFactory.createTestAccountNonGenerics(5, 'BDR', 1)[0];

        Contact newContact = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE AccountID = :newAccount.ID
            ORDER BY Account.Name
            LIMIT 1
        ];

        //Create a Quote
        Order_ERP__c newOrder = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'AAAAA-00001',
            'A1234-A5678',
            newAccount,
            newContact,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        newOrder.ERP_Contact__c = 'AAAAA';
        newOrder.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        newOrder.ERP_Billing_Address__c = '2 Unit E Northway';
        newOrder.ERP_Billing_City__c = 'Virginia Beach';
        newOrder.ERP_Billing_Country__c = 'United States';
        newOrder.ERP_Billing_State_or_Province__c = 'Virginia';

        Test.startTest();
        insert newOrder;
        Test.stopTest();

        Order_ERP__c insertedOrder = [
            SELECT ID, OwnerID, ContactID__c, AccountID__c
            FROM Order_ERP__c
            WHERE ID = :newOrder.ID
        ];
        System.assertNotEquals(insertedOrder.OwnerID, WEST_COAST_BDR, 'Order Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c FROM Contact WHERE ID = :newContact.ID];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [
            SELECT ID, OwnerID, Account_Owner_Type__c
            FROM Account
            WHERE ID = :insertedOrder.AccountID__c
        ];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void reassignWestCoast_skipOverNullState() {
        Account newAccount = TestDataFactory.createTestAccountNonGenerics(5, 'BDR', 1)[0];

        Contact newContact = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE AccountID = :newAccount.ID
            ORDER BY Account.Name
            LIMIT 1
        ];

        //Create a Quote
        Order_ERP__c newOrder = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'AAAAA-00001',
            'A1234-A5678',
            newAccount,
            newContact,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        newOrder.ERP_Contact__c = 'AAAAA';
        newOrder.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        newOrder.ERP_Billing_Address__c = '2 Unit E Northway';
        newOrder.ERP_Billing_City__c = 'Virginia Beach';
        newOrder.ERP_Billing_Country__c = 'United States';

        Test.startTest();
        insert newOrder;
        Test.stopTest();

        Order_ERP__c insertedOrder = [
            SELECT ID, OwnerID, ContactID__c, AccountID__c
            FROM Order_ERP__c
            WHERE ID = :newOrder.ID
        ];
        System.assertNotEquals(insertedOrder.OwnerID, WEST_COAST_BDR, 'Order Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c FROM Contact WHERE ID = :newContact.ID];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [
            SELECT ID, OwnerID, Account_Owner_Type__c
            FROM Account
            WHERE ID = :insertedOrder.AccountID__c
        ];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void reassignWestCoast_skipOverNonUSCountry() {
        Account newAccount = TestDataFactory.createTestAccountNonGenericsNonUS(1, 'BDR', 1)[0];

        Account returnedAccount = [SELECT id, BillingCountry FROM Account WHERE id = :newAccount.id LIMIT 1];

        Contact newContact = [
            SELECT
                ID,
                FirstName,
                LastName,
                Name,
                AccountID,
                Account.Name,
                Account.Email_Domain__c,
                Email,
                OwnerId,
                Account.BillingCountry
            FROM Contact
            WHERE AccountID = :newAccount.ID
            ORDER BY Account.Name
            LIMIT 1
        ];

        //Create a Quote
        Order_ERP__c newOrder = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'AAAAA-00001',
            'A1234-A5678',
            newAccount,
            newContact,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        newOrder.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        newOrder.ERP_Billing_Address__c = '2 Unit E Northway';
        newOrder.ERP_Billing_City__c = 'Paris';
        newOrder.ERP_Billing_Country__c = 'France';
        newOrder.ERP_Billing_State_or_Province__c = 'Alaska';

        Test.startTest();
        insert newOrder;
        Test.stopTest();

        Order_ERP__c insertedOrder = [
            SELECT ID, OwnerID, ContactID__c, AccountID__c
            FROM Order_ERP__c
            WHERE ID = :newOrder.ID
        ];
        System.assertNotEquals(insertedOrder.OwnerID, WEST_COAST_BDR, 'Order Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c FROM Contact WHERE ID = :newContact.ID];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [
            SELECT ID, OwnerID, Account_Owner_Type__c
            FROM Account
            WHERE ID = :insertedOrder.AccountID__c
        ];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void reassignWestCoast_skipOverGeneric() {
        Account newAccount = TestDataFactory.createTestAccountGenerics(5, 'BDR')[0];

        Contact newContact = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE AccountID = :newAccount.ID
            ORDER BY Account.Name
            LIMIT 1
        ];

        //Create a Quote
        Order_ERP__c newOrder = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'AAAAA-00001',
            'A1234-A5678',
            newAccount,
            newContact,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        newOrder.IS_Generic__c = true;
        newOrder.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        newOrder.ERP_Billing_Address__c = '2 Unit E Northway';
        newOrder.ERP_Billing_City__c = 'Paris';
        newOrder.ERP_Billing_Country__c = 'United States';
        newOrder.ERP_Billing_State_or_Province__c = 'Alaska';

        Test.startTest();
        insert newOrder;
        Test.stopTest();

        Order_ERP__c insertedOrder = [
            SELECT ID, OwnerID, ContactID__c, AccountID__c
            FROM Order_ERP__c
            WHERE ID = :newOrder.ID
        ];
        System.assertNotEquals(insertedOrder.OwnerID, WEST_COAST_BDR, 'Order Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c FROM Contact WHERE ID = :newContact.ID];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [
            SELECT ID, OwnerID, Account_Owner_Type__c
            FROM Account
            WHERE ID = :insertedOrder.AccountID__c
        ];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void coalesceState_selectParentAccount() {
        Account parentAccount = new Account();
        parentAccount.Name = 'ParentCo';
        parentAccount.BillingState = 'Maine';
        insert parentAccount;

        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingState = 'Ohio';
        account.ParentId = parentAccount.Id;
        insert account;

        Account passedAccount = [
            SELECT Id, Name, BillingState, Parent.BillingState
            FROM Account
            WHERE Id = :account.Id
        ];
        System.assertEquals(
            OrderERPHandler.coalesceState(passedAccount, 'Porto'),
            'Maine',
            'Expected parent account state'
        );
    }

    @isTest
    static void coalesceState_selectAccount() {
        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingState = 'Ohio';
        insert account;

        System.assertEquals(OrderERPHandler.coalesceState(account, 'Porto'), 'Ohio', 'Expected account state');
    }

    @isTest
    static void coalesceState_selectPassedString() {
        System.assertEquals(OrderERPHandler.coalesceState(null, 'Porto'), 'Porto', 'Expected returned passed String');
    }

    @isTest
    static void coalesceState_selectNone() {
        System.assertEquals(OrderERPHandler.coalesceState(null, null), '', 'Expected returned Empty String');
    }

    @isTest
    static void coalesceCountry_selectParentAccount() {
        Account parentAccount = new Account();
        parentAccount.Name = 'ParentCo';
        parentAccount.BillingCountry = 'Canada';
        parentAccount.BillingState = 'Ontario';
        insert parentAccount;

        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingCountry = 'United States';
        account.ParentId = parentAccount.Id;
        insert account;

        Account passedAccount = [
            SELECT Id, Name, BillingCountry, Parent.BillingCountry
            FROM Account
            WHERE Id = :account.Id
        ];
        System.assertEquals(
            OrderERPHandler.coalesceCountry(passedAccount, 'Portugal'),
            'Canada',
            'Expected parent account country'
        );
    }

    @isTest
    static void coalesceCountry_selectAccount() {
        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingCountry = 'Denmark';
        insert account;

        System.assertEquals(OrderERPHandler.coalesceCountry(account, 'Porto'), 'Denmark', 'Expected account country');
    }

    @isTest
    static void coalesceCountry_selectPassedString() {
        System.assertEquals(OrderERPHandler.coalesceCountry(null, 'Porto'), 'Porto', 'Expected returned passed String');
    }

    @isTest
    static void coalesceCountry_selectNone() {
        System.assertEquals(OrderERPHandler.coalesceCountry(null, null), '', 'Expected returned Empty String');
    }

    @isTest
    static void projectTest_cancelledOrder_singleOpp() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        insert ord;

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [SELECT Id, OpportunityID__c, Project__c FROM Order_ERP__C WHERE ID = :testOrderID];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity newOpp = [SELECT ID, Project__c, Project__r.Stage__c, StageName FROM Opportunity WHERE Id = :oppID];

        ID projID = newOpp.Project__c;
        Project__c proj = new Project__c();
        proj.Id = projId;
        proj.Stage__c = 'Closed Won';
        update proj;

        Test.startTest();
        ord.Order_Canceled_Flag__c = true;
        update ord;
        Test.stopTest();

        Date todayDate = date.today();
        Order_ERP__c myOrder = [
            SELECT OpportunityID__C, OpportunityID__R.Stagename, ID, Project__c
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];
        Opportunity resultOpp = [
            SELECT ID, StageName, Project__c, Project__r.Stage__c, Project__r.Close_Date__c
            FROM Opportunity
            WHERE ID = :myOrder.OpportunityID__c
            LIMIT 1
        ];

        System.assertEquals(
            'Closed Lost',
            resultOpp.StageName,
            'The opp was not switched to Closed Lost when the Order was canceled'
        );
        System.assertNotEquals(null, resultOpp.Project__c, 'The opp was not associated to a project');
        System.assertEquals('System Reopened', resultOpp.Project__r.Stage__c, 'The project remained open');
        System.assertEquals(
            todayDate,
            resultOpp.Project__r.Close_Date__c,
            'The close date on the project was not updated'
        );
    }

    @isTest
    static void projectTest_cancelledOrder_multipleOpps_oneSOppStillCw() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        insert ord;

        Order_ERP__c ord2 = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4443',
            'BBBBB-34568',
            '56564-55668',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord2.AccountID__c = a.Id;
        ord2.ContactID__c = c.Id;
        ord2.Account_Domain__c = 'superaccount.com';
        ord2.ERP_Company_Name__C = '';
        ord2.ERP_Contact_First_Name__c = 'John';
        ord2.ERP_Contact_Last_Name__c = 'Doe';
        ord2.Order_Email__c = 'johndoe@superaccount.com';
        insert ord2;

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [SELECT Id, OpportunityID__c, Project__c FROM Order_ERP__C WHERE ID = :testOrderID];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity newOpp = [SELECT ID, Project__c, Project__r.Stage__c, StageName FROM Opportunity WHERE Id = :oppID];

        ID projID = newOpp.Project__c;
        Project__c proj = new Project__c();
        proj.Id = projId;
        proj.Stage__c = 'Closed Won';
        update proj;

        Test.startTest();
        ord.Order_Canceled_Flag__c = true;
        update ord;
        Test.stopTest();

        Date todayDate = date.today();
        Order_ERP__c myOrder = [
            SELECT OpportunityID__C, OpportunityID__R.Stagename, ID, Project__c
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];
        Order_ERP__c myOrder2 = [
            SELECT OpportunityID__C, OpportunityID__R.Stagename, ID, Project__c
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord2.Xometry_ERP_ID__C
        ];
        Opportunity resultOpp = [
            SELECT ID, StageName, Project__c, Project__r.Stage__c
            FROM Opportunity
            WHERE ID = :myOrder.OpportunityID__c
            LIMIT 1
        ];
        Opportunity resultOppTwo = [
            SELECT ID, StageName, Project__c, Project__r.Stage__c
            FROM Opportunity
            WHERE ID = :myOrder2.OpportunityID__c
            LIMIT 1
        ];

        System.assertEquals(
            'Closed Lost',
            resultOpp.StageName,
            'The opp was not switched to Closed Lost when the Order was canceled'
        );
        System.assertNotEquals('Closed Lost', resultOppTwo.StageName, 'The opp switched to Closed Lost');
        System.assertEquals(
            resultOpp.Project__c,
            resultOppTwo.Project__c,
            'The opps were associated to different projects'
        );
        System.assertNotEquals(
            'Closed Lost',
            resultOpp.Project__r.Stage__c,
            'The project was switched to CL even though there are Open/CW opps'
        );
    }

    @isTest
    static void projectTest_cancelledOrder_multipleOpps_allCL() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        insert ord;

        Order_ERP__c ord2 = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4445',
            'BBBBB-34568',
            '56564-55668',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord2.AccountID__c = a.Id;
        ord2.ContactID__c = c.Id;
        ord2.Account_Domain__c = 'superaccount.com';
        ord2.ERP_Company_Name__C = '';
        ord2.ERP_Contact_First_Name__c = 'John';
        ord2.ERP_Contact_Last_Name__c = 'Doe';
        ord2.Order_Email__c = 'johndoe@superaccount.com';
        insert ord2;

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [SELECT Id, OpportunityID__c, Project__c FROM Order_ERP__C WHERE ID = :testOrderID];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity newOpp = [SELECT ID, Project__c, Project__r.Stage__c, StageName FROM Opportunity WHERE Id = :oppID];

        ID projID = newOpp.Project__c;
        Project__c proj = new Project__c();
        proj.Id = projId;
        proj.Stage__c = 'Closed Won';
        update proj;

        Test.startTest();
        ord.Order_Canceled_Flag__c = true;
        update ord;
        ord2.Order_Canceled_Flag__c = true;
        update ord2;
        Test.stopTest();

        Date todayDate = date.today();
        Order_ERP__c myOrder = [
            SELECT OpportunityID__C, OpportunityID__R.Stagename, ID, Project__c
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord.Xometry_ERP_ID__C
        ];
        Order_ERP__c myOrder2 = [
            SELECT OpportunityID__C, OpportunityID__R.Stagename, ID, Project__c
            FROM Order_ERP__C
            WHERE Xometry_ERP_ID__C = :ord2.Xometry_ERP_ID__C
        ];
        Opportunity resultOpp = [
            SELECT ID, StageName, Project__c, Project__r.Stage__c
            FROM Opportunity
            WHERE ID = :myOrder.OpportunityID__c
            LIMIT 1
        ];
        Opportunity resultOppTwo = [
            SELECT ID, StageName, Project__c, Project__r.Stage__c
            FROM Opportunity
            WHERE ID = :myOrder2.OpportunityID__c
            LIMIT 1
        ];

        System.assertEquals(
            'Closed Lost',
            resultOpp.StageName,
            'The opp was not switched to Closed Lost when the Order was canceled'
        );
        System.assertEquals(
            'Closed Lost',
            resultOppTwo.StageName,
            'The second opp was not switched to Closed Lost when the Order was canceled'
        );
        System.assertEquals(
            resultOpp.Project__c,
            resultOppTwo.Project__c,
            'The opps were associated to different projects'
        );
        System.assertEquals(
            'System Reopened',
            resultOpp.Project__r.Stage__c,
            'The project remained opened even though all opps are CL'
        );
    }

    @isTest
    static void createOpportunity_withOrderFields() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Amt_Stamping__c = 1234.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        ord.Ordered_Total_Qty_Stamping__c = 1;

        Test.startTest();
        insert ord;
        Test.stopTest();

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [SELECT Id, OpportunityID__c, Project__c FROM Order_ERP__C WHERE ID = :testOrderID];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity resultOpp = [
            SELECT
                ID,
                Name,
                Total_Amt_PolyJet3D__c,
                Total_Amt_Stamping__c,
                Total_Qty_PolyJet3D__c,
                Total_Qty_Stamping__c
            FROM Opportunity
            WHERE Id = :oppID
        ];

        System.assertEquals('Q12-3333-4444 | BBBBB-34567', resultOpp.Name, 'Opp name is missing order or quote ID');

        System.assertEquals(5678.00, resultOpp.Total_Amt_PolyJet3D__c, 'PolyJet3D Amt');
        System.assertEquals(1234.00, resultOpp.Total_Amt_Stamping__c, 'Stamping Amt');

        System.assertEquals(3, resultOpp.Total_Qty_PolyJet3D__c, 'PolyJet3D Qty');
        System.assertEquals(1, resultOpp.Total_Qty_Stamping__c, 'Stamping Qty');
    }

    @isTest
    static void updateOpportunity_withOrderFields() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        ord.process_isPolyJet_3D__c = false;
        ord.Ordered_Total_Amt_PolyJet3D__c = 0;
        ord.Ordered_Total_Qty_PolyJet3D__c = 0;
        insert ord;

        Test.startTest();
        ord.process_isPolyJet_3D__c = true;
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        update ord;
        Test.stopTest();

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [SELECT Id, OpportunityID__c, Project__c FROM Order_ERP__C WHERE ID = :testOrderID];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity resultOpp = [
            SELECT
                ID,
                Name,
                Total_Amt_PolyJet3D__c,
                Total_Amt_Stamping__c,
                Total_Qty_PolyJet3D__c,
                Total_Qty_Stamping__c
            FROM Opportunity
            WHERE Id = :oppID
        ];

        System.assertEquals(5678.00, resultOpp.Total_Amt_PolyJet3D__c, 'PolyJet3D Amt');
        System.assertEquals(3, resultOpp.Total_Qty_PolyJet3D__c, 'PolyJet3D Qty');
        System.assertEquals('Q12-3333-4444 | BBBBB-34567', resultOpp.Name, 'Order ID was not added to Opp name');
    }

    @isTest
    private static void createOpportunity_withQuoteType() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Amt_Stamping__c = 1234.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        ord.Ordered_Total_Qty_Stamping__c = 1;
        ord.Quote_Type__c = 'Auto-Quoted';

        Test.startTest();
        insert ord;
        Test.stopTest();

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [
            SELECT Id, OpportunityID__c, Quote_Type__c
            FROM Order_ERP__C
            WHERE ID = :testOrderID
        ];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity resultOpp = [SELECT ID, Quote_Type__c FROM Opportunity WHERE Id = :oppID];

        System.assertEquals(
            ord.Quote_Type__c,
            resultOpp.Quote_Type__c,
            'Opp should be created with Quote Type equal to quote'
        );
    }

    @isTest
    private static void updateOpportunity_withQuoteType() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        ord.process_isPolyJet_3D__c = false;
        ord.Ordered_Total_Amt_PolyJet3D__c = 0;
        ord.Ordered_Total_Qty_PolyJet3D__c = 0;
        ord.Quote_Type__c = 'Auto-Quoted';
        insert ord;

        Test.startTest();
        ord.Quote_Type__c = 'Manually-Quoted';
        update ord;
        Test.stopTest();

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [
            SELECT Id, OpportunityID__c, Quote_Type__c
            FROM Order_ERP__C
            WHERE ID = :testOrderID
        ];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity resultOpp = [SELECT ID, Quote_Type__c FROM Opportunity WHERE Id = :oppID];

        System.assertEquals(ord.Quote_Type__c, orderFetch.Quote_Type__c, 'Quote Type should be updated');
        System.assertEquals(
            orderFetch.Quote_Type__c,
            resultOpp.Quote_Type__c,
            'Opp Quote Type should equal updated value'
        );
    }

    @isTest
    private static void createOpportunity_addFusionOrigin() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Amt_Stamping__c = 1234.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        ord.Ordered_Total_Qty_Stamping__c = 1;
        ord.Quote_Type__c = 'Auto-Quoted';
        ord.OriginatedInFusion360__c = true;

        Test.startTest();
        insert ord;
        Test.stopTest();

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [
            SELECT Id, OpportunityID__c, OriginatedInFusion360__c
            FROM Order_ERP__C
            WHERE ID = :testOrderID
        ];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity resultOpp = [SELECT ID, OriginatedInFusion360__c FROM Opportunity WHERE Id = :oppID];

        System.assertEquals(
            ord.OriginatedInFusion360__c,
            resultOpp.OriginatedInFusion360__c,
            'Opp should be created with OriginatedInFusion360__c equal to order'
        );
    }
    @isTest
    private static void createOpportunity_withCerts() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = 'superaccount.com';
        ord.ERP_Company_Name__C = '';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'johndoe@superaccount.com';
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Amt_Stamping__c = 1234.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        ord.Ordered_Total_Qty_Stamping__c = 1;
        ord.Quote_Type__c = 'Auto-Quoted';
        ord.ITAR__c = true;
        ord.Hardware_Cert__c = true;
        ord.Conformance_Cert__c = true;
        ord.Material_Traceability_Cert__c = true;
        ord.Material_Cert__c = 'Domestic Compliant Material Cert';

        Test.startTest();
        insert ord;
        Test.stopTest();

        ID testOrderID = ord.ID;
        Order_ERP__C orderFetch = [
            SELECT Id, OpportunityID__c, OriginatedInFusion360__c
            FROM Order_ERP__C
            WHERE ID = :testOrderID
        ];

        ID oppID = orderFetch.OpportunityID__c;
        Opportunity resultOpp = [
            SELECT ID, ITAR__c, Hardware_Cert__c, Conformance_Cert__c, Material_Traceability_Cert__c, Material_Cert__c
            FROM Opportunity
            WHERE Id = :oppID
        ];

        System.assertEquals(resultOpp.ITAR__c, ord.ITAR__c, 'Opp should be created with ITAR__c equal to true');
        System.assertEquals(
            resultOpp.Hardware_Cert__c,
            ord.Hardware_Cert__c,
            'Opp should be created with Hardware_Cert__c equal to true'
        );
        System.assertEquals(
            resultOpp.Conformance_Cert__c,
            ord.Conformance_Cert__c,
            'Opp should be created with Conformance_Cert__c equal to true'
        );
        System.assertEquals(
            resultOpp.Material_Traceability_Cert__c,
            ord.Material_Traceability_Cert__c,
            'Opp should be created with Material_Traceability_Cert__c equal to true'
        );
        System.assertEquals(
            resultOpp.Material_Cert__c,
            ord.Material_Cert__c,
            'The Opp Material Cert Text did no match the quote'
        );
    }

    @isTest
    private static void accountUpdatesOwner_fromGNOHouse() {
        Account a = new Account();
        a.Name = 'Test Account';
        a.Account_Owner_Type__c = 'Ops';
        a.Email_Domain__c = 'coolcompany.com';
        a.OwnerId = AppConstants.GNO_HOUSE_USER;
        insert a;

        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Contact';
        c.Primary_Email__c = 'contact@coolcompany.com';
        c.AccountId = a.Id;
        c.OwnerId = AppConstants.GNO_HOUSE_USER;
        insert c;

        Order_ERP__c ord = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'BBBBB-34567',
            '56564-55667',
            a,
            c,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        ord.AccountID__c = a.Id;
        ord.ContactID__c = c.Id;
        ord.Account_Domain__c = a.Email_Domain__c;
        ord.ERP_Company_Name__C = 'Test Account';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.Order_Email__c = 'contact@coolcompany.com';
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Amt_Stamping__c = 1234.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        ord.Ordered_Total_Qty_Stamping__c = 1;
        ord.Quote_Type__c = 'Auto-Quoted';

        Test.startTest();
        insert ord;
        Test.stopTest();

        Account aResult = [SELECT Id, OwnerId FROM Account WHERE Id = :a.Id LIMIT 1];
        Contact cResult = [SELECT Id, OwnerId FROM Contact WHERE Id = :c.Id LIMIT 1];

        System.assertNotEquals(a.OwnerId, aResult.OwnerId, 'Account Owner should not be GNO House');
        System.assertEquals(AppConstants.SALES_HOUSE_USER, aResult.OwnerId, 'Account Owner should be Sales House');
        System.assertEquals(c.OwnerId, cResult.OwnerId, 'Contact Owner should be GNO House');
        System.assertNotEquals(AppConstants.SALES_HOUSE_USER, cResult.OwnerId, 'Contact Owner should not be Sales House');

    }

    @isTest
    private static void orderWithPartner_associatesPartnerAccount() {
        List<Account> accts = TestDataFactory.createTestAccountNonGenerics(1, 'Ops', 1);
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P12345';
        s.EmailAddress__c = 'contact@coolcompany.com';
        s.AccountDomain__c = 'coolcompany.com';
        s.SupplierCompanyName__c = 'Cool Supplier';
        s.LastName__c = 'Supplier';
        s.FirstName__c = 'Cool';
        s.Phone__c = '1234567890';
        s.IsGeneric__c = false;
        insert s;

        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Contact';
        c.Primary_Email__c = 'contact1@coolcompany.com';
        c.AccountId = accts[0].Id;
        c.OwnerId = AppConstants.GNO_HOUSE_USER;
        insert c;

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = s.EmailAddress__c;
        ord.ERP_Company_Name__C = 'Test Account';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = c.Primary_Email__c;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Amt_Stamping__c = 1234.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        ord.Ordered_Total_Qty_Stamping__c = 1;
        ord.Quote_Type__c = 'Auto-Quoted';
        ord.MKP_PartnerId__c = 'P12345';

        Test.startTest();
        insert ord;
        Test.stopTest();

        Contact cResult = [SELECT Id, OwnerId, GNO_PartnerId__c FROM Contact WHERE Id = :c.Id][0];
        Order_ERP__c oResult = [SELECT Id, AccountId__c, ContactId__c FROM Order_ERP__c WHERE Id = :ord.Id];
        Supplier__c sResult = [SELECT Id, AccountId__c, ContactID__c FROM Supplier__c WHERE Id = :s.Id];

        System.assertEquals(
            sResult.AccountId__c,
            oResult.AccountId__c,
            'Account should associate with supplier account'
        );
        System.assertEquals(c.Id, oResult.ContactId__c, 'Contact should associate with contact based on email');
        System.assertEquals(ord.MKP_PartnerId__c, cResult.GNO_PartnerId__c, 'Contact should have partner Id');
    }

    @isTest
    private static void orderWithPartner_associatesPartnerAccountMultipleContacts() {
        List<Account> accts = TestDataFactory.createTestAccountNonGenerics(3, 'Ops', 1);
        Contact c = [SELECT Id, Email, FirstName, LastName FROM Contact WHERE AccountId = :accts[0].Id];

        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P12345';
        s.EmailAddress__c = 'contact@coolcompany.com';
        s.AccountDomain__c = 'coolcompany.com';
        s.SupplierCompanyName__c = 'Cool Supplier';
        s.LastName__c = 'Supplier';
        s.FirstName__c = 'Cool';
        s.Phone__c = '1234567890';
        s.IsGeneric__c = false;
        insert s;

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = accts[0].Email_Domain__c;
        ord.ERP_Company_Name__C = 'Test Account';
        ord.ERP_Contact_First_Name__c = c.FirstName;
        ord.ERP_Contact_Last_Name__c = c.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = c.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Amt_Stamping__c = 1234.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        ord.Ordered_Total_Qty_Stamping__c = 1;
        ord.Quote_Type__c = 'Auto-Quoted';
        ord.MKP_PartnerId__c = 'P12345';

        Test.startTest();
        insert ord;
        Test.stopTest();

        Order_ERP__c oResult = [SELECT Id, AccountId__c, ContactId__c FROM Order_ERP__c WHERE Id = :ord.Id];
        Contact cResult = [SELECT Id, GNO_PartnerId__c FROM Contact WHERE Id = :c.Id];
        Supplier__c sResult = [SELECT Id, AccountId__c, ContactID__c FROM Supplier__c WHERE Id = :s.Id];

        System.assertEquals(
            sResult.AccountId__c,
            oResult.AccountId__c,
            'Account should associate with supplier account'
        );
        System.assertEquals(c.Id, oResult.ContactId__c, 'Contact should associate with contact based on email');
        System.assertEquals(
            cResult.GNO_PartnerId__c,
            ord.MKP_PartnerId__c,
            'Contact should be updated with partner Id'
        );
    }

    @isTest
    private static void orderWithPartner_associatesPartnerAccountNoContact() {
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P12345';
        s.EmailAddress__c = 'contact@coolcompany.com';
        s.AccountDomain__c = 'coolcompany.com';
        s.SupplierCompanyName__c = 'Cool Supplier';
        s.LastName__c = 'Supplier';
        s.FirstName__c = 'Cool';
        s.Phone__c = '1234567890';
        s.IsGeneric__c = false;
        insert s;

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = s.AccountDomain__c;
        ord.ERP_Company_Name__C = 'Test Account';
        ord.ERP_Contact_First_Name__c = 'John';
        ord.ERP_Contact_Last_Name__c = 'Doe';
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = '2ndcontact@coolcompany.com';
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.Ordered_Total_Amt_PolyJet3D__c = 5678.00;
        ord.Ordered_Total_Amt_Stamping__c = 1234.00;
        ord.Ordered_Total_Qty_PolyJet3D__c = 3;
        ord.Ordered_Total_Qty_Stamping__c = 1;
        ord.Quote_Type__c = 'Auto-Quoted';
        ord.MKP_PartnerId__c = 'P12345';

        Test.startTest();
        insert ord;
        Test.stopTest();

        Supplier__c sResult = [SELECT Id, AccountId__c, ContactId__c FROM Supplier__c WHERE Id = :s.Id];
        Order_ERP__c oResult = [SELECT Id, AccountId__c, ContactId__c FROM Order_ERP__c WHERE Id = :ord.Id];
        Contact cResult = [SELECT Id, GNO_PartnerId__c FROM Contact WHERE Id = :oResult.ContactId__c];

        System.assertEquals(
            sResult.AccountId__c,
            oResult.AccountId__c,
            'Account should associate with supplier account'
        );
        System.assertNotEquals(sResult.ContactId__c, cResult.Id, 'New Contact should be created');
        System.assertEquals(ord.MKP_PartnerId__c, cResult.GNO_PartnerID__c, 'Partner Id should be populated');
    }

    @isTest
    private static void orderCreatesOpsOrder() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.CaseManager__c = '';

        Test.startTest();
        insert ord;
        Test.stopTest();

        Order_ERP__c orderResult = [
            SELECT Id, Xometry_ERP_ID__c, Ops_Order__c
            FROM Order_ERP__c
            WHERE Id = :ord.Id
            LIMIT 1
        ];
        Ops_Order__c opsOrderResult = [
            SELECT Id, XometryOpsOrderID__c, Stage__c, CaseManager__c
            FROM Ops_Order__c
            LIMIT 1
        ];

        System.assertEquals(
            opsOrderResult.Id,
            orderResult.Ops_Order__c,
            'Ops Order not associated with managed service orders'
        );
        System.assertEquals(
            orderResult.Xometry_ERP_ID__c,
            opsOrderResult.XometryOpsOrderID__c,
            'Ops Order not set to correct order id'
        );
        System.assertEquals(null, opsOrderResult.CaseManager__c, 'Case Manager was set incorrectly');
    }

    @isTest
    private static void orderAssociateToOpsOrder() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];

        Ops_Order__c opsOrd = new Ops_Order__c(XometryOpsOrderID__c = 'BBBBB-34567');
        insert opsOrd;

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;

        Test.startTest();
        insert ord;
        Test.stopTest();

        Order_ERP__c orderResult = [
            SELECT Id, Xometry_ERP_ID__c, Ops_Order__c
            FROM Order_ERP__c
            WHERE Id = :ord.Id
            LIMIT 1
        ];
        List<Ops_Order__c> opsOrderResult = [SELECT Id, XometryOpsOrderID__c, Stage__c FROM Ops_Order__c];

        System.assertEquals(opsOrderResult.size(), 1, 'There should be no newly created Ops Orders');
        System.assertEquals(
            opsOrderResult[0].Id,
            orderResult.Ops_Order__c,
            'Ops Order not associated with managed service orders'
        );
        System.assertEquals(
            orderResult.Xometry_ERP_ID__c,
            opsOrderResult[0].XometryOpsOrderID__c,
            'Ops Order not set to correct order id'
        );
    }

    @isTest
    private static void orderAssociateToOpsOrderAndReopen() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];

        Ops_Order__c opsOrd = new Ops_Order__c(XometryOpsOrderID__c = 'BBBBB-34567', Stage__c = 'Complete');
        insert opsOrd;

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;

        Test.startTest();
        insert ord;
        Test.stopTest();

        Order_ERP__c orderResult = [
            SELECT Id, Xometry_ERP_ID__c, Ops_Order__c
            FROM Order_ERP__c
            WHERE Id = :ord.Id
            LIMIT 1
        ];
        List<Ops_Order__c> opsOrderResult = [SELECT Id, XometryOpsOrderID__c, Stage__c FROM Ops_Order__c];

        System.assertEquals(opsOrderResult.size(), 1, 'There should be no newly created Ops Orders');
        System.assertEquals(
            opsOrderResult[0].Id,
            orderResult.Ops_Order__c,
            'Ops Order not associated with managed service orders'
        );
        System.assertEquals(
            orderResult.Xometry_ERP_ID__c,
            opsOrderResult[0].XometryOpsOrderID__c,
            'Ops Order not set to correct order id'
        );
        System.assertEquals('Reopened by Updated Order', opsOrderResult[0].Stage__c, 'Stage was not changed');
    }

    @isTest
    public static void orderWithDuns_relatesDUNSAccount() {
        DNBConnect__D_B_Connect_Company_Profile__c cRecord = new DNBConnect__D_B_Connect_Company_Profile__c();
        cRecord.DNBConnect__PrimName__c = 'Test';
        cRecord.DNBConnect__DUNSNumber__c = '012345678';

        insert cRecord;

        List<Account> aList = TestDataFactory.createTestAccountNonGenerics(3, 'BDR', 1);
        aList[0].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        aList[1].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        aList[2].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;

        update aList;
        Contact c = [SELECT ID, FirstName, LastName, Email, AccountId FROM Contact][0];

        Order_ERP__c order = new Order_ERP__C();
        order.Account_Domain__c = aList[1].Email_Domain__c;
        order.ERP_Company_Name__C = aList[1].Name + 'Blue';
        order.ERP_Contact_First_Name__c = c.FirstName;
        order.ERP_Contact_Last_Name__c = c.LastName;
        order.ERP_Contact__C = 'BBBBB';
        order.ERP_PartPk__c = '56564-55667';
        order.Is_Generic__c = false;
        order.Order_Canceled_Flag__c = false;
        order.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        order.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        order.Order_Email__c = c.Email;
        order.Order_Subtotal__c = 4500.00;
        order.Order_Total__c = 5000.50;
        order.Payment_Type__c = 'credit_card';
        order.Xometry_ERP_ID__c = 'BBBBB-34567';
        order.process_isPolyJet_3D__c = true;
        order.UserDUNSNumber__c = '012345678';

        Test.startTest();
        insert order;
        Test.stopTest();

        Order_ERP__c oResult = [
            SELECT Id, AccountID__c, ContactID__c, ContactID__r.AccountID
            FROM Order_ERP__c
            WHERE Id = :order.Id
        ];
        // System.debug([select id, accountId from contact where id = :c.Id]);
        // System.debug(oResult.AccountID__c);
        // System.debug(oResult.ContactID__r.AccountID);
        // System.debug([select id from account where id = :aList[1].Id]);
        // System.debug(oResult.AccountID__c == oResult.ContactID__r.AccountID);
        System.assertEquals(aList[1].Id, oResult.AccountID__c, 'Account is not from duns');
        System.assertEquals(c.Id, oResult.ContactId__c, 'Contact was not correctly associated');
        System.assertEquals(
            oResult.AccountID__c,
            oResult.ContactID__r.AccountID,
            'Contact acct should match quote acct'
        );
    }

    @isTest
    public static void orderWithDuns_relatesDUNSAccountNewContact() {
        DNBConnect__D_B_Connect_Company_Profile__c cRecord = new DNBConnect__D_B_Connect_Company_Profile__c();
        cRecord.DNBConnect__PrimName__c = 'Test';
        cRecord.DNBConnect__DUNSNumber__c = '012345678';

        insert cRecord;

        List<Account> aList = TestDataFactory.createTestAccountNonGenerics(3, 'BDR', 1);
        aList[0].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        aList[1].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        aList[2].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;

        update aList;
        Contact c = [SELECT ID, FirstName, LastName, Email FROM Contact][0];

        Order_ERP__c order = new Order_ERP__C();
        order.Account_Domain__c = aList[1].Email_Domain__c;
        order.ERP_Company_Name__C = aList[1].Name + 'Blue';
        order.ERP_Contact_First_Name__c = 'John';
        order.ERP_Contact_Last_Name__c = 'Doe';
        order.ERP_Contact__C = 'BBBBB';
        order.ERP_PartPk__c = '56564-55667';
        order.Is_Generic__c = false;
        order.Order_Canceled_Flag__c = false;
        order.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        order.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        order.Order_Email__c = 'coolcompany@cool.com';
        order.Order_Subtotal__c = 4500.00;
        order.Order_Total__c = 5000.50;
        order.Payment_Type__c = 'credit_card';
        order.Xometry_ERP_ID__c = 'BBBBB-34567';
        order.process_isPolyJet_3D__c = true;
        order.UserDUNSNumber__c = '000000000';
        order.UserParentDUNSNumber__c = '234567890';
        order.UserUltimateDUNSNumber__c = '999999999';

        Test.startTest();
        insert order;
        Test.stopTest();

        Order_ERP__c oResult = [
            SELECT
                Id,
                AccountID__c,
                ContactID__c,
                ContactID__r.AccountID
            FROM Order_ERP__c
            WHERE Id = :order.Id
        ];
        System.assertEquals(aList[1].Id, oResult.AccountID__c, 'Account is not from duns');
        
        System.assertNotEquals(c.Id, oResult.ContactId__c, 'Contact should not be contact quote');
        System.assertEquals(
            oResult.AccountID__c,
            oResult.ContactID__r.AccountID,
            'Contact acct should match quote acct'
        );
    }

    @isTest
    private static void orderUpdatesOpsOrder() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.ERP_Status__c = 'Offer Accepted';
        insert ord;

        List<Ops_Order__c> opsOrderPretest = [SELECT Id, XometryOpsOrderID__c FROM Ops_Order__c];
        ID firstOpsOrder = opsOrderPretest[0].ID;
        delete opsOrderPretest[0];

        Test.startTest();
        ord.ERP_Status__c = 'In Progress';
        update ord;
        Test.stopTest();

        List<Ops_Order__c> opsOrderResult = [SELECT Id, XometryOpsOrderID__c, ERPStatus__c FROM Ops_Order__c];

        System.assertNotEquals(
            opsOrderResult[0].Id,
            firstOpsOrder,
            'Ops Order is not the newly created one from update'
        );
        System.assertEquals(
            'In Progress',
            opsOrderResult[0].ERPStatus__c,
            'The Order should have updated the Ops Order'
        );
    }

    @isTest
    private static void opsOrderDupTesting() {
        // This test was created due to duplicate Ops Orders attempting to be created.
        // This issue found was the Order map was not updated with the OpsOrder
        // when a OpsOrder existed but was not linked previously, due to launch times.
        // This attempted a insert of a new OpsOrder when the
        // OpsOrderFetchList and updatedOrders Lists did not match.

        List<Order_ERP__C> ordList = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = 'supercompany.com';
        ord.ERP_Company_Name__C = 'Name ';
        ord.ERP_Contact_First_Name__c = 'FirstName';
        ord.ERP_Contact_Last_Name__c = 'LastName';
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = 'Email@supercompany.com';
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.ERP_Status__c = 'Offer Accepted';
        ordList.add(ord);

        Order_ERP__C ord1 = new Order_ERP__C();
        ord1.Account_Domain__c = 'supercompany.com';
        ord1.ERP_Company_Name__C = 'Name ';
        ord1.ERP_Contact_First_Name__c = 'FirstName';
        ord1.ERP_Contact_Last_Name__c = 'LastName';
        ord1.ERP_Contact__C = 'BBBBB';
        ord1.ERP_PartPk__c = '56789-55678';
        ord1.Is_Generic__c = false;
        ord1.Order_Canceled_Flag__c = false;
        ord1.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord1.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord1.Order_Email__c = 'email@supercompany.com';
        ord1.Order_Subtotal__c = 4500.00;
        ord1.Order_Total__c = 5000.50;
        ord1.Payment_Type__c = 'credit_card';
        ord1.Xometry_ERP_ID__c = 'CCCCC-45678';
        ord1.ERP_Status__c = 'Offer Accepted';
        ordList.add(ord1);

        Order_ERP__C ord3 = new Order_ERP__C();
        ord3.Account_Domain__c = 'supercompany.com';
        ord3.ERP_Company_Name__C = 'Name ';
        ord3.ERP_Contact_First_Name__c = 'FirstName';
        ord3.ERP_Contact_Last_Name__c = 'LastName';
        ord3.ERP_Contact__C = 'BBBBB';
        ord3.ERP_PartPk__c = '56780-55678';
        ord3.Is_Generic__c = false;
        ord3.Order_Canceled_Flag__c = false;
        ord3.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord3.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord3.Order_Email__c = 'email@supercompany.com';
        ord3.Order_Subtotal__c = 4500.00;
        ord3.Order_Total__c = 5000.50;
        ord3.Payment_Type__c = 'credit_card';
        ord3.Xometry_ERP_ID__c = 'EEEEE-45679';
        ord3.ERP_Status__c = 'Offer Accepted';
        ordList.add(ord3);
        insert ordList;

        List<Ops_Order__c> opsOrderPretest = [
            SELECT Id, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderId__c IN (:ord.Xometry_ERP_ID__c, :ord1.Xometry_ERP_ID__c)
        ];
        delete opsOrderPretest;

        List<Ops_Order__c> opsOrdersList = new List<Ops_Order__c>();
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.XometryOpsOrderID__c = 'BBBBB-34567';
        opsOrdersList.add(opsOrder);
        insert opsOrdersList;

        Test.startTest();
        List<Order_ERP__C> updateList = new List<Order_ERP__C>();
        ord.ERP_Status__c = 'In Progress';
        updateList.add(ord);
        ord1.Order_Total__C = 5002.50;
        updateList.add(ord1);
        ord3.Order_Total__C = 5002.50;
        updateList.add(ord3);
        update updateList;
        Test.stopTest();

        List<Audit_Trail_Error__c> auditList = [
            SELECT ID, name, module__C, dev_audit_notes__c, statusCode__c, errorFields__c, errorMessage__c, Createddate
            FROM audit_trail_error__c
        ];
        System.assertEquals(0, auditList.size(), 'The audit trail should not have any errors');
        System.debug(
            'Audit:' +
            [
                SELECT
                    ID,
                    name,
                    module__C,
                    dev_audit_notes__c,
                    statusCode__c,
                    errorFields__c,
                    errorMessage__c,
                    Createddate
                FROM audit_trail_error__c
            ]
        );
    }

    @isTest
    private static void lastNameNull() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__c = 'Q12-3333-4444';
        insert myQuote;

        Contact cPreOrd = [SELECT Id, FirstName, LastName FROM Contact][0];
        System.assert(myQuote.Quote_Email__C == cPreOrd.LastName, 'Contact last name should be email pre order');
        Test.startTest();

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myQuote.Account_Domain__c;
        ord.ERP_Company_Name__C = 'Name';
        ord.ERP_Contact_First_Name__c = 'FirstName';
        ord.ERP_Contact_Last_Name__c = 'LastName';
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myQuote.Quote_Email__c;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-15000';
        ord.Xometry_Quote_ID__c = myQuote.Xometry_ERP_ID__c;
        ord.ERP_Status__c = 'Offer Accepted';
        insert ord;

        Test.stopTest();

        Contact cResult = [SELECT Id, FirstName, LastName FROM Contact][0];
        System.assertEquals(ord.ERP_Contact_Last_Name__c, cResult.LastName, 'Contact last name should not be an email');
    }

    @isTest
    private static void orderCreatesEUDCase() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2022, 4, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2022, 4, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.EUD_MissingEndUseData__c = true;
        ord.EUD_HasCase__c = false;
        ord.EUD_ImportReason__c = true;
        ord.EUD_Industry__c = true;
        ord.EUD_HTSCode__c = true;
        ord.EUD_PartDescription__c = false;
        ord.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';

        Test.startTest();
        insert ord;
        Test.stopTest();

        Order_ERP__c orderResult = [
            SELECT Id, EUD_HasCase__c, Ops_Order__c, Xometry_ERP_ID__c
            FROM Order_ERP__c
            WHERE Id = :ord.Id
            LIMIT 1
        ];

        Case caseResult = [SELECT Id, GNOOrder__c, EUD_Work_Stage__c FROM Case LIMIT 1];
        List<EmailMessage> emailResult = [
            SELECT Id, ParentId, Subject, FromAddress
            FROM EmailMessage
            WHERE ParentId = :caseResult.Id
        ];

        Part_Information__c part = [SELECT Id, hasHTSCode__c FROM Part_Information__c LIMIT 1];

        System.debug('From Address: ' + emailResult[0].FromAddress);
        System.assertEquals(true, orderResult.EUD_HasCase__c, 'EUD_HasCase__c field not updated correctly');
        System.assertEquals(caseResult.GNOOrder__c, orderResult.Ops_Order__c, 'Ops order not associated to case');
        System.assertEquals('1st Attempt Sent', caseResult.EUD_Work_Stage__c, 'EUD Work Stage was not updated');
        System.assertEquals(false, part.hasHTSCode__c, 'Part field was not updated');
        System.assertEquals(1, emailResult.size(), 'EUD Initial email has been sent');
    }

    @isTest
    private static void orderIsReloadedEUDCase() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2022, 4, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2022, 4, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.EUD_MissingEndUseData__c = true;
        ord.EUD_HasCase__c = false;
        ord.EUD_ImportReason__c = true;
        ord.EUD_Industry__c = true;
        ord.EUD_HTSCode__c = true;
        ord.EUD_PartDescription__c = false;
        ord.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';
        insert ord;

        delete ord;

        Order_ERP__C ordAgain = new Order_ERP__C();
        ordAgain.Account_Domain__c = myTestAccount.Email_Domain__c;
        ordAgain.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ordAgain.ERP_Contact_First_Name__c = myretContact.FirstName;
        ordAgain.ERP_Contact_Last_Name__c = myretContact.LastName;
        ordAgain.ERP_Contact__C = 'BBBBB';
        ordAgain.ERP_PartPk__c = '56564-55667';
        ordAgain.Is_Generic__c = false;
        ordAgain.Order_Canceled_Flag__c = false;
        ordAgain.Order_ERP_CreatedDate__c = date.newInstance(2022, 4, 15);
        ordAgain.Order_ERP_Time__c = dateTime.newInstance(2022, 4, 15, 10, 0, 30);
        ordAgain.Order_Email__c = myretContact.Email;
        ordAgain.Order_Subtotal__c = 4500.00;
        ordAgain.Order_Total__c = 5000.50;
        ordAgain.Payment_Type__c = 'credit_card';
        ordAgain.Xometry_ERP_ID__c = 'BBBBB-34567';
        ordAgain.process_isPolyJet_3D__c = true;
        ordAgain.EUD_MissingEndUseData__c = true;
        ordAgain.EUD_HasCase__c = false;
        ordAgain.EUD_ImportReason__c = true;
        ordAgain.EUD_Industry__c = true;
        ordAgain.EUD_HTSCode__c = true;
        ordAgain.EUD_PartDescription__c = false;
        ordAgain.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';

        Test.startTest();
        insert ordAgain;
        Test.stopTest();

        List<Case> caseResult = new List<Case>([SELECT Id FROM Case WHERE Category__c = 'End-use definition']);

        Set<Id> eudCaseSet = new Set<Id>();
        for (Case eudCase : caseResult) {
            eudCaseSet.add(eudCase.Id);
        }

        List<Part_Information__c> partList = [SELECT Id, hasHTSCode__c FROM Part_Information__c];

        List<EmailMessage> emailResult = [SELECT Id, ParentId FROM EmailMessage WHERE ParentId = :eudCaseSet];

        System.assertEquals(1, caseResult.size(), 'More than 1 case created for order with missing EUD');
        System.assertEquals(1, partList.size(), 'The same part was created multiple times');
        System.assertEquals(1, emailResult.size(), 'More than 1 email was sent');
    }

    @isTest
    private static void orderUpdatesEUDCase_ReadyToShip() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2022, 4, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2022, 4, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.EUD_MissingEndUseData__c = true;
        ord.EUD_HasCase__c = false;
        ord.EUD_ImportReason__c = true;
        ord.EUD_Industry__c = true;
        ord.EUD_HTSCode__c = false;
        ord.EUD_PartDescription__c = true;
        ord.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';
        insert ord;

        ord.EUD_MissingEndUseData__c = false;
        ord.EUD_HasCase__c = true;
        ord.EUD_ImportReason__c = true;
        ord.EUD_Industry__c = true;
        ord.EUD_HTSCode__c = true;
        ord.EUD_PartDescription__c = true;
        ord.EUD_LineItemBreakdown__c = '02E3CD3:';

        Test.startTest();
        update ord;
        Test.stopTest();

        Order_ERP__c orderResult = [
            SELECT Id, EUD_HasCase__c, Ops_Order__c
            FROM Order_ERP__c
            WHERE Id = :ord.Id
            LIMIT 1
        ];

        List<Part_Information__c> part = [SELECT Id, hasHTSCode__c FROM Part_Information__c];

        System.assertEquals(true, part[0].hasHTSCode__c, 'Part was updated with new EUD');
    }

    @isTest
    private static void orderUpdatesEUDCase_NotReadyToShip() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2022, 4, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2022, 4, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.EUD_MissingEndUseData__c = true;
        ord.EUD_HasCase__c = false;
        ord.EUD_ImportReason__c = false;
        ord.EUD_Industry__c = false;
        ord.EUD_HTSCode__c = false;
        ord.EUD_PartDescription__c = true;
        ord.EUD_LineItemBreakdown__c =
            '02E3CD3: HTS Code;' +
            '\n' +
            '02E3CD4: Industry, Import Reason;' +
            '\n' +
            '02E3CD5: Industry';
        insert ord;

        System.debug('Number of parts: ' + [SELECT Id FROM Part_Information__c].size());
        ord.EUD_MissingEndUseData__c = true;
        ord.EUD_HasCase__c = true;
        ord.EUD_ImportReason__c = false;
        ord.EUD_Industry__c = false;
        ord.EUD_HTSCode__c = true;
        ord.EUD_PartDescription__c = true;
        ord.EUD_LineItemBreakdown__c = '02E3CD4: Industry, Import Reason';
        update ord;
        System.debug('Number of parts: ' + [SELECT Id FROM Part_Information__c].size());

        ord.EUD_MissingEndUseData__c = true;
        ord.EUD_HasCase__c = true;
        ord.EUD_ImportReason__c = false;
        ord.EUD_Industry__c = true;
        ord.EUD_HTSCode__c = true;
        ord.EUD_PartDescription__c = true;
        ord.EUD_LineItemBreakdown__c = '02E3CD4: Import Reason';

        System.debug('Number of parts: ' + [SELECT Id FROM Part_Information__c].size());

        Test.startTest();
        update ord;
        Test.stopTest();

        List<Part_Information__c> part = [SELECT Id FROM Part_Information__c];

        System.assertEquals(3, part.size(), 'Incorrect amount of part objects created');
    }

    @isTest
    private static void orderCreatesEUDCase_accountEmailOptOut() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        myTestAccount.EUD_EmailOptOut__c = true;
        update myTestAccount;

        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2022, 4, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2022, 4, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.EUD_MissingEndUseData__c = true;
        ord.EUD_HasCase__c = false;
        ord.EUD_ImportReason__c = true;
        ord.EUD_Industry__c = true;
        ord.EUD_HTSCode__c = true;
        ord.EUD_PartDescription__c = false;
        ord.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';

        Test.startTest();
        insert ord;
        Test.stopTest();

        Order_ERP__c orderResult = [
            SELECT Id, EUD_HasCase__c, Ops_Order__c, Xometry_ERP_ID__c
            FROM Order_ERP__c
            WHERE Id = :ord.Id
            LIMIT 1
        ];

        Case caseResult = [SELECT Id, GNOOrder__c, EUD_Work_Stage__c FROM Case LIMIT 1];
        List<EmailMessage> emailResult = [
            SELECT Id, ParentId, Subject, FromAddress
            FROM EmailMessage
            WHERE ParentId = :caseResult.Id
        ];

        System.assertEquals(true, orderResult.EUD_HasCase__c, 'EUD_HasCase__c field not updated correctly');
        System.assertEquals(caseResult.GNOOrder__c, orderResult.Ops_Order__c, 'Ops order not associated to case');
        System.assertEquals(0, emailResult.size(), 'EUD Initial email has been sent');
    }

    @isTest
    private static void orderCreatesEUDCase_contactEmailOptOut() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email, EUD_EmailOptOut__c
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        myretContact.EUD_EmailOptOut__c = true;
        update myretContact;
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2022, 4, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2022, 4, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.EUD_MissingEndUseData__c = true;
        ord.EUD_HasCase__c = false;
        ord.EUD_ImportReason__c = true;
        ord.EUD_Industry__c = true;
        ord.EUD_HTSCode__c = true;
        ord.EUD_PartDescription__c = false;
        ord.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';

        Test.startTest();
        insert ord;
        Test.stopTest();

        List<EmailMessage> emailResult = [SELECT Id, ParentId, Subject, FromAddress FROM EmailMessage];

        System.assertEquals(0, emailResult.size(), 'EUD Initial email has been sent');
    }

    @isTest
    private static void newUpdateUpsertsOrderID() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__c = 'Q12-3333-4444';
        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);
        insert myQuote;

        Case pseCase = [
            SELECT Id, ShadowXometryOrderID__c
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :myQuote.Xometry_ERP_ID__c
        ];
        Id pseCaseID = pseCase.Id;

        System.assertEquals(
            null,
            pseCase.ShadowXometryOrderID__c,
            'The Shadow Order ID should be empty on the PSE Case'
        );

        CaseOpportunity__c caseOpp = [
            SELECT Id, Opportunity__c, Xometry_Order_ID__c
            FROM CaseOpportunity__c
            WHERE Xometry_ERP_ID__c = :myQuote.Xometry_ERP_ID__c
        ];

        System.assertEquals(null, caseOpp.Xometry_Order_ID__c, 'The Shadow Order ID should be empty on the caseOpp');

        Id caseOppId = caseOpp.Id;
        Id oppId = caseOpp.Opportunity__c;

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myQuote.Account_Domain__c;
        ord.ERP_Company_Name__C = 'Name';
        ord.ERP_Contact_First_Name__c = 'FirstName';
        ord.ERP_Contact_Last_Name__c = 'LastName';
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myQuote.Quote_Email__c;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-15000';
        ord.Xometry_Quote_ID__c = myQuote.Xometry_ERP_ID__c;
        ord.ERP_Status__c = 'Offer Accepted';

        Test.startTest();
        insert ord;
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, Order_ERP_Xom_ID__c FROM Opportunity];
        Case updatedCase = [SELECT ShadowXometryOrderID__c FROM Case WHERE Id = :pseCaseId];
        List<CaseOpportunity__c> updatedCaseOpp = [
            SELECT Xometry_Order_ID__c
            FROM CaseOpportunity__c
            WHERE Id = :caseOpp.Id
        ];

        System.assertEquals(1, updatedCaseOpp.size(), 'A new caseOpp was created when the order ID was updated');
        System.assertEquals(
            updatedOpp.Order_ERP_Xom_ID__c,
            updatedCase.ShadowXometryOrderID__c,
            'The shadow order ID on the case was not upserted'
        );
        System.assertEquals(
            updatedOpp.Order_ERP_Xom_ID__c,
            updatedCaseOpp[0].Xometry_Order_ID__c,
            'The Order Id on the caseOpp was not upserted'
        );
    }

    @isTest
    private static void orderCreatesOpsOrderwithChildren() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        ID testAccountID = retAccounts[0].ID;
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
            ORDER BY Name
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrders = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.process_isPolyJet_3D__c = true;
        ord.CaseManager__c = '';
        preTestOrders.add(ord);

        Order_ERP__C ord1 = new Order_ERP__C();
        ord1.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord1.ERP_Company_Name__C = myTestAccount.Name + 'Blue';
        ord1.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord1.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord1.ERP_Contact__C = 'BBBBB';
        ord1.ERP_PartPk__c = '56564-55667';
        ord1.Is_Generic__c = false;
        ord1.Order_Canceled_Flag__c = false;
        ord1.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord1.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord1.Order_Email__c = myretContact.Email;
        ord1.Order_Subtotal__c = 4500.00;
        ord1.Order_Total__c = 5000.50;
        ord1.Payment_Type__c = 'credit_card';
        ord1.Xometry_ERP_ID__c = 'BBBBB-34568';
        ord1.process_isPolyJet_3D__c = true;
        ord1.CaseManager__c = '';
        ord1.ParentOpsOrderID__c = ord.Xometry_ERP_ID__c;
        preTestOrders.add(ord1);
        Test.startTest();
        insert preTestOrders;
        Test.stopTest();

        Ops_Order__c opsOrderResultParent = [
            SELECT Id, XometryOpsOrderID__c, Stage__c, CaseManager__c, ParentOpsOrder__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :ord.Xometry_ERP_ID__c
            LIMIT 1
        ][0];
        Ops_Order__c opsOrderResultChild = [
            SELECT Id, XometryOpsOrderID__c, Stage__c, CaseManager__c, ParentOpsOrder__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :ord1.Xometry_ERP_ID__c
            LIMIT 1
        ][0];
        System.assertEquals(
            opsOrderResultParent.ID,
            opsOrderResultChild.ParentOpsOrder__c,
            'The Child Ops Order did not match the parent'
        );
        System.assert(!String.isblank(opsOrderResultChild.ParentOpsOrder__c));
    }

    @isTest
    public static void missingEUDOrdersEmailTest() {
        Map<String, Order_ERP__C> orderMap = TestDataFactory.createMissingEUDOrders(3, false);
        Set<Id> caseIDToEmailSet = new Set<Id>();
        Map<Id, String> eudCaseToOrderMap = new Map<Id, String>();
        System.debug(orderMap);
        insert orderMap.values();
        for (Case c : [SELECT Id, ShadowXometryOrderID__c FROM Case]) {
            caseIDToEmailSet.add(c.Id);
            eudCaseToOrderMap.put(c.Id, c.ShadowXometryOrderID__c);
        }
        Test.startTest();
        // case id to xom order id
        System.enqueueJob(new emailLauncher(caseIDToEmailSet, eudCaseToOrderMap, orderMap.values(), 0 ));
        Test.stopTest();
        List<EmailMessage> emailResults = [SELECT Id FROM EmailMessage];
        System.assertEquals(3, emailResults.size(), 'Should have 3 emails');
    }
 
    @isTest
    public static void missingEUDOrdersEmailRetryTest() {

        Case caseTest = new Case();
        caseTest.ShadowXometryOrderID__c = 'XOM123';
        caseTest.EUD_Work_Stage__C = 'No Reach Out Yet';
        caseTest.EUD_MissingEndUseData__c = TRUE;
        insert caseTest;

        Map<Id, String> eudCaseToOrderMap = new Map<Id, String>();
        eudCaseToOrderMap.put(caseTest.Id, caseTest.ShadowXometryOrderID__c);

        Test.startTest();

        System.enqueueJob(new emailLauncher(eudCaseToOrderMap.keySet(), eudCaseToOrderMap, new List<Order_ERP__C>(), 3 ));

        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM Audit_Trail_Error__c].size(), 'Error log should be created.');
    
    }

    @isTest
    public static void missingEUDOrdersEmailTest_regularAndBulk() {
        // Orders to create is set to 20 because of queueable testing limits
        // testing limits and the current batch size to send set at 20
        Map<String, Order_ERP__C> orderMap = TestDataFactory.createMissingEUDOrders(20, false);
        Set<Id> caseIDToEmailSet = new Set<Id>();
        Map<Id, String> eudCaseToOrderMap = new Map<Id, String>();

        Test.startTest();
        insert orderMap.values();
        Test.stopTest();
        List<EmailMessage> emailResults = [SELECT Id FROM EmailMessage];
        List<Case> caseResults = [SELECT Id, ShadowXometryOrderID__c, EUD_Work_Stage__c FROM Case];
        System.assertEquals(20, emailResults.size(), 'Should have 100 emails');
        System.assertEquals('1st Attempt Sent', caseResults[0].EUD_Work_Stage__c, 'Case should have 1st attempt sent');
    }

    @isTest
    private static void OrderToQuoteCleanUpTest() {
        
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__c = 'Q12-3333-4444';
        insert myQuote;

        Test.startTest();

        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myQuote.Account_Domain__c;
        ord.ERP_Company_Name__C = 'Name';
        ord.ERP_Contact_First_Name__c = 'FirstName';
        ord.ERP_Contact_Last_Name__c = 'LastName';
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myQuote.Quote_Email__c;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-15000';
        ord.Xometry_Quote_ID__c = myQuote.Xometry_ERP_ID__c;
        ord.ERP_Status__c = 'Offer Accepted';
        insert ord;

        Test.stopTest();

        Quote_ERP__C qResult = [SELECT Id, OrderERPSFID__C, OpportunityID__C, OwnerID FROM Quote_ERP__C WHERE Id = :myQuote.Id];
        System.assertEquals(ord.Id, qResult.OrderERPSFID__C, 'OrderERPSFID__C doesnt match with related Order');
    }

}