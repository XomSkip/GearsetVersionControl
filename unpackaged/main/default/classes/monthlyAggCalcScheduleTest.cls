@isTest
public class monthlyAggCalcScheduleTest {
    @isTest
    static void monthlyTest1() {
        System.debug('Starting the schedule test');

        User objUser = [
            SELECT Id
            FROM User
            WHERE
                Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Label = 'Ignore All VR')
                AND IsActive = TRUE
            LIMIT 1
        ];

        System.runAs(objUser) {
            //Integer
            List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
            Account testAccount = testAccountList[0];
            ID testAccountID = testAccount.ID;
            //
            List<Order_ERP__C> newOrdersList = new List<Order_ERP__C>();
            Contact myretContact = [
                SELECT ID, FirstName, LastName, Email
                FROM Contact
                WHERE AccountID = :testAccountID
                ORDER BY Name
            ];
            ID myretContactID = myretContact.ID;
            List<Order_ERP__C> insertOrdersList = new List<Order_ERP__C>();
            Date myDate = Date.today();
            Datetime myDateTime = Datetime.now();

            //Different Name Should Create new Opportunity on Existing BDR Account
            Order_ERP__C ord = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0000',
                'BBBBB-34567',
                '56564-55667',
                testAccount,
                myretContact,
                myDate,
                myDateTime
            );
            insertOrdersList.add(ord);

            //Different Name Should Create new Opportunity on Existing BDR Account
            Order_ERP__C ord1 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0001',
                'BBBBB-34568',
                '56564-55668',
                testAccount,
                myretContact,
                myDate,
                myDateTime
            );
            insertOrdersList.add(ord1);

            //Different Name Should Create new Opportunity on Existing BDR Account
            Order_ERP__C ord2 = TestDataFactory.createOrderERPFromAccContact(
                false,
                'Q00-0000-0002',
                'BBBBB-34569',
                '56564-55669',
                testAccount,
                myretContact,
                myDate,
                myDateTime
            );
            insertOrdersList.add(ord2);
            insert insertOrdersList;

            ord2.Order_Canceled_Flag__c = true;
            List<Opportunity> myOpps = [
                SELECT Id, Stagename, Amount, AccountID
                FROM Opportunity
                WHERE AccountID = :testAccountID
            ];
            Opportunity myOpp = myOpps[0];
            myOpp.Stagename = 'Closed Lost';
            myOpp.Loss_Reason__c = 'Order Cancelled';
            update myOpp;
            Account resAcct = [SELECT ID, YTDSpend__c FROM Account WHERE ID = :testAccountID];
            System.debug('The initial YTDSpend__C is: ' + resAcct.YTDSpend__c);
            // Dummy CRON expression: midnight on March 15.
            // Because this is a test, job executes
            // immediately after test stop test
            String CRON_EXP = '0 0 0 1 1 ? *';
            Test.startTest();
            System.debug('Here are the opportunities and their stages');
            myOpps = [SELECT Id, Stagename, Amount, AccountID FROM Opportunity WHERE AccountID = :testAccountID];
            for (Opportunity o : myOpps) {
                system.debug(o);
            }
            String jobID = System.schedule('MonthlyAggCalcSchedTest', CRON_EXP, new monthlyAggCalcSchedule());
            Test.stopTest();
            //Test Jobs Fire after job is run
            resAcct = [SELECT ID, YTDSpend__c FROM Account WHERE ID = :testAccountID];
            Decimal expRes = 10000.00;
            Decimal myamount = resAcct.YTDSpend__c;
            System.assertequals(expRes, myamount, 'The amounts are not equal');
        }

    }
}