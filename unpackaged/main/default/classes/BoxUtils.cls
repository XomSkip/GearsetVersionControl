public with sharing class BoxUtils {
    public class BoxResponse {
        public String error;
        public String data;
    }

    public static String accessToken = null;
    public static box.Toolkit toolkit;

    public static void validateBoxToolkit() {
        if (toolkit == null) {
            toolkit = new box.Toolkit();
        }
    }

    public static String getAccessToken() {
        BoxAuthenticationSettings__c bas = BoxAuthenticationSettings__c.getInstance();

        JWT_Box jwt = new JWT_Box();
        jwt.clientId = bas.clientId__c;
        jwt.clientSecret = bas.clientSecret__c;
        jwt.entityId = bas.enterpriseId__c;

        return jwt.getAccessToken();

        /*DevNote the lift of creating a cert for a lower environment can be a large lift so
        for dev testing or fast debugging if spinning up a new box environment you can replace the jwt call with 
        a new app in box with ouath for scripting authentication credentials aka grant_type=client_credentials
        */
        // BoxAuthenticationSettings__c bas = BoxAuthenticationSettings__c.getInstance();

        // String boxSubjectId = bas.Box_Subject_Id__c;

        // String endpoint = 'callout:Box_Rest_API/oauth2/token';
        // string payload =
        //     'client_id={!$Credential.UserName}&client_secret={!$Credential.Password}&grant_type=client_credentials&box_subject_type=user&box_subject_id=' +
        //     boxSubjectId;

        // // define transaction variables
        // HttpRequest req = new HttpRequest();
        // HttpResponse res = new HttpResponse();
        // Http h = new Http();

        // // Configure the request
        // req.setEndpoint(endpoint);
        // req.setMethod('POST');
        // req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        // req.setTimeout(120000);
        // req.setBody(payload);
        // res = h.send(req);
        // System.debug('res.getBody() ' + res.getBody());
        // if (
        //     (res.getStatusCode() == 200 ||
        //     res.getStatusCode() == 201) &&
        //     res.getBody() != null &&
        //     res.getBody() != null
        // ) {
        //     Map<String, Object> untypedMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        //     if (untypedMap.containsKey('access_token')) {
        //         return (String) untypedMap.get('access_token');
        //     }
        //     return '';
        // } else {
        //     return '';
        // }
    }

    public static HttpResponse sendRequest(String strEndPoint, String strMethod, String strBody) {
        if (accessToken == null)
            accessToken = getAccessToken();
        System.debug(accessToken);

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http h = new Http();

        req.setEndpoint(strEndPoint);
        req.setMethod(strMethod);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');

        if (strBody != null)
            req.setBody(strBody);
        System.debug(req.getBody());
        System.debug(req.getEndPoint());

        res = h.send(req);
        return res;
    }

    public static HttpResponse sendRequestToolkit(String strEndPoint, String strMethod, String strBody) {
        validateBoxToolkit();

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        req.setEndpoint(strEndPoint);
        req.setMethod(strMethod);
        //req.setHeader('Accept', 'content-type');
        req.setHeader('content-type', 'application/json');

        if (strBody != null)
            req.setBody(strBody);

        System.debug(req.getBody());
        System.debug(req.getEndPoint());

        res = Test.isRunningTest() ? new Http().send(req) : toolkit.sendRequest(req);
        return res;
    }

    @AuraEnabled
    public static BoxUser.Entry getBoxUser(String strExternalId) {
        return getBoxUserByField('external_app_user_id', strExternalId);
    }

    @AuraEnabled
    public static BoxUser.Entry getBoxUserByField(String strField, String strExternalId) {
        // String endpoint = 'callout:Box_Rest_API/2.0/users?external_app_user_id=' + strExternalId;
        String endpoint = 'callout:Box_Rest_API/2.0/users?' + strField + '=' + strExternalId;
        httpResponse res = sendRequest(endpoint, 'GET', null);

        BoxUser.userResponse objUser = (BoxUser.userResponse) JSON.deserialize(
            res.getBody().replace('"limit"', '"intlimit"'),
            BoxUser.userResponse.class
        );
        System.debug(objUser);
        if (
            (res.getStatusCode() == 200 ||
            res.getStatusCode() == 201) &&
            res.getBody() != null &&
            res.getBody() != null
        ) {
            return objUser.entries.size() > 0 ? objUser.entries[0] : null;
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static String createFolder(String parentFolderId, String folderName) {
        validateBoxToolkit();
        String folderId = toolkit.createFolder(folderName, parentFolderId, null);
        return folderId;
    }

    @AuraEnabled
    public static String createFolderForRecordId(String salesforceId, String folderName) {
        validateBoxToolkit();
        String folderId = toolkit.createFolderForRecordId(salesforceId, folderName, true);
        return folderId;
    }

    @AuraEnabled
    public static void commitChanges() {
        toolkit.commitChanges();
    }

    public static void moveFolder(String parentFolderId, String folderId) {
        String body = '{ "parent": { "id": "' + parentFolderId + '" } }';
        //String endpoint = 'callout:Box_Rest_API/2.0/folders/' + folderId;
        String endpoint = 'https://api.box.com/2.0/folders/' + folderId;
        httpResponse res = sendRequest(endpoint, 'PUT', body);

        if (
            (res.getStatusCode() == 200 ||
            res.getStatusCode() == 201) &&
            res.getBody() != null &&
            res.getBody() != null
        ) {
            Map<String, Object> untypedMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug(untypedMap);
        }
    }

    // strType: file,folder
    // strRole: editor,viewer,previewer,uploader,previewer uploader,viewer uploader,co-owner
    @AuraEnabled
    public static void shareFolderFile(String strType, String itemId, String shareToUserEmail, String strRole) {
        String body =
            '{ "item": { "type": "' +
            strType +
            '", "id": "' +
            itemId +
            '" }, "accessible_by": { "type": "user", "login": "' +
            shareToUserEmail +
            '" }, "role": "' +
            strRole +
            '" }';
        // String endpoint = 'callout:Box_Rest_API/2.0/collaborations';
        String endpoint = 'https://api.box.com/2.0/collaborations';
        httpResponse res = sendRequestToolkit(endpoint, 'POST', body);

        if (
            (res.getStatusCode() == 200 ||
            res.getStatusCode() == 201) &&
            res.getBody() != null &&
            res.getBody() != null
        ) {
            Map<String, Object> untypedMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug(untypedMap);
        } else {
            throw newMessageException(res.getBody());
        }
    }

    @AuraEnabled
    public static void shareFolderFileUserApp(String strType, String itemId, String shareToUserEmail, String strRole) {
        List<Contact> lstContact = [
            SELECT Xometry_ERP_Contact_ID__c
            FROM Contact
            WHERE Email = :shareToUserEmail
            LIMIT 1
        ];
        BoxUser.Entry objUser;
        if (!lstContact.isEmpty()) {
            objUser = getBoxUser(lstContact[0].Xometry_ERP_Contact_ID__c);
        }

        if (objUser != null) {
            String body =
                '{ "item": { "type": "' +
                strType +
                '", "id": "' +
                itemId +
                '" }, "accessible_by": { "type": "user", "id": "' +
                objUser.id +
                '" }, "role": "' +
                strRole +
                '" }';
            // String endpoint = 'callout:Box_Rest_API/2.0/collaborations';
            String endpoint = 'https://api.box.com/2.0/collaborations';
            httpResponse res = sendRequestToolkit(endpoint, 'POST', body);

            if (
                (res.getStatusCode() == 200 ||
                res.getStatusCode() == 201) &&
                res.getBody() != null
            ) {
                Map<String, Object> untypedMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug(untypedMap);
            } else {
                BoxError objBoxError = (BoxError) JSON.deserialize(res.getBody(), BoxError.class);
                String strError = '';
                if(objBoxError.context_info != null){
                    for(BoxError.Error objError : objBoxError.context_info.errors){
                        strError += objError.message + ' ,';
                    }
                    strError = strError.removeEnd(' ,');
                }
                else {
                    strError = objBoxError.message;
                }
                
                throw newMessageException(strError);
            }
        }
        else {
            throw newMessageException('Not found user with this email');
        }
    }

    private static AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }

    @AuraEnabled
    public static ResultSearchBox.Root search(String strQuery) {
        // String endpoint = 'callout:Box_Rest_API/2.0/search?' + strQuery;
        String endpoint = 'https://api.box.com/2.0/search?' + strQuery;
        httpResponse res = sendRequestToolkit(endpoint, 'GET', null);

        ResultSearchBox.Root objResult = (ResultSearchBox.Root) JSON.deserialize(
            res.getBody().replace('"limit"', '"intlimit"'),
            ResultSearchBox.Root.class
        );
        System.debug(objResult);
        if (
            (res.getStatusCode() == 200 ||
            res.getStatusCode() == 201) &&
            res.getBody() != null &&
            res.getBody() != null
        ) {
            return objResult;
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static BoxUser.Entry createUser(BoxUser.CreateUserRequest objUser) {
        String endpoint = 'callout:Box_Rest_API/2.0/users';
        httpResponse res = sendRequest(endpoint, 'POST', JSON.serialize(objUser));
        System.debug('res ' + res);
        System.debug('res.getBody() ' + res.getBody());

        BoxUser.Entry objResult = (BoxUser.Entry) JSON.deserialize(res.getBody(), BoxUser.Entry.class);
        System.debug(objResult);
        if ((res.getStatusCode() == 200 || res.getStatusCode() == 201)) {
            return objResult;
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static ItemBox.Response getItemsFolder(String strId) {
        // String endpoint = 'callout:Box_Rest_API/2.0/folders/' + strId + '/items';
        String endpoint = 'https://api.box.com/2.0/folders/' + strId + '/items';
        httpResponse res = sendRequestToolkit(endpoint, 'GET', null);

        ItemBox.Response objResult = (ItemBox.Response) JSON.deserialize(res.getBody(), ItemBox.Response.class);
        System.debug(objResult);
        if ((res.getStatusCode() == 200 || res.getStatusCode() == 201)) {
            return objResult;
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static String getFolderIdByRecordId(String recordId) {
        validateBoxToolkit();
        return toolkit.getFolderIdByRecordId(recordId);
    }

    public class CollabPayload {
        public Map<String, String> item = new Map<String, String>();
        public Map<String, String> accessible_by = new Map<String, String>();
        public String role;
        public Boolean can_view_path;
    }

    @AuraEnabled
    public static BoxResponse addCollaborator(
        String itemId,
        String itemType,
        String collaboratorId,
        String collaboratorType,
        String collaboratorRole
    ) {
        BoxResponse retResponse = new BoxResponse();

        CollabPayload collabPayload = new CollabPayload();
        collabPayload.item.put('type', itemType);
        collabPayload.item.put('id', itemId);
        collabPayload.accessible_by.put('type', collaboratorType);
        collabPayload.accessible_by.put('id', collaboratorId);
        collabPayload.role = collaboratorRole;
        collabPayload.can_view_path = true;

        String endpoint = 'callout:Box_Rest_API/2.0/collaborations';

        httpResponse res = sendRequest(endpoint, 'POST', JSON.serialize(collabPayload));

        retResponse.data = res.getBody();

        if ((res.getStatusCode() != 200 && res.getStatusCode() != 201)) {
            retResponse.error = res.getStatus();
        }

        return retResponse;
    }

    @AuraEnabled
    public static BoxResponse addLabelClassificationToFolder(String folderId, String label) {
        BoxResponse retResponse = new BoxResponse();

        Map<String, String> classificationPayload = new Map<String, String>();
        classificationPayload.put('Box__Security__Classification__Key', label);

        String endpoint =
            'callout:Box_Rest_API/2.0/folders/' +
            folderId +
            '/metadata/enterprise/securityClassification-6VMVochwUWo';

        httpResponse res = sendRequest(endpoint, 'POST', JSON.serialize(classificationPayload));

        retResponse.data = res.getBody();

        if ((res.getStatusCode() != 200 && res.getStatusCode() != 201)) {
            retResponse.error = res.getStatus();
        }

        return retResponse;
    }

    @AuraEnabled
    public static BoxResponse addCascadePolicyToFolder(String folderId) {
        BoxAuthenticationSettings__c bas = BoxAuthenticationSettings__c.getInstance();

        BoxResponse retResponse = new BoxResponse();

        Map<String, String> cascadePayload = new Map<String, String>();
        cascadePayload.put('folder_id', folderId);
        cascadePayload.put('scope', 'enterprise_' + bas.enterpriseId__c);
        cascadePayload.put('templateKey', 'securityClassification-6VMVochwUWo');

        String endpoint = 'callout:Box_Rest_API/2.0/metadata_cascade_policies';

        httpResponse res = sendRequest(endpoint, 'POST', JSON.serialize(cascadePayload));
        System.debug(LoggingLevel.ERROR, '*** : ' + res.getBody());

        retResponse.data = res.getBody();

        if ((res.getStatusCode() != 200 && res.getStatusCode() != 201)) {
            retResponse.error = res.getStatus();
        }

        return retResponse;
    }

    @AuraEnabled
    public static BoxResponse forceCascadePolicy(String cascadePolicyId) {
        BoxResponse retResponse = new BoxResponse();

        Map<String, String> forceCascadePayload = new Map<String, String>();
        forceCascadePayload.put('conflict_resolution', 'overwrite');

        String endpoint = 'callout:Box_Rest_API/2.0/metadata_cascade_policies/' + cascadePolicyId + '/apply';

        httpResponse res = BoxUtils.sendRequest(endpoint, 'POST', JSON.serialize(forceCascadePayload));
        System.debug(LoggingLevel.ERROR, '*** forceCascadePolicy: ' + res.getBody());

        retResponse.data = res.getBody();

        if ((res.getStatusCode() != 200 && res.getStatusCode() != 201)) {
            retResponse.error = res.getStatus();
        }

        return retResponse;
    }

}