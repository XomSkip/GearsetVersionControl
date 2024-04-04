@IsTest
private class SumarizeDocumentsBatch_Test {

    private static final String TEST_LIBRARY_NAME = 'BatchDocuments128901309';
    private static final User AUTHOR = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    @TestSetup
    private static void setup() {
        ContentWorkspace workspace = new ContentWorkspace();
        workspace.DeveloperName = TEST_LIBRARY_NAME;
        workspace.Name = TEST_LIBRARY_NAME;
        insert workspace;

        ContentWorkspaceMember member
                = [SELECT Id
                   FROM ContentWorkspaceMember
                   WHERE ContentWorkspaceId = :workspace.Id AND MemberId = :AUTHOR.Id];
        member.ContentWorkspacePermissionId
                = [SELECT Id
                   FROM ContentWorkspacePermission
                   WHERE Type = 'Author' LIMIT 1].Id;
        update member;
    }


    @IsTest
    private static void Execute_Test(){

        Case caseToInsert = new Case();
        caseToInsert.Origin = 'Email: Quotes@';
        caseToInsert.Priority = 'High';
        insert caseToInsert;
        
        Case objCase = [Select CaseNumber, CreatedDate FROM Case WHERE Id =: caseToInsert.Id];

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseToInsert.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Hi there, I have a question about </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'sample@test1.com';
        emailTest.ToAddress = 'Quotes@xometry.com';
        insert emailTest;

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Description = 'Test Description';
        contentVersion.Title = 'Silmarillion';
        contentVersion.OwnerId = UserInfo.getUserId();
        contentVersion.VersionData = Blob.valueOf('Test');
        contentVersion.PathOnClient = objCase.CaseNumber +'/' + contentVersion.Title + '.pdf';
        contentVersion.ContentLocation = 'S';
        insert contentVersion;

        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
            LIMIT 1
        ];

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = emailTest.Id,
            ContentDocumentId = contentVersions[0].ContentDocumentId,
            ShareType = 'V'
        );
        insert contentDocumentLink;

        Test.startTest();
            System.runAs(AUTHOR) {
                SumarizeDocumentsBatch b = new SumarizeDocumentsBatch();
                b.libraryName = TEST_LIBRARY_NAME;
                Database.executeBatch(b);
            }
        Test.stopTest();
        List<ContentVersion> createdDocuments 
                = [SELECT Id FROM ContentVersion WHERE Title LIKE 'SumarizeDocumentsBatch%'];
        Assert.areEqual(1, createdDocuments.size(),'Document should be created');

    }

    @isTest(seeAllData=false)
    static void Schedule_Test() {
        String CRON_EXP = '0 0 0 1 1 ? *';

        Test.startTest();
            SumarizeDocumentsBatch b = new SumarizeDocumentsBatch();
            b.libraryName = 'Batch Documents';
            String jobID = System.schedule('SumarizeDocumentsBatchTest', CRON_EXP, b);
        Test.stopTest();

        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}