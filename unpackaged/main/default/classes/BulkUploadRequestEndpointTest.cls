@IsTest
private class BulkUploadRequestEndpointTest {
    @isTest
    static void createRequestNoContact() {
        BulkUploadRequestEndpoint.BulkUploadFiles file1 = new BulkUploadRequestEndpoint.BulkUploadFiles();
        file1.fileLink = '7bce1d07-7615-4d9b-a47a-954a058f629f';
        file1.fileName = 'theFile.pdf';
        BulkUploadRequestEndpoint.BulkUploadFiles file2 = new BulkUploadRequestEndpoint.BulkUploadFiles();
        file2.fileLink = '7bce1d07-7615-4d9b-a47a-954a058f629g';
        file2.fileName = 'Long <File> Name?.stp';
        BulkUploadRequestEndpoint.BulkUploadFiles file3 = new BulkUploadRequestEndpoint.BulkUploadFiles();
        file3.fileLink = '7bce1d07-7615-4d9b-a47a-954a058f629g';
        file3.fileName = 'Boxy Box.stp';
        List<BulkUploadRequestEndpoint.BulkUploadFiles> files = new List<BulkUploadRequestEndpoint.BulkUploadFiles>{
            file1,
            file2,
            file3
        };
        BulkUploadRequestEndpoint.BulkUploadFields previously_ordered = new BulkUploadRequestEndpoint.BulkUploadFields();
        previously_ordered.key = 'previously_ordered_bool__c';
        previously_ordered.value = 'true';
        previously_ordered.type = 'boolean';
        BulkUploadRequestEndpoint.BulkUploadFields est_delivery = new BulkUploadRequestEndpoint.BulkUploadFields();
        est_delivery.key = 'estimated_delivery_date__c';
        est_delivery.value = '2020-05-24';
        est_delivery.type = 'date';
        BulkUploadRequestEndpoint.BulkUploadFields additional_info = new BulkUploadRequestEndpoint.BulkUploadFields();
        additional_info.key = 'additional_information__c';
        additional_info.value = 'Please add whipped cream and a cherry on top.';
        additional_info.type = 'string';
        BulkUploadRequestEndpoint.BulkUploadFields dummy_field = new BulkUploadRequestEndpoint.BulkUploadFields();
        dummy_field.key = 'not_a_real_field';
        dummy_field.value = 'This should not break the endpoint even though it does not exist on PSE form.';
        dummy_field.type = 'string';
        List<BulkUploadRequestEndpoint.BulkUploadFields> responses = new List<BulkUploadRequestEndpoint.BulkUploadFields>{
            previously_ordered,
            est_delivery,
            additional_info,
            dummy_field
        };
        Datetime dt = DateTime.parse('10/14/2011, 11:46 AM');

        Test.startTest();
        BulkUploadRequestEndpoint.BulkUploadResponseObject respObj = BulkUploadRequestEndpoint.createBulkUploadRequest(
            dt,
            'hello@fake.com',
            files,
            responses,
            '5b9bc3d5aa734f0038541b2b',
            '99999',
            'lastName',
            'www.xometry.com'
        );
        Test.stopTest();
        System.debug(respObj);
        System.assert(respObj.success, 'Creation of BulkUploadResponseObject failed');
        System.debug('Case created with ID of ' + respObj.caseID);
        Case thisCase = [
            SELECT Id, OwnerID, Origin, RecordTypeID, SuppliedEmail, PSE_Form__c, ContactId, AccountId
            FROM Case
            WHERE Id = :respObj.caseID
            LIMIT 1
        ];
        PSE_Form__c thisPSE = [
            SELECT Id, previously_ordered_bool__c, Case__c, Part_Links__c
            FROM PSE_Form__c
            WHERE Case__c = :thisCase.Id
            LIMIT 1
        ];
        System.debug(thisPSE.Part_Links__c);
        System.assert(thisCase != null);
        System.assert(thisPSE != null);
        System.assertEquals('Bulk Upload', thisCase.Origin);
        System.assertEquals(true, thisPSE.previously_ordered_bool__c);
        System.assertEquals(thisPSE.ID, thisCase.PSE_Form__c);
        System.assertEquals(thisCase.ID, thisPSE.Case__c);

        Contact thisContact = [
            SELECT Id, LeadSource, AccountId, OwnerId
            FROM Contact
            WHERE Primary_Email__c = :thisCase.SuppliedEmail
            LIMIT 1
        ];
        System.assert(thisContact != null);
        System.assert(thisContact.AccountId != null);
        System.assertEquals('Quoter', thisContact.LeadSource);
        System.assertEquals(thisCase.ContactId, thisContact.Id);
        System.assertEquals(thisCase.AccountID, thisContact.AccountId);
        System.assertEquals(thisCase.OwnerId, thisContact.OwnerId);
    }

    @isTest
    static void createRequestWithContact() {
        BulkUploadRequestEndpoint.BulkUploadFiles file1 = new BulkUploadRequestEndpoint.BulkUploadFiles();
        file1.fileLink = '7bce1d07-7615-4d9b-a47a-954a058f629f';
        file1.fileName = 'theFile.pdf';
        BulkUploadRequestEndpoint.BulkUploadFiles file2 = new BulkUploadRequestEndpoint.BulkUploadFiles();
        file2.fileLink = '7bce1d07-7615-4d9b-a47a-954a058f629g';
        file2.fileName = 'anotherFile.stp';
        BulkUploadRequestEndpoint.BulkUploadFiles file3 = new BulkUploadRequestEndpoint.BulkUploadFiles();
        file3.fileLink = '7bce1d07-7615-4d9b-a47a-954a058f629h';
        file3.fileName = 'moreFiles.dxf';
        List<BulkUploadRequestEndpoint.BulkUploadFiles> files = new List<BulkUploadRequestEndpoint.BulkUploadFiles>{
            file1,
            file2,
            file3
        };
        BulkUploadRequestEndpoint.BulkUploadFields manufacturing = new BulkUploadRequestEndpoint.BulkUploadFields();
        manufacturing.key = 'Manufacturing_Approach__c';
        manufacturing.value = '3d printing';
        manufacturing.type = 'string';
        List<BulkUploadRequestEndpoint.BulkUploadFields> responses = new List<BulkUploadRequestEndpoint.BulkUploadFields>{
            manufacturing
        };
        Datetime dt = DateTime.parse('10/27/2022, 11:46 AM');

        List<Account> newAccounts = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 1, 0);
        String email = [SELECT Email FROM Contact LIMIT 1][0].Email;

        Test.startTest();
        BulkUploadRequestEndpoint.BulkUploadResponseObject respObj = BulkUploadRequestEndpoint.createBulkUploadRequest(
            dt,
            email,
            files,
            responses,
            '5235235325325325325',
            '07787',
            'Doe',
            'www.xometry.com'
        );
        Test.stopTest();

        System.assert(respObj.success, 'Creation of BulkUploadResponseObject failed');
        Case thisCase = [
            SELECT SuppliedEmail, AccountId, ContactId, OwnerId
            FROM Case
            WHERE Id = :respObj.caseID
            LIMIT 1
        ];
        Contact thisContact = [SELECT Name, Email, OwnerId FROM Contact WHERE Id = :thisCase.ContactId];
        Account thisAccount = [SELECT Name FROM Account WHERE Id = :thisCase.AccountId];
        System.assertEquals('John Doe0', thisContact.Name);
        System.assertEquals(thisCase.SuppliedEmail, thisContact.Email);
        System.assertEquals('TestAccount0', thisAccount.Name);
        System.assertEquals(thisCase.OwnerId, thisContact.OwnerId);
    }
}