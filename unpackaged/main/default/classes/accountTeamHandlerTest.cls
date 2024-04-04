@isTest
public class accountTeamHandlerTest {
    @isTest
    static void accountTeamInsertMultiCSAM() {
        //Create an Account. Assign a CSAM and then try to add another CSAM
        //Create some Users
        List<Account_Team__c> aTeamList = new List<Account_Team__c>();
        List<Account> testAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
        Account testAccount = testAccounts[0];
        Account_Team__C aTeam1 = new Account_Team__C();
        aTeam1.Team_Role__c = AppConstants.CSAM_NAME;
        aTeam1.Team_Member__c = testAccount.ownerId;
        aTeam1.Account__c = testAccount.ID;
        aTeamList.add(aTeam1);
        Account testAccount2 = testAccounts[1];
        User testUser2 = TestDataFactory.createTestUserSecond()[0];
        String exceptionMessage;
        //Different User Duplicate CSAM on Account.
        Account_Team__C aTeam2 = new Account_Team__C();
        aTeam2.Team_Role__c = AppConstants.CSAM_NAME;
        aTeam2.Team_Member__c = testUser2.ID;
        aTeam2.Account__c = testAccount.ID;
        aTeamList.add(aTeam2);
        //Different Account that should get through
        Account_Team__C aTeam3 = new Account_Team__C();
        aTeam3.Team_Role__c = AppConstants.CSAM_NAME;
        aTeam3.Team_Member__c = testAccount2.ownerId;
        aTeam3.Account__c = testAccount2.ID;
        aTeamList.add(aTeam3);
        Test.startTest();
        aTeam2.Team_Role__c = AppConstants.CSAM_NAME;
        Database.insert(aTeamList, false);
        Test.stopTest();
        //Confirm that the count is Still 1
        List<AggregateResult> myCount = [
            SELECT count(ID) CSAMCount
            FROM Account_Team__C
            WHERE isDeleted = FALSE AND Team_Role__c = :AppConstants.CSAM_NAME
        ];
        Integer myNum = Integer.valueOf(String.valueOf(myCount[0].get('CSAMCount')));
        System.assertEquals(2, myNum, 'More then 2 CSAM exists on the table');
    }
    @isTest
    static void accountTeamNoDuplicateCheck() {
        List<Account> testAccounts = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 1);
        Account testAccount = testAccounts[0];
        string exceptionMessage;
        Account_Team__C aTeam1 = new Account_Team__C();
        aTeam1.Team_Role__c = AppConstants.TSE_NAME;
        aTeam1.Team_Member__c = testAccount.ownerId;
        aTeam1.Account__c = testAccount.ID;
        insert aTeam1;
        //Try to insert a Duplicate
        Account_Team__C aTeam2 = new Account_Team__C();
        aTeam2.Team_Role__c = AppConstants.TSE_NAME;
        aTeam2.Team_Member__c = testAccount.ownerId;
        aTeam2.Account__c = testAccount.ID;
        try {
            insert aTeam2;
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }
        List<AggregateResult> myCount = [
            SELECT count(ID) ObjCount
            FROM Account_Team__C
            WHERE isDeleted = FALSE AND Account__c = :testAccount.ID
        ];
        //There should only be one record on the object.
        Integer myNum = Integer.valueOf(String.valueOf(myCount[0].get('ObjCount')));
        System.assertEquals(1, myNum, 'More then one Record exists on the account team');
        System.assertEquals(true, !String.isblank(exceptionMessage), 'No exception message returned');
    }

    @isTest
    static void accountTeamNoDuplicateCheckBulk() {
        List<Account> testAccounts = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 1);
        Account testAccount = testAccounts[0];
        string exceptionMessage;
        List<Account_Team__C> aTeamList = new List<Account_Team__C>();
        Account_Team__C aTeam1 = new Account_Team__C();
        aTeam1.Team_Role__c = AppConstants.TSE_NAME;
        aTeam1.Team_Member__c = testAccount.ownerId;
        aTeam1.Account__c = testAccount.ID;
        aTeamList.add(aTeam1);
        //Try to insert a Duplicate
        User testUser2 = TestDataFactory.createTestUserSecond()[0];
        Account_Team__C aTeam2 = new Account_Team__C();
        aTeam2.Team_Role__c = AppConstants.TSE_NAME;
        aTeam2.Team_Member__c = testAccount.ownerId;
        aTeam2.Account__c = testAccount.ID;
        aTeamList.add(aTeam2);
        Database.insert(aTeamList, false);
        List<AggregateResult> myCount = [
            SELECT count(ID) ObjCount
            FROM Account_Team__C
            WHERE isDeleted = FALSE AND Account__c = :testAccount.ID
        ];

        //There should only be one record on the object.
        Integer myNum = Integer.valueOf(String.valueOf(myCount[0].get('ObjCount')));
        System.assertEquals(1, myNum, 'More then one Record exists on the account team');
        //System.assertEquals(true, !String.isblank(exceptionMessage), 'No exception message returned');
    }
    @isTest
    static void accountTeamHandlerTest() {
        //Create an Account. Assign a CSAM and then try to add another CSAM
        //Create some Users
        List<Account> testAccounts = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 1);
        Account testAccount = testAccounts[0];
        Account_Team__C aTeam1 = new Account_Team__C();
        aTeam1.Team_Role__c = AppConstants.CSAM_NAME;
        aTeam1.Team_Member__c = testAccount.ownerId;
        aTeam1.Account__c = testAccount.ID;
        insert aTeam1;
        List<AggregateResult> myCountPre = [
            SELECT count(ID) CSAMCount
            FROM Account_Team__C
            WHERE Account__c = :testAccount.ID
        ];
        // No filters
        Integer myNumPre = Integer.valueOf(String.valueOf(myCountPre[0].get('CSAMCount')));
        system.debug('My pre second test value is :' + myNumPre);
        User testUser2 = TestDataFactory.createTestUserSecond()[0];
        String exceptionMessage;
        Test.startTest();
        Account_Team__C aTeam2 = new Account_Team__C();
        aTeam2.Team_Role__c = AppConstants.CSAM_NAME;
        aTeam2.Team_Member__c = testUser2.ID;
        aTeam2.Account__c = testAccount.ID;
        try {
            insert aTeam2;
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        //Confirm that the count is Still 1
        List<AggregateResult> myCount = [
            SELECT count(ID) CSAMCount
            FROM Account_Team__C
            WHERE isDeleted = FALSE AND Account__c = :testAccount.ID AND Team_Role__c = :AppConstants.CSAM_NAME
        ];

        Integer myNum = Integer.valueOf(String.valueOf(myCount[0].get('CSAMCount')));
        System.assertEquals(1, myNum, 'More then one CSAM exists on the account');
        System.assertEquals(true, !String.isblank(exceptionMessage), 'No exception message returned');
    }
    @isTest
    static void updateAccountTeamHandlerTest() {
        //Create an Account. Assign a CSAM and then try to add another CSAM
        //Create some Users
        List<Account> testAccounts = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 1);
        Account testAccount = testAccounts[0];
        Account_Team__C aTeam1 = new Account_Team__C();
        aTeam1.Team_Role__c = AppConstants.CSAM_NAME;
        aTeam1.Team_Member__c = testAccount.ownerId;
        aTeam1.Account__c = testAccount.ID;
        insert aTeam1;
        User testUser2 = TestDataFactory.createTestUserSecond()[0];
        String exceptionMessage;
        Account_Team__C aTeam2 = new Account_Team__C();
        aTeam2.Team_Role__c = AppConstants.PSE_NAME;
        aTeam2.Team_Member__c = testUser2.ID;
        aTeam2.Account__c = testAccount.ID;
        insert aTeam2;
        Test.startTest();
        aTeam2.Team_Role__c = AppConstants.CSAM_NAME;
        try {
            update aTeam2;
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();
        //Confirm that the count is Still 1
        List<AggregateResult> myCount = [
            SELECT count(ID) CSAMCount
            FROM Account_Team__C
            WHERE isDeleted = FALSE AND Account__c = :testAccount.ID AND Team_Role__c = :AppConstants.CSAM_NAME
        ];

        Integer myNum = Integer.valueOf(String.valueOf(myCount[0].get('CSAMCount')));
        System.assertEquals(1, myNum, 'More then one CSAM exists on the account');
        System.assertEquals(true, !String.isblank(exceptionMessage), 'No exception message returned');
    }
}