@RestResource(urlMapping='/BulkUploadRequest/v1/*')
global with sharing class BulkUploadRequestEndpoint {
    /**
     * @description Creates a case and associated PSE form in salesforce after a bulk upload submission
     * @param customerEmail - customer email to generate case from
     * @param creation - date/time of upload
     * @param files - list of s3 links
     * @param responses - key (API location)/value/data type information corresponding to responses for the PSE Form
     * @param formSubmissionID - unique ID passed in by API representing ThirdPartyCreationID
     **/
    global class BulkUploadFields {
        public BulkUploadFields() {
        }
        public String key { get; set; }
        public String value { get; set; }
        public String type { get; set; }
    }

    global class BulkUploadFiles {
        public BulkUploadFiles() {
        }
        public String fileLink { get; set; }
        public String fileName { get; set; }
    }

    global class BulkUploadResponseObject {
        public BulkUploadResponseObject() {
        }
        public String caseID { get; set; }
        public Boolean success { get; set; }
    }

    @HTTPPost
    global static BulkUploadResponseObject createBulkUploadRequest(
        Datetime creation,
        String customerEmail,
        List<BulkUploadFiles> files,
        List<BulkUploadFields> responses,
        String formSubmissionID,
        String ERPUserId,
        String lastName,
        String bulkUploadUrl
    ) {
        try {
            Case thisCase = new Case(
                Subject = 'Bulk Upload',
                Status = 'Open',
                Origin = 'Bulk Upload',
                Priority = 'High',
                SuppliedEmail = customerEmail,
                RecordTypeId = AppConstants.casePSERecordTypeId,
                file_count__c = files.size(),
                ThirdPartyCreationID__c = formSubmissionID,
                bulk_upload_url__c = bulkUploadUrl
            );
            List<Contact> contactList = new List<Contact>(
                [SELECT Name, ID, AccountId, OwnerId FROM CONTACT WHERE Primary_Email__c = :customerEmail]
            );
            if (!contactList.isEmpty()) {
                thisCase.ContactId = contactList[0].Id;
                thisCase.AccountId = contactList[0].AccountId;
                thisCase.OwnerId = contactList[0].OwnerId;
            } else {
                Contact thisContact = new Contact(
                    Xometry_ERP_Contact_ID__c = ERPUserId,
                    Primary_Email__c = thisCase.SuppliedEmail,
                    LeadSource = 'Quoter'
                );
                // following precedent set in OrderERPHandler.cls where
                // contact last name defaults to email if without valid input
                if (!String.isBlank(lastName)) {
                    thisContact.LastName = lastName;
                } else {
                    thisContact.LastName = thisCase.SuppliedEmail;
                }
                List<Contact> newContactList = new List<Contact>();
                newContactList.add(thisContact);
                DatabaseUtilities.insertToDatabase(
                    newContactList,
                    'BulkUploadNewContact',
                    'Creating new Contact for bulk upload submission'
                );
                List<Contact> newContact = new List<Contact>(
                    [SELECT ID, AccountId, OwnerId FROM CONTACT WHERE Primary_Email__c = :thisCase.SuppliedEmail]
                );
                thisCase.ContactId = newContact[0].Id;
                thisCase.AccountId = newContact[0].AccountId;
                thisCase.OwnerId = newContact[0].OwnerId;
            }

            // The case and PSE form have to be inserted seperately and in this order
            // - otherwise the PSE Form does not show up in the Order view.
            List<Case> caseList = new List<Case>();
            caseList.add(thisCase);
            DatabaseUtilities.insertToDatabase(
                caseList,
                'BulkUploadCaseInsertion',
                'Creating new Case for bulk upload'
            );

            PSE_Form__c pse = new PSE_Form__c(Case__c = thisCase.Id, Email__c = customerEmail);
            Set<String> objectFields = Schema.SObjectType.PSE_Form__c.fields.getMap().keySet();
            List<String> lowerCaseObjectFields = new List<String>();
            for (String objectField : objectFields) {
                lowerCaseObjectFields.add(objectField.toLowerCase());
            }
            for (BulkUploadFields field : responses) {
                if (lowerCaseObjectFields.contains(field.key.toLowerCase())) {
                    if (field.type.toLowerCase() == 'date') {
                        Date newValue = Date.valueOf(field.value);
                        pse.put(field.key, newValue);
                    } else if (field.type.toLowerCase() == 'boolean') {
                        Boolean newValue = Boolean.valueOf(field.value);
                        pse.put(field.key, newValue);
                    } else {
                        pse.put(field.key, field.value);
                    }
                } else {
                    System.debug(field.key + ' not found as field on PSE Form');
                }
            }

            List<String> partFileLinks = new List<String>();
            for (Integer i = 0; i < files.size(); i++) {
                String partFileName = files[i].fileName;
                partFileName = partFileName.escapeHtml4().deleteWhitespace();
                partFileLinks.add(
                    '<ul><a href=' +
                    files[i].fileLink +
                    '/' +
                    partFileName.escapeHtml4() +
                    '>' +
                    partFileName +
                    '</a></ul>'
                );
            }
            pse.Part_Links__c = String.join(partFileLinks, '\n');
            List<PSE_Form__c> pseList = new List<PSE_Form__c>{ pse };
            DatabaseUtilities.insertToDatabase(
                pseList,
                'BulkUploadPSEInsertion',
                'Creating new bulk upload case-associated PSE Form'
            );

            for (Case c : caseList) {
                c.PSE_form__c = pse.ID;
            }
            DatabaseUtilities.saveToDatabase(
                caseList,
                'BulkUploadCaseUpdate',
                'Update bulk upload case to include PSE form'
            );

            BulkUploadResponseObject responseObj = new BulkUploadResponseObject();
            responseObj.caseID = thisCase.Id;
            responseObj.success = true;
            return responseObj;
        } catch (Exception e) {
            System.debug('Error ' + e + ' occurred; cancelling Bulk Upload');
            BulkUploadResponseObject responseObj = new BulkUploadResponseObject();
            responseObj.caseID = null;
            responseObj.success = false;
            return responseObj;
        }
    }
}