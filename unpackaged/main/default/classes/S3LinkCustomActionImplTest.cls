/* **************************************************************************
* Copyright © 2015-2021, Neilon Technologies LLP
* All rights reserved
*
* Controller Class: S3LinkCustomActionImplTest
* Created by Suresh Meghnathi: 22/04/2021
*
* - Test class for S3LinkCustomActionImpl.

* - Modifications:
* - Suresh Meghnathi, 22/04/2021 – Initial Development
************************************************************************** */
@isTest
private class S3LinkCustomActionImplTest {
    @TestSetup
    static void createTestData() {
        NEILON__Folder__c bucket = s3LinkTestUtils.createFoldersForBucket('Test_Bucket1');
    }

    static testMethod void testExcute() {
        Account testAccount = s3LinkTestUtils.createAccount();
        Case testCase = new Case(AccountId = testAccount.Id);
        insert testCase;
        NEILON__Folder__c folder = NEILON.apGlobalUtils.buildFolderArchitecture(testCase.Id);
        List<NEILON__File__c> files = s3LinkTestUtils.createFiles(folder);
        S3LinkCustomActionImpl controller = new S3LinkCustomActionImpl();
        String fileId = files[0].Id;
        controller.execute('add_to_account', new List<String>{ fileId }, testCase.Id, null);
        List<NEILON__File__c> accountFiles = [
            SELECT Id
            FROM NEILON__File__c
            WHERE NEILON__Account__c = :testAccount.Id AND Name = :files[0].Name
        ];
        System.assertEquals(accountFiles.size(), 1);
    }

    static testMethod void testExcuteWithoutAccount() {
        Case testCase = new Case();
        insert testCase;
        NEILON__Folder__c folder = NEILON.apGlobalUtils.buildFolderArchitecture(testCase.Id);
        List<NEILON__File__c> files = s3LinkTestUtils.createFiles(folder);
        S3LinkCustomActionImpl controller = new S3LinkCustomActionImpl();
        String fileId = files[0].Id;
        String jsonString = controller.execute('add_to_account', new List<String>{ fileId }, testCase.Id, null);
        S3LinkCustomActionImpl.CustomActionResponse response = (S3LinkCustomActionImpl.CustomActionResponse) JSON.deserialize(
            jsonString,
            S3LinkCustomActionImpl.CustomActionResponse.class
        );
        System.assertEquals(response.message, 'No account available for this case');
    }

    static testMethod void testExcuteWithoutCase() {
        S3LinkCustomActionImpl controller = new S3LinkCustomActionImpl();
        String jsonString = controller.execute('add_to_account', null, 'invalid', null);
        S3LinkCustomActionImpl.CustomActionResponse response = (S3LinkCustomActionImpl.CustomActionResponse) JSON.deserialize(
            jsonString,
            S3LinkCustomActionImpl.CustomActionResponse.class
        );
        System.assertEquals(response.message, 'We cannot find the case. Please contact support team');
    }
}