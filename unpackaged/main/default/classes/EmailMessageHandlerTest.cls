@isTest
private class EmailMessageHandlerTest {
    static Id caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('CaseMgmt')
        .getRecordTypeID();
    static Id caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('DFM_Case')
        .getRecordTypeID();
    static Id caseGeneralRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('GeneralSupportCase')
        .getRecordTypeID();
    static final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Supplies')
        .getRecordTypeID();

    @isTest(seeAllData=false)
    static void processSLAFlagsTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseManagementRTypeId;
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        insert emailTest;

        EmailMessage emailTest2 = new EmailMessage();
        emailTest2.Incoming = true;
        emailTest2.ParentId = caseTest.Id;
        insert emailTest2;

        EmailMessage emailTest3 = new EmailMessage();
        emailTest3.Incoming = false;
        emailTest3.ParentId = caseTest.Id;
        insert emailTest3;

        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Email_Pending_SLA__c FROM Case WHERE Id = :caseTest.Id].Email_Pending_SLA__c,
            'Datetime should be cleaned.'
        );
    }

    @isTest(seeAllData=false)
    static void processSLAFlagsTest2() {
        Case caseTest = new Case();
        caseTest.Priority = 'High';
        caseTest.Origin = 'Phone';
        caseTest.RecordTypeId = caseDFMRTypeId;
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        insert emailTest;

        EmailMessage emailTest2 = new EmailMessage();
        emailTest2.Incoming = false;
        emailTest2.ParentId = caseTest.Id;
        insert emailTest2;

        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Email_Pending_SLA__c FROM Case WHERE Id = :caseTest.Id].Email_Pending_SLA__c,
            'Datetime should be cleaned.'
        );
    }

    @isTest(seeAllData=false)
    static void processSLAFlagsTest3() {
        Case caseTest = new Case();
        caseTest.Priority = 'High';
        caseTest.Origin = 'Phone';
        caseTest.RecordTypeId = caseDFMRTypeId;
        caseTest.IsPartnerSupplier__c = false;
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        insert emailTest;

        EmailMessage emailTest2 = new EmailMessage();
        emailTest2.Incoming = false;
        emailTest2.ParentId = caseTest.Id;
        insert emailTest2;

        EmailMessage emailTest3 = new EmailMessage();
        emailTest3.Incoming = true;
        emailTest3.ParentId = caseTest.Id;
        insert emailTest3;

        Test.stopTest();

        caseTest = [SELECT Email_Pending_SLA__c, Next_SLA_End__c FROM Case WHERE Id = :caseTest.Id];

        System.assertNotEquals(null, caseTest.Email_Pending_SLA__c, 'Flag should be updated.');

        Id businessHoursId = [
            SELECT Id, Name, MondayEndTime
            FROM BusinessHours
            WHERE Name = 'Sourcing Team Business Hours'
        ]
        .Id;

        //SLA 2: Response to inbound CUSTOMER related cases with a priority of High/Urgent within 2 business hrs
        Integer businessHours = 2;
        Datetime newSLADate = System.BusinessHours.add(businessHoursId, System.now(), businessHours * 60 * 60 * 1000);

        System.assertEquals(newSLADate, caseTest.Next_SLA_End__c, 'Datetime should be updated.');
    }

    @isTest(seeAllData=false)
    static void processSLAFlagsResetOnCloseTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseManagementRTypeId;
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        insert emailTest;

        EmailMessage emailTest2 = new EmailMessage();
        emailTest2.Incoming = false;
        emailTest2.ParentId = caseTest.Id;
        insert emailTest2;

        caseTest.Status = 'Closed';
        update caseTest;

        EmailMessage emailTest3 = new EmailMessage();
        emailTest3.Incoming = true;
        emailTest3.ParentId = caseTest.Id;
        insert emailTest3;

        Test.stopTest();

        Integer businessHours = 6;
        Id businessHoursId = [
            SELECT Id, Name, MondayEndTime
            FROM BusinessHours
            WHERE Name = 'Sourcing Team Business Hours'
        ]
        .Id;
        Datetime newSLADate = System.BusinessHours.add(businessHoursId, System.now(), businessHours * 60 * 60 * 1000);

        System.assertEquals(
            newSLADate,
            [SELECT Next_SLA_End__c FROM Case WHERE Id = :caseTest.Id].Next_SLA_End__c,
            'Datetime should be reset.'
        );
    }

    @isTest(seeAllData=false)
    static void processCPCSLAFlagsTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        insert emailTest;

        EmailMessage emailTest2 = new EmailMessage();
        emailTest2.Incoming = true;
        emailTest2.ParentId = caseTest.Id;
        insert emailTest2;

        EmailMessage emailTest3 = new EmailMessage();
        emailTest3.Incoming = false;
        emailTest3.ParentId = caseTest.Id;
        insert emailTest3;

        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Email_Pending_SLA__c FROM Case WHERE Id = :caseTest.Id].Email_Pending_SLA__c,
            'Datetime should be cleaned.'
        );
    }

    @isTest(seeAllData=false)
    static void associateEmailsJobTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Ops_Order__c opsOrderTest = new Ops_Order__c();
        opsOrderTest.Stage__c = 'Partially Complete';
        opsOrderTest.XometryOpsOrderID__c = '440A1-15008';
        insert opsOrderTest;

        Supplier__c supplierTest = new Supplier__c();
        supplierTest.PartnerID__c = 'P-Test';
        supplierTest.SupplierCompanyName__c = 'P-Test';
        supplierTest.EmailAddress__c = 'email@tester.com';
        supplierTest.LastName__c = 'Supplier';
        insert supplierTest;

        Job__c jobTest = new Job__c();
        jobTest.Name = 'Test-Job';
        jobTest.XometryJobID__c = 'J0012345';
        jobTest.XometryOpsOrderID__c = opsOrderTest.XometryOpsOrderID__c;
        jobTest.Supplier__c = supplierTest.Id;
        insert jobTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Hi there, I am have a question about ' + jobTest.XometryJobID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'support@xometry.com';
        insert emailTest;

        Test.stopTest();

        caseTest = [
            SELECT RecordTypeId, OwnerId, GNOOrder__c, Job__c, Supplier__c, ShadowXometryJobID__c
            FROM Case
            WHERE Id = :caseTest.Id
        ];

        System.assertEquals(caseGeneralRTypeId, caseTest.RecordTypeId, 'RecordTypeId should be General Support Case');
        System.assertEquals(opsOrderTest.Id, caseTest.GNOOrder__c, 'Order should be associated');
        System.assertEquals(jobTest.Id, caseTest.Job__c, 'Job should be associated');
        System.assertEquals(supplierTest.Id, caseTest.Supplier__c, 'Supplier should be associated');
        System.assertEquals(jobTest.XometryJobID__c, caseTest.ShadowXometryJobID__c, 'Shadow Job ID should exist');
    }

    @isTest(seeAllData=false)
    static void associateEmailsMultipleJobsTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Ops_Order__c opsOrderTest = new Ops_Order__c();
        opsOrderTest.Stage__c = 'Partially Complete';
        opsOrderTest.XometryOpsOrderID__c = '440A1-15008';
        insert opsOrderTest;

        Supplier__c supplierTest = new Supplier__c();
        supplierTest.PartnerID__c = 'P-Test';
        supplierTest.SupplierCompanyName__c = 'P-Test';
        supplierTest.EmailAddress__c = 'email@tester.com';
        supplierTest.LastName__c = 'Supplier';
        insert supplierTest;

        List<Job__c> jobsToInsert = new List<Job__c>();
        Job__c jobTest = new Job__c();
        jobTest.Name = 'Test-Job';
        jobTest.XometryJobID__c = 'J0012345';
        jobTest.XometryOpsOrderID__c = opsOrderTest.XometryOpsOrderID__c;
        jobTest.Supplier__c = supplierTest.Id;
        jobsToInsert.add(jobTest);

        Job__c jobTest2 = new Job__c();
        jobTest2.Name = 'Test-Job';
        jobTest2.XometryJobID__c = 'J0154321';
        jobTest2.XometryOpsOrderID__c = opsOrderTest.XometryOpsOrderID__c;
        jobTest2.Supplier__c = supplierTest.Id;
        jobsToInsert.add(jobTest2);

        insert jobsToInsert;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody +=
            '<p>Hi there, I am have a question about ' +
            jobTest2.XometryJobID__c +
            ' and ' +
            jobTest.XometryJobID__c +
            '</p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'support@xometry.com';
        insert emailTest;

        Test.stopTest();

        caseTest = [SELECT RecordTypeId, OwnerId, GNOOrder__c, Job__c, Supplier__c FROM Case WHERE Id = :caseTest.Id];

        System.assertEquals(caseGeneralRTypeId, caseTest.RecordTypeId, 'RecordTypeId should be General Support Case');
        System.assertEquals(opsOrderTest.Id, caseTest.GNOOrder__c, 'Order should be associated');
        System.assertEquals(jobTest2.Id, caseTest.Job__c, 'First Job should be associated');
        System.assertEquals(supplierTest.Id, caseTest.Supplier__c, 'Supplier should be associated');
    }

    @isTest(seeAllData=false)
    static void associateEmailsNoFoundDataTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>This is just a random email Hello-there</p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'support@xometry.com';
        insert emailTest;

        Test.stopTest();

        caseTest = [
            SELECT RecordTypeId, GNOOrder__c, Opportunity__c, Job__c, Supplier__c
            FROM Case
            WHERE Id = :caseTest.Id
        ];

        System.assertEquals(caseGeneralRTypeId, caseTest.RecordTypeId, 'RecordTypeId should be General Support Case');
        System.assertEquals(null, caseTest.GNOOrder__c, 'No Order should be associated');
        System.assertEquals(null, caseTest.Opportunity__c, 'No Opp should be associated');
        System.assertEquals(null, caseTest.Job__c, 'No Job should be associated');
        System.assertEquals(null, caseTest.Supplier__c, 'No Supplier should be associated');
    }

    @isTest(seeAllData=false)
    static void routeEmailsFromPartnerPortalCaseManagerTest() {
        User testUser = TestDataFactory.createCaseManager()[0];

        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Ops_Order__c opsOrderTest = new Ops_Order__c();
        opsOrderTest.Stage__c = 'Partially Complete';
        opsOrderTest.XometryOpsOrderID__c = '440A1-15008';
        opsOrderTest.CaseManager__c = testUser.Id;
        insert opsOrderTest;

        Supplier__c supplierTest = new Supplier__c();
        supplierTest.PartnerID__c = 'P-Test';
        supplierTest.SupplierCompanyName__c = 'P-Test';
        supplierTest.EmailAddress__c = 'email@tester.com';
        supplierTest.LastName__c = 'Supplier';
        insert supplierTest;

        Job__c jobTest = new Job__c();
        jobTest.Name = 'Test-Job';
        jobTest.XometryJobID__c = 'J0012345';
        jobTest.XometryOpsOrderID__c = opsOrderTest.XometryOpsOrderID__c;
        jobTest.Supplier__c = supplierTest.Id;
        insert jobTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Subject Test - Job ' + jobTest.XometryJobID__c + ' - More text';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Order: ' + opsOrderTest.XometryOpsOrderID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>Job: ' + jobTest.XometryJobID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'partner-question@xometry.com';
        insert emailTest;

        Test.stopTest();

        caseTest = [
            SELECT RecordTypeId, Job__c, Supplier__c, OwnerId, POD__c, CaseManager__c, GNOOrder__c, Origin
            FROM Case
            WHERE Id = :caseTest.Id
        ];

        System.assertEquals(caseManagementRTypeId, caseTest.RecordTypeId, 'RecordTypeId should be CM');
        System.assertEquals(testUser.Id, caseTest.OwnerId, 'Owner should be updated');
        System.assertEquals(jobTest.Id, caseTest.Job__c, 'Job should be associated');
        System.assertEquals(supplierTest.Id, caseTest.Supplier__c, 'Supplier should be associated');
        System.assertEquals(opsOrderTest.Id, caseTest.GNOOrder__c, 'Order should be associated');
        System.assertEquals('Partner Portal', caseTest.Origin, 'Origin was not updated');
    }

    @isTest(seeAllData=false)
    static void routeEmailsFromPartnerPortalDFMTest() {
        User testUser = TestDataFactory.createCaseManager()[0];

        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Ops_Order__c opsOrderTest = new Ops_Order__c();
        opsOrderTest.Stage__c = 'Partially Complete';
        opsOrderTest.XometryOpsOrderID__c = '440A1-15008';
        opsOrderTest.CaseManager__c = testUser.Id;
        insert opsOrderTest;

        Supplier__c supplierTest = new Supplier__c();
        supplierTest.PartnerID__c = 'P-Test';
        supplierTest.SupplierCompanyName__c = 'P-Test';
        supplierTest.EmailAddress__c = 'email@tester.com';
        supplierTest.LastName__c = 'Supplier';
        insert supplierTest;

        Job__c jobTest = new Job__c();
        jobTest.Name = 'Test-Job';
        jobTest.XometryJobID__c = 'J0012345';
        jobTest.XometryOpsOrderID__c = opsOrderTest.XometryOpsOrderID__c;
        jobTest.Supplier__c = supplierTest.Id;
        insert jobTest;

        Group dfmGroup = [
            SELECT Id, Name
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'First_Impressions'
            LIMIT 1
        ];

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Subject Test - Job ' + jobTest.XometryJobID__c + ' - DFM Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Order: ' + opsOrderTest.XometryOpsOrderID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>Job: ' + jobTest.XometryJobID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'partner-question@xometry.com';
        insert emailTest;

        Test.stopTest();

        caseTest = [SELECT RecordTypeId, OwnerId, GNOOrder__c FROM Case WHERE Id = :caseTest.Id];

        System.assertEquals(caseManagementRTypeId, caseTest.RecordTypeId, 'RecordTypeId should be CM');
        System.assertEquals(dfmGroup.Id, caseTest.OwnerId, 'Owner should be first impressions Queue');
        System.assertEquals(opsOrderTest.Id, caseTest.GNOOrder__c, 'Order should be associated');
    }

    @isTest(seeAllData=false)
    static void routeEmailsFromPartnerPortalPODQueueAndOrderTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Ops_Order__c opsOrderTest = new Ops_Order__c();
        opsOrderTest.Stage__c = 'Partially Complete';
        opsOrderTest.XometryOpsOrderID__c = '440A1-15008';
        opsOrderTest.POD__c = 'First Impressions';
        insert opsOrderTest;

        Group podQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :opsOrderTest.POD__c LIMIT 1];

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Subject Test - Job - Partner Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Order: ' + opsOrderTest.XometryOpsOrderID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'partner-question@xometry.com';
        insert emailTest;

        Test.stopTest();

        caseTest = [SELECT RecordTypeId, OwnerId, GNOOrder__c FROM Case WHERE Id = :caseTest.Id];

        System.assertEquals(caseManagementRTypeId, caseTest.RecordTypeId, 'RecordTypeId should be CM');
        System.assertEquals(podQueue.Id, caseTest.OwnerId, 'Owner should be POD Queue');
        System.assertEquals(opsOrderTest.Id, caseTest.GNOOrder__c, 'Order should be associated');
    }

    @isTest(seeAllData=false)
    static void associateEmailsCaseOppJunctionTest() {
        Order_ERP__C ord = TestDataFactory.createOrderERP(
            true,
            'Q12-3333-4444',
            '440A1-15008',
            'johndoe@gmail.com',
            '',
            'johndoe@gmail.com',
            false,
            false
        );

        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Job__c jobTest = new Job__c();
        jobTest.Name = 'Test-Job';
        jobTest.XometryJobID__c = 'J0012345';
        jobTest.XometryOpsOrderID__c = '440A1-15008';
        insert jobTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>I am asking a question about ' + jobTest.XometryJobID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'support@xometry.com';
        insert emailTest;

        Test.stopTest();

        caseTest = [SELECT RecordTypeId, Opportunity__c FROM Case WHERE Id = :caseTest.Id];

        CaseOpportunity__c caseOpp = [SELECT Opportunity__c FROM CaseOpportunity__c LIMIT 1];

        System.assertEquals(null, caseTest.Opportunity__c, 'Opp should not be assocaited to case');
        System.assertNotEquals(null, caseOpp.Opportunity__c, 'CaseOpp junction was not created');
    }

    @isTest(seeAllData=false)
    static void routeEmailsFromPartnerPortalOrderMatcherTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Test.startTest();
        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Certificate is about to expire';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p> Our records show that your ISO 14001 certification will expire in 120 days. </p><br/>';
        emailTest.HtmlBody += '<p>  (https://f2hn7wzm.r.us-east-1.awstrack.me/L0/https:%2F%2Fwork.xometry.com%2Fcertifications/1/0100017de57516ef-113adb8a-feb3-4104-893b-70659f5296bb-000000/6F-kAFAfTMdB8LQwG3I5JsNGVsU=250) </p><br/>';
        emailTest.HtmlBody += '<p>  (https://www.sap.com/agreements-sap-business-network-privacy-statement) </p><br/>';
        emailTest.HtmlBody += '<p>  * TE Environmental-Related Substances </p><br/>';
        emailTest.HtmlBody += '<p> Schlumberger-Private </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'test@xometry.com';
        insert emailTest;
        Test.stopTest();

        caseTest = [SELECT ShadowXometryOrderID__c FROM Case WHERE Id = :emailTest.ParentID];

        System.assertEquals(null, caseTest.ShadowXometryOrderID__c, 'Regex matched incorrectly');
    }

    @isTest(seeAllData=false)
    static void routeEmailsFromPartnerPortalQuoteMatcherTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Test.startTest();
        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Certificate is about to expire';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>  (https://f2hn7wzm.r.us-east-1.awstrack.me/L0/https:%2F%2Fwork.xometry.com%2Fcertifications/1/0100017de57516ef-113adbQ8a-feb3-4104-893b-70659f5296bb-000000/6F-kAFAfTMdB8LQwG3I5JsNGVsU=250) </p><br/>';
        emailTest.HtmlBody += '<p>  * QUE-TEST-123 </p><br/>';
        emailTest.HtmlBody += '<p> Inquiry about Q12-9501-4037. </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'test@xometry.com';
        insert emailTest;
        Test.stopTest();

        caseTest = [SELECT Shadow_Xometry_ERP_ID__c FROM Case WHERE Id = :emailTest.ParentID];

        System.assertEquals('Q12-9501-4037', caseTest.Shadow_Xometry_ERP_ID__c, 'Regex matched quote incorrectly');
    }

    @isTest(seeAllData=false)
    static void routeEmailsFromPartnerPortalPreFissionQuoteMatcherTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Quote_ERP__C quote = TestDataFactory.createPreFissionQuote(true);

        Test.startTest();
        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Checking in on an old quote';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>  (https://f2hn7wzm.r.us-east-1.awstrack.me/L0/https:%2F%2Fwork.xometry.com%2Fcertifications/1/0100017de57516ef-113adbQ8a-feb3-4104-893b-70659f5296bb-000000/6F-kAFAfTMdB8LQwG3I5JsNGVsU=250) </p><br/>';
        emailTest.HtmlBody += '<p>  * 461AC-15028 </p><br/>';
        emailTest.HtmlBody += '<p> Inquiry about Q12-9501-4037. </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'test@xometry.com';
        insert emailTest;
        Test.stopTest();

        caseTest = [SELECT Shadow_Xometry_ERP_ID__c FROM Case WHERE Id = :emailTest.ParentID];

        System.assertEquals('461AC-15028', caseTest.Shadow_Xometry_ERP_ID__c, 'Regex matched quote incorrectly');
    }

    @isTest(seeAllData=false)
    static void routeEmailsFromPartnerPortalPreFissionQuoteAndOrderQuoteFirstMatcherTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Quote_ERP__C quote = TestDataFactory.createPreFissionQuote(true);
        Order_ERP__c ord = TestDataFactory.createOrderERPFromQuote(false, quote);
        ord.Xometry_ERP_ID__c = '461AC-15029';
        ord.Order_Canceled_Flag__c = false;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.process_isDMLS__c = true;
        insert ord;

        quote.Xometry_Order_ID__c = '461AC-15029';
        update quote;

        Test.startTest();
        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Checking in on an old quote';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>  (https://f2hn7wzm.r.us-east-1.awstrack.me/L0/https:%2F%2Fwork.xometry.com%2Fcertifications/1/0100017de57516ef-113adbQ8a-feb3-4104-893b-70659f5296bb-000000/6F-kAFAfTMdB8LQwG3I5JsNGVsU=250) </p><br/>';
        emailTest.HtmlBody += '<p>  * Quote: 461AC-15028 </p><br/>';
        emailTest.HtmlBody += '<p>  * Order: 461AC-15029 </p><br/>';
        emailTest.HtmlBody += '<p> Inquiry about Q12-9501-4037. </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'test@xometry.com';
        insert emailTest;
        Test.stopTest();

        caseTest = [SELECT Shadow_Xometry_ERP_ID__c, ShadowXometryOrderID__c FROM Case WHERE Id = :emailTest.ParentID];

        System.assertEquals('461AC-15028', caseTest.Shadow_Xometry_ERP_ID__c, 'Quote match not working as expected');
        System.assertEquals('461AC-15029', caseTest.ShadowXometryOrderID__c, 'Order match not working as expected');
    }

    @isTest(seeAllData=false)
    static void routeEmailsFromPartnerPortalPreFissionQuoteAndOrderOrderFirstMatcherTest() {
        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Quote_ERP__C quote = TestDataFactory.createPreFissionQuote(true);
        Order_ERP__c ord = TestDataFactory.createOrderERPFromQuote(false, quote);
        ord.Xometry_ERP_ID__c = '461AC-15029';
        ord.Order_Canceled_Flag__c = false;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.process_isDMLS__c = true;
        insert ord;

        Test.startTest();
        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Checking in on an old quote';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>  (https://f2hn7wzm.r.us-east-1.awstrack.me/L0/https:%2F%2Fwork.xometry.com%2Fcertifications/1/0100017de57516ef-113adbQ8a-feb3-4104-893b-70659f5296bb-000000/6F-kAFAfTMdB8LQwG3I5JsNGVsU=250) </p><br/>';
        emailTest.HtmlBody += '<p>  * Quote: 461AC-15029 </p><br/>';
        emailTest.HtmlBody += '<p>  * Order: 461AC-15028 </p><br/>';
        emailTest.HtmlBody += '<p> Inquiry about Q12-9501-4037. </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'test@xometry.com';
        insert emailTest;
        Test.stopTest();

        caseTest = [SELECT Shadow_Xometry_ERP_ID__c, ShadowXometryOrderID__c FROM Case WHERE Id = :emailTest.ParentID];

        System.assertEquals('461AC-15028', caseTest.Shadow_Xometry_ERP_ID__c, 'Quote match not working as expected');
        System.assertEquals('461AC-15029', caseTest.ShadowXometryOrderID__c, 'Order match not working as expected');
    }

    @isTest
    static void setIsPartnerFlagOnCaseRecord_SupplierDomainFoundTest() {
        ID casePartnerManagementRTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Partner_Management')
            .getRecordTypeID();
        Supplier__c supplier = TestDataFactory.createSupplier(true);
        supplier.SupplierStatus__c = 'approved';
        supplier.IsGeneric__c = false;
        supplier.EmailAddress__c = 'supplier@pizzashopnotgeneric.com';
        supplier.AccountDomain__c = 'pizzashopnotgeneric.com';
        update supplier;

        Case caseToInsert = new Case();
        caseToInsert.Origin = 'Email: Support@';
        caseToInsert.Priority = 'High';
        caseToInsert.RecordTypeId = casePartnerManagementRTypeID;
        insert caseToInsert;

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseToInsert.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Hi there, I am have a question about </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'supplier2@pizzashopnotgeneric.com';
        Test.StartTest();
        insert emailTest;
        Test.StopTest();
        Case caseToCompare = [SELECT IsPartnerSupplier__c FROM Case][0];

        System.Assert(caseToCompare.IsPartnerSupplier__c == true, 'IsPartnerSupplier__c remains unchecked');
    }

    @isTest
    static void setIsPartnerFlagOnCaseRecord_SupplierEmailFoundTest() {
        ID casePartnerManagementRTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Partner_Management')
            .getRecordTypeID();
        Supplier__c supplier = TestDataFactory.createSupplier(true);
        supplier.SupplierStatus__c = 'approved';
        supplier.IsGeneric__c = false;
        supplier.EmailAddress__c = 'sample@test.com';
        supplier.AccountDomain__c = 'gmail.com';
        update supplier;

        Case caseToInsert = new Case();
        caseToInsert.Origin = 'Email: Support@';
        caseToInsert.Priority = 'High';
        caseToInsert.RecordTypeId = casePartnerManagementRTypeID;

        insert caseToInsert;

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseToInsert.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Hi there, I am have a question about </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'sample@test.com';
        Test.StartTest();
        insert emailTest;
        Test.StopTest();
        Case caseToCompare = [SELECT IsPartnerSupplier__c FROM Case][0];
        System.Assert(caseToCompare.IsPartnerSupplier__c == true, 'IsPartnerSupplier__c remains unchecked');
    }

    @isTest
    static void setIsPartnerFlagOnCaseRecord_SupplierNotFoundTest() {
        ID casePartnerManagementRTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Partner_Management')
            .getRecordTypeID();
        Supplier__c supplier = TestDataFactory.createSupplier(true);
        supplier.SupplierStatus__c = 'approved';
        supplier.IsGeneric__c = true;
        supplier.EmailAddress__c = 'sample@test.com';
        supplier.AccountDomain__c = 'gmail.com';
        update supplier;

        Case caseToInsert = new Case();
        caseToInsert.Origin = 'Email: Support@';
        caseToInsert.Priority = 'High';
        caseToInsert.RecordTypeId = casePartnerManagementRTypeID;
        insert caseToInsert;

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseToInsert.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Hi there, I am have a question about </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'sample@test1.com';
        Test.StartTest();
        insert emailTest;
        Test.StopTest();
        Case caseToCompare = [SELECT IsPartnerSupplier__c FROM Case][0];
        System.Assert(caseToCompare.IsPartnerSupplier__c == false, 'IsPartnerSupplier__c was checked for non-supplier');
    }

    @isTest(seeAllData=false)
    static void detectAutoReplyNotSpam_Test() {
        Case caseTest = new Case();
        caseTest.Status = 'New';
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = EmailMessageHandler.GetRecordTypeInfosByDeveloperName.get('GeneralSupportCase')
            .getRecordTypeID();
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Subject = 'Xometry I Love You';
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.TextBody = 'copypasta autoreply.';
        emailTest.FromAddress = 'truereply@notxometry.com';
        insert emailTest;

        Test.stopTest();

        System.assertEquals('New', [SELECT Status FROM Case WHERE Id = :caseTest.Id].Status, 'Case should be updated.');
    }

    @isTest(seeAllData=false)
    static void detectAutoReplySpamBody_Test() {
        Case caseTest = new Case();
        caseTest.Status = 'New';
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = EmailMessageHandler.GetRecordTypeInfosByDeveloperName.get('GeneralSupportCase')
            .getRecordTypeID();
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Subject = 'Xometry I Love You';
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.TextBody = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam molestie blandit purus, in maximus turpis sollicitudin ac. Vestibulum varius orci faucibus mauris ornare, vestibulum iaculis leo mattis. Nunc tincidunt rhoncus lorem, ut convallis nulla dictum ac. Cras non vestibulum nibh, nec pellentesque risus. Vivamus vitae neque eget sapien finibus volutpat. Nunc non dolor vitae urna bibendum mattis quis a purus. Proin sit amet libero sagittis, vulputate turpis eu, dignissim ante. Ut euismod lacus a ligula auctor viverra. Aenean et sem at dolor iaculis sodales dictum id felis. Sed rutrum lectus id augue tempus, eu volutpat mauris feugiat. Nam posuere enim a tellus tincidunt, sed venenatis arcu posuere. Vivamus fringilla, odio ut imperdiet tempor, nisi eros congue ipsum, vitae auctor velit justo vitae dolor. Fusce facilisis tortor magna, sit amet eleifend elit tincidunt vitae. Nullam scelerisque mi id mattis porta. Donec convallis orci ut augue vestibulum dapibus. Sed luctus est ac justo pulvinar, eu sagittis metus lacinia. Praesent egestas lacus eu magna suscipit, eu blandit libero bibendum. In ut ornare urna. Quisque suscipit orci id facilisis fringilla. Suspendisse lacinia risus ligula, sed tincidunt lectus aliquet blandit. Curabitur vel urna ut dolor pulvinar congue. Pellentesque mattis consectetur ipsum, non accumsan eros ornare quis. Aliquam sed nunc viverra urna porttitor imperdiet id sed tellus. Morbi eleifend, nisl sit amet convallis pellentesque, justo mauris sollicitudin dolor, vel auctor augue sapien ut quam. Curabitur sed dolor id neque porttitor euismod eu non magna. Praesent nisi purus, porta vel porttitor in, tincidunt non felis. Mauris at pellentesque nisi, elementum egestas justo. In lobortis eros magna, ac porta arcu feugiat luctus. Fusce vulputate interdum nunc, a scelerisque velit dignissim quis. Aliquam nibh mauris, volutpat ac maximus id, dapibus at quam. Morbi sagittis, arcu nec laoreet gravida, nisl dolor porta nisi, eu laoreet mauris nulla ut felis. Integer a ornare nisl, et euismod est. Vestibulum scelerisque leo at vehicula porta. In sit amet cursus mi, vitae efficitur sem. Curabitur suscipit orci quis tortor gravida sagittis. Sed porttitor tempor ex, vitae tristique neque pellentesque id. Vivamus in placerat neque. Sed ac risus at elit dapibus semper in nec erat. Praesent non dictum mi, non interdum enim. Nam gravida nulla augue, eu ultrices arcu pellentesque id. Donec tempor dui ut dolor mattis pellentesque. Integer ac pulvinar ante. Phasellus molestie, quam nec porttitor varius, mauris nibh convallis nisi, et feugiat urna ligula in lacus. Vestibulum ac felis ipsum. Sed interdum dapibus tincidunt. Etiam elit purus, vulputate blandit est a, egestas euismod mi. Morbi hendrerit, ante a luctus iaculis, ante est rhoncus massa, a aliquam neque odio eu sem. Ut vel libero neque. Donec a elit purus. Phasellus sed velit et est iaculis aliquam. Integer quis justo eu leo ullamcorper lobortis. Suspendisse laoreet vitae erat vel auctor. Suspendisse finibus gravida augue, ac feugiat metus ultrices nec. Fusce ornare in nunc vitae mattis. Cras dignissim orci quis dolor tincidunt pellentesque. Vestibulum consectetur bibendum mauris nec pharetra copypasta autoreply.';
        emailTest.FromAddress = 'autoreply@notxometry.com';
        insert emailTest;

        Test.stopTest();

        System.assertEquals(
            'Closed',
            [SELECT Status FROM Case WHERE Id = :caseTest.Id].Status,
            'Case should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void detectAutoReplySpamSubject_Test() {
        Case caseTest = new Case();
        caseTest.Status = 'New';
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = EmailMessageHandler.GetRecordTypeInfosByDeveloperName.get('GeneralSupportCase')
            .getRecordTypeID();
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Subject = 'Congratulations SensibleUsername!';
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.TextBody = 'Congratulations, you won $1,000,000! random text.';
        emailTest.FromAddress = 'obviusautoreply@notxometry.com';
        insert emailTest;

        Test.stopTest();

        System.assertEquals(
            'Closed',
            [SELECT Status FROM Case WHERE Id = :caseTest.Id].Status,
            'Case should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void detectAutoReplySpamAddress_Test() {
        Case caseTest = new Case();
        caseTest.Status = 'New';
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = EmailMessageHandler.GetRecordTypeInfosByDeveloperName.get('GeneralSupportCase')
            .getRecordTypeID();
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Subject = 'Xometry I Love You';
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.TextBody = 'random text.';
        emailTest.FromAddress = 'obviusautoreply@notxometry.com';
        insert emailTest;

        Test.stopTest();

        System.assertEquals(
            'Closed',
            [SELECT Status FROM Case WHERE Id = :caseTest.Id].Status,
            'Case should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void detectAutoReplySpamFilterOR_Test() {
        Case caseTest = new Case();
        caseTest.Status = 'New';
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = EmailMessageHandler.GetRecordTypeInfosByDeveloperName.get('DFM_Case').getRecordTypeID();
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Subject = 'obvius scam';
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.TextBody = 'random text.';
        emailTest.FromAddress = 'autoreply@notxometry.com';
        insert emailTest;

        Test.stopTest();

        System.assertEquals(
            'Closed',
            [SELECT Status FROM Case WHERE Id = :caseTest.Id].Status,
            'Case should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void detectAutoReplySpamFilterAND_Test() {
        Case caseTest = new Case();
        caseTest.Status = 'New';
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email:info@bigbluesaw.com';
        caseTest.RecordTypeId = EmailMessageHandler.GetRecordTypeInfosByDeveloperName.get('DFM_Case').getRecordTypeID();
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Subject = 'Very convincing subject';
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.HtmlBody = 'virus';
        emailTest.FromAddress = 'convincingemail@notxometry.com';
        insert emailTest;

        Test.stopTest();

        Case caseTestResult = [SELECT Status, IsClosedByAutoClose__c FROM Case WHERE Id = :caseTest.Id];

        System.assertEquals('Closed', caseTestResult.Status, 'Case should be updated.');
        System.assertEquals(true, caseTestResult.IsClosedByAutoClose__c, 'Case should be updated.');
    }

    @isTest(seeAllData=false)
    static void detectAutoReplyPriority_Test() {
        //Email_Autoreply_Rule__mdt test4 and test5 will match

        Case caseTest = new Case();
        caseTest.Status = 'New';
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email:info@bigbluesaw.com';
        caseTest.RecordTypeId = EmailMessageHandler.GetRecordTypeInfosByDeveloperName.get('DFM_Case').getRecordTypeID();
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Subject = 'obvius scam';
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.HtmlBody = 'you won $';
        emailTest.FromAddress = 'convincingemail@notxometry.com';
        insert emailTest;

        Test.stopTest();

        Case caseTestResult = [SELECT Status, IsClosedByAutoClose__c, Reason FROM Case WHERE Id = :caseTest.Id];

        System.assertEquals('Closed', caseTestResult.Status, 'Case should be updated.');
        System.assertEquals(true, caseTestResult.IsClosedByAutoClose__c, 'Case should be updated.');
        System.assertEquals('Instructions not clear', caseTestResult.Reason, 'Case should be updated.');
    }

    @isTest(seeAllData=false)
    static void detectAutoReplyNoBody_Test() {
        Case caseTest = new Case();
        caseTest.Status = 'New';
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email Supplies@';
        caseTest.RecordTypeId = AppConstants.caseSellerMarketPlaceRTypeId;
        insert caseTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Subject = 'PO Ref: 12345';
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.FromAddress = 'jt@seipp.com';
        emailTest.ToAddress = 'supplies@xometry.com';
        emailTest.TextBody = null;
        insert emailTest;

        Test.stopTest();

        System.assertEquals(1, [SELECT ID FROM Case].size(), 'The Case was not inserted with an empty body');
    }

    @isTest(seeAllData=false)
    static void routePartRejectedEmails() {
        User testUser = TestDataFactory.createCaseManager()[0];

        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Ops_Order__c opsOrderTest = new Ops_Order__c();
        opsOrderTest.Stage__c = 'Partially Complete';
        opsOrderTest.XometryOpsOrderID__c = '440A1-15008';
        opsOrderTest.CaseManager__c = testUser.Id;
        insert opsOrderTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject =
            '[Xometry Support] Part #03FD6B9 for Order ' +
            opsOrderTest.XometryOpsOrderID__c +
            ' has been rejected during final inspection';
        emailTest.HtmlBody = '<p> Total quantity ordered: 2 /p><br/>';
        emailTest.HtmlBody += '<p> Sample size: 2 </p><br/>';
        emailTest.HtmlBody += '<p> #partrejected </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'info@xometry.com';
        emailTest.ToAddress = 'support@xometry.com';
        insert emailTest;

        Test.stopTest();

        caseTest = [
            SELECT RecordTypeId, Job__c, Supplier__c, OwnerId, POD__c, CaseManager__c, GNOOrder__c, Origin
            FROM Case
            WHERE Id = :caseTest.Id
        ];

        System.assertEquals(caseManagementRTypeId, caseTest.RecordTypeId, 'RecordTypeId should be CM');
        System.assertEquals(testUser.Id, caseTest.OwnerId, 'Owner should be updated');
        System.assertEquals(opsOrderTest.Id, caseTest.GNOOrder__c, 'Order should be associated');
        System.assertNotEquals('Partner Portal', caseTest.Origin, 'Origin was incorrectly updated');
    }
}