@IsTest
private class XomEndpoint_PartnerPortalResourceTest {
    @isTest
    static void createPartnerPortalCaseTest() {
        ID thisCaseId = XomEndpoint_PartnerPortalResource.createPartnerPortalCase(
            'partneremail@test.com',
            'issue',
            'Finishing Issue',
            'Cannot Find',
            'Parter Issue - J0012345 - Finishing Issue - Cannot Find - Fabrication Started',
            'I tried to use my local finisher but they would take too long',
            'J0012345',
            '5b9bc3d5aa734f0038541b2b',
            '0123ABCE',
            '12345-12345',
            true,
            false,
            '0A785fTr04b781sl8xUFW8'
        );
        System.assert(thisCaseId != null);
        Case thisCase = [SELECT Id, Subject, RecordTypeID FROM Case WHERE Id = :thisCaseId];
        System.assert(thisCase != null);
        System.assertEquals(
            thisCase.Subject,
            'Parter Issue - J0012345 - Finishing Issue - Cannot Find - Fabrication Started',
            'The subject was not updated'
        );
        System.assertEquals(AppConstants.caseManagementRTypeId, thisCase.RecordTypeID, 'Case record type is not CM');
    }

    @isTest
    static void handleDuplicatePartnerPortalCaseTest() {
        String thirdPartyEventID = '0A785fTr04b781sl8xUFW8';
        ID thisCaseId = XomEndpoint_PartnerPortalResource.createPartnerPortalCase(
            'partneremail@test.com',
            'issue',
            'Finishing Issue',
            'Cannot Find',
            'Parter Issue - J0012345 - Finishing Issue - Cannot Find - Fabrication Started',
            'I tried to use my local finisher but they would take too long',
            'J0012345',
            '5b9bc3d5aa734f0038541b2b',
            '0123ABCE',
            '12345-12345',
            true,
            false,
            thirdPartyEventID
        );
        ID duplicateCaseId = XomEndpoint_PartnerPortalResource.createPartnerPortalCase(
            'partneremail@test.com',
            'issue',
            'Finishing Issue',
            'Cannot Find',
            'Parter Issue - J0012345 - Finishing Issue - Cannot Find - Fabrication Started',
            'I tried to use my local finisher but they would take too long',
            'J0012345',
            '5b9bc3d5aa734f0038541b2b',
            '0123ABCE',
            '12345-12345',
            true,
            false,
            thirdPartyEventID
        );

        System.assert(duplicateCaseId != null);
        List<Case> newCaseList = new List<Case>(
            [SELECT Id FROM Case WHERE ThirdPartyCreationID__c = :thirdPartyEventID]
        );
        System.assertEquals(1, newCaseList.size(), 'A duplicate PP case was created');
    }
}