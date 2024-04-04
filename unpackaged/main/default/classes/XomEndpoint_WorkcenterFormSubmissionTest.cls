@isTest
public class XomEndpoint_WorkcenterFormSubmissionTest {

    @isTest
    static void createCaseFromWorkcenterBasic() {
        Job__c j = TestDataFactory.createJobWithSupplier();
        insert j;
        Supplier__c s = [SELECT Id, PartnerID__c, ContactId__c FROM Supplier__c][0];

        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission.FormResponse fr = XomEndpoint_WorkcenterFormSubmission.createCaseFromSubmission(
            'test@email.com',
            'test-form-id',
            'Workcenter',
            'Partner Portal',
            'P-Test',
            'Test-Job',
            'Subject',
            'None Submitted',
            'CaseMgmt',
            new List<XomEndpoint_WorkcenterFormSubmission.FormDataField>()
        );
        Test.stopTest();

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c FROM Case][0];
        System.assertEquals(cRes.Id, fr.CaseId, 'CaseId was not returned');
        System.assertEquals(s.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(s.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(j.Id, cRes.Job__c, 'Should have lookup to correct job');
    }

    @isTest
    static void createCaseFromWorkcenterOther() {
        Job__c j = TestDataFactory.createJobWithSupplier();
        insert j;
        Supplier__c s = [SELECT Id, PartnerID__c, ContactId__c FROM Supplier__c][0];

        List<XomEndpoint_WorkcenterFormSubmission.FormDataField> otherFields = new List<XomEndpoint_WorkcenterFormSubmission.FormDataField>{
            new XomEndpoint_WorkcenterFormSubmission.FormDataField(
                'Additional_VQC_Email__c',
                'email@test.com',
                'string'
            )
        };
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission.FormResponse fr = XomEndpoint_WorkcenterFormSubmission.createCaseFromSubmission(
            'email@tester.com',
            'test-form-id',
            'Workcenter',
            'Partner Portal',
            'P-Test',
            'Test-Job',
            'Subject',
            'None Submitted',
            'VQC_Case',
            otherFields
        );
        Test.stopTest();

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, Additional_VQC_Email__c FROM Case][0];
        System.assertEquals(cRes.Id, fr.CaseId, 'CaseId was not returned');
        System.assertEquals(s.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(s.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(j.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(
            'email@test.com',
            cRes.Additional_VQC_Email__c,
            'The case should have the other field populated'
        );
    }

    @isTest
    static void createCaseFromWorkcenterBasicV3() {

        RestRequest req = new RestRequest();
        req.requestURI = 'https://xometrytest.com/api/WorkcenterFormSubmission/v3/';
        RestContext.request = req;

        Job__c j = TestDataFactory.createJobWithSupplier();
        insert j;
        Supplier__c s = [SELECT Id, PartnerID__c, ContactId__c FROM Supplier__c][0];

        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_v3.FormResponse fr = XomEndpoint_WorkcenterFormSubmission_v3.createCaseFromSubmission(
            'test@email.com',
            'test-form-id',
            'Workcenter',
            'Partner Portal',
            'P-Test',
            'Test-Job',
            'Subject',
            'None Submitted',
            'CaseMgmt',
            'TestCategory',
            'CM',
            String.valueOf(System.today()),
            'submittername',
            'submitter@notxometry.com',
            new List<XomEndpoint_WorkcenterFormSubmission_v3.FormDataField>()
        );
        Test.stopTest();

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c FROM Case][0];
        System.assertEquals(cRes.Id, fr.CaseId, 'CaseId was not returned');
        System.assertEquals(s.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(s.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(j.Id, cRes.Job__c, 'Should have lookup to correct job');
    }

    static Map<Id,Group> queues
            = new Map<Id,Group>([SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']);

    // (Case: Case Origin EQUALS Workcenter) AND (Case: Type EQUALS Ask a Question) => First Impression
    @IsTest
    static void createCaseFromWorkcenter_NonVQC_CM_First_Impressions() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String workcenterType = 'Ask a Question';
        String relatedOrderPod = 'First_Impressions';
        String recordTypeDeveloperName = 'CaseMgmt';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c firstImpressionOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,firstImpressionOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        workcenterType,
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c, Type,
                Work_Center_Category__c, RecordTypeId, OwnerId, GNO_PODOpsOrder__c
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(firstImpressionOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assertEquals(relatedOrderPod, queues.get(cRes.OwnerId).DeveloperName, 'First impressions queue should own case');
    }

    // (Case: Case Origin EQUALS Workcenter) AND (Case: Type EQUALS VQC) => Quality Control Queue
    @IsTest
    static void createCaseFromWorkcenter_NonVQC_CM_First_QCQ() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String workcenterType = 'Ask a Question';
        String relatedOrderPod = 'First_Impressions';
        String recordTypeDeveloperName = 'VQC_Case';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c firstImpressionOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,firstImpressionOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        workcenterType,
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c, Type,
                Work_Center_Category__c, RecordTypeId, OwnerId, GNO_PODOpsOrder__c
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(firstImpressionOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assertEquals(relatedOrderPod, queues.get(cRes.OwnerId).DeveloperName, 'Quality control queue should own case');
    }

    // (Case: Case Origin EQUALS Workcenter) AND (Case: POD On Ops Order EQUALS First Impressions) => First Impression
    @IsTest
    static void createCaseFromWorkcenter_NonVQC_CM_First_Impressions2() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String workcenterType = 'Ask a Question';
        String relatedOrderPod = 'First_Impressions';
        String recordTypeDeveloperName = 'CaseMgmt';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c firstImpressionOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,firstImpressionOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        workcenterType,
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c, Type,
                Work_Center_Category__c, RecordTypeId, OwnerId, GNO_PODOpsOrder__c
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(firstImpressionOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assertEquals(relatedOrderPod, queues.get(cRes.OwnerId).DeveloperName, 'First impressions queue should own case');
    }

    // (Case: Case Origin EQUALS Workcenter) AND (Case: POD On Ops Order EQUALS SpaceTechs) => SpaceTechs
    @IsTest
    static void createCaseFromWorkcenter_NonVQC_CM_Space_Techs() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String workcenterType = 'Out of Spec';
        String relatedOrderPod = 'SpaceTechs';
        String recordTypeDeveloperName = 'CaseMgmt';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c firstImpressionOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,firstImpressionOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        workcenterType,
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c, Type,
                Work_Center_Category__c, RecordTypeId, OwnerId, GNO_PODOpsOrder__c
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(firstImpressionOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assertEquals(relatedOrderPod, queues.get(cRes.OwnerId).DeveloperName, 'Space techs queue should own case');
    }

    // (Case: Case Origin EQUALS Workcenter) AND (Case: POD On Ops Order EQUALS Automotive) => Automotive
    @IsTest
    static void createCaseFromWorkcenter_NonVQC_Automotive() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String relatedOrderPod = 'Automotive';
        String recordTypeDeveloperName = 'CaseMgmt';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c automotiveOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,automotiveOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        'Partner Portal',
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c,
                Work_Center_Category__c, RecordTypeId, OwnerId
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(automotiveOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assertEquals(relatedOrderPod, queues.get(cRes.OwnerId).DeveloperName, 'Automotive Queue should own case');
    }

    // (Case: Case Origin EQUALS Workcenter) AND (Case: POD On Ops Order EQUALS Impodsters) => Impodsters
    @IsTest
    static void createCaseFromWorkcenter_NonVQC_Impodsters() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String relatedOrderPod = 'Impodsters';
        String groupDeveloperName = 'Impodsters';
        String recordTypeDeveloperName = 'CaseMgmt';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c automotiveOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,automotiveOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        'Partner Portal',
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c,
                Work_Center_Category__c, RecordTypeId, OwnerId
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals('IMpodsters', cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assert(groupDeveloperName.equalsIgnoreCase(queues.get(cRes.OwnerId).DeveloperName),
                'Impodsters queue should own case');
    }

    // (Case: Case Origin EQUALS Workcenter) AND (Case: POD On Ops Order EQUALS Atomic Rocks) => Atomic Rocks
    @IsTest
    static void createCaseFromWorkcenter_NonVQC_AtomicRocks() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String relatedOrderPod = 'Atomic Rocks';
        String groupDeveloperName = 'Atomic_Rocks';
        String recordTypeDeveloperName = 'CaseMgmt';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c automotiveOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,automotiveOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        'Partner Portal',
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c,
                Work_Center_Category__c, RecordTypeId, OwnerId
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(automotiveOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assertEquals(groupDeveloperName, queues.get(cRes.OwnerId).DeveloperName, 'atomic rocks queue should own case');
    }

    // (Case: Case Origin EQUALS Workcenter) AND (Case: POD On Ops Order EQUALS Triple Threat) => Triple Threat
    @IsTest
    static void createCaseFromWorkcenter_NonVQC_TripleThreat() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String relatedOrderPod = 'Triple Threat';
        String groupDeveloperName = 'Triple_Threat';
        String recordTypeDeveloperName = 'CaseMgmt';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c automotiveOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,automotiveOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        'Partner Portal',
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c,
                Work_Center_Category__c, RecordTypeId, OwnerId
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(automotiveOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assertEquals(groupDeveloperName, queues.get(cRes.OwnerId).DeveloperName, 'triple threat queue should own case');
    }

    // (Case: Case Origin EQUALS Workcenter) AND (Case: POD On Ops Order EQUALS Additive POD) => Additive POD
    @IsTest
    static void createCaseFromWorkcenter_AdditivePOD() {
        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        String relatedOrderPod = 'Amazing';
        String groupDeveloperName = 'Additive';
        String recordTypeDeveloperName = 'CaseMgmt';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c automotiveOrder = createAndInsertOrderByPod(relatedOrderPod);
        Job__c job = createRelatedJob(jobId,automotiveOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        'Partner Portal',
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c,
                Work_Center_Category__c, RecordTypeId, OwnerId
        FROM Case
        WHERE Id = :fr.CaseId];

        Id caseManagerRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(automotiveOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(caseManagerRecordTypeId, cRes.RecordTypeId, 'Should be case manager record type');
        Assert.isNotNull(cRes.OwnerId,'Case should have an owner');
        System.assertEquals(groupDeveloperName, queues.get(cRes.OwnerId).DeveloperName, 'additive queue should own case');
    }


    @IsTest
    static void createCaseFromWorkcenter_VQC() {

        // Arrange
        String jobId = 'Test-Job';
        String partnerId = 'P-Test';
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'POD/DFM';
        String recordTypeDeveloperName = 'VQC_Case';
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        Ops_Order__c automotiveOrder = createAndInsertOrderByPod('Automotive');
        Job__c job = createRelatedJob(jobId,automotiveOrder.Id);
        Supplier__c supplier = createAndInsertPartnerById(partnerId);

        // Act
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse
                fr = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        'Partner Portal',
                        partnerId,
                        jobId,
                        'Subject',
                        'None Submitted',
                        recordTypeDeveloperName,
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>());
        Test.stopTest();

        // Assert
        supplier = [SELECT Id, PartnerID__c, ContactID__c
        FROM Supplier__c
        WHERE Id = :supplier.Id];

        Case cRes = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Work_Center_Category__c,
                Who_In_Pod__c, RecordTypeId
        FROM Case
        WHERE Id = :fr.CaseId];

        Id dmRecordTypeId
                = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                        .get(recordTypeDeveloperName)
                        .getRecordTypeId();

        System.assertEquals(category, cRes.Work_Center_Category__c, 'Work center category populated');
        System.assertEquals(whoInPod, cRes.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(automotiveOrder.POD__c, cRes.POD__c, 'Case pod is the same as the related order pod');
        System.assertEquals(supplier.Id, cRes.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cRes.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cRes.Job__c, 'Should have lookup to correct job');
        System.assertEquals(dmRecordTypeId, cRes.RecordTypeId, 'Should be VQC record type');
    }

    @IsTest
    static void createCaseFromWorkcenter_OtherFields() {
        String category = 'Can\'t Find it / Substitution Request';
        String whoInPod = 'CM';
        Job__c job = TestDataFactory.createJobWithSupplier();
        insert job;
        Supplier__c supplier = [SELECT Id, PartnerID__c, ContactID__c FROM Supplier__c][0];
        String submitterName = 'Tester Name';
        String submitterEmail = 'tester.name@xometry.fake';
        String estCompletedDate = '2023-11-15';

        List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField> otherFields
                = new List<XomEndpoint_WorkcenterFormSubmission_V3.FormDataField>{
                        new XomEndpoint_WorkcenterFormSubmission_V3.FormDataField(
                                'Additional_VQC_Email__c',
                                'email@test.com',
                                'string'
                        )
                };
        Test.startTest();
        XomEndpoint_WorkcenterFormSubmission_V3.FormResponse fr
                = XomEndpoint_WorkcenterFormSubmission_V3.createCaseFromSubmission(
                        'email@tester.com',
                        'test-form-id',
                        'Workcenter',
                        'Partner Portal',
                        'P-Test',
                        'Test-Job',
                        'Subject',
                        'None Submitted',
                        'VQC_Case',
                        category,
                        whoInPod,
                        estCompletedDate,
                        submitterName,
                        submitterEmail,
                        otherFields
                );
        Test.stopTest();

        Case cse = [SELECT Id, Supplier__c, ContactId, Job__c, POD__c, Who_In_Pod__c,
                Work_Center_Category__c, RecordTypeId, OwnerId, Additional_VQC_Email__c
        FROM Case
        WHERE Id = :fr.CaseId];
        System.assertEquals(category, cse.Work_Center_Category__c, 'Work center category is populated');
        System.assertEquals(whoInPod, cse.Who_In_Pod__c, 'Who In Pod populated');
        System.assertEquals(supplier.Id, cse.Supplier__c, 'Should have lookup to correct supplier');
        System.assertEquals(supplier.ContactID__c, cse.ContactId, 'Should have lookup to correct contact');
        System.assertEquals(job.Id, cse.Job__c, 'Should have lookup to correct job');
        System.assertEquals('email@test.com', cse.Additional_VQC_Email__c,
                'The case should have the other field populated'
        );
    }

    private static Job__c createRelatedJob(String jobId, Id relatedOrderId) {
        Job__c job= new Job__c();
        job.Name = jobId;
        job.XometryJobID__c = jobId;
        job.XometryOpsOrderID__c = '1234';
        insert job;
        job.OrderID__c = relatedOrderId;
        update job;
        return job;
    }

    private static Supplier__c createAndInsertPartnerById(String partnerId) {
        Supplier__c partner = new Supplier__c();
        partner.PartnerID__c =  partnerId;
        partner.SupplierCompanyName__c = 'P-Test';
        partner.EmailAddress__c = 'email@tester.com';
        partner.LastName__c = 'Supplier';
        insert partner;
        return partner;
    }

    private static Ops_Order__c createAndInsertOrderByPod(String podName) {
        Ops_Order__c order = new Ops_Order__c();
        order.Name = 'AAAA2-00001';
        order.XometryOpsOrderID__c = 'AAAA2-00001';
        order.POD__c = podName;
        insert order;
        return order;
    }

}