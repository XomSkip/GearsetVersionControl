public class S3FileHandler {
    /**
     * @description if s3 file related to case and case field Zendesk_File_Timestamp__c contains delimiter,
     * attempt to parse file created date from Zendesk_File_Timestamp__c
     * @param newFileList new s3 files
     */
    public static void populateCreatedDate(List<NEILON__File__c> newFileList) {
        Map<Id, Map<String, NEILON__File__c>> filesToProcessByNameMapByCaseIdMap = new Map<Id, Map<String, NEILON__File__c>>();
        for (NEILON__File__c thisFile : newFileList) {
            if (thisFile.NEILON__Case__c != null) {
                if (filesToProcessByNameMapByCaseIdMap.containsKey(thisFile.NEILON__Case__c)) {
                    filesToProcessByNameMapByCaseIdMap.get(thisFile.NEILON__Case__c).put(thisFile.Name, thisFile);
                } else {
                    filesToProcessByNameMapByCaseIdMap.put(
                        thisFile.NEILON__Case__c,
                        new Map<String, NEILON__File__c>{ thisFile.Name => thisFile }
                    );
                }
            }
        }
        if (filesToProcessByNameMapByCaseIdMap.size() > 0) {
            List<Case> caseList = new List<Case>(
                [
                    SELECT Id, Zendesk_File_Timestamp__c
                    FROM Case
                    WHERE Id IN :filesToProcessByNameMapByCaseIdMap.keySet()
                ]
            );
            for (Case thisCase : caseList) {
                if (thisCase.Zendesk_File_Timestamp__c != null) {
                    try {
                        List<String> filesAndCreatedDatesList = thisCase.Zendesk_File_Timestamp__c.split(';');
                        for (String thisFileAndCreatedDateStr : filesAndCreatedDatesList) {
                            List<String> thisFileAndCreatedDate = thisFileAndCreatedDateStr.split('~');
                            String fileName = thisFileAndCreatedDate[0];
                            String dateTimeStr = thisFileAndCreatedDate[1];
                            if (filesToProcessByNameMapByCaseIdMap.get(thisCase.Id).containsKey(fileName)) {
                                filesToProcessByNameMapByCaseIdMap.get(thisCase.Id)
                                    .get(fileName)
                                    .File_Created_Date__c = (DateTime) JSON.deserialize(
                                    '"' +
                                    dateTimeStr +
                                    '"',
                                    DateTime.class
                                );
                            }
                        }
                    } catch (Exception e) {
                        handleError(e);
                    }
                }
            }
        }
    }

    /**
     * @description logs a general exception to audit trail error
     * @param e general exception error
     */
    @TestVisible
    private static void handleError(Exception e) {
        Audit_Trail_Error__c auditError = new Audit_Trail_Error__c();
        auditError.Module__c = 'S3FileHandler.populateCreatedDate';
        auditError.Dev_Audit_Notes__c = 'Error populating file created date';
        auditError.errorMessage__c = e.getMessage().abbreviate(250);
        insert auditError;
    }

    public static void tagS3Files(List<NEILON__File__c> newFiles) {
        List<NEILON__File__c> files = [
            SELECT
                Id,
                Name,
                NEILON__Content_Document_Id__c,
                NEILON__Export_Attachment_Id__c,
                NEILON__Parent_Id__c,
                NEILON__Parent_Object_API_Name__c,
                NEILON__Case__c,
                CreatedDate
            FROM NEILON__File__c
            WHERE
                NEILON__Content_Document_Id__c != NULL
                AND NEILON__Export_Attachment_Id__c != NULL
                AND NEILON__Case__c != NULL
                AND Id IN :newFiles
        ];
        if (!files.isEmpty()) {
            tagS3FilesInChatterPostComments(files);
            tagS3FilesInEmailPostComments(files);
        }
    }

    /**
     * @description Add S3-Files as chatter post comments
     * @param List<NEILON__File__c> files - S3 files to tag
     */
    private static void tagS3FilesInChatterPostComments(List<NEILON__File__c> files) {
        List<NEILON__File__c> s3FilesToUpdateList = new List<NEILON__File__c>();
        DateTime oldestDocumentCreatedDate = System.today();
        List<NEILON__File__c> updatedFiles = files;
        Set<String> contentVersionIds = new Set<String>();
        Set<String> contentDocumentIds = new Set<String>();
        Map<Id, NEILON__File__c> filesByContentVersionIds = new Map<Id, NEILON__File__c>();
        Map<Id, String> contentVersionIdsByContentDocumentIds = new Map<Id, String>();
        for (NEILON__File__c file : updatedFiles) {
            contentVersionIds.add(file.NEILON__Export_Attachment_Id__c);
            contentDocumentIds.add(file.NEILON__Content_Document_Id__c);
            filesByContentVersionIds.put(file.NEILON__Export_Attachment_Id__c, file);
            contentVersionIdsByContentDocumentIds.put(
                file.NEILON__Content_Document_Id__c,
                file.NEILON__Export_Attachment_Id__c
            );
        }
        List<ContentDocument> contentDocuments = [
            SELECT Id, CreatedDate
            FROM ContentDocument
            WHERE Id IN :contentDocumentIds
        ];
        for (ContentDocument contentDocument : contentDocuments) {
            if (contentDocument.CreatedDate < oldestDocumentCreatedDate) {
                oldestDocumentCreatedDate = contentDocument.CreatedDate;
            }
        }
        List<FeedAttachment> allFeedAttachments = [
            SELECT Id, Type, Value, Title, RecordId, FeedEntityId
            FROM FeedAttachment
            WHERE
                (Type = 'Content'
                OR Type = 'InlineImage')
                AND (RecordId IN :contentVersionIds
                OR RecordId IN :contentDocumentIds)
        ];
        Map<Id, Id> versionIdsByFeedItemId = new Map<Id, Id>();
        Set<Id> feedCommentIds = new Set<Id>();
        for (FeedAttachment feedAttachment : allFeedAttachments) {
            String feedEntityId = feedAttachment.FeedEntityId;
            if (!feedEntityId.startswith('0D5')) {
                feedCommentIds.add(feedEntityId);
            } else {
                versionIdsByFeedItemId.put(feedAttachment.FeedEntityId, feedAttachment.RecordId);
            }
        }
        if (!feedCommentIds.isEmpty()) {
            Map<Id, FeedComment> feedCommentsById = new Map<Id, FeedComment>();
            feedCommentsById = new Map<Id, FeedComment>(
                [
                    SELECT Id, RelatedRecordId, FeedItemId
                    FROM FeedComment
                    WHERE
                        (Id IN :feedCommentIds
                        OR CommentType = 'ContentComment')
                        AND SystemModstamp >= :oldestDocumentCreatedDate
                ]
            );
            for (FeedComment feedComment : feedCommentsById.values()) {
                if (feedComment.RelatedRecordId != null) {
                    versionIdsByFeedItemId.put(feedComment.FeedItemId, feedComment.RelatedRecordId);
                }
            }
        }
        for (Id feedItemId : versionIdsByFeedItemId.keySet()) {
            String feedEntityId = feedItemId;
            Id versionId = versionIdsByFeedItemId.get(feedItemId);
            if (contentVersionIdsByContentDocumentIds.containsKey(versionId)) {
                versionId = contentVersionIdsByContentDocumentIds.get(versionId);
            }
            NEILON__File__c file = filesByContentVersionIds.get(versionId);
            if (file != null) {
                ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                ConnectApi.EntityLinkSegmentInput entityLinkSegment = new ConnectApi.EntityLinkSegmentInput();
                entityLinkSegment.entityId = file.Id;
                messageBodyInput.messageSegments.add(entityLinkSegment);
                ConnectApi.TextSegmentInput createdDateSegment = new ConnectApi.TextSegmentInput();
                createdDateSegment.text = ' - File Created ' + file.CreatedDate.format();
                messageBodyInput.messageSegments.add(createdDateSegment);
                ConnectApi.CommentInput comment = new ConnectApi.CommentInput();
                comment.body = messageBodyInput;
                ConnectApi.Comment feedElement = ConnectApi.ChatterFeeds.postCommentToFeedElement(
                    null,
                    feedItemId,
                    comment,
                    null
                );
                file.Feed_Item_ID__c = feedEntityId;
                s3FilesToUpdateList.add(file);
            }
        }
        if (s3FilesToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(
                s3FilesToUpdateList,
                'S3FileHandler.tagS3FilesInChatterPostComments',
                'Updating S3 Files with lookups to chatter posts'
            );
        }
    }

    /**
     * @description Add S3-Files as email post comments
     * @param List<NEILON__File__c> files - S3 files to add
     */
    private static void tagS3FilesInEmailPostComments(List<NEILON__File__c> files) {
        List<NEILON__File__c> s3FilesToUpdateList = new List<NEILON__File__c>();
        Map<String, Set<NEILON__File__c>> filesByEmailMessageId = new Map<String, Set<NEILON__File__c>>();
        Set<Id> caseIds = new Set<Id>();
        Set<String> contentVersionIds = new Set<String>();
        Set<String> contentDocumentIds = new Set<String>();
        for (NEILON__File__c file : files) {
            if (
                file.NEILON__Parent_Id__c != null &&
                file.NEILON__Parent_Object_API_Name__c == 'EmailMessage__c' &&
                file.NEILON__Case__c != null
            ) {
                Set<NEILON__File__c> filesForEmail = filesByEmailMessageId.get(file.NEILON__Parent_Id__c);
                if (filesForEmail == null) {
                    filesForEmail = new Set<NEILON__File__c>();
                    filesByEmailMessageId.put(file.NEILON__Parent_Id__c, filesForEmail);
                }
                filesForEmail.add(file);
                contentVersionIds.add(file.NEILON__Export_Attachment_Id__c);
                contentDocumentIds.add(file.NEILON__Content_Document_Id__c);
                caseIds.add(file.NEILON__Case__c);
            }
        }
        if (filesByEmailMessageId == null || filesByEmailMessageId.isEmpty()) {
            return;
        }

        DateTime oldestDocumentCreatedDate = System.today();
        for (ContentDocument contentDocument : [
            SELECT Id, CreatedDate
            FROM ContentDocument
            WHERE Id IN :contentDocumentIds
        ]) {
            if (contentDocument.CreatedDate < oldestDocumentCreatedDate) {
                oldestDocumentCreatedDate = contentDocument.CreatedDate;
            }
        }
        List<EmailMessage> emailMessages = [
            SELECT Id, CreatedById, ParentId, CreatedDate
            FROM EmailMessage
            WHERE
                Id IN :filesByEmailMessageId.keySet()
                AND ParentId IN :caseIds
                AND CreatedDate >= :oldestDocumentCreatedDate
        ];

        if (!emailMessages.isEmpty()) {
            List<FeedItem> feedItems = [
                SELECT Id, ParentId, InsertedById, CreatedDate
                FROM FeedItem
                WHERE
                    InsertedById = :UserInfo.getUserId()
                    AND Type = 'EmailMessageEvent'
                    AND ParentId IN :caseIds
                    AND CreatedDate >= :oldestDocumentCreatedDate
                ORDER BY CreatedDate DESC
            ];
            Map<Id, List<FeedItem>> feedItemsByCaseId = new Map<Id, List<FeedItem>>();
            for (FeedItem feedItem : feedItems) {
                List<FeedItem> feedItemsForCase = feedItemsByCaseId.get(feedItem.ParentId);
                if (feedItemsForCase == null) {
                    feedItemsForCase = new List<FeedItem>();
                    feedItemsByCaseId.put(feedItem.ParentId, feedItemsForCase);
                }
                feedItemsForCase.add(feedItem);
            }

            for (EmailMessage emailMessage : emailMessages) {
                List<FeedItem> feedPosts = feedItemsByCaseId.get(emailMessage.ParentId);
                if (feedPosts == null || feedPosts.isEmpty()) {
                    continue;
                }
                FeedItem feedItem = feedPosts[0];
                if (emailMessage.CreatedById == feedItem.InsertedById) {
                    Set<NEILON__File__c> s3Files = filesByEmailMessageId.get(emailMessage.Id);
                    for (NEILON__File__c s3File : s3Files) {
                        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                        ConnectApi.EntityLinkSegmentInput entityLinkSegment = new ConnectApi.EntityLinkSegmentInput();
                        entityLinkSegment.entityId = s3File.Id;
                        messageBodyInput.messageSegments.add(entityLinkSegment);
                        ConnectApi.TextSegmentInput createdDateSegment = new ConnectApi.TextSegmentInput();
                        createdDateSegment.text = ' - File Created ' + s3File.CreatedDate.format();
                        messageBodyInput.messageSegments.add(createdDateSegment);
                        ConnectApi.CommentInput comment = new ConnectApi.CommentInput();
                        comment.body = messageBodyInput;
                        ConnectApi.Comment feedElement = ConnectApi.ChatterFeeds.postCommentToFeedElement(
                            null,
                            feedItem.Id,
                            comment,
                            null
                        );
                        s3File.Email_Message_ID__c = emailMessage.Id;
                        s3FilesToUpdateList.add(s3File);
                    }
                }
            }

            DatabaseUtilities.saveToDatabase(
                s3FilesToUpdateList,
                'S3FileHandler.tagS3FilesInEmailPostComments',
                'Updating S3 Files with lookups to email messages'
            );
        }
    }
}