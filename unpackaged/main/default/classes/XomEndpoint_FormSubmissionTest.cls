@isTest
public with sharing class XomEndpoint_FormSubmissionTest {
    @isTest
    static void submitFormFromEndpointBasic() {
        Test.startTest();
        XomEndpoint_FormSubmission.FormSubmissionResponse lr = XomEndpoint_FormSubmission.submitForm(
            'LastName',
            'Other',
            'test@email.com',
            'Test Company',
            new List<XomEndpoint_FormSubmission.FormDataField>{
                new XomEndpoint_FormSubmission.FormDataField(
                    'Contact_Form_Status__c',
                    'New/Unresolved',
                    'String',
                    'Update'
                ),
                new XomEndpoint_FormSubmission.FormDataField(
                    'Contact_Form_Submission_Links__c',
                    'New link',
                    'String',
                    'Append'
                )
            }
        );
        Test.stopTest();

        List<Lead> lResults = [SELECT Id FROM Lead];
        System.assertEquals(lr.ResourceId, lResults[0].Id, 'The lead found should match the results');
    }

    @isTest
    static void submitFormFromEndpointFail() {
        Test.startTest();
        XomEndpoint_FormSubmission.FormSubmissionResponse lr = XomEndpoint_FormSubmission.submitForm(
            '',
            'Other',
            'test@email.com',
            'Test Company',
            new List<XomEndpoint_FormSubmission.FormDataField>()
        );
        Test.stopTest();

        System.assert(lr.Status != 'Success', 'The response should have an error');
    }

    @isTest
    static void submitFormFromEndpointDup() {
        Lead l = new Lead(
            LastName = 'LastName',
            LeadSource = 'Other',
            Email = 'test@email.com',
            Company = 'Test Company'
        );
        insert l;
        Test.startTest();
        XomEndpoint_FormSubmission.FormSubmissionResponse lr = XomEndpoint_FormSubmission.submitForm(
            'LastName',
            'Other',
            'test@email.com',
            'Test Company',
            new List<XomEndpoint_FormSubmission.FormDataField>()
        );
        Test.stopTest();

        List<Lead> lResults = [SELECT Id FROM Lead];
        System.assert(lr.Status == 'Success', 'The response should be a success');
        System.assertEquals(l.Id, lr.ResourceId, 'The first lead should be returned');
    }

    @isTest
    static void submitFormFromEndpointContact() {
        Account a = TestDataFactory.createTestAccountGenerics(1, 'BDR')[0];
        Contact c = [SELECT Id, LastName, Email FROM Contact][0];
        Test.startTest();
        XomEndpoint_FormSubmission.FormSubmissionResponse lr = XomEndpoint_FormSubmission.submitForm(
            c.LastName,
            'Other',
            c.Email,
            a.Email_Domain__c,
            new List<XomEndpoint_FormSubmission.FormDataField>()
        );
        Test.stopTest();

        List<Contact> cResults = [SELECT Id FROM Contact];
        System.assertEquals(lr.ResourceId, cResults[0].Id, 'The contact returned should match the results');
    }

    @isTest
    static void submitFormFromEndpointUpdate() {
        XomEndpoint_FormSubmission.submitForm(
            'LastName',
            'Other',
            'test@email.com',
            'Test Company',
            new List<XomEndpoint_FormSubmission.FormDataField>{
                new XomEndpoint_FormSubmission.FormDataField(
                    'Contact_Form_Status__c',
                    'New/Unresolved',
                    'String',
                    'Update'
                ),
                new XomEndpoint_FormSubmission.FormDataField(
                    'Contact_Form_Submission_Links__c',
                    'Link 1',
                    'String',
                    'Append'
                )
            }
        );

        Test.startTest();
        XomEndpoint_FormSubmission.FormSubmissionResponse lr = XomEndpoint_FormSubmission.submitForm(
            'LastName',
            'Other',
            'test@email.com',
            'Test Company',
            new List<XomEndpoint_FormSubmission.FormDataField>{
                new XomEndpoint_FormSubmission.FormDataField(
                    'Contact_Form_Status__c',
                    'New/Unresolved',
                    'String',
                    'Update'
                ),
                new XomEndpoint_FormSubmission.FormDataField(
                    'Contact_Form_Submission_Links__c',
                    'Link 2',
                    'String',
                    'Append'
                )
            }
        );
        Test.stopTest();

        List<Lead> lResults = [SELECT Id, Contact_Form_Submission_Links__c FROM Lead];
        System.assertEquals(lr.ResourceId, lResults[0].Id, 'The lead found should match the results');
        System.assertEquals(
            'Link 2<br/>Link 1'.stripHtmlTags(),
            lResults[0].Contact_Form_Submission_Links__c.stripHtmlTags(),
            'Field should have both values'
        );
    }
}