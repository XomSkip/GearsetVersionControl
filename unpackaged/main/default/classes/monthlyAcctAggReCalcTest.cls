@isTest
private class monthlyAcctAggReCalcTest {
    @isTest
    static void batchAcctAggUpdateMainTest() {
        User objUser = [
            SELECT Id
            FROM User
            WHERE
                Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Label = 'Ignore All VR')
                AND IsActive = TRUE
            LIMIT 1
        ];

        System.runAs(objUser) {
            List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
            Account testAccount = testAccountList[0];
            ID dummyOwnerID = testAccount.ownerID;
            ID testAccountID = testAccount.ID;
            List<Order_ERP__C> newOrdersList = new List<Order_ERP__C>();
            Contact myretContact = [
                SELECT ID, FirstName, LastName, Email
                FROM Contact
                WHERE AccountID = :testAccountID
                ORDER BY Name
            ];
            ID myretContactID = myretContact.ID;
            List<Order_ERP__C> insertOrdersList = new List<Order_ERP__C>();
            Date thisYear = Date.today();
            Date lastYear = Date.today().addYears(-1);
            Date yearBeforeLast = Date.today().addYears(-2);
            Datetime thisYearDatetime = Datetime.now();
            Datetime lastYearDatetime = Datetime.now().addYears(-1);
            Datetime yearBeforeLastDatetime = Datetime.now().addYears(-2);
            // this year
            Order_ERP__C ord = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0000',
                'BBBBB-34567',
                '56564-55667',
                testAccount,
                myretContact,
                thisYear,
                thisYearDatetime
            );
            insertOrdersList.add(ord);

            Order_ERP__C ord1 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0001',
                'BBBBB-34568',
                '56564-55668',
                testAccount,
                myretContact,
                thisYear,
                thisYearDatetime
            );
            insertOrdersList.add(ord1);

            Order_ERP__C ord2 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0002',
                'BBBBB-34569',
                '56564-55669',
                testAccount,
                myretContact,
                thisYear,
                thisYearDatetime
            );
            insertOrdersList.add(ord2);

            // Last year
            Order_ERP__C ord3 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0003',
                'BBBBB-34570',
                '56564-55670',
                testAccount,
                myretContact,
                lastYear,
                lastYearDatetime
            );
            insertOrdersList.add(ord3);

            Order_ERP__C ord4 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0004',
                'BBBBB-34571',
                '56564-55671',
                testAccount,
                myretContact,
                lastYear,
                lastYearDatetime
            );
            insertOrdersList.add(ord4);

            Order_ERP__C ord5 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0005',
                'BBBBB-34572',
                '56564-55672',
                testAccount,
                myretContact,
                lastYear,
                lastYearDatetime
            );
            insertOrdersList.add(ord5);

            // Year before Last
            Order_ERP__C ord6 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0006',
                'BBBBB-34573',
                '56564-55673',
                testAccount,
                myretContact,
                yearBeforeLast,
                yearBeforeLastDatetime
            );
            insertOrdersList.add(ord6);

            Order_ERP__C ord7 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0007',
                'BBBBB-34574',
                '56564-55674',
                testAccount,
                myretContact,
                yearBeforeLast,
                yearBeforeLastDatetime
            );
            insertOrdersList.add(ord7);

            Order_ERP__C ord8 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0008',
                'BBBBB-34575',
                '56564-55675',
                testAccount,
                myretContact,
                yearBeforeLast,
                yearBeforeLastDatetime
            );
            insertOrdersList.add(ord8);
            insert insertOrdersList;

            ord2.Order_Canceled_Flag__c = true;

            // Account resAcct = [SELECT ID, YTDSpend__c FROM Account WHERE ID = :testAccountID];
            // System.debug('The initial YTDSpend__C is: ' + resAcct.YTDSpend__c);

            List<Opportunity> myOpps = new List<Opportunity>();
            List<Opportunity> lstOpp = new List<Opportunity>();

            for (Opportunity opp : [
                SELECT Id, Stagename, Amount, AccountId, CloseDate, RecordTypeId
                FROM Opportunity
                WHERE AccountID = :testAccountID
            ]) {
                if (opp.AccountID == testAccountID) {
                    myOpps.add(opp);
                }
            }

            ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get('Manufacturing_Services')
                .getRecordTypeID();

            Opportunity myOpp = myOpps[0];
            myOpp.RecordTypeId = oppManufacturingServRTypeID;
            myOpp.Stagename = 'Closed Lost';
            myOpp.Loss_Reason__c = 'Order Cancelled';

            lstOpp.add(myOpp);

            update lstOpp;
            System.debug('**CM** lstOpp ' + lstOpp);
        }
        Account noOrderTestAccount = new Account();
        ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Customer')
            .getRecordTypeID();
        noOrderTestAccount.name = 'EmptyShell';
        noOrderTestAccount.ownerID = [SELECT OwnerId FROM Account LIMIT 1].OwnerId;
        noOrderTestAccount.recordTypeID = accountCustomerRecordTypeID;
        noOrderTestAccount.Generic_Account__c = false;
        noOrderTestAccount.Account_Owner_Type__c = 'AM';
        noOrderTestAccount.Email_Domain__c = 'noOrderTest.com';

        Test.startTest();
        insert noOrderTestAccount;
        monthlyAcctAggReCalc batch = new monthlyAcctAggReCalc();
        Database.executeBatch(batch);
        Test.stopTest();
        List<Account> accounts = [
            SELECT
                ID,
                Name,
                YTDSpend__c,
                Lifetime_Spend__c,
                Number_Orders__c,
                Number_Contacts__c,
                This_Year_Account_Spend__c,
                Last_Year_Account_Spend__c,
                Year_Before_Last_Account_Spend__c
            FROM Account
        ];
        Account resAcct = accounts[0];
        System.assertequals(10000, resAcct.YTDSpend__c, 'YTDSpend__c is not correct');
        System.assertequals(40000, resAcct.Lifetime_Spend__c, 'Lifetime_Spend__c is not correct');
        System.assertequals(8, resAcct.Number_Orders__c, 'Number_Orders__c is not correct');
        System.assertequals(1, resAcct.Number_Contacts__c, 'Number_Contacts__c is not correct');
        System.assertequals(10000, resAcct.This_Year_Account_Spend__c, 'This_Year_Account_Spend__c is not correct');
        System.assertequals(15000, resAcct.Last_Year_Account_Spend__c, 'Last_Year_Account_Spend__c is not correct');
        System.assertequals(
            15000,
            resAcct.Year_Before_Last_Account_Spend__c,
            'Year_Before_Last_Account_Spend__c is not correct'
        );
        for (account a : accounts) {
            if (a.Name == 'EmptyShell') {
                System.assertequals(0, a.YTDSpend__C, 'FYTD for empty account was not 0!');
            }
        }
    }

    @isTest
    static void batchAcctAggUpdateMainTest_Supplies() {
        User objUser = [
            SELECT Id
            FROM User
            WHERE
                Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Label = 'Ignore All VR')
                AND IsActive = TRUE
            LIMIT 1
        ];
        System.runAs(objUser) {
            List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
            Account testAccount = testAccountList[0];
            ID dummyOwnerID = testAccount.ownerID;
            ID testAccountID = testAccount.ID;
            Contact myretContact = [
                SELECT ID, FirstName, LastName, Email
                FROM Contact
                WHERE AccountID = :testAccountID
                ORDER BY Name
            ];
            ID myretContactID = myretContact.ID;
            List<Order_ERP__C> insertOrdersList = new List<Order_ERP__C>();
            Date thisYear = Date.today();
            Date lastYear = Date.today().addYears(-1);
            Date yearBeforeLast = Date.today().addYears(-2);
            Datetime thisYearDatetime = Datetime.now();
            Datetime lastYearDatetime = Datetime.now().addYears(-1);
            Datetime yearBeforeLastDatetime = Datetime.now().addYears(-2);
            // this year

            // Account resAcct = [SELECT ID, YTDSpend__c FROM Account WHERE ID = :testAccountID];
            // System.debug('The initial YTDSpend__C is: ' + resAcct.YTDSpend__c);

            ID oppSupplierRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get('Supplies')
                .getRecordTypeID();

            List<Supplies_Quote__C> lstSuppliesQuote = new List<Supplies_Quote__C>();
            Supplies_Quote__C sQuoteTest = TestDataFactory.createSuppliesQuote(
                false,
                myretContact.Email,
                testAccount.Email_Domain__c,
                myretContact.FirstName,
                myretContact.LastName,
                thisYear,
                thisYearDateTime
            );
            Supplies_Quote__C sQuoteTest2 = TestDataFactory.createSuppliesQuote(
                false,
                myretContact.Email,
                testAccount.Email_Domain__c,
                myretContact.FirstName,
                myretContact.LastName,
                thisYear,
                thisYearDateTime
            );
            sQuoteTest2.P21_ERP_ID__c = 'OE23478';
            Supplies_Quote__C sQuoteTest3 = TestDataFactory.createSuppliesQuote(
                false,
                myretContact.Email,
                testAccount.Email_Domain__c,
                myretContact.FirstName,
                myretContact.LastName,
                lastYear,
                lastYearDateTime
            );
            sQuoteTest3.P21_ERP_ID__c = 'OE23479';
            Supplies_Quote__C sQuoteTest4 = TestDataFactory.createSuppliesQuote(
                false,
                myretContact.Email,
                testAccount.Email_Domain__c,
                myretContact.FirstName,
                myretContact.LastName,
                lastYear,
                lastYearDateTime
            );
            sQuoteTest4.P21_ERP_ID__c = 'OE23480';
            Supplies_Quote__C sQuoteTest5 = TestDataFactory.createSuppliesQuote(
                false,
                myretContact.Email,
                testAccount.Email_Domain__c,
                myretContact.FirstName,
                myretContact.LastName,
                yearBeforeLast,
                yearBeforeLastDateTime
            );
            sQuoteTest5.P21_ERP_ID__c = 'OE23481';
            Supplies_Quote__C sQuoteTest6 = TestDataFactory.createSuppliesQuote(
                false,
                myretContact.Email,
                testAccount.Email_Domain__c,
                myretContact.FirstName,
                myretContact.LastName,
                yearBeforeLast,
                yearBeforeLastDateTime
            );
            sQuoteTest6.P21_ERP_ID__c = 'OE23482';

            lstSuppliesQuote.add(sQuoteTest);
            lstSuppliesQuote.add(sQuoteTest2);
            lstSuppliesQuote.add(sQuoteTest3);
            lstSuppliesQuote.add(sQuoteTest4);
            lstSuppliesQuote.add(sQuoteTest5);
            lstSuppliesQuote.add(sQuoteTest6);
            insert lstSuppliesQuote;

            List<Opportunity> myOpps = new List<Opportunity>();
            List<Opportunity> lstOpp = new List<Opportunity>();

            for (Opportunity opp : [
                SELECT Id, Stagename, Amount, AccountId, CloseDate, RecordTypeId
                FROM Opportunity
                WHERE RecordTypeId = :oppSupplierRTypeID OR AccountID = :testAccountID
            ]) {
                if (opp.RecordTypeId == oppSupplierRTypeID) {
                    lstOpp.add(opp);
                }

                if (opp.AccountID == testAccountID) {
                    myOpps.add(opp);
                }
            }

            lstOpp[0].StageName = 'Closed Won';
            lstOpp[0].CloseDate = System.today();
            lstOpp[1].StageName = 'Closed Lost';
            lstOpp[1].CloseDate = System.today();
            lstOpp[2].StageName = 'Closed Won';
            lstOpp[2].CloseDate = System.today().addYears(-1);
            lstOpp[3].StageName = 'Closed Lost';
            lstOpp[3].CloseDate = System.today().addYears(-1);
            lstOpp[4].StageName = 'Closed Won';
            lstOpp[4].CloseDate = System.today().addYears(-2);
            lstOpp[5].StageName = 'Closed Won';
            lstOpp[5].CloseDate = System.today().addYears(-2);

            update lstOpp;
            System.debug('**CM** lstOpp ' + lstOpp);
        }

        Test.startTest();
        monthlyAcctAggReCalc batch = new monthlyAcctAggReCalc();
        Database.executeBatch(batch);
        Test.stopTest();
        List<Account> accounts = [
            SELECT
                ID,
                Sup_Lifetime_Spend__c,
                Sup_This_Year_Account_Spend__c,
                Sup_Last_Year_Account_Spend__c,
                Sup_Year_Before_Last_Account_Spend__c
            FROM Account
        ];
        Account resAcct = accounts[0];
        System.assertequals(2000, resAcct.Sup_Lifetime_Spend__c, 'Sup_Lifetime_Spend__c is not correct');
        System.assertequals(
            500,
            resAcct.Sup_This_Year_Account_Spend__c,
            'Sup_This_Year_Account_Spend__c is not correct'
        );
        System.assertequals(
            500,
            resAcct.Sup_Last_Year_Account_Spend__c,
            'Sup_Last_Year_Account_Spend__c is not correct'
        );
        System.assertequals(
            1000,
            resAcct.Sup_Year_Before_Last_Account_Spend__c,
            'Sup_Year_Before_Last_Account_Spend__c is not correct'
        );
    }
}