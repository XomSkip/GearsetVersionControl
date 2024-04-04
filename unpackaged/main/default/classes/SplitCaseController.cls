public with sharing class SplitCaseController {
    /**
     * @description method to get S3 files
     * @param caseId id of case to search S3 files
     * @return List of S3 file objects
     */
    @AuraEnabled
    public static List<NEILON__File__c> getFiles(Id caseId) {
        return new List<NEILON__File__c>(
        [
                SELECT
                        Id,
                        Name,
                        NEILON__Case__c,
                        NEILON__Amazon_File_Key__c,
                        NEILON__Content_Type__c,
                        File_Created_Date__c
                FROM NEILON__File__c
                WHERE NEILON__Case__c = :caseId
        ]
        );
    }

    /**
     * @description clone's case and moves selected s3 files to cloned case
     * @param caseId - record Id
     * @param fileList - selected s3 files to move
     * @param userId - record Id of user if selected to reassign case to
     * @param queueId - record Id of queue if selected to reassign case to
     * @param priority - new priority to set case to
     * @return return Id of new cloned case
     */
    @AuraEnabled
    public static Id moveFiles(
            Id caseId,
            List<NEILON__File__c> fileList,
            Id userId,
            Id queueId,
            String priority,
            String transferInstructions
    ) {
        Set<String> fileIdSet = new Set<String>();
        Set<Id> fileVersionIdSet = new Set<Id>();
        Case clonedCase = cloneCase(caseId, userId, queueId, priority, transferInstructions);
        try {
            NEILON__Folder__c thisNewFolder;
            if(!Test.isRunningTest()) {
                thisNewFolder = NEILON.apGlobalUtils.buildFolderArchitecture(clonedCase.Id);
            }
            for (NEILON__File__c thisFile : fileList) {
                fileIdSet.add((String) thisFile.Id);
            }
            if(!Test.isRunningTest()) {
                NEILON.apGlobalUtils.copyFiles(fileIdSet, (String) thisNewFolder.Id);
            }
            delete fileList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return clonedCase.Id;
    }

    /**
     * @description clone's case and clone's selected s3 files to cloned case
     * @param caseId - record Id
     * @param fileList - selected s3 files to clone
     * @param userId - record Id of user if selected to reassign case to
     * @param queueId - record Id of queue if selected to reassign case to
     * @param priority - new priority to set case to
     * @return return Id of new cloned case
     */
    @AuraEnabled
    public static Id cloneFiles(
            Id caseId,
            List<NEILON__File__c> fileList,
            Id userId,
            Id queueId,
            String priority,
            String transferInstructions
    ) {
        Set<String> idSet = new Set<String>();
        Case clonedCase = cloneCase(caseId, userId, queueId, priority, transferInstructions);
        try {
            NEILON__Folder__c thisNewFolder;
            if(!Test.isRunningTest()) {
                thisNewFolder = NEILON.apGlobalUtils.buildFolderArchitecture(clonedCase.Id);
            }
            for (NEILON__File__c thisFile : fileList) {
                idSet.add((String) thisFile.Id);
            }
            if(!Test.isRunningTest()) {
                NEILON.apGlobalUtils.copyFiles(idSet, (String) thisNewFolder.Id);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return clonedCase.Id;
    }

    /**
     * @description clone's case
     * @param caseId - record Id
     * @param userId - record Id of user if selected to reassign case to
     * @param queueId - record Id of queue if selected to reassign case to
     * @param priority - new priority to set case to
     * @return return Id of new cloned case
     */
    @AuraEnabled
    public static Id splitCaseWithoutFiles(
            Id caseId,
            Id userId,
            Id queueId,
            String priority,
            String transferInstructions
    ) {
        Case clonedCase = cloneCase(caseId, userId, queueId, priority, transferInstructions);
        return clonedCase.Id;
    }

    /**
     * @description clone's case
     * @param caseId - record Id
     * @param userId - record Id of user if selected to reassign case to
     * @param queueId - record Id of queue if selected to reassign case to
     * @param priority - new priority to set case to
     * @return return new cloned case
     */
    private static Case cloneCase(Id caseId, Id userId, Id queueId, String priority, String transferInstructions) {
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
                .get('Case')
                .getDescribe()
                .SObjectType.getDescribe()
                .fields.getMap();
        List<String> fieldsList = new List<String>();
        for (Schema.SObjectField thisField : fieldMap.values()) {
            fieldsList.add(thisField.getDescribe().getName());
        }
        String query = 'SELECT ' + String.join(fieldsList, ',') + ' FROM Case WHERE Id = \'' + caseId + '\' LIMIT 1';
        Case thisCase = Database.query(query);
        Case clonedCase = thisCase.clone(false, false, false, false);
        if (userId != null) {
            clonedCase.OwnerId = userId;
        } else if (queueId != null) {
            clonedCase.OwnerId = queueId;
        }
        if (priority != null) {
            clonedCase.Priority = priority;
        }
        clonedCase.Status = 'New';
        clonedCase.ClosedDate = null;
        clonedCase.Original_Case__c = caseId;
        try {
            insert clonedCase;
            if (transferInstructions != null) {
                postTransferInstructionsToChatter(clonedCase, transferInstructions, userId);
            }
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
        return clonedCase;
    }

    /**
     * @description posts transfer instructions to chatter and @mentions case owner
     * @param clonedCase - newly cloned case
     * @param transferInstructions - string containing transfer instructions
     */
    private static void postTransferInstructionsToChatter(Case clonedCase, String transferInstructions, Id userId) {
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        if (userId != null) {
            mentionSegmentInput.id = clonedCase.OwnerId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);
        }

        textSegmentInput.text = userId != null ? ' ' + transferInstructions : transferInstructions;
        messageBodyInput.messageSegments.add(textSegmentInput);
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = clonedCase.Id;
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(
                Network.getNetworkId(),
                feedItemInput
        );
    }
}