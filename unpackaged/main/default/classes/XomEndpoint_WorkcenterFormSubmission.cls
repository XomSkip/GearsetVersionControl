@RestResource(urlMapping='/WorkcenterFormSubmission/v1/*')
global class XomEndpoint_WorkcenterFormSubmission {
    global class FormDataField {
        String key { get; set; }
        String value { get; set; }
        String type { get; set; }
        public FormDataField() {
        }
        public FormDataField(String key, String value, String type) {
            this.key = key;
            this.value = value;
            this.type = type;
        }
    }

    global class FormResponse {
        public string CaseNumber;
        public string CaseId;

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
     * @param otherFields A list is other form data fields that are not required
     */
    global static FormResponse createCaseFromSubmission(
        String email,
        String formId,
        String origin,
        String type,
        String partnerId,
        String jobId,
        String subject,
        String attachmentStatus,
        String recordTypeName,
        List<FormDataField> otherFields
    ) {
        // default to General Record Type
        // TODO: Add routing based on info
        Case c = new Case(
            SuppliedEmail = email,
            ThirdPartyCreationID__c = formId,
            Origin = origin,
            Type = type,
            Job_Number__c = jobId,
            Subject = subject,
            AttachmentStatus__c = attachmentStatus,
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get(recordTypeName)
                .getRecordTypeId()
        );

        // Handle associations
        if (!String.isBlank(partnerId)) {
            List<Supplier__c> sList = [SELECT Id, ContactId__c FROM Supplier__c WHERE PartnerID__c = :partnerId];
            if (!sList.isEmpty()) {
                Supplier__c s = sList[0];
                c.Supplier__c = s.Id;
                c.ContactId = s.ContactId__c;
            }
        }

        if (!String.isBlank(jobId)) {
            List<Job__c> jList = [
                SELECT Id, OrderId__c, XometryOpsOrderID__c
                FROM Job__c
                WHERE XometryJobID__c = :jobId
            ];
            if (!jList.isEmpty()) {
                Job__c j = jList[0];
                c.Job__c = j.Id;
                c.GNOOrder__c = j.OrderId__c;
                c.OrderId__c = j.XometryOpsOrderID__c;
            }
        }

        // Loop through other fields
        if (!otherFields.isEmpty()) {
            for (FormDataField d : otherFields) {
                if (d.type.toLowerCase() == 'date') {
                    Date newValue = Date.valueOf(d.value);
                    c.put(d.key, newValue);
                } else if (d.type.toLowerCase() == 'boolean') {
                    Boolean newValue = Boolean.valueOf(d.value);
                    c.put(d.key, newValue);
                } else {
                    if(d.key.toLowerCase() == 'description')
                    {
                        if(subject.contains(':'))
                        {
                            String strTopic = subject.split(': ')[1];
                            d.value = d.value.replace('Topic: '+strTopic, 'Topic: '+strTopic+'\nDetails:');
                        }
                        d.value = d.value.replace('Topic:','\nTopic:');
                    }

                    c.put(d.key, d.value);
                }
            }
        }

        //Fetching the assignment rules on case
        AssignmentRule AR = new AssignmentRule();
        AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];

        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;

        c.setOptions(dmlOpts);

        DatabaseUtilities.insertToDatabase(
            new List<Case>{ c },
            'createCaseFromSubmission',
            'Insert case from WorkcenterFormSubmission'
        );
        Case caseResult = [SELECT Id, CaseNumber FROM Case WHERE Id = :c.Id][0];
        return new FormResponse(caseResult.Id, caseResult.CaseNumber);
    }
}