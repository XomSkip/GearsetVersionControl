@isTest
public class XomEndpoint_MQRequestResourceTest {
    
    @isTest
    static void testPseCasesCanBeCreated() {        
        Quote_ERP__C quote = TestDataFactory.createQuote(false);
        quote.Xometry_ERP_ID__C = 'AAAAA-00001';
        insert quote;

        List<XomEndpoint_MQRequestResource.MQPseDataItem> boundaryQuestionObjects = new List<XomEndpoint_MQRequestResource.MQPseDataItem> {
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Test Label 1',
                'Test Key 1',
                'Test Value 1'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Test Label 2',
                'Test Key 2',
                'Test Value 2'
            )
        };
        
        Test.startTest();
        XomEndpoint_MQRequestResource.MQRequestResponseShape response = XomEndpoint_MQRequestResource.createMQRequest('AAAAA-00001', 'pse_form_cnc', boundaryQuestionObjects);
        Test.stopTest();

        PSE_Form__c pseForm = [SELECT Id, Quote_ID__c, RecordTypeId  FROM PSE_Form__c WHERE Quote_ID__c = 'AAAAA-00001'];

        System.assertEquals(pseForm.id, response.PSEFormObjectId, 'REST response did not return PSEForm ID');
    }

    @isTest
    static void testSlugsMapToPSEFields() {        
        Quote_ERP__C quote = TestDataFactory.createQuote(false);
        quote.Xometry_ERP_ID__C = 'AAAAA-00001';
        insert quote;


        List<XomEndpoint_MQRequestResource.MQPseDataItem> boundaryQuestionObjects = new List<XomEndpoint_MQRequestResource.MQPseDataItem> {
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Are you open to receiving design feedback that may reduce your cost or lead time?',
                'open_to_design_feedback',
                'No'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Is there anything else you would like us to know about your project?',
                'anything_else_we_should_know',
                'Nothing comes to mind.'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'When do you need your parts to be delivered?',
                'when_need_order_delivered',
                '2023-01-29'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'When will you place the order?',
                'when_likely_to_place_order',
                '2023-01-20'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Do your parts need to be manufactured in the U.S.?',
                'parts_must_be_made_in_usa',
                'Yes'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Do you have a price target?',
                'what_price_for_parts',
                '$1000'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Select the option that better matches the priorities of your project.',
                'important_aspect',
                'Shortest Possible Leadtime'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Have you ordered this part from Xometry before?',
                'ordered_from_xometry_before',
                'Yes'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Do you plan on ordering additional quantities of this design in the future?',
                'plan_on_ordering_more',
                'Yes'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Are your parts cosmetic, structural or both?',
                'cosmetic_or_structural_parts',
                'Cosmetic'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Is a formal Production Part Approval Process (PAPP) required on this project?',
                'is_papp_required',
                'Yes'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Is this an order for an active project or are you inquiring for budgetary reasons?',
                'active_or_checking_cost',
                'I am checking the cost.'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'The tooling cost includes 10 trial parts. Will you need more trial parts before your order is complete?',
                'additional_trial_parts_quantity',
                '10 Trial Parts'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'After this order, when are you likely to order again and in what quantity?',
                'estimated_future_volume',
                'Next week, 1000 units.'
            ),
            new XomEndpoint_MQRequestResource.MQPseDataItem(
                'Will you need more trial parts before your order is complete?',
                'needs_additional_trial_parts',
                'yEs'
            )
        };
        
        Test.startTest();
        XomEndpoint_MQRequestResource.MQRequestResponseShape response = XomEndpoint_MQRequestResource.createMQRequest('AAAAA-00001', 'pse_form_cnc', boundaryQuestionObjects);
        Test.stopTest();

        Map<String, String> fieldNameToExpectedValue = new Map<String, String>{
            'Design_Feedback__c' => 'No',
            'Additional_Info__c' => 'Nothing comes to mind.',
            'WhenDoYouNeedYourOrderDelivered__c' => '2023-01-29',
            'WhenLikelyToPlaceOrder__c' => '2023-01-20',
            'usa_production_required__c' => 'Yes',
            'Price_For_Parts__c' => '$1000',
            'Important_Aspect__c' => 'Shortest Possible Leadtime',
            'Ordered_From_Xometry_Before__c' => 'Yes',
            'ordering_additional_volume_picklist__c' => 'Yes',
            'cosmetic_or_structural_parts__c' => 'Cosmetic',
            'Is_a_formal_production_approval_process__c' => 'Yes',
            'Active_Project__c' => 'I am checking the cost.',
            'How_Many_Additional_Trial_Parts_Needed__c' => '10 Trial Parts',
            'Estimated_Future_Volume__c' => 'Next week, 1000 units.',
            'Needs_Additional_Trial_Parts__c' => 'Yes'
        };
        List<String> fieldNameList = new List<String>();
        for (String fieldName : fieldNameToExpectedValue.keySet()) {
            fieldNameList.add(fieldName);
        }

        PSE_Form__c pseForm = Database.query(
            'SELECT Id, Quote_ID__c, RecordTypeId, ' +
            String.join(fieldNameList, ', ') +
            ' FROM PSE_Form__c where Quote_ID__c = \'AAAAA-00001\' LIMIT 1'
        );

        System.assertEquals(
            pseForm.RecordTypeId,
            Schema.SObjectType.PSE_Form__c.getRecordTypeInfosByDeveloperName().get('Dynamic_Form').getRecordTypeId(),
            'Expected Record Type ID to correspond to the "Dynamic_Form" Record Type Developer Name.'
        );

        for (String fieldName: fieldNameToExpectedValue.keySet()) {
            System.assertEquals(
                pseForm.get(fieldName),
                fieldNameToExpectedValue.get(fieldName),
                'Field: ' + fieldName + ' was not copied correctly.'
            );
        }

        System.assertEquals(pseForm.id, response.PSEFormObjectId, 'REST response did not return PSEForm ID');
    }
}