@isTest
private class ordAggUpdatesTest {
    @isTest
    static void queueableTest() {
        User objUser = [
            SELECT Id
            FROM User
            WHERE
                Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Label = 'Ignore All VR')
                AND IsActive = TRUE
            LIMIT 1
        ];

        ID testAccountID;
        System.runAs(objUser) {
            List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
            Account testAccount = testAccountList[0];
            ID dummyOwnerID = testAccount.ownerID;
            testAccountID = testAccount.ID;
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
            ord1.process_isCarbon__c = true;
            ord1.process_isCNC_Machining__c = true;
            ord1.process_isDie_Casting__c = true;
            ord1.process_isDie_Casting__c = true;
            ord1.process_isDirect_Sourced__c = true;
            ord1.process_isExtrusion__c = true;
            ord1.process_isFDM__c = true;
            ord1.process_isHPMultJetFusion__c = true;
            ord1.process_isInjection_Molding__c = true;
            ord1.process_isPlasticExtrusion__c = true;
            ord1.process_isSLS__c = true;
            ord1.process_isSheet_metal__c = true;
            ord1.process_isSLS__c = true;
            ord1.process_isStamping__c = true;
            ord1.process_isSLA__c = true;
            ord1.process_isUrethane_Casting__c = true;
            ord1.process_isBinderJetting__c = true;
            ord1.process_isSheetCutting__c = true;
            ord1.process_isTubeBending__c = true;
            ord1.process_isTubeCutting__c = true;
            ord1.process_isOther__c = true;
            ord1.process_isOther_NotIncluded__c = true;
            ord1.process_isLSPc__c = true;
            ord1.process_isAssembly__c = true;
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
        }
        List<Order_ERP__C> inOrdersList = [SELECT AccountID__c, ContactID__C, process_isCarbon__c, process_isCNC_Machining__c, 
                                                    process_isDie_Casting__c, process_isDMLS__c, process_isDirect_Sourced__c, 
                                                    process_isExtrusion__c, process_isFDM__c, process_isHPMultJetFusion__c, 
                                                    process_isInjection_Molding__c, process_isPolyJet_3D__c, process_isPlasticExtrusion__c, 
                                                    process_isSLS__c, process_isSheet_metal__c, process_isStamping__c, 
                                                    process_isSLA__c, process_isUrethane_Casting__c, process_isBinderJetting__c, 
                                                    process_isSheetCutting__c, process_isTubeBending__c, process_isTubeCutting__c, 
                                                    process_isOther__c, process_isOther_NotIncluded__c, process_isLSPc__c, process_isAssembly__c
                                            FROM Order_ERP__C];

        Test.startTest();
            ID jobID = System.enqueueJob(new ordAggUpdates(inOrdersList));
        Test.stopTest();

        Account account = [SELECT Lifetime_Spend__c, Number_Orders__c, YTDSpend__c, Rolling_12_Spend__c FROM Account WHERE Id =: testAccountID LIMIT 1];

        assert.areEqual(40000, account.Lifetime_Spend__c);
        assert.areEqual(8, account.Number_Orders__c);
        assert.areEqual(10000, account.YTDSpend__c);
        assert.areEqual(10000, account.Rolling_12_Spend__c);
    }
}