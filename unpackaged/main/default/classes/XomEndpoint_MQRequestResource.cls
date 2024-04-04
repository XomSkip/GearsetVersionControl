@RestResource(urlMapping='/CreateMQRequest/v1/*')
global class XomEndpoint_MQRequestResource {
    global class MQPseDataItem {
        String label;
        String key;
        String value;

        // Exclusively consumed by the Test Class 
        public MqPseDataItem(String label, String key, String value) {
            this.label = label;
            this.key = key;
            this.value = value;
        }
    }

    global class MQRequestResponseShape {
        public String PSEFormObjectId;

        public MQRequestResponseShape(String PSEFormObjectId) {
            this.PSEFormObjectId = PSEFormObjectId;
        }
    }


    public static void updatePSEFormFromQuestions(
        List<MQPseDataItem> questions,
        PSE_Form__c pseForm
    ) {
        for (MQPseDataItem q : questions) {
            String mappedPSEFormFieldName = PSEFormFieldMapper.getPSEFormFieldName(q.key);

            if (String.isBlank(mappedPSEFormFieldName)) {
                continue;
            }

            // These are Yes/No picklists. They have a little bit of extra
            // processing to make piping data into the fields less brittle.
            String mappedPSEFormFieldValue = q.value;
            if (q.key == 'plan_on_ordering_more' || q.key == 'needs_additional_trial_parts') {
                // This key maps to a picklist, so we add some special treatment
                // to make it not so prone to failure
                mappedPseFormFieldValue = mappedPSEFormFieldValue.toLowerCase() == 'yes' ? 'Yes' : 'No';
            }

            pseForm.put(mappedPSEFormFieldName, mappedPSEFormFieldValue);
        }
    }

    @HttpPost
    global static MQRequestResponseShape createMQRequest(
        String quoteId,
        String questionnaireSlug,
        List<MQPseDataItem> questions
    ) {

        PSE_Form__c pseForm = new PSE_Form__c(
            Quote_ID__c = quoteId,
            RecordTypeId = Schema.SObjectType.PSE_Form__c.getRecordTypeInfosByDeveloperName()
            .get('Dynamic_Form')
            .getRecordTypeId()
        );
        
        updatePSEFormFromQuestions(questions, pseForm);

        DatabaseUtilities.insertToDatabase(
            new List<PSE_Form__c>{ pseForm },
            'XomEndpoint_MQRequestResource.createMQRequest',
            'Insert PSE Form object before Linking Question objects'
        );

        return new MQRequestResponseShape(pseForm.id);
    }
}