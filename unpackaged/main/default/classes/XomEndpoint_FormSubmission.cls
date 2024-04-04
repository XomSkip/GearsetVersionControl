@RestResource(urlMapping='/FormSubmission/v1/*')
global class XomEndpoint_FormSubmission {
    global class FormDataField {
        String key { get; set; }
        String value { get; set; }
        String type { get; set; }
        String action { get; set; }
        public FormDataField() {
        }
        public FormDataField(String key, String value, String type, String action) {
            this.key = key;
            this.value = value;
            this.type = type;
            this.action = action;
        }
    }

    global class FormSubmissionResponse {
        public string ResourceId;
        public string ResourceType;
        public string Status;
        public string Error;
        public FormSubmissionResponse(String ResourceId, String Status, String ResourceType, String Error) {
            this.ResourceId = ResourceId;
            this.Status = Status;
            this.ResourceType = ResourceType;
            this.Error = Error;
        }
    }

    @HttpPost
    /**
     * @description Used for lead creation
     * @param fields The list is the fields for the lead
     */
    global static FormSubmissionResponse submitForm(
        String LastName,
        String LeadSource,
        String Email,
        String Company,
        List<FormDataField> fields
    ) {
        String qString = 'SELECT Id, ';
        String qFields = '';
        for (FormDataField field : fields) {
            if (field.action == 'Append') {
                qFields += field.key + ', ';
            }
        }
        String contQString;
        contQString = qString + qFields + 'Email FROM Contact WHERE Email = :Email';
        String leadQString = qString + qFields + 'Email FROM Lead WHERE Email = :Email';
        SObject obj;
        String resourceType;
        List<Contact> contactSearch = Database.query(contQString);
        if (!contactSearch.isEmpty()) {
            // Existing Contact
            resourceType = 'Contact';
            obj = mapFormFieldsToObject('Contact', fields, contactSearch[0]);
            obj.Id = contactSearch[0].Id;
            obj.put(Schema.Contact.Contact_Form_Status__c, 'New/Unresolved');
            obj.put(Schema.Contact.Contact_Form_Last_Submission__c, System.now());
        } else {
            resourceType = 'Lead';
            List<Lead> leadSearch = Database.query(leadQString);
            if (leadSearch.size() > 0) {
                // Existing Lead
                obj = mapFormFieldsToObject('Lead', fields, leadSearch[0]);
                obj.Id = leadSearch[0].Id;
            } else {
                // New Lead
                obj = mapFormFieldsToObject('Lead', fields, null);
                obj.put(Schema.Lead.LastName, LastName);
                obj.put(Schema.Lead.LeadSource, LeadSource);
                obj.put(Schema.Lead.Email, Email);
                obj.put(Schema.Lead.Company, Company);
            }
            obj.put(Schema.Lead.Contact_Form_Status__c, 'New/Unresolved');
            obj.put(Schema.Lead.Contact_Form_Last_Submission__c, System.now());
        }

        List<Database.UpsertResult> upsertRes = DatabaseUtilities.upsertToDatabase(
            new List<SObject>{ obj },
            'LeadFormSubmission',
            'The lead was not upserted from form'
        );

        if (upsertRes[0].isSuccess()) {
            return new FormSubmissionResponse(obj.Id, 'Success', resourceType, null);
        } else {
            List<Database.Error> errorList = upsertRes[0].getErrors();
            Database.Error err = errorList[0];
            return new FormSubmissionResponse(null, 'Error', null, err.getMessage());
        }
    }

    public static sObject mapFormFieldsToObject(String objType, List<FormDataField> fields, SObject searchResult) {
        SObject obj;
        SObjectType objTypeDescribe = Schema.getGlobalDescribe().get(objType);
        obj = Schema.getGlobalDescribe().get(objType).newSObject();
        Set<String> objectFields = objTypeDescribe.getDescribe().fields.getMap().keySet();
        List<String> lowerCaseObjectFields = new List<String>();
        for (String objectField : objectFields) {
            lowerCaseObjectFields.add(objectField.toLowerCase());
        }

        for (FormDataField field : fields) {
            if (lowerCaseObjectFields.contains(field.key.toLowerCase())) {
                if (field.type.toLowerCase() == 'date') {
                    Date newValue = Date.valueOf(field.value);
                    obj.put(field.key, newValue);
                } else if (field.type.toLowerCase() == 'boolean') {
                    Boolean newValue = Boolean.valueOf(field.value);
                    obj.put(field.key, newValue);
                } else {
                    if (searchResult != null && field.action == 'Append') {
                        String currentVal = (String) searchResult.get(field.key);
                        if (currentVal != null) {
                            obj.put(field.key, field.value + '<br/>' + currentVal);
                        } else {
                            obj.put(field.key, field.value);
                        }
                    } else {
                        obj.put(field.key, field.value);
                    }
                }
            } else {
                System.debug(field.key + ' not found as field on Lead Object');
            }
        }
        return obj;
    }
}