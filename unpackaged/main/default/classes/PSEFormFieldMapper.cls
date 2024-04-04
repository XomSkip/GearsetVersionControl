public with sharing class PSEFormFieldMapper {

    // Note that these sets of PSE_Form_Field names (values of this map, and
    // BANTOnlyFields) MUST be orthogonal.
    public static Map<String, String> customerFormSlugToPSEFormFieldName = new Map<String, String>{
        'when_need_order_delivered' => 'WhenDoYouNeedYourOrderDelivered__c',
        'when_likely_to_place_order' => 'WhenLikelyToPlaceOrder__c',
        'open_to_design_feedback' => 'Design_Feedback__c',
        'parts_must_be_made_in_usa' => 'usa_production_required__c',
        'what_price_for_parts' => 'Price_For_Parts__c',
        'important_aspect' => 'Important_Aspect__c',
        'ordered_from_xometry_before' => 'Ordered_From_Xometry_Before__c',
        'plan_on_ordering_more' => 'ordering_additional_volume_picklist__c',
        'cosmetic_or_structural_parts' => 'cosmetic_or_structural_parts__c',
        'is_papp_required' => 'Is_a_formal_production_approval_process__c',
        'active_or_checking_cost' => 'Active_Project__c',
        'needs_additional_trial_parts' => 'Needs_Additional_Trial_Parts__c',
        'additional_trial_parts_quantity' => 'How_Many_Additional_Trial_Parts_Needed__c',
        'estimated_future_volume' => 'Estimated_Future_Volume__c',
        'anything_else_we_should_know' => 'Additional_Info__c',
        'previous_quote_id' => 'Previous_Quote_ID__c',
        'is_itar' => 'ITAR__c'
    };

    // These are fields that are currently in use by the BANT form, but NOT by
    // the customer form experience. As such, they do not need slug mappings.
    static List<String> BANTOnlyFields = new List<String>{
        'Manufacturing_Approach__c',
        'Sample_Date_Requirement__c',
        'Allow_Partial_Qty_Shipments__c',
        'Future_Cross_Sell__c',
        'have_you_made_these_parts_before__c',
        'Final_Quote_Email_List__c',
        'Sales_Question_Contact__c',
        'Manufacturing_Location__c',
        'do_you_have_a_price_target_picklist__c'
    };

    public static String getPSEFormFieldName(String name) {
        if (customerFormSlugToPSEFormFieldName.containsKey(name)) {
            return customerFormSlugToPSEFormFieldName.get(name);
        }
        else {
            return null;
        }
    }

    public static List<String> getAllPSEFormDashboardFieldNames() {
        List<String> result = new List<String>();

        result.addAll(customerFormSlugToPSEFormFieldName.values());
        result.addAll(BANTOnlyFields);
        
        return result;
    }
}