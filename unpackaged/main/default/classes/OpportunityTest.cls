@isTest
public class OpportunityTest {
    @isTest
    static void oppOwnerLockedChange() {
        //Test that when the Opportunity Owner is locked via Hold_Op_to_Prior_Owner__c that updating the Opportunity does not occur

        Opportunity testOpp = TestDataFactory.createOppOwnerUnLockedChange();
        ID testOppID = testOpp.ID;
        //Attempt to Change Opportunity Owner it should not change since it is locked

        Test.startTest();
        update testOpp;
        Test.stopTest();
        //Check that the OwnerID after the Update is still the original Owner
        Opportunity postUpdateOpp = [SELECT ID, OwnerID, Amount FROM Opportunity WHERE ID = :testOpp.Id];
        system.assertEquals(postUpdateOpp.OwnerID, testOpp.OwnerId, 'The OwnerID was changed');
        system.assertEquals(postUpdateOpp.Amount, 600, 'The amount was not updated');
        //test that the other value was updated
    }

    @isTest
    static void oppOwnerUnLockedChange() {
        //Test that when the Opportunity Owner is not locked via Hold_Op_to_Prior_Owner__c that updating the Opportunity does  occur;
        Opportunity testOpp = TestDataFactory.createOppOwnerUnLockedChange();
        ID testOppID = testOpp.ID;
        //Attempt to Change Opportunity Owner it should now change since it is unlocked

        Test.startTest();
        update testOpp;
        Test.stopTest();
        //Check that the OwnerID after the Update is is the new owner
        Opportunity postUpdateOpp = [SELECT ID, OwnerID, Amount FROM Opportunity WHERE ID = :testOppID];
        system.assertEquals(postUpdateOpp.OwnerID, testOpp.OwnerID, 'The OwnerID was not changed');
        system.assertEquals(postUpdateOpp.Amount, 600, 'The amount was not updated');
        //test that the other value was updated
    }

    @isTest
    static void oppTest_updateOppStageStartDate() {
        Opportunity newOpp = TestDataFactory.createOppWithAccContact(false, 'AM');
        newOpp.StageName = 'Closed Won';

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        ID newOppId = newOpp.ID;
        Opportunity resultOpp = [
            SELECT ID, StageName, Current_Stage_Start_Date__c
            FROM Opportunity
            WHERE ID = :newOppId
        ][0];
        System.assertEquals('Closed Won', resultOpp.StageName, 'Stage Not Changed');
        System.assertEquals(date.today(), resultOpp.Current_Stage_Start_Date__c, 'Stage Start Date Not Changed');
    }

    @isTest
    static void oppTest_createNewProjectWithNoneExisting() {
        Opportunity newOpp = TestDataFactory.createOppWithAccContact(false, 'AM');
        newOpp.Line_of_Business__c = 'Marketplace';

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        ID newOppId = newOpp.ID;
        Opportunity resultOpp = [SELECT ID, Project__c FROM Opportunity WHERE ID = :newOppId][0];
        System.assertNotEquals(resultOpp.Project__c, null, 'A new project was not created');
    }

    @isTest
    static void oppTest_associateWithNoOrder() {
        map<String, List<SObject>> mapReturn = TestDataFactory.createOppWithProjAndOrder(
            'Locked',
            null,
            false,
            false,
            1,
            true,
            true
        );
        Opportunity newOpp = (Opportunity) mapReturn.get('Opportunity')[0];
        Project__c associatedProject = (Project__c) mapReturn.get('Project__c')[0];

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName, Project__c FROM Opportunity WHERE ID = :newOpp.Id LIMIT 1];

        System.assertNotEquals(associatedProject.Id, resultOpp.Project__c, 'Project not associated to Open Project');
    }

    @isTest
    static void oppTest_associateWithSingleExistingOpenProject() {
        map<String, List<SObject>> mapReturn = TestDataFactory.createOppWithProjAndOrder(
            'Open',
            'Marketplace',
            true,
            false,
            1,
            true,
            true
        );
        Opportunity newOpp = (Opportunity) mapReturn.get('Opportunity')[0];
        Project__c associatedProject = (Project__c) mapReturn.get('Project__c')[0];

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName, Project__c FROM Opportunity WHERE ID = :newOpp.Id][0];

        System.assertEquals(associatedProject.Id, resultOpp.Project__c, 'Project not associated to Open Project');
    }

    @isTest
    static void oppTest_createNewProjectWithSingleExistingClosedProject() {
        map<String, List<SObject>> mapReturn = TestDataFactory.createOppWithProjAndOrder(
            'Open',
            'Marketplace',
            false,
            true,
            1,
            true,
            true
        );
        Opportunity newOpp = (Opportunity) mapReturn.get('Opportunity')[0];
        Project__c closedProject = (Project__c) mapReturn.get('Project__c')[0];

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, Project__c FROM Opportunity WHERE ID = :newOpp.Id][0];
        System.assertNotEquals(null, resultOpp.Project__c, 'A new project was not created');
        System.assertNotEquals(
            closedProject.Id,
            resultOpp.Project__c,
            'Closed Project should not be associated to Opp'
        );
    }

    @isTest
    static void oppTest_whenAllProjectsClosedCreateNewProject() {
        map<String, List<SObject>> mapReturn = TestDataFactory.createOppWithProjAndOrder(
            'Open',
            'Marketplace',
            false,
            true,
            2,
            false,
            true
        );
        Opportunity newOpp = (Opportunity) mapReturn.get('Opportunity')[0];
        Project__c associatedProject = (Project__c) mapReturn.get('Project__c')[0];
        Project__c associatedProject2 = (Project__c) mapReturn.get('Project__c')[1];

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, Project__c FROM Opportunity WHERE ID = :newOpp.Id][0];

        System.assertNotEquals(null, resultOpp.Project__c, 'A new project was not created');
        System.assertNotEquals(
            associatedProject.Id,
            resultOpp.Project__c,
            'Opp should not be associated with Closed Project1'
        );
        System.assertNotEquals(
            associatedProject2.Id,
            resultOpp.Project__c,
            'Opp should not be associated with Closed Project2'
        );
    }

    @isTest
    static void oppTest_whenMultipleProjectsChooseLatest() {
        map<String, List<SObject>> mapReturn = TestDataFactory.createOppWithProjAndOrder(
            'Open',
            'Marketplace',
            false,
            false,
            2,
            false,
            false
        );
        Opportunity newOpp = (Opportunity) mapReturn.get('Opportunity')[0];
        Project__c olderProject = (Project__c) mapReturn.get('Project__c')[0];
        olderProject.CreatedDate = Date.newInstance(2020, 5, 14);
        insert olderProject;

        Project__c newerProject = (Project__c) mapReturn.get('Project__c')[1];
        newerProject.CreatedDate = Date.newInstance(2020, 5, 15);
        insert newerProject;

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, Project__c FROM Opportunity WHERE ID = :newOpp.Id][0];

        System.assertNotEquals(null, resultOpp.Project__c, 'A new project was not created');
        System.assertNotEquals(
            olderProject.Id,
            resultOpp.Project__c,
            'Opp should not be associated with older Project'
        );
        System.assertEquals(newerProject.Id, resultOpp.Project__c, 'Opp should be associated with newer Project');
    }

    @isTest
    static void oppTest_createProjectContactJunction() {
        Opportunity newOpp = TestDataFactory.createOppWithAccContact(false, 'AM');
        newOpp.Line_of_Business__c = 'Marketplace';

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT Project__c FROM Opportunity WHERE ID = :newOpp.Id][0];
        Contact c = [SELECT ID FROM Contact LIMIT 1];

        Project_Contact__c resultJunction = [
            SELECT Project__c, Contact__c, Primary__c
            FROM Project_Contact__c
            WHERE Project__c = :resultOpp.Project__c
        ][0];

        System.assertEquals(resultOpp.Project__c, resultJunction.Project__c, 'A new project Junction was not created');
        System.assertEquals(c.Id, resultJunction.Contact__c, 'Contact Junction set incorrectly');
        System.assertEquals(true, resultJunction.Primary__c, 'Junction should be marked as Primary');
    }

    @isTest
    static void oppTest_createNoProjectContactJunction() {
        Opportunity oldOpp = TestDataFactory.createOppWithAccContact(false, 'AM');
        oldOpp.Line_of_Business__c = 'Marketplace';
        insert oldOpp;

        Contact c = [SELECT ID, AccountId FROM Contact LIMIT 1];

        Opportunity newOpp = new Opportunity();
        newOpp.StageName = 'Open';
        newOpp.AccountId = c.AccountId;
        newOpp.Primary_Contact__C = c.Id;
        newOpp.CloseDate = Date.newInstance(2019, 6, 15);
        newOpp.Name = 'TestOpp';
        newOpp.Line_of_Business__c = 'Marketplace';

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT Project__c FROM Opportunity WHERE ID = :newOpp.Id][0];

        List<Project_Contact__c> resultJunction = [
            SELECT Project__c, Contact__c, Primary__c
            FROM Project_Contact__c
            WHERE Project__c = :resultOpp.Project__c
        ];

        System.assertEquals(
            resultOpp.Project__c,
            resultJunction[0].Project__c,
            'A new project Junction was not created'
        );
        System.assertEquals(c.Id, resultJunction[0].Contact__c, 'Contact Junction set incorrectly');
        System.assertEquals(true, resultJunction[0].Primary__c, 'Junction should be marked as Primary');
        System.assertEquals(1, resultJunction.size());
    }

    @isTest
    static void oppTest_testNewName() {
        map<String, List<SObject>> mapReturn = TestDataFactory.createOppWithProjAndOrder(
            null,
            'Marketplace',
            false,
            false,
            0,
            true,
            true
        );
        Account a = (Account) mapReturn.get('Account')[0];
        Contact c = (Contact) mapReturn.get('Contact')[0];
        Opportunity newOpp = (Opportunity) mapReturn.get('Opportunity')[0];

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, Project__c, Project__r.Name FROM Opportunity WHERE ID = :newOpp.Id][0];

        List<String> splitString = resultOpp.Project__r.Name.split(' - ', 3);

        System.assertNotEquals(null, resultOpp.Project__c, 'A new project was not created');
        System.assertEquals(a.Name, splitString[0], 'Account Name does not match');
        System.assertEquals(c.Name, splitString[1], 'Contact Name does not match');
        System.assertNotEquals(null, splitString[2], 'Datetime does not exist in Project Name');
    }

    @isTest
    static void oppTest_testClosedWon() {
        Opportunity testOpp = TestDataFactory.createOppOwnerUnLockedChange();
        testOpp.StageName = 'Closed Won';

        Test.startTest();
        update testOpp;
        Test.stopTest();
        //Check that the OwnerID after the Update is is the new owner
        Opportunity postUpdateOpp = [SELECT ID, Primary__c FROM Opportunity WHERE ID = :testOpp.Id];
        system.assertEquals(postUpdateOpp.Primary__c, true, 'Primary was not set to true');
        //test that the other value was updated
    }

    @isTest
    static void oppTest_testClosedLost() {
        Opportunity testOpp = TestDataFactory.createOppOwnerUnLockedChange();
        testOpp.Amount = 600;
        testOpp.StageName = 'Closed Lost';

        Test.startTest();
        update testOpp;
        Test.stopTest();
        //Check that the OwnerID after the Update is is the new owner
        Opportunity postUpdateOpp = [SELECT ID, Primary__c FROM Opportunity WHERE ID = :testOpp.Id];
        system.assertEquals(postUpdateOpp.Primary__c, false, 'Primary was not set to false');
        //test that the other value was updated
    }

    @isTest
    static void oppTest_createIQOppWProject() {
        Opportunity newOpp = TestDataFactory.createOppWithAccContact(false, 'AM');
        newOpp.Name = 'TestOpp';

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        ID newOppId = newOpp.ID;
        Opportunity resultOpp = [SELECT ID, Project__c, Line_of_Business__c FROM Opportunity WHERE ID = :newOppId][0];
        System.assertNotEquals(resultOpp.Project__c, null, 'A new project was not created');
        System.assertEquals(resultOpp.Line_of_Business__c, 'Instant Quote', 'A new project was not created');
    }

    @isTest
    static void projectTest_reopenedOppInClosedProject() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(
            true,
            'AM',
            'Closed Lost',
            'Closed Lost',
            null,
            null
        );

        Test.startTest();
        newOpp.StageName = 'Closed Won';
        update newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c resultProject = [SELECT ID, Stage__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertEquals('Closed Won', resultOpp.StageName, 'The opp remained Closed Lost');
        System.assertEquals('System Reopened', resultProject.Stage__c, 'The project remained Closed');
    }

    @isTest
    static void projectTest_closedOppInClosedProject() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(
            true,
            'AM',
            'Closed Won',
            'Closed Won',
            null,
            null
        );

        Test.startTest();
        newOpp.StageName = 'Closed Lost';
        update newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c resultProject = [SELECT ID, Stage__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertEquals('Closed Lost', resultOpp.StageName, 'The opp remained Closed Won');
        System.assertEquals('System Reopened', resultProject.Stage__c, 'The project remained Closed');
    }

    @isTest
    static void projectTest_updatedPrimaryOppResetsAmount() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(false, 'AM', 'Open', 'Open', null, 10);
        newOpp.Primary__c = false;
        insert newOpp;

        Test.startTest();
        newOpp.Primary__c = true;
        update newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName, Amount FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertEquals(resultOpp.Amount, resultProject.Amount__c, 'Project should have amount from Opportunity');
        System.assertEquals(10, resultProject.Amount__c, 'Project should have amount of 10.00');
    }

    @isTest
    static void projectTest_nonPrimaryDoesNotChangeProjectAmount() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(false, 'AM', 'Open', 'Open', 0, 10);
        newOpp.Primary__c = false;
        insert newOpp;

        Test.startTest();
        newOpp.Amount = 20.00;
        update newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName, Amount FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertNotEquals(
            resultOpp.Amount,
            resultProject.Amount__c,
            'Project should not have amount from Opportunity'
        );
        System.assertEquals(0, resultProject.Amount__c, 'Project should have amount of 0.00');
    }

    @isTest
    static void projectTest_updatedMultipleUpdatesResetProjectAmount() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(false, 'AM', 'New', 'Open', null, 10);
        newOpp.Primary__c = false;
        insert newOpp;

        Test.startTest();
        newOpp.Amount = 20.00;
        newOpp.Primary__c = true;
        update newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName, Amount FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertEquals(resultOpp.Amount, resultProject.Amount__c, 'Project should have amount from Opportunity');
        System.assertEquals(20, resultProject.Amount__c, 'Project should have amount of 10.00');
    }

    @isTest
    static void projectTest_multipleOppsOnlyUpdateWithPrimaryValue() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c projectToUpdate = new Project__c();
        projectToUpdate.Primary_Contact__c = c.Id;
        projectToUpdate.AccountId__c = a.Id;
        projectToUpdate.Amount__c = 10.00;
        projectToUpdate.Project__c = 'PreInserted Project';
        projectToUpdate.Stage__c = 'New';
        insert projectToUpdate;

        Opportunity newOpp = new Opportunity();
        newOpp.StageName = 'Open';
        newOpp.Primary__c = true;
        newOpp.Amount = 10.00;
        newOpp.AccountId = a.Id;
        newOpp.Primary_Contact__C = c.Id;
        newOpp.CloseDate = Date.newInstance(2019, 6, 14);
        newOpp.Name = 'TestOpp';
        newOpp.Project__c = projectToUpdate.Id;
        insert newOpp;

        Opportunity nonPrimaryOpp1 = new Opportunity();
        nonPrimaryOpp1.StageName = 'Open';
        nonPrimaryOpp1.Primary__c = false;
        nonPrimaryOpp1.Amount = 100.00;
        nonPrimaryOpp1.AccountId = a.Id;
        nonPrimaryOpp1.Primary_Contact__C = c.Id;
        nonPrimaryOpp1.CloseDate = Date.newInstance(2019, 6, 14);
        nonPrimaryOpp1.Name = 'TestOpp';
        nonPrimaryOpp1.Project__c = projectToUpdate.Id;
        insert nonPrimaryOpp1;

        Opportunity nonPrimaryOpp2 = new Opportunity();
        nonPrimaryOpp2.StageName = 'Open';
        nonPrimaryOpp2.Primary__c = false;
        nonPrimaryOpp2.Amount = 1000.00;
        nonPrimaryOpp2.AccountId = a.Id;
        nonPrimaryOpp2.Primary_Contact__C = c.Id;
        nonPrimaryOpp2.CloseDate = Date.newInstance(2019, 6, 14);
        nonPrimaryOpp2.Name = 'TestOpp';
        nonPrimaryOpp2.Project__c = projectToUpdate.Id;
        insert nonPrimaryOpp2;

        Test.startTest();
        newOpp.Amount = 20.00;
        update newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName, Amount FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :projectToUpdate.ID][0];

        System.assertEquals(resultOpp.Amount, resultProject.Amount__c, 'Project should have amount from Opportunity');
        System.assertEquals(20, resultProject.Amount__c, 'Project should have amount of 10.00');
    }

    @isTest
    static void projectTest_changedOppProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c project = new Project__c();
        project.Primary_Contact__c = c.Id;
        project.AccountId__c = a.Id;
        project.Amount__c = 10.00;
        project.Project__c = 'PreInserted Project';
        project.Stage__c = 'New';
        insert project;

        Project__c projectTwo = new Project__c();
        projectTwo.Primary_Contact__c = c.Id;
        projectTwo.AccountId__c = a.Id;
        projectTwo.Amount__c = 0.00;
        projectTwo.Project__c = 'PreInserted Project Two';
        projectTwo.Stage__c = 'New';
        insert projectTwo;

        Opportunity newOpp = new Opportunity();
        newOpp.StageName = 'Open';
        newOpp.Primary__c = true;
        newOpp.Amount = 10.00;
        newOpp.AccountId = a.Id;
        newOpp.Primary_Contact__C = c.Id;
        newOpp.CloseDate = Date.newInstance(2019, 6, 14);
        newOpp.Name = 'TestOpp';
        newOpp.Project__c = project.Id;
        insert newOpp;

        Test.startTest();
        newOpp.Project__c = projectTwo.Id;
        update newOpp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT ID, StageName, Amount FROM Opportunity WHERE ID = :newOpp.Id][0];
        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :project.ID][0];
        Project__c resultProjectTwo = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :projectTwo.ID][0];

        System.assertEquals(
            resultOpp.Amount,
            resultProjectTwo.Amount__c,
            'Project should have amount from Opportunity'
        );
        System.assertEquals(0, resultProject.Amount__c, 'Project should have amount of 10.00');
        System.assertEquals(10, resultProjectTwo.Amount__c, 'Project should have amount of 10.00');
    }

    ///////// New Changes here
    @isTest
    static void projectTest_deletedPrimaryOppChangesProject() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(false, 'AM', 'New', 'Open', 10, 10);
        newOpp.Primary__c = true;
        insert newOpp;

        Test.startTest();
        delete newOpp;
        Test.stopTest();

        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertEquals(0, resultProject.Amount__c, 'Project should have amount of 0.00');
    }

    @isTest
    static void projectTest_deletedNonPrimaryOppChangesProject() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(true, 'AM', 'New', 'Open', 10, 10);
        newOpp.Primary__c = true;

        Test.startTest();
        delete newOpp;
        Test.stopTest();

        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertEquals(10, resultProject.Amount__c, 'Project should have amount of 10.00');
    }

    @isTest
    static void projectTest_insertedPrimaryOppChangesProject() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(false, 'AM', 'New', 'Open', 0, 10);
        newOpp.Primary__c = true;

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertEquals(10, resultProject.Amount__c, 'Project should have amount of 0.00');
    }

    @isTest
    static void projectTest_insertedNonPrimaryOppChangesProject() {
        Opportunity newOpp = TestDataFactory.createOppWithProjectAcc(false, 'AM', 'New', 'Open', 0, 10);

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Project__c resultProject = [SELECT ID, Stage__c, Amount__c FROM Project__c WHERE ID = :newOpp.Project__c][0];

        System.assertEquals(0, resultProject.Amount__c, 'Project should have amount of 0.00');
    }
    @isTest
    static void projectTest_nameLongerThanEighty() {
        Contact testContact = new Contact();
        testContact.FirstName = 'JohnDoeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
        testContact.LastName = 'Doeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
        testContact.Email = 'JohnDoeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee@mahoo.com';
        testContact.Primary_Email__c = 'JohnDoeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee@mahoo.com';
        insert testContact;

        Opportunity newOpp = new Opportunity();
        newOpp.StageName = 'Open';
        newOpp.Primary__c = false;
        newOpp.Amount = 10.00;
        newOpp.Primary_Contact__C = testContact.Id;
        newOpp.CloseDate = Date.newInstance(2019, 6, 14);
        newOpp.Line_of_Business__c = 'Instant Quote';
        newOpp.Name = 'TestOpp';

        Test.startTest();
        insert newOpp;
        Test.stopTest();

        Project__c resultProject = [SELECT ID, Name, Project__c FROM Project__c][0];

        System.assertEquals(
            'JohnDoeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee Doeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
            resultProject.Name,
            'Project should have a truncated name'
        );
        System.assertEquals(
            'JohnDoeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee Doeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
            resultProject.Project__c,
            'Project should have a truncated project'
        );
    }

    @isTest
    static void oppTest_reassignCaseOwner() {
        // we have to create the Opp second hand from the Quote because the quote handler creates Cases
        Quote_ERP__c myQuote = new Quote_ERP__C();
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.ERP_PartPK__c = 'A1234-A5678';
        myQuote.Quote_Price__c = 50.15;
        myQuote.Xometry_ERP_ID__C = 'AAAAA-00001';
        myQuote.ERP_Contact__c = 'AAAAA';
        myQuote.IS_Generic__c = false;
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);
        insert myQuote;

        Group pseQueue = [
            SELECT Id, Name
            FROM Group
            WHERE Type = 'Queue' AND Name = 'Pre-Sales Engineering Queue'
            LIMIT 1
        ];

        Case originalCase = [SELECT Id, OwnerId FROM Case][0];
        System.assertEquals(originalCase.OwnerId, pseQueue.Id, 'Case should be routed to PSE Queue originally');

        myQuote.process_isCNC_Machining__c = true;

        Test.startTest();
        update myQuote;
        Test.stopTest();

        Case changedCase = [SELECT Id, OwnerId FROM Case][0];
        System.assertNotEquals(changedCase.OwnerId, pseQueue.Id, 'Case should not be routed to PSE Queue anymore');
    }

    @isTest(seeAllData=false)
    static void testKeepTotalFieldsCase() {
        List<Opportunity> lstOpportunities = new List<Opportunity>();
        List<Case> lstCases = new List<Case>();

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Open';
        opp.Amount = 100;
        opp.LineItemCount__c = 2;
        opp.Total_Amt_BinderJetting__c = 100;
        opp.Total_Amt_Carbon__c = 200;
        opp.Total_Amt_CNC__c = 300;
        opp.Total_Amt_DieCasting__c = 400;
        opp.Total_Amt_DirectSourced__c = 500;
        opp.Total_Amt_DMLS__c = 600;
        opp.Total_Amt_Extrusion__c = 700;
        opp.Total_Amt_FDM__c = 800;
        opp.Total_Amt_HPMultJetFusion__c = 900;
        opp.Total_Amt_InjectionMolding__c = 1000;
        opp.Total_Amt_InjectionMoldingTool__c = 1100;
        opp.Total_Amt_PolyJet3D__c = 1200;
        opp.Total_Amt_SheetCutting__c = 1300;
        opp.Total_Amt_SheetMetal__c = 1400;
        opp.Total_Amt_SLA__c = 1500;
        opp.Total_Amt_SLS__c = 1600;
        opp.Total_Amt_Stamping__c = 1700;
        opp.Total_Amt_UrethaneCasting__c = 1800;
        opp.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp);

        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Test1';
        opp1.StageName = 'Open';
        opp1.Amount = 100;
        opp1.LineItemCount__c = 2;
        opp1.Total_Amt_BinderJetting__c = 100;
        opp1.Total_Amt_Carbon__c = 200;
        opp1.Total_Amt_CNC__c = 300;
        opp1.Total_Amt_DieCasting__c = 400;
        opp1.Total_Amt_DirectSourced__c = 500;
        opp1.Total_Amt_DMLS__c = 600;
        opp1.Total_Amt_Extrusion__c = 700;
        opp1.Total_Amt_FDM__c = 800;
        opp1.Total_Amt_HPMultJetFusion__c = 900;
        opp1.Total_Amt_InjectionMolding__c = 1000;
        opp1.Total_Amt_InjectionMoldingTool__c = 1100;
        opp1.Total_Amt_PolyJet3D__c = 1200;
        opp1.Total_Amt_SheetCutting__c = 1300;
        opp1.Total_Amt_SheetMetal__c = 1400;
        opp1.Total_Amt_SLA__c = 1500;
        opp1.Total_Amt_SLS__c = 1600;
        opp1.Total_Amt_Stamping__c = 1700;
        opp1.Total_Amt_UrethaneCasting__c = 1800;
        opp1.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp1);

        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Test2';
        opp2.StageName = 'Open';
        opp2.Amount = 100;
        opp2.LineItemCount__c = 2;
        opp2.Total_Amt_BinderJetting__c = 100;
        opp2.Total_Amt_Carbon__c = 200;
        opp2.Total_Amt_CNC__c = 300;
        opp2.Total_Amt_DieCasting__c = 400;
        opp2.Total_Amt_DirectSourced__c = 500;
        opp2.Total_Amt_DMLS__c = 600;
        opp2.Total_Amt_Extrusion__c = 700;
        opp2.Total_Amt_FDM__c = 800;
        opp2.Total_Amt_HPMultJetFusion__c = 900;
        opp2.Total_Amt_InjectionMolding__c = 1000;
        opp2.Total_Amt_InjectionMoldingTool__c = 1100;
        opp2.Total_Amt_PolyJet3D__c = 1200;
        opp2.Total_Amt_SheetCutting__c = 1300;
        opp2.Total_Amt_SheetMetal__c = 1400;
        opp2.Total_Amt_SLA__c = 1500;
        opp2.Total_Amt_SLS__c = 1600;
        opp2.Total_Amt_Stamping__c = 1700;
        opp2.Total_Amt_UrethaneCasting__c = 1800;
        opp2.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp2);

        insert lstOpportunities;

        Case testCase = new Case(Opportunity__c = opp.Id);
        lstCases.add(testCase);

        Case testCase1 = new Case(Opportunity__c = opp1.Id);
        lstCases.add(testCase1);

        Case testCase2 = new Case(Opportunity__c = opp2.Id);
        lstCases.add(testCase2);

        Case testCase3 = new Case(Opportunity__c = opp.Id);
        lstCases.add(testCase3);

        insert lstCases;

        Test.startTest();
        lstOpportunities[0].Amount = 500;
        lstOpportunities[0].StageName = 'Closed Won';
        lstOpportunities[0].Total_Amt_Extrusion__c = 200;
        lstOpportunities[0].Total_Amt_FDM__c = 200;
        lstOpportunities[0].Total_Amt_HPMultJetFusion__c = 200;
        lstOpportunities[0].Total_Amt_InjectionMolding__c = 200;
        lstOpportunities[0].Total_Amt_InjectionMoldingTool__c = 200;
        lstOpportunities[0].Total_Amt_PolyJet3D__c = 200;
        lstOpportunities[0].Total_Amt_SheetCutting__c = 300;
        lstOpportunities[0].Total_Amt_SheetMetal__c = 300;
        lstOpportunities[0].Total_Amt_SLA__c = 300;
        lstOpportunities[0].Total_Amt_SLS__c = 300;
        lstOpportunities[0].Total_Amt_Stamping__c = 300;
        lstOpportunities[0].Total_Amt_UrethaneCasting__c = 300;
        update lstOpportunities[0];

        lstOpportunities[1].LineItemCount__c = 5;
        lstOpportunities[1].StageName = 'Closed Lost';
        lstOpportunities[1].Total_Amt_BinderJetting__c = 100;
        lstOpportunities[1].Total_Amt_Carbon__c = 100;
        lstOpportunities[1].Total_Amt_CNC__c = 100;
        lstOpportunities[1].Total_Amt_DieCasting__c = 100;
        lstOpportunities[1].Total_Amt_DirectSourced__c = 100;
        lstOpportunities[1].Total_Amt_DMLS__c = 100;
        lstOpportunities[1].Total_Amt_SheetCutting__c = 300;
        lstOpportunities[1].Total_Amt_SheetMetal__c = 300;
        lstOpportunities[1].Total_Amt_SLA__c = 300;
        lstOpportunities[1].Total_Amt_SLS__c = 300;
        lstOpportunities[1].Total_Amt_Stamping__c = 300;
        lstOpportunities[1].Total_Amt_UrethaneCasting__c = 300;
        update lstOpportunities[1];

        lstOpportunities[2].Amount = 200;
        lstOpportunities[2].LineItemCount__c = 5;
        lstOpportunities[2].StageName = 'Closed Won';
        lstOpportunities[2].Total_Amt_BinderJetting__c = 100;
        lstOpportunities[2].Total_Amt_Carbon__c = 100;
        lstOpportunities[2].Total_Amt_CNC__c = 100;
        lstOpportunities[2].Total_Amt_DieCasting__c = 100;
        lstOpportunities[2].Total_Amt_DirectSourced__c = 100;
        lstOpportunities[2].Total_Amt_DMLS__c = 100;
        lstOpportunities[2].Total_Amt_Extrusion__c = 200;
        lstOpportunities[2].Total_Amt_FDM__c = 200;
        lstOpportunities[2].Total_Amt_HPMultJetFusion__c = 200;
        lstOpportunities[2].Total_Amt_InjectionMolding__c = 200;
        lstOpportunities[2].Total_Amt_InjectionMoldingTool__c = 200;
        lstOpportunities[2].Total_Amt_PolyJet3D__c = 200;
        update lstOpportunities[2];
        Test.stopTest();

        testCase = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                Total_Amt_BinderJetting_opps__c,
                Total_Amt_Carbon_opps__c,
                Total_Amt_CNC_opps__c,
                Total_Amt_DieCasting_opps__c,
                Total_Amt_DirectSourced_opps__c,
                Total_Amt_DMLS_opps__c,
                Total_Amt_Extrusion_opps__c,
                Total_Amt_FDM_opps__c,
                Total_Amt_HPMultJetFusion_opps__c,
                Total_Amt_InjectionMolding_opps__c,
                Total_Amt_InjectionMoldingTool_opps__c,
                Total_Amt_PolyJet3D_opps__c,
                Total_Amt_SheetCutting_opps__c,
                Total_Amt_SheetMetal_opps__c,
                Total_Amt_SLA_opps__c,
                Total_Amt_SLS_opps__c,
                Total_Amt_Stamping_opps__c,
                Total_Amt_UrethaneCasting_opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :lstCases[0].Id
            LIMIT 1
        ];
        testCase1 = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                Total_Amt_BinderJetting_opps__c,
                Total_Amt_Carbon_opps__c,
                Total_Amt_CNC_opps__c,
                Total_Amt_DieCasting_opps__c,
                Total_Amt_DirectSourced_opps__c,
                Total_Amt_DMLS_opps__c,
                Total_Amt_Extrusion_opps__c,
                Total_Amt_FDM_opps__c,
                Total_Amt_HPMultJetFusion_opps__c,
                Total_Amt_InjectionMolding_opps__c,
                Total_Amt_InjectionMoldingTool_opps__c,
                Total_Amt_PolyJet3D_opps__c,
                Total_Amt_SheetCutting_opps__c,
                Total_Amt_SheetMetal_opps__c,
                Total_Amt_SLA_opps__c,
                Total_Amt_SLS_opps__c,
                Total_Amt_Stamping_opps__c,
                Total_Amt_UrethaneCasting_opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :lstCases[1].Id
            LIMIT 1
        ];
        testCase2 = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                Total_Amt_BinderJetting_opps__c,
                Total_Amt_Carbon_opps__c,
                Total_Amt_CNC_opps__c,
                Total_Amt_DieCasting_opps__c,
                Total_Amt_DirectSourced_opps__c,
                Total_Amt_DMLS_opps__c,
                Total_Amt_Extrusion_opps__c,
                Total_Amt_FDM_opps__c,
                Total_Amt_HPMultJetFusion_opps__c,
                Total_Amt_InjectionMolding_opps__c,
                Total_Amt_InjectionMoldingTool_opps__c,
                Total_Amt_PolyJet3D_opps__c,
                Total_Amt_SheetCutting_opps__c,
                Total_Amt_SheetMetal_opps__c,
                Total_Amt_SLA_opps__c,
                Total_Amt_SLS_opps__c,
                Total_Amt_Stamping_opps__c,
                Total_Amt_UrethaneCasting_opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :lstCases[2].Id
            LIMIT 1
        ];
        testCase3 = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                Total_Amt_BinderJetting_opps__c,
                Total_Amt_Carbon_opps__c,
                Total_Amt_CNC_opps__c,
                Total_Amt_DieCasting_opps__c,
                Total_Amt_DirectSourced_opps__c,
                Total_Amt_DMLS_opps__c,
                Total_Amt_Extrusion_opps__c,
                Total_Amt_FDM_opps__c,
                Total_Amt_HPMultJetFusion_opps__c,
                Total_Amt_InjectionMolding_opps__c,
                Total_Amt_InjectionMoldingTool_opps__c,
                Total_Amt_PolyJet3D_opps__c,
                Total_Amt_SheetCutting_opps__c,
                Total_Amt_SheetMetal_opps__c,
                Total_Amt_SLA_opps__c,
                Total_Amt_SLS_opps__c,
                Total_Amt_Stamping_opps__c,
                Total_Amt_UrethaneCasting_opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :lstCases[3].Id
            LIMIT 1
        ];

        System.assertEquals(1, testCase.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            2,
            testCase.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(500, testCase.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            100,
            testCase.Total_Amt_BinderJetting_opps__c,
            'The total amount of BinderJetting opps does not match'
        );
        System.assertEquals(200, testCase.Total_Amt_Carbon_opps__c, 'The total amount of Carbon opps does not match');
        System.assertEquals(300, testCase.Total_Amt_CNC_opps__c, 'The total amount of CNC opps does not match');
        System.assertEquals(
            400,
            testCase.Total_Amt_DieCasting_opps__c,
            'The total amount of DieCasting opps does not match'
        );
        System.assertEquals(
            500,
            testCase.Total_Amt_DirectSourced_opps__c,
            'The total amount of DirectSourced opps does not match'
        );
        System.assertEquals(600, testCase.Total_Amt_DMLS_opps__c, 'The total amount of DMLS opps does not match');
        System.assertEquals(
            200,
            testCase.Total_Amt_Extrusion_opps__c,
            'The total amount of Extrusion opps does not match'
        );
        System.assertEquals(200, testCase.Total_Amt_FDM_opps__c, 'The total amount of FDM opps does not match');
        System.assertEquals(
            200,
            testCase.Total_Amt_HPMultJetFusion_opps__c,
            'The total amount of HPMultJetFusion opps does not match'
        );
        System.assertEquals(
            200,
            testCase.Total_Amt_InjectionMolding_opps__c,
            'The total amount of InjectionMolding opps does not match'
        );
        System.assertEquals(
            200,
            testCase.Total_Amt_InjectionMoldingTool_opps__c,
            'The total amount of InjectionMoldingTool opps does not match'
        );
        System.assertEquals(
            200,
            testCase.Total_Amt_PolyJet3D_opps__c,
            'The total amount of PolyJet3D opps does not match'
        );
        System.assertEquals(
            300,
            testCase.Total_Amt_SheetCutting_opps__c,
            'The total amount of SheetCutting opps does not match'
        );
        System.assertEquals(
            300,
            testCase.Total_Amt_SheetMetal_opps__c,
            'The total amount of SheetMetal opps does not match'
        );
        System.assertEquals(300, testCase.Total_Amt_SLA_opps__c, 'The total amount of SLA opps does not match');
        System.assertEquals(300, testCase.Total_Amt_SLS_opps__c, 'The total amount of SLS opps does not match');
        System.assertEquals(
            300,
            testCase.Total_Amt_Stamping_opps__c,
            'The total amount of Stamping opps does not match'
        );
        System.assertEquals(
            300,
            testCase.Total_Amt_UrethaneCasting_opps__c,
            'The total amount of UrethaneCasting opps does not match'
        );
        System.assertEquals(
            500,
            testCase.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            0,
            testCase.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );

        System.assertEquals(1, testCase1.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            5,
            testCase1.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(100, testCase1.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            100,
            testCase1.Total_Amt_BinderJetting_opps__c,
            'The total amount of BinderJetting opps does not match'
        );
        System.assertEquals(100, testCase1.Total_Amt_Carbon_opps__c, 'The total amount of Carbon opps does not match');
        System.assertEquals(100, testCase1.Total_Amt_CNC_opps__c, 'The total amount of CNC opps does not match');
        System.assertEquals(
            100,
            testCase1.Total_Amt_DieCasting_opps__c,
            'The total amount of DieCasting opps does not match'
        );
        System.assertEquals(
            100,
            testCase1.Total_Amt_DirectSourced_opps__c,
            'The total amount of DirectSourced opps does not match'
        );
        System.assertEquals(100, testCase1.Total_Amt_DMLS_opps__c, 'The total amount of DMLS opps does not match');
        System.assertEquals(
            700,
            testCase1.Total_Amt_Extrusion_opps__c,
            'The total amount of Extrusion opps does not match'
        );
        System.assertEquals(800, testCase1.Total_Amt_FDM_opps__c, 'The total amount of FDM opps does not match');
        System.assertEquals(
            900,
            testCase1.Total_Amt_HPMultJetFusion_opps__c,
            'The total amount of HPMultJetFusion opps does not match'
        );
        System.assertEquals(
            1000,
            testCase1.Total_Amt_InjectionMolding_opps__c,
            'The total amount of InjectionMolding opps does not match'
        );
        System.assertEquals(
            1100,
            testCase1.Total_Amt_InjectionMoldingTool_opps__c,
            'The total amount of InjectionMoldingTool opps does not match'
        );
        System.assertEquals(
            1200,
            testCase1.Total_Amt_PolyJet3D_opps__c,
            'The total amount of PolyJet3D opps does not match'
        );
        System.assertEquals(
            300,
            testCase1.Total_Amt_SheetCutting_opps__c,
            'The total amount of SheetCutting opps does not match'
        );
        System.assertEquals(
            300,
            testCase1.Total_Amt_SheetMetal_opps__c,
            'The total amount of SheetMetal opps does not match'
        );
        System.assertEquals(300, testCase1.Total_Amt_SLA_opps__c, 'The total amount of SLA opps does not match');
        System.assertEquals(300, testCase1.Total_Amt_SLS_opps__c, 'The total amount of SLS opps does not match');
        System.assertEquals(
            300,
            testCase1.Total_Amt_Stamping_opps__c,
            'The total amount of Stamping opps does not match'
        );
        System.assertEquals(
            300,
            testCase1.Total_Amt_UrethaneCasting_opps__c,
            'The total amount of UrethaneCasting opps does not match'
        );
        System.assertEquals(
            0,
            testCase1.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            100,
            testCase1.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );

        System.assertEquals(1, testCase2.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            5,
            testCase2.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(200, testCase2.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            100,
            testCase2.Total_Amt_BinderJetting_opps__c,
            'The total amount of BinderJetting opps does not match'
        );
        System.assertEquals(100, testCase2.Total_Amt_Carbon_opps__c, 'The total amount of Carbon opps does not match');
        System.assertEquals(100, testCase2.Total_Amt_CNC_opps__c, 'The total amount of CNC opps does not match');
        System.assertEquals(
            100,
            testCase2.Total_Amt_DieCasting_opps__c,
            'The total amount of DieCasting opps does not match'
        );
        System.assertEquals(
            100,
            testCase2.Total_Amt_DirectSourced_opps__c,
            'The total amount of DirectSourced opps does not match'
        );
        System.assertEquals(100, testCase2.Total_Amt_DMLS_opps__c, 'The total amount of DMLS opps does not match');
        System.assertEquals(
            200,
            testCase2.Total_Amt_Extrusion_opps__c,
            'The total amount of Extrusion opps does not match'
        );
        System.assertEquals(200, testCase2.Total_Amt_FDM_opps__c, 'The total amount of FDM opps does not match');
        System.assertEquals(
            200,
            testCase2.Total_Amt_HPMultJetFusion_opps__c,
            'The total amount of HPMultJetFusion opps does not match'
        );
        System.assertEquals(
            200,
            testCase2.Total_Amt_InjectionMolding_opps__c,
            'The total amount of InjectionMolding opps does not match'
        );
        System.assertEquals(
            200,
            testCase2.Total_Amt_InjectionMoldingTool_opps__c,
            'The total amount of InjectionMoldingTool opps does not match'
        );
        System.assertEquals(
            200,
            testCase2.Total_Amt_PolyJet3D_opps__c,
            'The total amount of PolyJet3D opps does not match'
        );
        System.assertEquals(
            1300,
            testCase2.Total_Amt_SheetCutting_opps__c,
            'The total amount of SheetCutting opps does not match'
        );
        System.assertEquals(
            1400,
            testCase2.Total_Amt_SheetMetal_opps__c,
            'The total amount of SheetMetal opps does not match'
        );
        System.assertEquals(1500, testCase2.Total_Amt_SLA_opps__c, 'The total amount of SLA opps does not match');
        System.assertEquals(1600, testCase2.Total_Amt_SLS_opps__c, 'The total amount of SLS opps does not match');
        System.assertEquals(
            1700,
            testCase2.Total_Amt_Stamping_opps__c,
            'The total amount of Stamping opps does not match'
        );
        System.assertEquals(
            1800,
            testCase2.Total_Amt_UrethaneCasting_opps__c,
            'The total amount of UrethaneCasting opps does not match'
        );
        System.assertEquals(
            200,
            testCase2.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            0,
            testCase2.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );

        System.assertEquals(1, testCase3.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            2,
            testCase3.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(500, testCase3.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            100,
            testCase3.Total_Amt_BinderJetting_opps__c,
            'The total amount of BinderJetting opps does not match'
        );
        System.assertEquals(200, testCase3.Total_Amt_Carbon_opps__c, 'The total amount of Carbon opps does not match');
        System.assertEquals(300, testCase3.Total_Amt_CNC_opps__c, 'The total amount of CNC opps does not match');
        System.assertEquals(
            400,
            testCase3.Total_Amt_DieCasting_opps__c,
            'The total amount of DieCasting opps does not match'
        );
        System.assertEquals(
            500,
            testCase3.Total_Amt_DirectSourced_opps__c,
            'The total amount of DirectSourced opps does not match'
        );
        System.assertEquals(600, testCase3.Total_Amt_DMLS_opps__c, 'The total amount of DMLS opps does not match');
        System.assertEquals(
            200,
            testCase3.Total_Amt_Extrusion_opps__c,
            'The total amount of Extrusion opps does not match'
        );
        System.assertEquals(200, testCase3.Total_Amt_FDM_opps__c, 'The total amount of FDM opps does not match');
        System.assertEquals(
            200,
            testCase3.Total_Amt_HPMultJetFusion_opps__c,
            'The total amount of HPMultJetFusion opps does not match'
        );
        System.assertEquals(
            200,
            testCase3.Total_Amt_InjectionMolding_opps__c,
            'The total amount of InjectionMolding opps does not match'
        );
        System.assertEquals(
            200,
            testCase3.Total_Amt_InjectionMoldingTool_opps__c,
            'The total amount of InjectionMoldingTool opps does not match'
        );
        System.assertEquals(
            200,
            testCase3.Total_Amt_PolyJet3D_opps__c,
            'The total amount of PolyJet3D opps does not match'
        );
        System.assertEquals(
            300,
            testCase3.Total_Amt_SheetCutting_opps__c,
            'The total amount of SheetCutting opps does not match'
        );
        System.assertEquals(
            300,
            testCase3.Total_Amt_SheetMetal_opps__c,
            'The total amount of SheetMetal opps does not match'
        );
        System.assertEquals(300, testCase3.Total_Amt_SLA_opps__c, 'The total amount of SLA opps does not match');
        System.assertEquals(300, testCase3.Total_Amt_SLS_opps__c, 'The total amount of SLS opps does not match');
        System.assertEquals(
            300,
            testCase3.Total_Amt_Stamping_opps__c,
            'The total amount of Stamping opps does not match'
        );
        System.assertEquals(
            300,
            testCase3.Total_Amt_UrethaneCasting_opps__c,
            'The total amount of UrethaneCasting opps does not match'
        );
        System.assertEquals(
            500,
            testCase3.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            0,
            testCase3.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );
    }

    @isTest(seeAllData=false)
    static void testKeepTotalFieldsDelOpp() {
        List<Opportunity> lstOpportunities = new List<Opportunity>();

        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Closed Won';
        opp.Amount = 100;
        opp.LineItemCount__c = 2;
        opp.CloseDate = System.today().addDays(10);
        opp.Total_Amt_BinderJetting__c = 100;
        opp.Total_Amt_Carbon__c = 200;
        opp.Total_Amt_CNC__c = 300;
        opp.Total_Amt_DieCasting__c = 400;
        opp.Total_Amt_DirectSourced__c = 500;
        opp.Total_Amt_DMLS__c = 600;
        opp.Total_Amt_Extrusion__c = 700;
        opp.Total_Amt_FDM__c = 800;
        opp.Total_Amt_HPMultJetFusion__c = 900;
        opp.Total_Amt_InjectionMolding__c = 1000;
        opp.Total_Amt_InjectionMoldingTool__c = 1100;
        opp.Total_Amt_PolyJet3D__c = 1200;
        opp.Total_Amt_SheetCutting__c = 1300;
        opp.Total_Amt_SheetMetal__c = 1400;
        opp.Total_Amt_SLA__c = 1500;
        opp.Total_Amt_SLS__c = 1600;
        opp.Total_Amt_Stamping__c = 1700;
        opp.Total_Amt_UrethaneCasting__c = 1800;
        lstOpportunities.add(opp);

        Opportunity opp1 = new Opportunity(Name = 'Test1');
        opp1.StageName = 'Closed Lost';
        opp1.Amount = 100;
        opp1.LineItemCount__c = 2;
        opp1.CloseDate = System.today().addDays(10);
        opp1.Total_Amt_BinderJetting__c = 100;
        opp1.Total_Amt_Carbon__c = 200;
        opp1.Total_Amt_CNC__c = 300;
        opp1.Total_Amt_DieCasting__c = 400;
        opp1.Total_Amt_DirectSourced__c = 500;
        opp1.Total_Amt_DMLS__c = 600;
        opp1.Total_Amt_Extrusion__c = 700;
        opp1.Total_Amt_FDM__c = 800;
        opp1.Total_Amt_HPMultJetFusion__c = 900;
        opp1.Total_Amt_InjectionMolding__c = 1000;
        opp1.Total_Amt_InjectionMoldingTool__c = 1100;
        opp1.Total_Amt_PolyJet3D__c = 1200;
        opp1.Total_Amt_SheetCutting__c = 1300;
        opp1.Total_Amt_SheetMetal__c = 1400;
        opp1.Total_Amt_SLA__c = 1500;
        opp1.Total_Amt_SLS__c = 1600;
        opp1.Total_Amt_Stamping__c = 1700;
        opp1.Total_Amt_UrethaneCasting__c = 1800;
        lstOpportunities.add(opp1);

        insert lstOpportunities;

        Case testCase = new Case(Opportunity__c = opp.Id);
        insert testCase;

        testCase.Opportunity__c = opp1.Id;
        update testCase;

        testCase = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                Total_Amt_BinderJetting_opps__c,
                Total_Amt_Carbon_opps__c,
                Total_Amt_CNC_opps__c,
                Total_Amt_DieCasting_opps__c,
                Total_Amt_DirectSourced_opps__c,
                Total_Amt_DMLS_opps__c,
                Total_Amt_Extrusion_opps__c,
                Total_Amt_FDM_opps__c,
                Total_Amt_HPMultJetFusion_opps__c,
                Total_Amt_InjectionMolding_opps__c,
                Total_Amt_InjectionMoldingTool_opps__c,
                Total_Amt_PolyJet3D_opps__c,
                Total_Amt_SheetCutting_opps__c,
                Total_Amt_SheetMetal_opps__c,
                Total_Amt_SLA_opps__c,
                Total_Amt_SLS_opps__c,
                Total_Amt_Stamping_opps__c,
                Total_Amt_UrethaneCasting_opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :testCase.Id
            LIMIT 1
        ];

        Test.startTest();
        delete lstOpportunities[0];
        Test.stopTest();

        testCase = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                Total_Amt_BinderJetting_opps__c,
                Total_Amt_Carbon_opps__c,
                Total_Amt_CNC_opps__c,
                Total_Amt_DieCasting_opps__c,
                Total_Amt_DirectSourced_opps__c,
                Total_Amt_DMLS_opps__c,
                Total_Amt_Extrusion_opps__c,
                Total_Amt_FDM_opps__c,
                Total_Amt_HPMultJetFusion_opps__c,
                Total_Amt_InjectionMolding_opps__c,
                Total_Amt_InjectionMoldingTool_opps__c,
                Total_Amt_PolyJet3D_opps__c,
                Total_Amt_SheetCutting_opps__c,
                Total_Amt_SheetMetal_opps__c,
                Total_Amt_SLA_opps__c,
                Total_Amt_SLS_opps__c,
                Total_Amt_Stamping_opps__c,
                Total_Amt_UrethaneCasting_opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :testCase.Id
            LIMIT 1
        ];

        System.assertEquals(1, testCase.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            2,
            testCase.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(100, testCase.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            100,
            testCase.Total_Amt_BinderJetting_opps__c,
            'The total amount of BinderJetting opps does not match'
        );
        System.assertEquals(200, testCase.Total_Amt_Carbon_opps__c, 'The total amount of Carbon opps does not match');
        System.assertEquals(300, testCase.Total_Amt_CNC_opps__c, 'The total amount of CNC opps does not match');
        System.assertEquals(
            400,
            testCase.Total_Amt_DieCasting_opps__c,
            'The total amount of DieCasting opps does not match'
        );
        System.assertEquals(
            500,
            testCase.Total_Amt_DirectSourced_opps__c,
            'The total amount of DirectSourced opps does not match'
        );
        System.assertEquals(600, testCase.Total_Amt_DMLS_opps__c, 'The total amount of DMLS opps does not match');
        System.assertEquals(
            700,
            testCase.Total_Amt_Extrusion_opps__c,
            'The total amount of Extrusion opps does not match'
        );
        System.assertEquals(800, testCase.Total_Amt_FDM_opps__c, 'The total amount of FDM opps does not match');
        System.assertEquals(
            900,
            testCase.Total_Amt_HPMultJetFusion_opps__c,
            'The total amount of HPMultJetFusion opps does not match'
        );
        System.assertEquals(
            1000,
            testCase.Total_Amt_InjectionMolding_opps__c,
            'The total amount of InjectionMolding opps does not match'
        );
        System.assertEquals(
            1100,
            testCase.Total_Amt_InjectionMoldingTool_opps__c,
            'The total amount of InjectionMoldingTool opps does not match'
        );
        System.assertEquals(
            1200,
            testCase.Total_Amt_PolyJet3D_opps__c,
            'The total amount of PolyJet3D opps does not match'
        );
        System.assertEquals(
            1300,
            testCase.Total_Amt_SheetCutting_opps__c,
            'The total amount of SheetCutting opps does not match'
        );
        System.assertEquals(
            1400,
            testCase.Total_Amt_SheetMetal_opps__c,
            'The total amount of SheetMetal opps does not match'
        );
        System.assertEquals(1500, testCase.Total_Amt_SLA_opps__c, 'The total amount of SLA opps does not match');
        System.assertEquals(1600, testCase.Total_Amt_SLS_opps__c, 'The total amount of SLS opps does not match');
        System.assertEquals(
            1700,
            testCase.Total_Amt_Stamping_opps__c,
            'The total amount of Stamping opps does not match'
        );
        System.assertEquals(
            1800,
            testCase.Total_Amt_UrethaneCasting_opps__c,
            'The total amount of UrethaneCasting opps does not match'
        );
        System.assertEquals(
            0,
            testCase.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            100,
            testCase.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );
    }

    @isTest(seeAllData=false)
    static void createTeamMemberTest() {
        Opportunity testOpp = new Opportunity(Name = 'Test', CloseDate = Date.today(), StageName = 'Open');
        insert testOpp;

        Case testCase = new Case(
            SuppliedEmail = 'test@test.com',
            Opportunity__c = testOpp.Id,
            RecordTypeId = AppConstants.casePSERecordTypeId
        );
        insert new List<Case>{ testCase };

        Id originalOwnerId = [SELECT OwnerId FROM Case WHERE Id = :testCase.Id].OwnerId;

        System.assertEquals(
            1,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase.Id AND MemberId = :originalOwnerId].size(),
            'Only one CaseTeamMember should be created.'
        );

        User testContactOwnerUser = TestDataFactory.createTestUsers()[0];

        Test.startTest();
        testOpp.OwnerId = testContactOwnerUser.Id;
        update testOpp;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase.Id AND MemberId = :testContactOwnerUser.Id]
                .size(),
            'Only one CaseTeamMember should be created.'
        );

        System.assertEquals(
            0,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase.Id AND MemberId = :originalOwnerId].size(),
            'CaseTeamMember should be deleted.'
        );
    }
    @isTest
    public static void assignOppToCaseTest() {
        Account a = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 1)[0];

        Case c = new Case();
        c.Subject = 'test1';
        c.Status = 'New';
        c.Type = 'FinServ';
        c.Supplies_Xometry_Job__c = 'J0036578';
        c.RecordTypeId = AppConstants.caseSellerMarketPlaceRTypeId;
        insert c;

        Opportunity opp = new Opportunity();
        opp.Name = 'Opp1';
        opp.CloseDate = Date.today();
        opp.AccountId = a.Id;
        opp.StageName = 'New';
        opp.Shadow_JobId__c = c.Supplies_Xometry_Job__c;
        opp.RecordTypeId = AppConstants.oppSellerMarketplaceRecordTypeId;

        Test.startTest();
        insert opp;
        Test.stopTest();

        Case cResult = [SELECT Supplies_Xometry_Job__c, Opportunity__c FROM Case WHERE Id = :c.Id];
        Opportunity resultOpp = [SELECT Id FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(resultOpp.Id, cResult.Opportunity__c, 'Case Match with opportunity');
    }

    @isTest(seeAllData=false)
    static void associateToCaseOppTest() {
        CaseOpportunity__c caseOppTest = new CaseOpportunity__c(Xometry_ERP_ID__c = 'AAAAA-00001');
        CaseOpportunity__c caseOppTest2 = new CaseOpportunity__c(Xometry_ERP_ID__c = 'AAAAA-00002');
        insert new List<CaseOpportunity__c>{ caseOppTest, caseOppTest2 };

        Opportunity testOpp = new Opportunity(
            Name = 'Test',
            CloseDate = Date.today(),
            StageName = 'Open',
            Last_Quote_Xometry_ERP_ID__c = 'AAAAA-00001'
        );
        Opportunity testOpp2 = new Opportunity(
            Name = 'Test',
            CloseDate = Date.today(),
            StageName = 'Open',
            Last_Quote_Xometry_ERP_ID__c = 'AAAAA-00002'
        );
        insert testOpp2;

        Test.startTest();
        testOpp2.Last_Quote_Xometry_ERP_ID__c = 'AAAAA-00003';
        upsert new List<Opportunity>{ testOpp, testOpp2 };
        Test.stopTest();

        Map<Id, CaseOpportunity__c> caseOppResult = new Map<Id, CaseOpportunity__c>(
            [SELECT Opportunity__c FROM CaseOpportunity__c]
        );

        System.assertEquals(
            testOpp.Id,
            caseOppResult.get(caseOppTest.Id).Opportunity__c,
            'CaseOpportunity__c should be updated with the new Opp'
        );
        System.assertEquals(
            null,
            caseOppResult.get(caseOppTest2.Id).Opportunity__c,
            'CaseOpportunity__c should be reset'
        );
    }

    @isTest
    static void addProjectAdHoc() {
        //Create an Opp through quote
        Set<ID> testOppIDSet = new Set<ID>();
        testDataFactory.createQuoteWithAcc(true, 'AM');
        Opportunity testOpp = [SELECT Id, Project__c FROM Opportunity][0];
        testOppIDSet.add(testOpp.ID);
        //Delete the project
        Project__c testProject = new Project__c();
        testProject.ID = testOpp.Project__c;
        delete testProject;
        test.StartTest();
        Opportunity testOppSetup = [SELECT Id, Project__c FROM Opportunity WHERE ID = :testOpp.ID];
        List<Project__c> projectSize = [SELECT ID FROM Project__c];
        System.assertEquals(null, testOppSetup.Project__c, 'A project existed');
        System.assertEquals(0, projectSize.size(), 'The opp had a project');
        OpportunityHandler.associateToProjectAdHoc(testOppIDSet);
        test.StopTest();
        Opportunity testOppPost = [SELECT Id, Project__c FROM Opportunity WHERE ID = :testOpp.ID];
        System.assertEquals(true, String.isNotBlank(testOppPost.Project__c), 'The opp did not get a project');
        List<Project__c> projectPost = [SELECT ID FROM Project__c];
        System.assertEquals(1, projectPost.size(), 'There was no project');
    }

    @isTest
    static void setFirstSalesAndAccountOwners_OnInsert() {
        Account a = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 1)[0];

        Id accountOwnerId = [SELECT OwnerId FROM Account WHERE Id = :a.ID].OwnerId;

        Opportunity opp = new Opportunity();
        opp.Name = 'Opp1';
        opp.CloseDate = Date.today();
        opp.AccountId = a.Id;
        opp.StageName = 'New';
        opp.RecordTypeId = AppConstants.oppManufacturingServRTypeID;
        opp.OwnerID = AppConstants.SALES_HOUSE_USER;
        opp.Quote_Created_Date__c = AppConstants.oppOwnerStampLaunchTime.addDays(28);

        Test.startTest();
        insert opp;
        Test.stopTest();

        Opportunity resultOpp = [
            SELECT
                Id,
                OwnerID,
                FirstSalesOwner__c,
                FirstSalesOwnerRole__c,
                AccountOwnerOnCreation__c,
                AccountOwnerOnCreationRole__c
            FROM Opportunity
            LIMIT 1
        ][0];
        System.assertEquals(resultOpp.OwnerID, resultOpp.FirstSalesOwner__c, 'The First Sales Owner was not populated');
        System.assertNotEquals(null, resultOpp.FirstSalesOwnerRole__c, 'The First Sales Owner role was not populated');
        System.assertEquals(
            accountOwnerId,
            resultOpp.AccountOwnerOnCreation__c,
            'The Account Owner on creation does not match the quote\'s Account Owner'
        );
        System.assertEquals(
            'BDR',
            resultOpp.AccountOwnerOnCreationRole__c,
            'The Account Owner On Creation\'s role was not populated'
        );
    }

    @isTest
    static void setInitialAccountOwner_ExcludedSalesOwner_OnInsert() {
        Account a = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 1)[0];

        Id accountOwnerId = [SELECT OwnerId FROM Account WHERE Id = :a.ID].OwnerId;

        Opportunity opp = new Opportunity();
        opp.Name = 'Opp1';
        opp.CloseDate = Date.today();
        opp.AccountId = a.Id;
        opp.StageName = 'New';
        opp.RecordTypeId = AppConstants.oppManufacturingServRTypeID;
        //Use a user from the exclusion list
        opp.OwnerID = AppConstants.HOUSE_USERS_TO_EXCLUDE_FOR_SALES_OWNERSHIP[0];
        opp.Quote_Created_Date__c = AppConstants.oppOwnerStampLaunchTime.addDays(28);

        Test.startTest();
        insert opp;
        Test.stopTest();

        Opportunity resultOpp = [
            SELECT
                Id,
                OwnerID,
                FirstSalesOwner__c,
                FirstSalesOwnerRole__c,
                AccountOwnerOnCreation__c,
                AccountOwnerOnCreationRole__c
            FROM Opportunity
            LIMIT 1
        ][0];
        System.assertEquals(
            null,
            resultOpp.FirstSalesOwner__c,
            'The First Sales Owner was populated with an excluded user'
        );
        System.assertEquals(
            null,
            resultOpp.FirstSalesOwnerRole__c,
            'The First Sales Owner role was populated with the role from an excluded user'
        );
        System.assertEquals(
            accountOwnerId,
            resultOpp.AccountOwnerOnCreation__c,
            'The Account Owner on creation does not match the quote\'s Account Owner'
        );
        System.assertNotEquals(
            null,
            resultOpp.AccountOwnerOnCreationRole__c,
            'The Account Owner On Creation\'s role was not populated'
        );
    }

    @isTest
    static void setFirstSalesOwnerAndIgnoreAccountOwnerChange_OnUpdate() {
        Account a = TestDataFactory.createTestAccountNonGenerics(1, 'Ops', 1)[0];

        Opportunity opp = new Opportunity();
        opp.Name = 'Opp1';
        opp.CloseDate = Date.today();
        opp.AccountId = a.Id;
        opp.StageName = 'New';
        opp.RecordTypeId = AppConstants.oppManufacturingServRTypeID;
        //Use a user from the exclusion list
        opp.OwnerID = AppConstants.HOUSE_USERS_TO_EXCLUDE_FOR_SALES_OWNERSHIP[0];
        opp.Quote_Created_Date__c = AppConstants.oppOwnerStampLaunchTime.addDays(28);
        insert Opp;

        a.OwnerID = AppConstants.SALES_API_USER;
        update a;

        Test.startTest();
        //Reassign the Opp to a qualified user
        opp.OwnerID = AppConstants.SALES_HOUSE_USER;
        update opp;
        Test.stopTest();

        Opportunity resultOpp = [
            SELECT
                Id,
                OwnerID,
                FirstSalesOwner__c,
                FirstSalesOwnerRole__c,
                AccountOwnerOnCreation__c,
                AccountOwnerOnCreationRole__c
            FROM Opportunity
            LIMIT 1
        ][0];
        System.assertEquals(
            AppConstants.SALES_HOUSE_USER,
            resultOpp.FirstSalesOwner__c,
            'The First Sales Owner was not populated when a qualified user owner the opp'
        );
        System.assertNotEquals(null, resultOpp.FirstSalesOwnerRole__c, 'The First Sales Owner role was not populated');
        System.assertNotEquals(
            AppConstants.SALES_API_USER,
            resultOpp.AccountOwnerOnCreation__c,
            'The Account Owner On Creation should not have changed when the account owner changed'
        );
    }

    @isTest
    static void setAccountOwnerFromOrder() {
        Account a = TestDataFactory.createTestAccountNonGenerics(1, 'Ops', 1)[0];

        Id accountOwnerId = [SELECT OwnerId FROM Account WHERE Id = :a.ID].OwnerId;

        Opportunity opp = new Opportunity();
        opp.Name = 'Opp1';
        opp.CloseDate = Date.today();
        opp.AccountId = a.Id;
        opp.StageName = 'New';
        opp.RecordTypeId = AppConstants.oppManufacturingServRTypeID;
        opp.OwnerID = accountOwnerId;
        opp.Order_Date__c = AppConstants.oppOwnerStampLaunchTime.addDays(28);

        Test.startTest();
        insert opp;
        Test.stopTest();

        Opportunity resultOpp = [SELECT Id, AccountOwnerOnCreation__c FROM Opportunity LIMIT 1][0];

        System.assertNotEquals(
            null,
            resultOpp.AccountOwnerOnCreation__c,
            'The Account Owner On Creation was not populated when the Opp was created by an order'
        );
    }
}