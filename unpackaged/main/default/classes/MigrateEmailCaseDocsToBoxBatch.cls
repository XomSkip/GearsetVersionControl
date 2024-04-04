global class MigrateEmailCaseDocsToBoxBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    class CustomException extends Exception { }
    
    static final String METHOD_NAME = 'MigrateEmailCaseDocsToBoxBatch';
    
    //Size limit in bytes 1Mb = 1048576
    public Integer sizeLimit = 26214400;

    public String query = ' SELECT ContentDocumentId, Checksum, FileExtension, ContentSize, Title FROM ContentVersion USING SCOPE Team WHERE IsLatest = TRUE AND inBox__c = FALSE ';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Sobject> scope) {

        Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>();

        for(ContentVersion cv : (List<ContentVersion>) scope){

            if( cv.ContentSize <= sizeLimit ){
                cvMap.put(cv.ContentDocumentId, cv);
            }

        }

        //check if its related to relevant object
        Map<Id,Id> emailIdCDIdMap = new Map<Id,Id>();
        for( ContentDocumentLink cdl : [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :cvMap.keySet()] ){
            
            //check prefix looking for EmailMessages
            if(cdl.LinkedEntityId != null && String.valueOf(cdl.LinkedEntityId).substring(0, 3) == '02s' ){
                String emailMessageId = String.valueOf(cdl.LinkedEntityId);
                emailIdCDIdMap.put(emailMessageId, cdl.ContentDocumentId);
            }

        }

        Map<Id,Id> caseIdEmailIdMap = new Map<Id,Id>(); 
        for( EmailMessage eMessage : [SELECT Id, ParentId FROM EmailMessage WHERE Id IN :emailIdCDIdMap.keySet()] ){
            //check prefix looking for Cases
            if( String.valueOf(eMessage.ParentId).substring(0, 3) == '500' ){
                caseIdEmailIdMap.put( eMessage.ParentId, eMessage.Id );
            }
        }

        List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();
        List<ContentVersion> cvToUpdateList = new List<ContentVersion>();
        List<Case> caseToUpdateList = new List<Case>();

        if(!caseIdEmailIdMap.isEmpty()){

            String strToken = OAuthServicesUtils.getAccessTokenCredentials();

            for( Case oneCase : [SELECT Id, CaseNumber, Box_Folder__c FROM Case WHERE Id IN :caseIdEmailIdMap.keySet()] ){

                Id emailId = caseIdEmailIdMap.get(oneCase.Id);
                Id contentDocumentId = emailIdCDIdMap.get(emailId);
                ContentVersion cv = cvMap.get(contentDocumentId);

                try{

                    if( String.isBlank(oneCase.Box_Folder__c) ){
                        CreateFolderResponse createFolderResponse = BoxUserViewController.createFolder(oneCase.Id);
                        oneCase.Box_Folder__c = createFolderResponse.caseFolder;
                        oneCase.BoxITARConsumerFolderId__c = createFolderResponse.consumerFolderITAR;
                        oneCase.BoxNonITARConsumerFolderId__c = createFolderResponse.consumerFolderNonITAR;
                        caseToUpdateList.add( oneCase );
                    }

                    String strEndPoint = 'callout:XometryServices/box/service/migrateAttachment';

                    Map<String,String> bodyMap = new Map<String,String>();
                    bodyMap.put('folder_id', oneCase.Box_Folder__c);
                    bodyMap.put('document_id', cv.Id);
                    bodyMap.put('file_name', cv.Title);
                    bodyMap.put('file_extension', cv.FileExtension);
                    bodyMap.put('file_size', String.valueOf(cv.ContentSize) );
                    bodyMap.put('md5', cv.Checksum);

                    HttpRequest req = new HttpRequest();
                    req.setHeader('Authorization', 'Bearer ' + strToken);
                    req.setEndpoint(strEndPoint);
                    req.setMethod('POST');
                    req.setHeader('Accept', 'application/json');
                    req.setHeader('Content-Type', 'application/json');
                    req.setBody( JSON.serialize(bodyMap) );

                    HttpResponse resp = new Http().send(req);

                    if(resp.getStatusCode() == 200){
                        cv.inBox__c = true;
                        cvToUpdateList.add(cv);
                    }else{
                        throw new CustomException( 'Status: ' + resp.getStatus() + ', Body: ' + resp.getBody() );
                    }

                }catch(Exception e){

                    System.debug(LoggingLevel.ERROR, '*** Error Message: ' + e.getMessage() + 'StackTrace: ' + e.getStackTraceString());
                    
                    Audit_Trail_Error__c auditError = new Audit_Trail_Error__c();
                    auditError.Module__c = METHOD_NAME;
                    auditError.Dev_Audit_Notes__c = 'Exception throw';
                    auditError.SourceId__c = cv.Id;
                    auditError.errorMessage__c = e.getMessage().abbreviate(250);
                    auditErrorList.add(auditError);

                }
            }

        }

        BoxUtils.commitChanges();

        DatabaseUtilities.saveToDatabase(
            caseToUpdateList,
            METHOD_NAME,
            'Update Case . Box_Folder__c'
        );

        DatabaseUtilities.saveToDatabase(
            cvToUpdateList,
            METHOD_NAME,
            'Flag ContentVersion inBox__c as Migrated'
        );


        if( !auditErrorList.isEmpty() ){
            insert auditErrorList;
        }

    }

    global void finish(Database.BatchableContext BC) {

    }

}