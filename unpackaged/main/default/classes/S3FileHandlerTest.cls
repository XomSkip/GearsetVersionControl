@isTest
private class S3FileHandlerTest {
    @TestSetup
    static void createTestData() {
        NEILON__Folder__c bucket = s3LinkTestUtils.createFoldersForBucket('Test_Bucket1');
        s3LinkTestUtils.createContentDocument('Test Chatter Attachment Small');
    }

    @isTest
    private static void testHandleError() {
        DmlException e = new DmlException();
        e.setMessage('test');
        Test.startTest();
        S3FileHandler.handleError(e);
        Test.stopTest();
    }

    @isTest
    private static void testAfterInsertChatterPost() {
        NEILON__File_Export_Configuration__c fileExportConfig = new NEILON__File_Export_Configuration__c(
            Name = 'File Export Configuration'
        );
        fileExportConfig.NEILON__Auto_Create_S3_Link_File_for_Attachment__c = true;
        fileExportConfig.NEILON__Objects_to_Export_Salesforce_Attachments__c = '500';
        fileExportConfig.NEILON__Delete_Salesforce_Attachment__c = true;
        insert fileExportConfig;
        Case testCase = s3LinkTestUtils.createCase();
        testCase.Zendesk_File_Timestamp__c = 'Test Chatter Attachment Small.pdf~2021-05-04T15:51:35.000000+00:00;';
        update testCase;
        ContentVersion contentVersion1 = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Title = 'Test Chatter Attachment Small'
            LIMIT 1
        ];
        Test.startTest();
        FeedItem feedItem = new FeedItem(ParentId = testCase.Id, RelatedRecordId = contentVersion1.Id);
        insert feedItem;
        List<FeedAttachment> allFeedAttachments = [
            SELECT Id, Type, Value, Title, RecordId, FeedEntityId
            FROM FeedAttachment
            WHERE FeedEntityId = :feedItem.Id
        ];
        FeedComment feedComment = new FeedComment(FeedItemId = feedItem.Id, RelatedRecordId = contentVersion1.Id);
        insert feedComment;
        Test.stopTest();
        List<ContentDocument> contentDocuments = [
            SELECT Id
            FROM ContentDocument
            WHERE Id = :contentVersion1.ContentDocumentId
        ];
        System.assertEquals(contentDocuments.size(), 1);
    }

    @isTest
    private static void testAfterInsertEmailPost() {
        NEILON__File_Export_Configuration__c fileExportConfig = new NEILON__File_Export_Configuration__c(
            Name = 'File Export Configuration'
        );
        fileExportConfig.NEILON__Auto_Create_S3_Link_File_for_Attachment__c = true;
        fileExportConfig.NEILON__Objects_to_Export_Email_Attachments__c = '500';
        fileExportConfig.NEILON__Show_Email_Attachments_in_S3_Files_List__c = true;
        fileExportConfig.NEILON__Link_Email_Attachments_to_Email_Parent__c = true;
        fileExportConfig.NEILON__Delete_Salesforce_Attachment__c = true;
        insert fileExportConfig;
        Case testCase = s3LinkTestUtils.createCase();
        testCase.Zendesk_File_Timestamp__c = 'Test Chatter Attachment Small.pdf~2021-05-04T15:51:35.000000+00:00;';
        update testCase;
        ContentVersion contentVersion1 = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Title = 'Test Chatter Attachment Small'
            LIMIT 1
        ];
        Test.startTest();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType emailMessageObjectType = gd.get('EmailMessage');
        SObject emailMessage = emailMessageObjectType.newSObject();
        emailMessage.put('FromAddress', 'test@abc.org');
        emailMessage.put('Incoming', true);
        emailMessage.put('ToAddress', 'hello@test.case.salesforce.com');
        emailMessage.put('Subject', 'Test Email');
        emailMessage.put('TextBody', 'Test Body');
        emailMessage.put('ParentId', testCase.Id);
        insert emailMessage;
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = emailMessage.Id,
            ContentDocumentId = contentVersion1.ContentDocumentId,
            ShareType = 'V'
        );
        insert contentDocumentLink;
        Test.stopTest();
        List<NEILON__File__c> fileList = new List<NEILON__File__c>(
            [SELECT Id, File_Created_Date__c FROM NEILON__File__c]
        );
        System.assertNotEquals(0, fileList.size(), 'File should exist');
        System.assertNotEquals(null, fileList[0].File_Created_Date__c, 'File Created Date should be populated');
    }
}