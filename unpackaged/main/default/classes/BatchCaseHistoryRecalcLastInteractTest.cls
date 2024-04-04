@isTest
private class BatchCaseHistoryRecalcLastInteractTest {

    @isTest(seeAllData=false)
    static void testMethod1() {

        User testUser2 = TestDataFactory.createTestUserSecond()[0];

        Opportunity testOpp = new Opportunity(Name = 'Test', CloseDate = Date.today(), StageName = 'Open');
        insert testOpp;
        
        Case testCase = new Case(SuppliedEmail = 'test@test.com', Opportunity__c = testOpp.Id);
        testCase.RecordTypeId = AppConstants.casePSERecordTypeId;
        insert testCase;

        Group objQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' LIMIT 1];

        testCase.OwnerId = testUser2.Id;
        update testCase;

        List<CaseHistory__c> lstCaseHistry = [
            SELECT Id, OldOwnerText__c, NewOwnerText__c, OldUserOwner__c, NewUserOwner__c, DurationMinutes__c
            FROM CaseHistory__c
            ORDER BY Id DESC
        ];

        System.assertEquals( 1, lstCaseHistry.size() );

        Test.setCreatedDate(lstCaseHistry[0].Id, Datetime.now().addDays(-10));

        testCase.Status = 'In Progress';
        update testCase;

        lstCaseHistry = [
            SELECT Id, OldOwnerText__c, NewOwnerText__c, OldUserOwner__c, NewUserOwner__c, DurationMinutes__c
            FROM CaseHistory__c
            ORDER BY Id DESC
        ];

        testCase.OwnerId = UserInfo.getUserId();
        update testCase;

        lstCaseHistry = [
            SELECT Id, OldOwnerText__c, NewOwnerText__c, OldUserOwner__c, NewUserOwner__c, DurationMinutes__c
            FROM CaseHistory__c
            ORDER BY Id DESC
        ];

        lstCaseHistry[0].DurationMinutes__c = 0;
        update lstCaseHistry[0];

        test.StartTest();

        Database.executeBatch( new BatchCaseHistoryRecalcLastInteraction() );

        test.StopTest();

        lstCaseHistry = [
            SELECT Id, OldOwnerText__c, NewOwnerText__c, OldUserOwner__c, NewUserOwner__c, DurationMinutes__c
            FROM CaseHistory__c
            ORDER BY Id DESC
        ];

        System.assertNotEquals(
            0,
            lstCaseHistry[0].DurationMinutes__c,
            'The Duration of CaseHistory record was not populated'
        );

    }
}