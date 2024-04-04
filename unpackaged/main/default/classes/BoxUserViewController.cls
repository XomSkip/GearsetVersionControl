public class BoxUserViewController {
    @AuraEnabled
    static public List<Contact> getBoxUserContact(String inputEmail) {
        return [SELECT Id, Name, Email, Xometry_ERP_Contact_ID__c FROM Contact WHERE Email = :inputEmail LIMIT 1];
    }

    @AuraEnabled
    static public boolean searchFolder(String caseId) {
        ResultSearchBox.Root result = BoxUtils.search('query=' + caseId + '&type=folder&fields=name');
        if (result.total_count > 0) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled
    static public CreateFolderResponse createFolder(String caseId) {
        CreateFolderResponse resp;

        try {
            Case objCase = [SELECT CaseNumber, CreatedDate FROM Case WHERE Id = :caseId];
            String strRootFolderName = objCase.CreatedDate.format('yyyy MMMM');
            String strIdRootFolder;

            ResultSearchBox.Root result = BoxUtils.search(
                'query=%22%0A' +
                strRootFolderName.replace(' ', '+') +
                '%22%0A&type=folder&fields=name'
            );
            if (result.total_count == 0) {
                // String strCasesRootFolderId = '207368767577';

                String strCasesFolderName = 'Cases';
                ResultSearchBox.Root resultCases = BoxUtils.search(
                    'query=' +
                    strCasesFolderName +
                    '&type=folder&fields=name'
                );
                String strCasesRootFolderId = resultCases.entries[0].id;

                strIdRootFolder = BoxUtils.createFolder(strCasesRootFolderId, strRootFolderName);
            } else {
                strIdRootFolder = result.entries[0].id;
            }

            String caseFolderId = BoxUtils.createFolderForRecordId(caseId, objCase.caseNumber);
            BoxUtils.moveFolder(strIdRootFolder, caseFolderId);

            //Create SubFolders
            String itarInternalFolderId = BoxUtils.createFolder(
                caseFolderId,
                objCase.caseNumber + '-Sensitive-Internal'
            );
            String itarConsumerFolderId = BoxUtils.createFolder(
                itarInternalFolderId,
                'Sensitive-' +
                objCase.caseNumber +
                '-Consumer'
            );

            String nonItarinternalFolderId = BoxUtils.createFolder(
                caseFolderId,
                objCase.caseNumber + '-Not Export-Controlled-Internal'
            );
            String nonItarConsumerFolderId = BoxUtils.createFolder(
                nonItarinternalFolderId,
                'Not Export-Controlled-' +
                objCase.caseNumber +
                '-Consumer'
            );

            if (!System.isBatch()) {
                createFolderPostProcessingFuture(
                    objCase.Id,
                    caseFolderId,
                    nonItarinternalFolderId,
                    itarInternalFolderId,
                    nonItarConsumerFolderId,
                    itarConsumerFolderId
                );

                BoxUtils.commitChanges();
            } else {
                createFolderPostProcessing(
                    objCase.Id,
                    caseFolderId,
                    nonItarinternalFolderId,
                    itarInternalFolderId,
                    nonItarConsumerFolderId,
                    itarConsumerFolderId
                );
            }

            resp = new CreateFolderResponse('Success', caseFolderId, itarConsumerFolderId, nonItarConsumerFolderId);
        } catch (Exception e) {
            resp = new CreateFolderResponse(e.getMessage(), '', '', '');
        }

        return resp;
    }

    @future(callout=true)
    static public void createFolderPostProcessingFuture(
        Id caseId,
        String caseFolderId,
        String nonItarinternalFolderId,
        String itarInternalFolderId,
        String nonItarConsumerFolderId,
        String itarConsumerFolderId
    ) {
        createFolderPostProcessing(
            caseId,
            caseFolderId,
            nonItarinternalFolderId,
            itarInternalFolderId,
            nonItarConsumerFolderId,
            itarConsumerFolderId
        );

        List<Case> case2up = new List<Case>();
        case2up.add(
            new Case(
                Id = caseId,
                Box_Folder__c = caseFolderId,
                BoxITARConsumerFolderId__c = itarConsumerFolderId,
                BoxNonITARConsumerFolderId__c = nonItarConsumerFolderId
            )
        );
        DatabaseUtilities.saveToDatabase(case2up, 'addDefaultCollaborator', 'Update Case box folder Id');
    }

    static public void createFolderPostProcessing(
        Id caseId,
        String caseFolderId,
        String nonItarinternalFolderId,
        String itarInternalFolderId,
        String nonItarConsumerFolderId,
        String itarConsumerFolderId
    ) {
        addDefaultCollaborator(caseFolderId, nonItarinternalFolderId);

        addDefaultClassification(nonItarinternalFolderId, itarInternalFolderId);
    }

    static public String addDefaultCollaborator(String caseFolderId, String nonItarinternalFolderId) {
        String resp = 'Success';
        try {
            BoxAuthenticationSettings__c bas = BoxAuthenticationSettings__c.getInstance();

            String groupId = bas.Collaboration_Group__c;
            BoxUtils.BoxResponse boxResp = BoxUtils.addCollaborator(
                nonItarinternalFolderId,
                'folder',
                groupId,
                'group',
                'editor'
            );
        } catch (Exception e) {
            resp = e.getMessage();
        }

        return resp;
    }

    static public String addDefaultClassification(String nonItarinternalFolderId, String itarInternalFolderId) {
        String resp;

        try {
            BoxAuthenticationSettings__c bas = BoxAuthenticationSettings__c.getInstance();

            BoxUtils.BoxResponse boxResp = BoxUtils.addLabelClassificationToFolder(
                nonItarinternalFolderId,
                bas.Classification_NonITAR__c
            );

            BoxUtils.BoxResponse boxResp2 = BoxUtils.addLabelClassificationToFolder(
                itarInternalFolderId,
                bas.Classification_ITAR__c
            );

            BoxUtils.BoxResponse boxResp3 = BoxUtils.addCascadePolicyToFolder(nonItarinternalFolderId);

            Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(boxResp3.data);
            System.debug(LoggingLevel.ERROR, '*** respMap: ' + respMap);
            if (respMap.containsKey('id')) {
                BoxUtils.forceCascadePolicy(String.valueOf(respMap.get('id')));
            }

            BoxUtils.BoxResponse boxResp4 = BoxUtils.addCascadePolicyToFolder(itarInternalFolderId);

            Map<String, Object> respMap2 = (Map<String, Object>) JSON.deserializeUntyped(boxResp4.data);
            System.debug(LoggingLevel.ERROR, '*** respMap2: ' + respMap2);
            if (respMap2.containsKey('id')) {
                BoxUtils.forceCascadePolicy(String.valueOf(respMap2.get('id')));
            }

            resp = 'success';
        } catch (Exception e) {
            resp = e.getMessage();
        }

        return resp;
    }

    @AuraEnabled
    static public String createUser(string name, string login, string external_app_user_id, string job_title) {
        try {
            BoxUser.CreateUserRequest objUser = new BoxUser.CreateUserRequest();
            objUser.name = name;
            objUser.login = login;
            objUser.external_app_user_id = external_app_user_id;
            objUser.job_title = null;
            BoxUtils.createUser(objUser);
            return 'Success';
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    @AuraEnabled
    static public void addAuditError(string email, string errorMessage) {
        try {
            Audit_Trail_Error__c auditError = new Audit_Trail_Error__c();
            auditError.Module__c = 'boxUserView';
            auditError.Dev_Audit_Notes__c = 'Contact search from box';
            auditError.errorMessage__c = 'LWC BoxUser: ' + errorMessage;
            auditError.errorFields__c = email;
            insert auditError;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}