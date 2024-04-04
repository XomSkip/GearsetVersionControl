@isTest
public class ProjectTest {
    @isTest
    static void oppTest_closeOppsWhenProjectCloses_singleOppInProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOpp = TestDataFactory.createOpportunity(false, c.Id, a.Id, null, Date.newInstance(2019, 6, 14));
        newOpp.Project__c = projectToClose.Id;
        insert newOpp;

        Opportunity newOppTwo = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppTwo.StageName = 'Closed Won';
        newOppTwo.Project__c = projectToClose.Id;
        insert newOppTwo;

        Test.startTest();
        projectToClose.Stage__c = 'Closed Won';
        update projectToClose;
        Test.stopTest();

        Date todayDate = date.today();
        Opportunity resultOpp = [SELECT StageName, CloseDate FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c closedProject = [SELECT Stage__c FROM Project__c WHERE ID = :projectToClose.Id][0];

        System.assertEquals('Closed Lost', resultOpp.StageName, 'The opp was not switched to Closed Lost');
        System.assertEquals('Closed Won', closedProject.Stage__c, 'The project is still open');
        System.assertEquals(todayDate, resultOpp.CloseDate, 'The close date was not updated');
    }

    @isTest
    static void oppTest_closeOppsWhenProjectCloses_multipleNewOppsInProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.Name = 'TestOppOne';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        Opportunity newOppTwo = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppTwo.Name = 'TestOppTwo';
        newOppTwo.Project__c = projectToClose.Id;
        insert newOppTwo;

        Test.startTest();
        projectToClose.Stage__c = 'Closed Lost';
        projectToClose.Closed_Lost_Reason__c = 'Lost reason sample';
        update projectToClose;
        Test.stopTest();

        Date todayDate = date.today();
        Opportunity resultOppOne = [
            SELECT StageName, CloseDate, Loss_Reason__c
            FROM Opportunity
            WHERE ID = :newOppOne.Id
        ][0];
        Opportunity resultOppTwo = [
            SELECT StageName, CloseDate, Loss_Reason__c
            FROM Opportunity
            WHERE ID = :newOppTwo.Id
        ][0];
        Project__c closedProject = [
            SELECT Stage__c, Closed_Lost_Reason__c
            FROM Project__c
            WHERE ID = :projectToClose.Id
        ][0];

        System.assertEquals('Closed Lost', resultOppOne.StageName, 'The first opp was not switched to Closed Lost');
        System.assertEquals('Closed Lost', resultOppTwo.StageName, 'The second opp was not switched to Closed Lost');
        System.assertEquals('Closed Lost', closedProject.Stage__c, 'The project is still open');
        System.assertEquals(todayDate, resultOppOne.CloseDate, 'The close date for the first opp was not updated');
        System.assertEquals(todayDate, resultOppTwo.CloseDate, 'The close date for the second opp was not updated');
        System.assertEquals(
            resultOppOne.Loss_Reason__c,
            closedProject.Closed_Lost_Reason__c,
            'the Opps loss reason  mirror the Project s loss reason'
        );
        System.assertEquals(
            resultOppTwo.Loss_Reason__c,
            closedProject.Closed_Lost_Reason__c,
            'the Opps loss reason  mirror the Project s loss reason'
        );
    }

    @isTest
    static void oppTest_closeOppsWhenProjectCloses_multipleOppsInProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.Name = 'TestOppOne';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        Opportunity newOppTwo = new Opportunity();
        newOppTwo.StageName = 'Closed Won';
        newOppTwo.AccountId = a.Id;
        newOppTwo.Primary_Contact__C = c.Id;
        newOppTwo.CloseDate = Date.newInstance(2019, 6, 14);
        newOppTwo.Name = 'TestOppTwo';
        newOppTwo.Project__c = projectToClose.Id;
        insert newOppTwo;

        Test.startTest();
        projectToClose.Stage__c = 'Closed Won';
        update projectToClose;
        Test.stopTest();

        Date todayDate = date.today();
        Opportunity resultOppOne = [SELECT StageName, CloseDate FROM Opportunity WHERE ID = :newOppOne.Id][0];
        Opportunity resultOppTwo = [SELECT StageName, CloseDate FROM Opportunity WHERE ID = :newOppTwo.Id][0];
        Project__c closedProject = [SELECT Stage__c FROM Project__c WHERE ID = :projectToClose.Id][0];

        System.assertEquals('Closed Lost', resultOppOne.StageName, 'The first opp was not switched to Closed Lost');
        System.assertNotEquals(
            'Closed Lost',
            resultOppTwo.StageName,
            'The second opp was switched to Closed Lost, should be CW'
        );
        System.assertNotEquals('Open', closedProject.Stage__c, 'The project is still open');
        System.assertEquals(todayDate, resultOppOne.CloseDate, 'The close date for the first opp was not updated');
        System.assertNotEquals(
            todayDate,
            resultOppTwo.CloseDate,
            'The close date for the second opp was updated when it should not have'
        );
    }

    @isTest
    static void oppTest_closeOppsWhenProjectCloses_noOppsInProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Test.startTest();
        projectToClose.Stage__c = 'Closed Won';
        update projectToClose;
        Test.stopTest();

        Date todayDate = date.today();
        Project__c closedProject = [SELECT Stage__c FROM Project__c WHERE ID = :projectToClose.Id][0];

        System.assertEquals('Closed Won', closedProject.Stage__c, 'The project is still open');
    }

    @isTest
    static void oppTest_closeOppsWhenProjectCloses_oppAlreadyClosed() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOpp = TestDataFactory.createOpportunity(false, c.Id, a.Id, null, Date.newInstance(2019, 6, 14));
        newOpp.Name = 'TestOpp';
        newOpp.Project__c = projectToClose.Id;
        newOpp.StageName = 'Closed Won';
        insert newOpp;

        Test.startTest();
        projectToClose.Stage__c = 'Closed Won';
        update projectToClose;
        Test.stopTest();

        Date todayDate = date.today();
        Opportunity resultOpp = [SELECT StageName, CloseDate FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c closedProject = [SELECT Stage__c FROM Project__c WHERE ID = :projectToClose.Id][0];

        System.assertEquals('Closed Won', resultOpp.StageName, 'The opp was not already CW and switched to CL');
        System.assertNotEquals('Open', closedProject.Stage__c, 'The project is still open');
        System.assertNotEquals(todayDate, resultOpp.CloseDate, 'The close date was incorrectly updated');
    }

    @isTest
    static void projectTest_validateClosedProjectOpps_cwOppInCwProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.StageName = 'Closed Won';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        projectToClose.Stage__c = 'Closed Won';
        boolean exceptionThrown = false;

        Test.startTest();
        try {
            update projectToClose;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Project__c closedProject = [SELECT Stage__c FROM Project__c WHERE ID = :projectToClose.Id][0];

        System.assertEquals(
            'Closed Won',
            closedProject.Stage__c,
            'The project was not CW successfully, even though there is at least one CW Opp'
        );
        System.assertEquals(false, exceptionThrown, 'Exception encountered');
    }

    @isTest
    static void projectTest_validateClosedProjectOpps_noCwOppInClProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.StageName = 'Closed Lost';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        boolean exceptionThrown = false;

        Test.startTest();
        try {
            projectToClose.Stage__c = 'Closed Lost';
            update projectToClose;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Project__c closedProject = [SELECT Stage__c FROM Project__c WHERE ID = :projectToClose.Id][0];

        System.assertEquals(
            'Closed Lost',
            closedProject.Stage__c,
            'The project was not CL successfully, even though there are no CW Opps'
        );
        System.assertEquals(false, exceptionThrown, 'Exception encountered');
    }

    @isTest
    static void projectTest_validateClosedProjectOpps_error_noCwOppInCwProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.StageName = 'Closed Lost';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        Opportunity newOppTwo = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppTwo.StageName = 'Closed Lost';
        newOppTwo.Project__c = projectToClose.Id;
        insert newOppTwo;

        projectToClose.Stage__c = 'Closed Won';
        boolean exceptionThrown = false;

        Test.startTest();
        try {
            update projectToClose;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception not encountered');
    }

    @isTest
    static void projectTest_validateClosedProjectOpps_error_CwOppInClProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.StageName = 'Closed Won';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        Opportunity newOppTwo = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppTwo.StageName = 'Closed Lost';
        newOppTwo.Project__c = projectToClose.Id;
        insert newOppTwo;

        projectToClose.Stage__c = 'Closed Lost';
        boolean exceptionThrown = false;

        Test.startTest();
        try {
            update projectToClose;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception not encountered');
    }

    @isTest
    static void projectTest_holdOwnerId() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        ID testOrigOwnerID = a.OwnerID;

        Project__c projectToClose = TestDataFactory.createProject(
            false,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );
        projectToClose.Hold_Project_to_Prior_Owner__c = true;
        projectToClose.OwnerId = testOrigOwnerID;
        projectToClose.Amount__c = 100;
        insert projectToClose;
        ID projectID = projectToClose.Id;

        List<User> userList = TestDataFactory.createTestUserSecond();
        User newOwner = userList[0];
        ID newOwnerID = newOwner.ID;

        Test.startTest();
        projectToClose.OwnerId = newOwnerID;
        projectToClose.Amount__c = 300;
        update projectToClose;
        Test.stopTest();

        Project__c postUpdateProject = [SELECT ID, OwnerID, Amount__c FROM Project__c WHERE ID = :projectId];
        system.assertEquals(postUpdateProject.OwnerID, testOrigOwnerID, 'The OwnerID was changed');
        system.assertEquals(postUpdateProject.Amount__c, 300, 'The amount was not updated');
    }

    @isTest
    static void projectTest_insertSetCloseDate() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        ID testOrigOwnerID = a.OwnerID;

        Project__c projectToClose = TestDataFactory.createProject(
            false,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Closed Won'
        );
        projectToClose.OwnerId = testOrigOwnerID;
        projectToClose.Amount__c = 100;

        Test.startTest();
        insert projectToClose;
        Test.stopTest();

        Project__c postUpdateProject = [
            SELECT ID, OwnerID, Close_Date__c
            FROM Project__c
            WHERE ID = :projectToClose.Id
        ];
        system.assertEquals(date.today(), postUpdateProject.Close_Date__c, 'Close Date not set to today');
    }

    @isTest
    static void projectTest_updateSetCloseDate() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        ID testOrigOwnerID = a.OwnerID;

        Project__c projectToClose = TestDataFactory.createProject(
            false,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );
        projectToClose.OwnerId = testOrigOwnerID;
        projectToClose.Amount__c = 100;
        insert projectToClose;

        Test.startTest();
        projectToClose.Stage__c = 'Closed Won';
        update projectToClose;
        Test.stopTest();

        Project__c postUpdateProject = [
            SELECT ID, OwnerID, Close_Date__c
            FROM Project__c
            WHERE ID = :projectToClose.Id
        ];
        system.assertEquals(date.today(), postUpdateProject.Close_Date__c, 'Close Date not set to today');
    }

    @isTest
    static void projectTest_insertJunction() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c1 = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            false,
            c1.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );
        projectToClose.Amount__c = 100;

        Test.startTest();
        insert projectToClose;
        Test.stopTest();

        Project_Contact__c postUpdateProject = [
            SELECT ID, Project__c, Contact__c, Primary__c
            FROM Project_Contact__c
            WHERE Project__c = :projectToClose.Id
        ];
        system.assertEquals(
            projectToClose.Id,
            postUpdateProject.Project__c,
            'Project Contact not created with correct project'
        );
        system.assertEquals(c1.Id, postUpdateProject.Contact__c, 'Project Contact not created with correct contact');
        system.assertEquals(true, postUpdateProject.Primary__c, 'Project Contact not created primary');
    }

    @isTest
    static void projectTest_updateJunction() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c1 = [SELECT ID FROM Contact][0];
        Contact c2 = [SELECT ID FROM Contact][1];

        Project__c projectToClose = TestDataFactory.createProject(
            false,
            c1.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );
        projectToClose.Amount__c = 100;
        insert projectToClose;

        Test.startTest();
        projectToClose.Primary_Contact__c = c2.Id;
        update projectToClose;
        Test.stopTest();

        Project_Contact__c postUpdateProject1 = [
            SELECT ID, Project__c, Contact__c, Primary__c
            FROM Project_Contact__c
            WHERE Project__c = :projectToClose.Id AND Contact__c = :c1.Id
        ];
        Project_Contact__c postUpdateProject2 = [
            SELECT ID, Project__c, Contact__c, Primary__c
            FROM Project_Contact__c
            WHERE Project__c = :projectToClose.Id AND Contact__c = :c2.Id
        ];
        system.assertEquals(
            projectToClose.Id,
            postUpdateProject1.Project__c,
            'Project Contact not created with correct project'
        );
        system.assertEquals(c1.Id, postUpdateProject1.Contact__c, 'Project Contact not created with correct contact');
        system.assertEquals(false, postUpdateProject1.Primary__c, 'Project Contact not created primary');

        system.assertEquals(
            projectToClose.Id,
            postUpdateProject2.Project__c,
            'Project Contact not created with correct project'
        );
        system.assertEquals(c2.Id, postUpdateProject2.Contact__c, 'Project Contact not created with correct contact');
        system.assertEquals(true, postUpdateProject2.Primary__c, 'Project Contact not created primary');
    }

    @isTest
    static void projectTest_updateExistingJunction() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c1 = [SELECT ID FROM Contact][0];
        Contact c2 = [SELECT ID FROM Contact][1];

        Project__c projectToClose = TestDataFactory.createProject(
            false,
            c1.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );
        projectToClose.Amount__c = 100;
        insert projectToClose;

        projectToClose.Primary_Contact__c = c2.Id;
        update projectToClose;

        Test.startTest();
        projectToClose.Primary_Contact__c = c1.Id;
        update projectToClose;
        Test.stopTest();

        Project_Contact__c postUpdateProject1 = [
            SELECT ID, Project__c, Contact__c, Primary__c
            FROM Project_Contact__c
            WHERE Project__c = :projectToClose.Id AND Contact__c = :c1.Id
        ];
        Project_Contact__c postUpdateProject2 = [
            SELECT ID, Project__c, Contact__c, Primary__c
            FROM Project_Contact__c
            WHERE Project__c = :projectToClose.Id AND Contact__c = :c2.Id
        ];
        system.assertEquals(
            projectToClose.Id,
            postUpdateProject1.Project__c,
            'Project Contact not created with correct project'
        );
        system.assertEquals(c1.Id, postUpdateProject1.Contact__c, 'Project Contact not created with correct contact');
        system.assertEquals(true, postUpdateProject1.Primary__c, 'Project Contact not created primary');

        system.assertEquals(
            projectToClose.Id,
            postUpdateProject2.Project__c,
            'Project Contact not created with correct project'
        );
        system.assertEquals(c2.Id, postUpdateProject2.Contact__c, 'Project Contact not created with correct contact');
        system.assertEquals(false, postUpdateProject2.Primary__c, 'Project Contact not created primary');
    }
    @isTest
    static void projectTest_setAmountOnCloseWonTest() {
        ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Manufacturing_Services')
            .getRecordTypeID();
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProjectwithLB(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open',
            'Instant Quote'
        );
        List<Opportunity> testOppsList = new List<Opportunity>();
        Opportunity testOpp1 = new Opportunity();
        testOpp1.Name = 'TestOPP1';
        testOpp1.StageName = 'Closed Won';
        testOpp1.Amount = 500.22;
        testOpp1.Primary_Contact__C = c.Id;
        testOpp1.AccountID = a.Id;
        testOpp1.CloseDate = Date.newInstance(2022, 2, 17);
        testOpp1.RecordTypeId = oppManufacturingServRTypeID;
        testOpp1.Primary__c = true;
        testOpp1.Line_of_Business__c = 'Instant Quote';
        testOppsList.add(testOpp1);
        Opportunity testOpp2 = new Opportunity();
        testOpp2.Name = 'TestOPP2';
        testOpp2.StageName = 'Closed Won';
        testOpp2.Amount = 500.22;
        testOpp2.Primary_Contact__C = c.Id;
        testOpp2.AccountID = a.Id;
        testOpp2.CloseDate = Date.newInstance(2022, 2, 17);
        testOpp2.RecordTypeId = oppManufacturingServRTypeID;
        testOpp2.Primary__c = true;
        testOpp2.Line_of_Business__c = 'Instant Quote';
        testOppsList.add(testOpp2);
        insert testOppsList;
        Opportunity testOpp1Result = [SELECT ID, Project__C FROM Opportunity WHERE ID = :testOpp1.ID];
        System.debug('Opp1 result');
        System.debug(testOpp1Result);
        ID testProjectID = testOpp1Result.Project__C;

        Project__C testProject = new Project__C(id = testProjectID, amount__c = 450.33);
        update testProject;
        Test.startTest();
        testProject.Stage__c = 'Closed Won';
        update testProject;
        Test.stopTest();
        Project__c testProjectResult = [SELECT Id, Amount__c, Stage__c FROM Project__C WHERE ID = :testProjectID];
        System.debug('Project result');
        System.debug(testProjectResult);
        System.assertEquals(1000.44, testProjectResult.Amount__c, 'The project amount was not updated');
    }

    @isTest(seeAllData=false)
    static void projectTest_setCurrentStageStartDate() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        ID testOrigOwnerID = a.OwnerID;

        Project__c projectToClose = TestDataFactory.createProject(
            false,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );
        projectToClose.OwnerId = testOrigOwnerID;
        projectToClose.Amount__c = 100;
        insert projectToClose;

        Test.startTest();

        projectToClose.Stage__c = 'Closed Won';
        update projectToClose;

        Test.stopTest();

        Project__c postUpdateProject = [
            SELECT ID, OwnerID, Current_Stage_Start_Date__c
            FROM Project__c
            WHERE ID = :projectToClose.Id
        ];
        system.assertEquals(date.today(), postUpdateProject.Current_Stage_Start_Date__c, 'Close Date not set to today');
    }

    @isTest
    static void projectTest_notRunApexValidationFromOpp() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        projectToClose.Stage__c = 'Closed Lost';
        update projectToClose;

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.StageName = 'Closed Won';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        try {
            projectToClose.Amount__c = 300;
            update projectToClose;
        } catch (DmlException e) {
        }

        projectToClose = [SELECT Amount__c FROM Project__c WHERE Id =: projectToClose.Id];
        System.assertNotEquals(300, projectToClose.Amount__c, 'The project was updated');
        
        Opportunity newOppTwo = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        // newOppTwo.StageName = 'Closed Lost';
        newOppTwo.Project__c = projectToClose.Id;
        newOppTwo.Primary__c = true;
        insert newOppTwo;

        newOppTwo.Amount = 300;
        Test.startTest();
            update newOppTwo;
        Test.stopTest();

        projectToClose = [SELECT Amount__c FROM Project__c WHERE Id =: projectToClose.Id];
        System.assertEquals(300, projectToClose.Amount__c, 'The project was not updated');
        
        List<Audit_Trail_Error__c> auditResultList = [SELECT Id, Module__c, errorMessage__c, SourceId__c FROM Audit_Trail_Error__c];
        System.assert(auditResultList.isEmpty(), 'An error occur');
    }

    @isTest
    static void projectTest_validateClosedProjectOpps_notErrorFromOpp_noCwOppInCwProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.StageName = 'Closed Lost';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        Opportunity newOppTwo = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppTwo.StageName = 'Closed Lost';
        newOppTwo.Project__c = projectToClose.Id;
        insert newOppTwo;

        projectToClose.Stage__c = 'Closed Won';
        boolean exceptionThrown = false;

        try {
            update projectToClose;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception not encountered');

        OpportunityHandler.isAmountUpdatedFromOpp = true;
        exceptionThrown = false;

        Test.startTest();
        try {
            update projectToClose;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(!exceptionThrown, 'Exception encountered');
    }

    @isTest
    static void projectTest_validateClosedProjectOpps_notErrorFromOpp_CwOppInClProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToClose = TestDataFactory.createProject(
            true,
            c.ID,
            a.Id,
            null,
            'PreInserted Project',
            'Open'
        );

        Opportunity newOppOne = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppOne.StageName = 'Closed Won';
        newOppOne.Project__c = projectToClose.Id;
        insert newOppOne;

        Opportunity newOppTwo = TestDataFactory.createOpportunity(
            false,
            c.Id,
            a.Id,
            null,
            Date.newInstance(2019, 6, 14)
        );
        newOppTwo.StageName = 'Closed Lost';
        newOppTwo.Project__c = projectToClose.Id;
        insert newOppTwo;

        projectToClose.Stage__c = 'Closed Lost';
        boolean exceptionThrown = false;

        try {
            update projectToClose;
        } catch (DmlException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Exception not encountered');

        OpportunityHandler.isAmountUpdatedFromOpp = true;
        exceptionThrown = false;

        Test.startTest();
        try {
            update projectToClose;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(!exceptionThrown, 'Exception encountered');
    }
}