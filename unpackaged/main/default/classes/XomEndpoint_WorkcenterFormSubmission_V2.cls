/**
 * @description Integration for workcenter center forms.
 */
@RestResource(UrlMapping='/WorkcenterFormSubmission/v2/*')
global class XomEndpoint_WorkcenterFormSubmission_V2 {
    global class XomEndpoint_WorkcenterFormSubmission_V2Exception extends Exception { }
    global class FormDataField {

        String key { get; set; }
        String value { get; set; }
        String type { get; set; }
        public FormDataField() { }
        public FormDataField(String key, String value, String type) {
            this.key = key;
            this.value = value;
            this.type = type;
        }
    }

    global class FormResponse {
        public String CaseNumber;
        public String CaseId;

        public FormResponse(String CaseId, String CaseNumber) {
            this.CaseId = CaseId;
            this.CaseNumber = CaseNumber;
        }
    }

    @HttpPost
    /**
     * @description Used for form submission
     * @param email Email to be used as the contact on the case
     * @param formId Third party id for reference
     * @param origin Where the form is being submitted
     * @param type The type of submission and will be used for routing
     * @param partnerId The id of the partner that should be linked to the case
     * @param jobId The id of the job that should be linked to the case
     * @param subject The subject for the case
     * @param attachmentStatus Determines if files are pending or none needed
     * @param recordTypeName The Developer Name of the record type for the case
     * @param category The workcenter category
     * @param whoInPod Role of the person handling the request within the pod
     * @param otherFields A list is other form data fields that are not required
     */
    global static XomEndpoint_WorkcenterFormSubmission_V2.FormResponse createCaseFromSubmission(
            String email,
            String formId,
            String origin,
            String type,
            String partnerId,
            String jobId,
            String subject,
            String attachmentStatus,
            String recordTypeName,
            String category,
            String whoInPod,
            List<XomEndpoint_WorkcenterFormSubmission_V2.FormDataField> otherFields
    ) {
        try{
            System.debug('Request headers: ' + RestContext.request.headers);
            System.debug('Request method: ' + RestContext.request.httpMethod);
            System.debug('Request parameters: ' + RestContext.request.params);
            System.debug('Request remote address: ' + RestContext.request.remoteAddress);
            System.debug('Request body: ' + RestContext.request.requestBody);
            System.debug('Request requestURI: ' + RestContext.request.requestURI);
            System.debug('Request resourcePath: ' + RestContext.request.resourcePath);
            System.debug('email: ' + email);
            System.debug('formId: ' + formId);
            System.debug('origin: ' + origin);
            System.debug('type: ' + type);
            System.debug('partnerId: ' + partnerId);
            System.debug('jobId: ' + jobId);
            System.debug('subject: ' + subject);
            System.debug('attachmentStatus: ' + attachmentStatus);
            System.debug('recordTypeName: ' + recordTypeName);
            System.debug('category: ' + category);
            System.debug('Who In Pod: ' + whoInPod);
            Case cse
                = createCase(email,formId,origin,type,partnerId,jobId,subject,
                             attachmentStatus,recordTypeName,category,whoInPod,
                             otherFields);
            System.debug('>>>>> Case Id: ' + cse.Id);
            return new FormResponse(cse.Id,cse.CaseNumber);
        }
        catch (Exception e) {
            throw new XomEndpoint_WorkcenterFormSubmission_V2Exception(e);
        }
    }


    private static Case createCase(
        String email,
        String formId,
        String origin,
        String type,
        String partnerId,
        String jobId,
        String subject,
        String attachmentStatus,
        String recordTypeName,
        String category,
        String whoInPod,
        List<XomEndpoint_WorkcenterFormSubmission_V2.FormDataField> otherFields)
    {
        Case cse = new Case(
            SuppliedEmail = email,
            ThirdPartyCreationID__c = formId,
            Origin = origin,
            Type = type,
            Job_Number__c = jobId,
            Subject = subject,
            AttachmentStatus__c = attachmentStatus,
            RecordTypeId
                = recordTypeName == 'VQC_Case'
                ? getCaseRecordTypeByDevName(recordTypeName)
                : getCaseRecordTypeByPod(whoInPod)
        );
        if(String.isNotBlank(category)){
            cse.Work_Center_Category__c = category;
        }
        if(String.isNotBlank(whoInPod)){
            cse.Who_In_Pod__c = whoInPod;
        }
        if (!String.isBlank(partnerId)) {
            List<Supplier__c> suppliers
                    = [SELECT Id, ContactID__c FROM Supplier__c WHERE PartnerID__c = :partnerId];
            if (!suppliers.isEmpty()) {
                Supplier__c s = suppliers[0];
                cse.Supplier__c = s.Id;
                cse.ContactId = s.ContactID__c;
            }
        }
        if (!String.isBlank(jobId)) {
            List<Job__c> jobs =
            [SELECT Id, OrderID__c, OrderID__r.POD__c, XometryOpsOrderID__c
            FROM Job__c
            WHERE XometryJobID__c = :jobId];
            if (!jobs.isEmpty()) {
                Job__c job = jobs[0];
                cse.Job__c = job.Id;
                cse.GNOOrder__c = job.OrderID__c;
                cse.OrderID__c = job.XometryOpsOrderID__c;
                if(job.OrderID__c!=null && String.isNotBlank(job.OrderID__r.POD__c)){
                    cse.POD__c = job.OrderID__r.POD__c;
                }
            }
        }
        // Loop through other fields
        if (!otherFields.isEmpty()) {
            for (FormDataField otherField : otherFields) {
                if (otherField.type.toLowerCase() == 'date') {
                    Date newValue = Date.valueOf(otherField.value);
                    cse.put(otherField.key, newValue);
                } else if (otherField.type.toLowerCase() == 'boolean') {
                    Boolean newValue = Boolean.valueOf(otherField.value);
                    cse.put(otherField.key, newValue);
                } else {
                    if(otherField.key.toLowerCase() == 'description')
                    {
                        if(subject.contains(':'))
                        {
                            String strTopic = subject.split(': ')[1];
                            otherField.value = otherField.value.replace('Topic: '+strTopic, 'Topic: '+strTopic+'\nDetails:');
                        }
                        otherField.value = otherField.value.replace('Topic:','\nTopic:');
                    }
                    cse.put(otherField.key, otherField.value);
                }
            }
        }

        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId = [
                SELECT Id
                FROM AssignmentRule
                WHERE SobjectType = 'Case' AND Active = TRUE LIMIT 1].Id;
        cse.setOptions(dmlOpts);
        insert cse;

        return [SELECT Id, CaseNumber FROM Case WHERE Id = :cse.Id];
    }

    private static Id getCaseRecordTypeByPod(String whoInPod) {
        String recordTypeDevName;
        switch on whoInPod {
            when 'CM' {
                recordTypeDevName = 'CaseMgmt';
            }
            when 'POD/DFM' {
                recordTypeDevName = 'DFM_Case';
            }
        }
        return getCaseRecordTypeByDevName(recordTypeDevName);
    }

    private static Id getCaseRecordTypeByDevName(String recordTypeDevName) {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get(recordTypeDevName)
                .getRecordTypeId();
    }

}