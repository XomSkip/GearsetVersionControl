@IsTest
private class XomEndpoint_UserInfo_Test {

    @IsTest
    static void happyPath_createContact(){
        // Arrange
        XomEndpoint_UserInfo.UserInformation erpPayload
                = new XomEndpoint_UserInfo.UserInformation();
        erpPayload.xometryUserId = 'Picard-47-Alpha-Tango';
        erpPayload.firstName = 'Jean-Luc';
        erpPayload.lastName = 'Picard';
        erpPayload.email = 'bald.eagle@ncc1701d.com';

        setupIncomingRequestFromERP(erpPayload);

        // Act
        Test.startTest();
            XomEndpoint_UserInfo.writeCustomerRegistration();
        Test.stopTest();

        // Assert
        Contact createdCustomerRecord
                = [SELECT Id, FirstName, LastName, Primary_Email__c, LeadSource, Xometry_ERP_Contact_ID__c, OwnerId
                   FROM Contact
                   WHERE Primary_Email__c = :erpPayload.email];

        // CRITERIA(1/2): The contact record was correctly generated
        System.assertEquals(erpPayload.firstName,createdCustomerRecord.FirstName,
                'First name should be populated with erp first name');
        System.assertEquals(erpPayload.lastName,createdCustomerRecord.LastName,
                'Last name should be populated with erp last name');
        System.assertEquals(erpPayload.email,createdCustomerRecord.Primary_Email__c,
                'Email should be populated with erp email');
        System.assertEquals(erpPayload.xometryUserId,createdCustomerRecord.Xometry_ERP_Contact_ID__c,
                'ERP_Contact_ID__c should be populated with crc house user');
        System.assertEquals('Registered User',createdCustomerRecord.LeadSource,
                'Lead source should be registered user.');
        System.assertEquals(AppConstants.CPC_HOUSE_USER,createdCustomerRecord.OwnerId,
                'Owner Id should be CPC user');

        // CRITERIA(2/2): Proper response is returned on the outgoing response
        System.assertEquals(200, RestContext.response.statusCode,'HTTP response status indicates success');
        System.assertEquals(erpPayload.xometryUserId,
                RestContext.response.responseBody.toString(),
                'HTTP response status indicates the record update succeeded');
    }

    @IsTest
    static void happyPath_updateContact(){
        // Arrange
        XomEndpoint_UserInfo.UserInformation erpPayload
                = new XomEndpoint_UserInfo.UserInformation();
        erpPayload.xometryUserId = 'Picard-47-Alpha-Tango-Update';
        erpPayload.firstName = 'Jean-Luc';
        erpPayload.email = 'bald.eagle@ncc1701d.com';

        setupIncomingRequestFromERP(erpPayload);

        Contact relatedCustomerRecord = new Contact(
            Primary_Email__c = 'bald.eagle@ncc1701d.com',  // <--- Unique identifier is email
            LastName = 'Picard',
            Xometry_ERP_Contact_ID__c = 'Picard-47-Alpha-Tango'
        );
        insert relatedCustomerRecord;

        // Act
        Test.startTest();
            XomEndpoint_UserInfo.writeCustomerRegistration();
        Test.stopTest();

        // Assert
        Contact updatedCustomerRecord
                = [SELECT Id, FirstName, LastName, Primary_Email__c, LeadSource, Xometry_ERP_Contact_ID__c
                   FROM Contact
                   WHERE Primary_Email__c = :erpPayload.email];

        // CRITERIA(1/2): The contact record was correctly updated
        System.assertEquals(erpPayload.firstName,updatedCustomerRecord.FirstName,
                'First name should be populated with erp first name');
        System.assertNotEquals(erpPayload.xometryUserId,updatedCustomerRecord.Xometry_ERP_Contact_ID__c,
                'ERP Id should not have been updated');  // <-- THIS FIELD IS NOT UPDATABLE ONCE SET -->
        System.assertEquals(relatedCustomerRecord.LastName,updatedCustomerRecord.LastName,
                'Last name should not have changed');
        System.assertEquals(relatedCustomerRecord.Primary_Email__c,updatedCustomerRecord.Primary_Email__c,
                'Email should not have changed');

        // CRITERIA(2/2): Proper response is returned on the outgoing response
        System.assertEquals(200, RestContext.response.statusCode,'HTTP response status indicates success');
        System.assertEquals(erpPayload.xometryUserId,
                RestContext.response.responseBody.toString(),
                'HTTP response status indicates the record update succeeded');
    }


    @IsTest
    static void happyPath_noDestructiveUpdate(){
        // Arrange
        XomEndpoint_UserInfo.UserInformation erpPayload
                = new XomEndpoint_UserInfo.UserInformation();
        erpPayload.xometryUserId = 'Picard-47-Alpha-Tango';
        erpPayload.firstName = '';
        erpPayload.lastName = '';
        erpPayload.email = 'bald.eagle@ncc1701d.com';

        setupIncomingRequestFromERP(erpPayload);

        Contact customerRecordBeforeUpdate = new Contact(
            Primary_Email__c = 'bald.eagle@ncc1701d.com',
            Xometry_ERP_Contact_ID__c = 'Picard-47-Alpha-Tango',
            FirstName = 'Jean-Luc',
            LastName = 'Picard'
        );
        insert customerRecordBeforeUpdate;

        // Act
        Test.startTest();
            XomEndpoint_UserInfo.writeCustomerRegistration();
        Test.stopTest();

        // Assert
        Contact updatedCustomerRecord
                = [SELECT Id, FirstName, LastName, Primary_Email__c, LeadSource, Xometry_ERP_Contact_ID__c
                   FROM Contact
                   WHERE Primary_Email__c = :erpPayload.email];

        // CRITERIA(1/2): The contact record was correctly updated
        System.assertEquals(customerRecordBeforeUpdate.FirstName,updatedCustomerRecord.FirstName,
                'First name should not have changed');
        System.assertEquals(customerRecordBeforeUpdate.LastName,updatedCustomerRecord.LastName,
                'Last name should not have changed');
        System.assertEquals(customerRecordBeforeUpdate.Primary_Email__c,updatedCustomerRecord.Primary_Email__c,
                'Email should not have changed');
        System.assertEquals(customerRecordBeforeUpdate.Xometry_ERP_Contact_ID__c,updatedCustomerRecord.Xometry_ERP_Contact_ID__c,
                'ERP Id should not have changed');

        // CRITERIA(2/2): Proper response is returned on the outgoing response
        System.assertEquals(200, RestContext.response.statusCode,'HTTP response status indicates success');
        System.assertEquals(erpPayload.xometryUserId,
                RestContext.response.responseBody.toString(),
                'HTTP response status indicates the record update succeeded');
    }

    @IsTest
    static void errorPath_noPayload(){
        // Arrange
        setupIncomingRequestFromERP(null);

        // Act
        Test.startTest();
            XomEndpoint_UserInfo.writeCustomerRegistration();
        Test.stopTest();

        // Assert
        System.assertEquals(400,RestContext.response.statusCode,'HTTP response status should indicate bad request');

        System.assertEquals('No data was found with this request.',
                getError(RestContext.response).description,
                'Error description should indicate that no data was sent with the request');
    }

    @IsTest
    static void errorPath_emptyPayload(){
        // Arrange
        Contact customer = new Contact(
            Xometry_ERP_Contact_ID__c = 'Picard-47-Alpha-Tango',
            FirstName = 'James',
            LastName = 'Kirk',
            Primary_Email__c = 'its.not.a.toupee@ncc1701.com',
            LeadSource = 'Earth'
        );
        insert customer;

        XomEndpoint_UserInfo.UserInformation erpRecordWithEmptyPayload
                = new XomEndpoint_UserInfo.UserInformation();

        setupIncomingRequestFromERP(erpRecordWithEmptyPayload);

        // Act
        Test.startTest();
            XomEndpoint_UserInfo.writeCustomerRegistration();
        Test.stopTest();

        // Assert
        System.assertEquals(400, RestContext.response.statusCode,'HTTP response status indicates failure');
        System.assertEquals('The following required fields are missing: xometryUserId, email',
               getError(RestContext.response).description,
               'Error description lists all of the missing data');
    }

    @IsTest
    static void errorPath_missingEmailAddress(){
        // Arrange
        Contact customer = new Contact(
                Xometry_ERP_Contact_ID__c = 'Picard-47-Alpha-Tango',
                FirstName = 'James',
                LastName = 'Kirk',
                Primary_Email__c = 'its.not.a.toupee@ncc1701.com',
                LeadSource = 'Earth'
        );
        insert customer;

        XomEndpoint_UserInfo.UserInformation erpRecordWithMissingData  = new XomEndpoint_UserInfo.UserInformation();
        erpRecordWithMissingData.xometryUserId = 'Picard-47-Alpha-Tango';

        setupIncomingRequestFromERP(erpRecordWithMissingData);

        // Act
        Test.startTest();
            XomEndpoint_UserInfo.writeCustomerRegistration();
        Test.stopTest();

        // Assert
        System.assertEquals(400, RestContext.response.statusCode,'HTTP response status indicates failure');
        System.assertEquals('The following required fields are missing: email',
                getError(RestContext.response).description,
                'Error description lists all of the missing data');
    }

    private static XomEndpoint_UserInfo.Error getError(RestResponse response) {
        String resBody = response.responseBody.toString();
        return  (XomEndpoint_UserInfo.Error)JSON.deserialize(resBody,XomEndpoint_UserInfo.Error.class);
    }

    private static void setupIncomingRequestFromERP(XomEndpoint_UserInfo.UserInformation data) {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestURI = '/services/apexrest/UserInfo/';
        RestContext.request.httpMethod = 'PATCH';
        RestContext.request.requestBody = Blob.valueOf(JSON.serializePretty(data));
    }

}