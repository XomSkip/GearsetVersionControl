/* **************************************************************************
* Copyright © 2015-2020, Neilon Technologies LLP
* All rights reserved
*
* Controller Class: s3LinkTestUtils
* Created by Anil Meghnathi: 05/10/2020
*
* - Used to create the test data.

* - Modifications:
* - Anil Meghnathi, 05/10/2020 – Initial Development
************************************************************************** */
@isTest
public without sharing class s3LinkTestUtils {
    public static NEILON__Folder__c createFoldersForBucket(String name) {
        NEILON__Folder__c bucket = new NEILON__Folder__c(Name = name);
        bucket.NEILON__Parent__c = null;
        bucket.NEILON__Active__c = true;
        bucket.NEILON__Default__c = true;
        bucket.NEILON__File_Versioning__c = true;
        insert bucket;
        return bucket;
    }

    public static List<NEILON__File__c> createFiles(NEILON__Folder__c folder) {
        List<NEILON__File__c> files = new List<NEILON__File__c>();
        NEILON__File__c file1 = new NEILON__File__c(Name = 'File1.png');
        file1.NEILON__Folder__c = folder.Id;
        file1.NEILON__Bucket_Name__c = 'Test_Bucket1';
        file1.NEILON__Extension__c = '.png';
        file1.NEILON__Size__c = 5000;
        file1.NEILON__Content_Type__c = 'image/png';
        file1.NEILON__Track_Download_History__c = true;
        files.add(file1);
        NEILON__File__c file2 = new NEILON__File__c(Name = 'File2.png');
        file2.NEILON__Folder__c = folder.Id;
        file2.NEILON__Bucket_Name__c = 'Test_Bucket1';
        file2.NEILON__Extension__c = '.jpg';
        file2.NEILON__Size__c = 5001;
        file2.NEILON__Content_Type__c = 'image/jpg';
        files.add(file2);
        NEILON__File__c file3 = new NEILON__File__c(Name = 'File3.png');
        file3.NEILON__Folder__c = folder.Id;
        file3.NEILON__Bucket_Name__c = 'Test_Bucket1';
        file3.NEILON__Extension__c = '.pdf';
        file3.NEILON__Size__c = 5000;
        file3.NEILON__Content_Type__c = 'image/pdf';
        files.add(file3);
        insert files;
        return files;
    }

    public static List<NEILON__Folder__c> createSubfolders(NEILON__Folder__c parentFolder) {
        List<NEILON__Folder__c> subFolders = new List<NEILON__Folder__c>();
        NEILON__Folder__c sub1 = new NEILON__Folder__c(Name = parentFolder.Name + '_Sub_Folder1');
        sub1.NEILON__Bucket_Name__c = parentFolder.NEILON__Bucket_Name__c;
        sub1.NEILON__Parent__c = parentFolder.Id;
        subFolders.add(sub1);
        NEILON__Folder__c sub2 = new NEILON__Folder__c(Name = parentFolder.Name + '_Sub_Folder2');
        sub2.NEILON__Bucket_Name__c = parentFolder.NEILON__Bucket_Name__c;
        sub2.NEILON__Parent__c = parentFolder.Id;
        subFolders.add(sub2);
        insert subFolders;
        return subFolders;
    }

    public static ContentDocument createContentDocument(String title) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Description = 'Test Description';
        contentVersion.Title = title;
        contentVersion.OwnerId = UserInfo.getUserId();
        contentVersion.VersionData = Blob.valueOf(title);
        contentVersion.PathOnClient = 'Bucket 1/' + contentVersion.Title + '.pdf';
        contentVersion.ContentLocation = 'S';
        insert contentVersion;
        return [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];
    }

    public static ContentDocumentLink createContentDocument(String title, Id linkedEntityId) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Description = 'Test Description';
        contentVersion.Title = title;
        contentVersion.OwnerId = UserInfo.getUserId();
        contentVersion.VersionData = Blob.valueOf('TestData');
        contentVersion.PathOnClient = 'Bucket 1/' + contentVersion.Title + '.pdf';
        contentVersion.ContentLocation = 'S';
        insert contentVersion;
        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
            LIMIT 1
        ];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = linkedEntityId,
            ContentDocumentId = contentVersions[0].ContentDocumentId,
            ShareType = 'V'
        );
        insert contentDocumentLink;
        return contentDocumentLink;
    }

    public static Account createAccount() {
        Account testAccount = new Account(name = 'Test Account');
        insert testAccount;
        return testAccount;
    }

    public static Case createCase() {
        Case testCase = new Case();
        insert testCase;
        return testCase;
    }
}