@isTest(seeAllData=true)
private class SplitCaseControllerTest {
    @isTest
    private static void moveFilesTest() {
        createData();
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'TestCase' LIMIT 1];
        List<NEILON__File__c> fileList;
        String returnStr;
        Test.startTest();
        fileList = SplitCaseController.getFiles(testCase.Id);
        returnStr = SplitCaseController.moveFiles(testCase.Id, fileList, null, null, 'High', 'Test');
        Test.stopTest();
        System.assertNotEquals(null, fileList, 'fileList should not be null');
        System.assertNotEquals(null, returnStr, 'returnStr should not be null');
    }

    @isTest
    private static void cloneFilesTest() {
        createData();
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'TestCase' LIMIT 1];
        List<NEILON__File__c> fileList;
        String returnStr;
        Test.startTest();
        fileList = SplitCaseController.getFiles(testCase.Id);
        returnStr = SplitCaseController.cloneFiles(testCase.Id, fileList, null, null, 'High', 'Test');
        Test.stopTest();
        System.assertNotEquals(null, fileList, 'fileList should not be null');
        System.assertNotEquals(null, returnStr, 'returnStr should not be null');
    }

    @isTest
    private static void splitCaseWithoutFilesTest() {
        createData();
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'TestCase' LIMIT 1];
        String returnStr;
        Test.startTest();
        returnStr = SplitCaseController.splitCaseWithoutFiles(testCase.Id, null, null, 'High', 'Test');
        Test.stopTest();
        System.assertNotEquals(null, returnStr, 'returnStr should not be null');
    }

    private static void createData() {
        Case testCase = new Case(Status = 'New', Priority = 'Medium', Origin = 'Web', Subject = 'TestCase');
        insert testCase;
        NEILON__Folder__c testBucket = new NEILON__Folder__c(Name = 'testbucket');
        insert testBucket;
        NEILON__Folder__c testFolder = NEILON.apGlobalUtils.buildFolderArchitecture(testCase.Id);
        NEILON__File__c file = new NEILON__File__c(NEILON__Description__c = 'Test Description');
        NEILON__File__c testFile = NEILON.apGlobalUtils.createS3File(
            Blob.valueOf('Test'),
            'test.txt',
            file,
            testBucket.Name +
            '/Cases/' +
            testCase.Id +
            '/test.txt'
        );
        Group testGroup = new Group(Name = 'Test', Type = 'Queue');
        insert testGroup;
    }
}