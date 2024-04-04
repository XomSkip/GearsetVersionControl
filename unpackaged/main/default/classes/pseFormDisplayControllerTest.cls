@isTest
public class pseFormDisplayControllerTest {
    @isTest
    static void testPseFormWithNoPopulatedFields() {
        Case testCase = TestDataFactory.createTestCases(1, 'Web', 'PSE_Case')[0];

        PSE_Form__c pseForm = new PSE_Form__c(Case__c = testCase.Id);

        insert pseForm;

        Test.startTest();
        pseFormDisplayController.PSEFormFoundResult result = pseFormDisplayController.getPSEQuestionsForCaseId(
            testCase.Id
        );
        Test.stopTest();

        System.assertEquals(result.pseFormId, pseForm.Id);
        // Note this is an important test - it is not only verifying that we
        // behave as expected when a PSEForm is not populated, it is also
        // verifying that our "Null state" - that is, the state from which we
        // will begin to detect whether fields are not null, and thusly
        // determine if they should be displayed - is in fact empty.
        System.assertEquals(result.pseFormFieldNames.size(), 0);
    }

    @isTest
    static void testPseFormWithAPopulatedField() {
        Case testCase = TestDataFactory.createTestCases(1, 'Web', 'PSE_Case')[0];

        PSE_Form__c pseForm = new PSE_Form__c(
            Case__c = testCase.Id,
            Additional_Info__c = 'Here is some additional info!'
        );

        insert pseForm;

        Test.startTest();
        pseFormDisplayController.PSEFormFoundResult result = pseFormDisplayController.getPSEQuestionsForCaseId(
            testCase.Id
        );
        Test.stopTest();

        System.assertEquals(result.pseFormId, pseForm.Id);
        System.assertEquals(result.pseFormFieldNames.size(), 1);
        System.assertEquals(result.pseFormFieldNames[0], 'Additional_Info__c');
    }

    @isTest
    static void testCaseWithNoPSEForm() {
        Case testCase = TestDataFactory.createTestCases(1, 'Web', 'PSE_Case')[0];

        Test.startTest();
        pseFormDisplayController.PSEFormFoundResult result = pseFormDisplayController.getPSEQuestionsForCaseId(
            testCase.Id
        );
        Test.stopTest();

        System.assertEquals(result, null);
    }
}