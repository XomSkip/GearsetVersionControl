@isTest
public with sharing class DownstreamEvent_Test {
    static final ID casePSERecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('PSE_Case')
        .getRecordTypeId();

    @isTest
    private static void doNotChangeCSAMContact() {
        //Change 1 Test
        //Have an Account with 2 Contacts and 1 of those Contacts is owned the CSAM on the account team.
        // Update the Account Owner. The Contact owned by the Csam should not change.
        //This Test Will Change a CSAM to a different CSAM. Everything not owned by a CSAM should not change.
        Map<String, List<sObject>> mySetUpMap = TestDataFactory.createDataForEnterpriseTest();
        Account testAccount = (Account) mySetUpMap.get('Account')[0];
        Account_Team__C testATeamRec = (Account_Team__C) mySetupMap.get('Account_Team__C')[0];
        List<Contact> testContactList = mySetUpMap.get('Contact');
        Map<String, Contact> testContactMapByEmail = new Map<String, Contact>();
        for (Contact c : testContactList) {
            testContactMapByEmail.put(c.email, c);
        }
        List<User> testUserList = mySetUpMap.get('User');
        //Create a Map of the Users by Alias to identify New
        Map<String, User> testUserMapbyEmail = new Map<String, User>();
        for (User u : testUserList) {
            testUserMapbyEmail.put(u.email, u);
        }
        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
        Downstream_Event__e e = new Downstream_Event__e();
        ID oldAccountOwnerID = testAccount.OwnerId;
        ID newAccountOwnerID = testUserMapbyEmail.get('BruceTest@test.org').ID;
        ID csamOwnerID = testUserMapbyEmail.get('BobTest@test.org').ID;
        //Contact that should change
        Contact contactShouldChange = testContactMapByEmail.get('patty@spacex.com');
        ID contactShouldChangeOwnerID = testContactMapByEmail.get('patty@spacex.com').OwnerId;

        Account testAccountRes = [SELECT ID, Name, OwnerID, Owner.name FROM Account WHERE ID = :testAccount.ID];
        Contact contactPre = [
            SELECT ID, name, email, owner.name, ownerid
            FROM contact
            WHERE email = 'patty@spacex.com'
        ];
        Contact contactPre2 = [
            SELECT ID, name, email, owner.name, ownerid
            FROM contact
            WHERE email = 'jamie@spacex.com'
        ];
        //Contact that should not change
        Contact contactShouldNotChange = testContactMapByEmail.get('jamie@spacex.com');
        ID contactShouldNotChangeOwnerID = testContactMapByEmail.get('jamie@spacex.com').OwnerId;
        System.assertEquals(oldAccountOwnerID, contactShouldChangeOwnerID, 'The initial setup is not right');
        System.assertEquals(csamOwnerID, contactShouldNotChangeOwnerID, 'The initial setup is not right');

        testAccount.ownerId = newAccountOwnerID;
        update testAccount;
        e.SourceId__c = testAccount.Id;
        e.OldOwner__c = oldAccountOwnerID;
        e.NewOwner__c = newAccountOwnerID;
        e.Object__c = 'Account';
        downstreamEvents.add(e);
        test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        test.stopTest();
        //patty@spacex.com should change to Bruce
        Account accountResultPostTest = [SELECT ID, OwnerId FROM Account WHERE ID = :testAccount.ID];
        System.assertEquals(newAccountOwnerID, accountResultPostTest.OwnerId, 'The Account Owner did not change');
        Contact contactResultNotOwnedbyCSAM = [SELECT ID, OwnerId FROM Contact WHERE ID = :contactShouldChange.ID];
        System.assertEquals(newAccountOwnerID, contactResultNotOwnedbyCSAM.OwnerId, 'The contact did not change owner');
        //jamie@spacex.com should stays owned by Bob
        Contact contactResultOwnedbyCSAM = [SELECT ID, OwnerId FROM Contact WHERE ID = :contactShouldNotChange.ID];
        System.assertEquals(
            csamOwnerID,
            contactResultOwnedbyCSAM.OwnerId,
            'The contact did not stays as a CSAM owned contact'
        );
    }

    @isTest
    private static void successTeamTest() {
        //Change 1 Test that now overrides the CSAM because the Account and new Owner is Success Team
        //Have an Account with 2 Contacts and 1 of those Contacts is owned the CSAM on the account team.
        // Update the Account Owner. The Contact owned by the Csam should change since its moving to Success.
        Map<String, List<sObject>> mySetUpMap = TestDataFactory.createDataForEnterpriseTest();
        Account testAccount = (Account) mySetUpMap.get('Account')[0];
        Account_Team__C testATeamRec = (Account_Team__C) mySetupMap.get('Account_Team__C')[0];
        List<Contact> testContactList = mySetUpMap.get('Contact');
        Map<String, Contact> testContactMapByEmail = new Map<String, Contact>();
        for (Contact c : testContactList) {
            testContactMapByEmail.put(c.email, c);
        }
        List<User> testUserList = mySetUpMap.get('User');
        //Create a Map of the Users by Alias to identify New
        Map<String, User> testUserMapbyEmail = new Map<String, User>();
        for (User u : testUserList) {
            testUserMapbyEmail.put(u.email, u);
        }
        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
        Downstream_Event__e e = new Downstream_Event__e();
        ID oldAccountOwnerID = testAccount.OwnerId;
        ID newAccountOwnerID = AppConstants.SALES_HOUSE_USER;
        ID csamOwnerID = testUserMapbyEmail.get('BobTest@test.org').ID;
        //Contact that should change
        Contact contactShouldChange = testContactMapByEmail.get('patty@spacex.com');
        ID contactShouldChangeOwnerID = testContactMapByEmail.get('patty@spacex.com').OwnerId;

        Account testAccountRes = [SELECT ID, Name, OwnerID, Owner.name FROM Account WHERE ID = :testAccount.ID];
        Contact contactPre = [
            SELECT ID, name, email, owner.name, ownerid
            FROM contact
            WHERE email = 'patty@spacex.com'
        ];
        Contact contactPre2 = [
            SELECT ID, name, email, owner.name, ownerid
            FROM contact
            WHERE email = 'jamie@spacex.com'
        ];
        //Contact that should not change
        Contact contactShouldNotChange = testContactMapByEmail.get('jamie@spacex.com');
        ID contactShouldNotChangeOwnerID = testContactMapByEmail.get('jamie@spacex.com').OwnerId;
        System.assertEquals(oldAccountOwnerID, contactShouldChangeOwnerID, 'The initial setup is not right');
        System.assertEquals(csamOwnerID, contactShouldNotChangeOwnerID, 'The initial setup is not right');

        testAccount.ownerId = newAccountOwnerID;
        //testAccount.House_Retainer__c = true;
        update testAccount;
        e.SourceId__c = testAccount.Id;
        e.OldOwner__c = oldAccountOwnerID;
        e.NewOwner__c = newAccountOwnerID;
        e.Object__c = 'Account';
        downstreamEvents.add(e);
        test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        test.stopTest();

        Account accountResultPostTest = [SELECT ID, House_Retainer__c, OwnerId FROM Account WHERE ID = :testAccount.ID];
        System.assertEquals(newAccountOwnerID, accountResultPostTest.OwnerId, 'The Account Owner did not change');
        System.assertEquals(true, accountResultPostTest.House_Retainer__c, 'The Account is not House Retainer');
        //patty@spacex.com should change to success team
        Contact contactResultNotOwnedbyCSAM = [SELECT ID, OwnerId FROM Contact WHERE ID = :contactShouldChange.ID];
        System.assertEquals(newAccountOwnerID, contactResultNotOwnedbyCSAM.OwnerId, 'The contact did not change owner');
        //jamie@spacex.com should move to success team
        Contact contactoldOwnedbyCSAM = [SELECT ID, OwnerId FROM Contact WHERE ID = :contactShouldNotChange.ID];
        System.assertEquals(
            newAccountOwnerID,
            contactoldOwnedbyCSAM.OwnerId,
            'The contact did not switch to Success Team'
        );
    }

    @isTest
    private static void processCSAMAteamChange() {
        //This Test Will Change a CSAM to a different CSAM. Everything not owned by a CSAM should not change.
        Map<String, List<sObject>> mySetUpMap = TestDataFactory.createDataForEnterpriseTest();
        Account testAccount = (Account) mySetUpMap.get('Account')[0];
        Account_Team__C testATeamRec = (Account_Team__C) mySetupMap.get('Account_Team__C')[0];
        List<Contact> testContactList = mySetUpMap.get('Contact');
        Map<String, Contact> testContactMapByEmail = new Map<String, Contact>();
        for (Contact c : testContactList) {
            testContactMapByEmail.put(c.email, c);
        }
        List<User> testUserList = mySetUpMap.get('User');
        List<Project__C> testProjectList = mySetUpMap.get('Project__C');
        Map<String, Project__C> testProjectMap = new Map<String, Project__C>();
        Set<ID> ProjectIDSet = new Set<ID>();
        for (Project__c p : testProjectList) {
            testProjectMap.put(p.Project__c, p);
            ProjectIDSet.add(p.ID);
        }
        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
        ID projectOwnedbyMainAccount = testProjectMap.get('Rocket').ID;
        ID projectOwnedbyCSAM = testProjectMap.get('Pencil').ID;
        ID projectOwnedbyOther = testProjectMap.get('Pencil2').ID;
        //Change the CSAM from Bob to Alfred on the Account Team
        Map<String, User> testUserMapbyEmail = new Map<String, User>();
        //Create a Map of the Users by Alias to identify New
        for (User u : testUserList) {
            testUserMapbyEmail.put(u.email, u);
        }
        // Contact Owned by Account Owner should stay
        Set<ID> contactIDSet = new Set<ID>();
        ID mainAccountContactID = testContactMapByEmail.get('patty@spacex.com').ID;
        ID mainAccountContact2ID = testContactMapByEmail.get('samantha@spacex.com').ID;
        ID csamContactID = testContactMapByEmail.get('joe@spacex.com').ID;
        ID csamContact2ID = testContactMapByEmail.get('jamie@spacex.com').ID;
        System.debug('Owner of the 2nd Contact: ' + testContactMapByEmail.get('jamie@spacex.com').ownerid);
        ID otherContactID = testContactMapByEmail.get('rudolf@spacex.com').ID;

        contactIDSet.add(mainAccountContactID);
        contactIDSet.add(mainAccountContact2ID);
        contactIDSet.add(csamContactID);
        contactIDSet.add(csamContact2ID);
        contactIDSet.add(otherContactID);
        // Contact Owner by the oldCSAM should switch
        // Project Owned by the oldCSAM should switch
        // Project Owned by the main Account Owner should stay
        ID mainAccountOwner = testAccount.OwnerId;
        ID newCSAMownerID = testUserMapbyEmail.get('AlfredTest@test.org').ID;
        ID oldCSAMownerID = testATeamRec.Team_Member__c;
        ID nonAccountOwner = testUserMapbyEmail.get('jeffDTest@test.org').ID;
        testATeamRec.Team_Member__c = newCSAMownerID;

        //Safety Check that one of the contacts is ownerd by the Old CSAM;
        System.AssertEquals(
            oldCSAMownerID,
            testContactMapByEmail.get('joe@spacex.com').ownerID,
            'This contact does not have the correct CSAM setup'
        );
        System.AssertEquals(
            oldCSAMownerID,
            testContactMapByEmail.get('jamie@spacex.com').ownerID,
            'This contact does not have the correct CSAM setup'
        );
        update testATeamRec;
        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = testAccount.Id;
        e.OldOwner__c = oldCSAMownerID;
        e.NewOwner__c = newCSAMownerID;
        e.Object__c = 'Account_Team__C';
        downstreamEvents.add(e);
        test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        test.stopTest();
        Map<ID, Contact> contactResultMap = new Map<ID, Contact>(
            [SELECT ID, Ownerid FROM Contact WHERE ID IN :contactIDSet]
        );
        System.AssertEquals(5, contactResultMap.keySet().size(), 'There were not 5 results returned');
        for (Contact c : contactResultMap.values()) {
            if (c.Id == mainAccountContactID) {
                System.AssertEquals(
                    mainAccountOwner,
                    c.OwnerID,
                    'The expected owner did not match the main account Owner'
                );
            } else if (c.Id == mainAccountContact2ID) {
                System.AssertEquals(
                    mainAccountOwner,
                    c.OwnerID,
                    'The expected owner did not match the main account Owner'
                );
            } else if (c.Id == csamContactID) {
                System.AssertEquals(newCSAMownerID, c.OwnerID, 'The expected owner did not match the New CSAM owner');
            } else if (c.Id == csamContact2ID) {
                System.AssertEquals(newCSAMownerID, c.OwnerID, 'The expected owner did not match the New CSAM owner');
            } else if (c.ID == otherContactID) {
                System.AssertEquals(
                    nonAccountOwner,
                    c.OwnerID,
                    'The expected owner was not the non main non CSAM owner'
                );
            }
        }

        Map<ID, Project__C> projectResultMap = new Map<ID, Project__C>(
            [SELECT ID, OwnerId FROM Project__C WHERE ID IN :ProjectIDSet]
        );
        System.assertEquals(3, projectResultMap.keySet().size(), 'There were not 3 projects returned');
        for (Project__c p : projectResultMap.values()) {
            if (p.ID == projectOwnedbyMainAccount) {
                System.assertEquals(
                    mainAccountOwner,
                    p.OwnerId,
                    'The expected owner did not match the main account Owner'
                );
            } else if (p.ID == projectOwnedbyCSAM) {
                System.assertEquals(newCSAMownerID, p.OwnerId, 'The expected owner did not match the New CSAM Owner');
            } else if (p.ID == projectOwnedbyOther) {
                System.assertEquals(
                    nonAccountOwner,
                    p.OwnerId,
                    'The expected owner was not the non main non CSAM owner'
                );
            }
        }
    }

    @isTest
    private static void processIMWithMETADATAAteamChange() {
        //This Test Will Change an IMS (Injection Molding Specialist) to a different Injection Molding Specialist Everything not owned by a IMS should not change.
        Map<String, List<sObject>> mySetUpMap = TestDataFactory.createDataForEnterpriseTest(
            'Injection Molding Specialist'
        );
        Account testAccount = (Account) mySetUpMap.get('Account')[0];
        Account_Team__C testATeamRec = (Account_Team__C) mySetupMap.get('Account_Team__C')[0];
        System.debug('Here is the first Ateam member');
        System.debug(testATeamRec);
        Account_Team__C testCsamTeamRec = (Account_Team__C) mySetupMap.get('Account_Team__C')[1];
        List<Contact> testContactList = mySetUpMap.get('Contact');
        Map<String, Contact> testContactMapByEmail = new Map<String, Contact>();
        Set<String> contactEmailSet = new Set<String>();
        for (Contact c : testContactList) {
            contactEmailSet.add(c.Email);
        }
        for (Contact c : [SELECT Id, OwnerId, Email FROM Contact WHERE Email IN :contactEmailSet]) {
            testContactMapByEmail.put(c.email, c);
        }
        List<User> testUserList = mySetUpMap.get('User');
        List<Project__C> testProjectList = mySetUpMap.get('Project__C');
        Map<String, Project__C> testProjectMap = new Map<String, Project__C>();
        Set<ID> ProjectIDSet = new Set<ID>();
        for (Project__c p : testProjectList) {
            testProjectMap.put(p.Project__c, p);
            ProjectIDSet.add(p.ID);
        }
        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
        ID projectOwnedbyMainAccount = testProjectMap.get('Rocket').ID;
        ID projectOwnedbyIMS = testProjectMap.get('Pencil').ID;
        ID projectOwnedbyOther = testProjectMap.get('Pencil2').ID;
        //Change the ims from Bob to Alfred on the Account Team
        Map<String, User> testUserMapbyEmail = new Map<String, User>();
        //Create a Map of the Users by Alias to identify New
        for (User u : testUserList) {
            testUserMapbyEmail.put(u.email, u);
        }
        // Contact Owned by Account Owner should stay
        Set<ID> contactIDSet = new Set<ID>();
        ID mainAccountContactID = testContactMapByEmail.get('patty@spacex.com').ID;
        ID mainAccountContact2ID = testContactMapByEmail.get('samantha@spacex.com').ID;
        ID imsContactID = testContactMapByEmail.get('joe@spacex.com').ID;
        ID imsContact2ID = testContactMapByEmail.get('jamie@spacex.com').ID;
        ID otherContactID = testContactMapByEmail.get('rudolf@spacex.com').ID;
        ID csamContactID = testContactMapByEmail.get('hilary@spacex.com').ID;

        contactIDSet.add(mainAccountContactID);
        contactIDSet.add(mainAccountContact2ID);
        contactIDSet.add(imsContactID);
        contactIDSet.add(imsContact2ID);
        contactIDSet.add(otherContactID);
        contactIDSet.add(csamContactID);
        // Contact Owner by the oldIMS should switch
        // Project Owned by the oldIMS should switch
        // Project Owned by the main Account Owner should stay
        ID mainAccountOwner = testAccount.OwnerId;
        ID newIMSownerID = testUserMapbyEmail.get('AlfredTest@test.org').ID;
        ID oldIMSownerID = testATeamRec.Team_Member__c;
        ID nonAccountOwner = testUserMapbyEmail.get('jeffDTest@test.org').ID;
        ID csamAteamOwner = testUserMapbyEmail.get('SelenaTest@test.org').ID;
        testATeamRec.Team_Member__c = newIMSownerID;

        //Safety Check that one of the contacts is ownerd by the Old IMS;
        System.AssertEquals(
            oldIMSownerID,
            testContactMapByEmail.get('joe@spacex.com').ownerID,
            'This contact does not have the correct IMS setup'
        );
        System.AssertEquals(
            oldIMSownerID,
            testContactMapByEmail.get('jamie@spacex.com').ownerID,
            'This contact does not have the correct IMS setup'
        );
        System.assertEquals(
            csamAteamOwner,
            testContactMapByEmail.get('hilary@spacex.com').ownerID,
            'This contact does have the correct CSAM owner setup'
        );
        update testATeamRec;
        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = testAccount.Id;
        e.OldOwner__c = oldIMSownerID;
        e.NewOwner__c = newIMSownerID;
        e.Object__c = 'Account_Team__C';
        downstreamEvents.add(e);
        test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        test.stopTest();
        Map<ID, Contact> contactResultMap = new Map<ID, Contact>(
            [SELECT ID, Ownerid FROM Contact WHERE ID IN :contactIDSet]
        );
        System.AssertEquals(6, contactResultMap.keySet().size(), 'There were not 6 results returned');
        for (Contact c : contactResultMap.values()) {
            if (c.Id == mainAccountContactID) {
                System.AssertEquals(
                    mainAccountOwner,
                    c.OwnerID,
                    'The expected owner did not match the main account Owner'
                );
            } else if (c.Id == mainAccountContact2ID) {
                System.AssertEquals(
                    mainAccountOwner,
                    c.OwnerID,
                    'The expected owner did not match the main account Owner'
                );
            } else if (c.Id == imsContactID) {
                System.AssertEquals(newIMSownerID, c.OwnerID, 'The expected owner did not match the New IMS owner');
            } else if (c.Id == imsContact2ID) {
                System.AssertEquals(newIMSownerID, c.OwnerID, 'The expected owner did not match the New IMS owner');
            } else if (c.ID == otherContactID) {
                System.AssertEquals(
                    nonAccountOwner,
                    c.OwnerID,
                    'The expected owner was not the non main non IMS owner'
                );
            } else if (c.ID == csamContactID) {
                System.AssertEquals(csamAteamOwner, c.OwnerID, 'The expected owner was not the CSAM on the Ateam');
            }
        }

        Map<ID, Project__C> projectResultMap = new Map<ID, Project__C>(
            [SELECT ID, OwnerId FROM Project__C WHERE ID IN :ProjectIDSet]
        );
        System.assertEquals(3, projectResultMap.keySet().size(), 'There were not 3 projects returned');
        for (Project__c p : projectResultMap.values()) {
            if (p.ID == projectOwnedbyMainAccount) {
                System.assertEquals(
                    mainAccountOwner,
                    p.OwnerId,
                    'The expected owner did not match the main account Owner'
                );
            } else if (p.ID == projectOwnedbyIMS) {
                System.assertEquals(newIMSownerID, p.OwnerId, 'The expected owner did not match the New IMS Owner');
            } else if (p.ID == projectOwnedbyOther) {
                System.assertEquals(
                    nonAccountOwner,
                    p.OwnerId,
                    'The expected owner was not the non main non IMS owner'
                );
            }
        }
    }

    @isTest
    private static void processCSAMDeleteTeamChange() {
        //This Test Will Delete a CSAM. Everything owned by the CSAM should revert to the accountOwner
        Map<String, List<sObject>> mySetUpMap = TestDataFactory.createDataForEnterpriseTest();
        Account testAccount = (Account) mySetUpMap.get('Account')[0];
        Account_Team__C testATeamRec = (Account_Team__C) mySetupMap.get('Account_Team__C')[0];
        List<Contact> testContactList = mySetUpMap.get('Contact');
        Map<String, Contact> testContactMapByEmail = new Map<String, Contact>();
        for (Contact c : testContactList) {
            testContactMapByEmail.put(c.email, c);
        }
        List<User> testUserList = mySetUpMap.get('User');
        List<Project__C> testProjectList = mySetUpMap.get('Project__C');
        Map<String, Project__C> testProjectMap = new Map<String, Project__C>();
        Set<ID> ProjectIDSet = new Set<ID>();
        for (Project__c p : testProjectList) {
            testProjectMap.put(p.Project__c, p);
            ProjectIDSet.add(p.ID);
        }
        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
        ID projectOwnedbyMainAccount = testProjectMap.get('Rocket').ID;
        ID projectOwnedbyCSAM = testProjectMap.get('Pencil').ID;
        ID projectOwnedbyOther = testProjectMap.get('Pencil2').ID;
        //Change the CSAM from Bob to Alfred on the Account Team
        Map<String, User> testUserMapbyEmail = new Map<String, User>();
        //Create a Map of the Users by Alias to identify New
        for (User u : testUserList) {
            testUserMapbyEmail.put(u.email, u);
        }
        // Contact Owned by Account Owner should stay
        Set<ID> contactIDSet = new Set<ID>();
        ID mainAccountContactID = testContactMapByEmail.get('patty@spacex.com').ID;
        ID mainAccountContact2ID = testContactMapByEmail.get('samantha@spacex.com').ID;
        ID csamContactID = testContactMapByEmail.get('joe@spacex.com').ID;
        ID csamContact2ID = testContactMapByEmail.get('jamie@spacex.com').ID;
        System.debug('Owner of the 2nd Contact: ' + testContactMapByEmail.get('jamie@spacex.com').ownerid);
        ID otherContactID = testContactMapByEmail.get('rudolf@spacex.com').ID;

        contactIDSet.add(mainAccountContactID);
        contactIDSet.add(mainAccountContact2ID);
        contactIDSet.add(csamContactID);
        contactIDSet.add(csamContact2ID);
        contactIDSet.add(otherContactID);
        // Contact Owner by the oldCSAM should switch
        // Project Owned by the oldCSAM should switch
        // Project Owned by the main Account Owner should stay
        ID mainAccountOwner = testAccount.OwnerId;
        ID newCSAMownerID = testUserMapbyEmail.get('AlfredTest@test.org').ID;
        ID oldCSAMownerID = testATeamRec.Team_Member__c;
        ID nonAccountOwner = testUserMapbyEmail.get('jeffDTest@test.org').ID;

        //Safety Check that one of the contacts is ownerd by the Old CSAM;
        System.AssertEquals(
            oldCSAMownerID,
            testContactMapByEmail.get('joe@spacex.com').ownerID,
            'This contact does not have the correct CSAM setup'
        );
        System.AssertEquals(
            oldCSAMownerID,
            testContactMapByEmail.get('jamie@spacex.com').ownerID,
            'This contact does not have the correct CSAM setup'
        );
        delete testATeamRec;
        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = testAccount.Id;
        e.OldOwner__c = oldCSAMownerID;
        e.NewOwner__c = mainAccountOwner;
        e.Object__c = 'Account_Team__C_Delete';
        downstreamEvents.add(e);
        test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        test.stopTest();
        Map<ID, Contact> contactResultMap = new Map<ID, Contact>(
            [SELECT ID, Ownerid FROM Contact WHERE ID IN :contactIDSet]
        );
        System.AssertEquals(5, contactResultMap.keySet().size(), 'There were not 5 results returned');
        for (Contact c : contactResultMap.values()) {
            if (c.Id == mainAccountContactID) {
                System.AssertEquals(
                    mainAccountOwner,
                    c.OwnerID,
                    'The expected owner did not match the main account Owner'
                );
            } else if (c.Id == mainAccountContact2ID) {
                System.AssertEquals(
                    mainAccountOwner,
                    c.OwnerID,
                    'The expected owner did not match the main account Owner'
                );
            } else if (c.Id == csamContactID) {
                System.AssertEquals(
                    mainAccountOwner,
                    c.OwnerID,
                    'The expected owner did not match the main account Owner'
                );
            } else if (c.Id == csamContact2ID) {
                System.AssertEquals(
                    mainAccountOwner,
                    c.OwnerID,
                    'The expected owner did not match the main account Owner'
                );
            } else if (c.ID == otherContactID) {
                System.AssertEquals(
                    nonAccountOwner,
                    c.OwnerID,
                    'The expected owner was not the non main non CSAM owner'
                );
            }
        }

        Map<ID, Project__C> projectResultMap = new Map<ID, Project__C>(
            [SELECT ID, OwnerId FROM Project__C WHERE ID IN :ProjectIDSet]
        );
        System.assertEquals(3, projectResultMap.keySet().size(), 'There were not 3 projects returned');
        for (Project__c p : projectResultMap.values()) {
            if (p.ID == projectOwnedbyMainAccount) {
                System.assertEquals(
                    mainAccountOwner,
                    p.OwnerId,
                    'The expected owner did not match the main account Owner'
                );
            } else if (p.ID == projectOwnedbyCSAM) {
                System.assertEquals(
                    mainAccountOwner,
                    p.OwnerId,
                    'The expected owner did not match the main account Owner'
                );
            } else if (p.ID == projectOwnedbyOther) {
                System.assertEquals(
                    nonAccountOwner,
                    p.OwnerId,
                    'The expected owner was not the non main non CSAM owner'
                );
            }
        }
    }

    @isTest
    private static void processAccountOwnerChange() {
        Map<String,Account> acctMap = TestDataFactory.createTestAccountHierarchy();
        List<Account> accts2 = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 1, 2);
        List<Contact> cList = new List<Contact>();
        Contact c1 = TestDataFactory.createContact(false, acctMap.get('Dragon Keepers'));
        Contact c2 = TestDataFactory.createContact(false, acctMap.get('Fireball Dragons'));
        Contact c3 = TestDataFactory.createContact(false, acctMap.get('HellKite Dragons'));
        cList.add(c1);
        cList.add(c2);
        cList.add(c3);
        insert cList;

        Quote_ERP__c q = TestDataFactory.createQuote(
            false,
            acctMap.get('Dragon Keepers').Email_Domain__c,
            c1.FirstName,
            c1.LastName,
            c1.Email
        );
        q.Xometry_ERP_ID__C = 'Q22-4444-4444';
        insert q;

        List<User> users = TestDataFactory.createTestUsersList(3);
        Map<String, Id> rolesMap = new Map<String, Id>();
        for (CaseTeamRole tRole : [SELECT Id, Name FROM CaseTeamRole]) {
            rolesMap.put(tRole.Name, tRole.Id);
        }

        Id roleOppOwnerId = rolesMap.get('PSE2.0-Opportunity Owner');
        Id oldAcctOwner = acctMap.get('Dragon Keepers').OwnerId;

        List<Case> cases = new List<Case>();
        // Case to swap to new owner
        Case case1 = new Case();
        case1.OwnerId = acctMap.get('Dragon Keepers').OwnerId;
        case1.AccountId = acctMap.get('Dragon Keepers').Id;
        case1.ContactID = c1.Id;
        case1.Category__c = 'Auto response';
        case1.Subject = 'test';
        cases.add(case1);
        // case should not swap to new owner because owner is not related
        Case case2 = new Case();
        case2.OwnerId = users[2].Id;
        case2.AccountId = acctMap.get('Dragon Keepers').Id;
        case2.ContactID = c1.Id;
        case2.RecordTypeId = casePSERecordTypeId;
        case2.Category__c = 'None';
        case2.Subject = 'test2';
        cases.add(case2);
        // case should stay with old owner because it's closed
        Case case3 = new Case();
        case3.OwnerId = acctMap.get('Dragon Keepers').OwnerId;
        case3.Status = 'Closed';
        case3.AccountId = acctMap.get('Dragon Keepers').Id;
        case3.ContactID = c1.Id;
        case3.Category__c = 'Auto response';
        case3.Subject = 'test3';
        cases.add(case3);
        insert cases;

        List<CaseTeamMember> tmList = new List<CaseTeamMember>();
        CaseTeamMember teamMember = new CaseTeamMember();
        teamMember.ParentId = case1.Id;
        teamMember.MemberId = oldAcctOwner;
        teamMember.TeamRoleId = roleOppOwnerId;
        tmList.add(teamMember);
        CaseTeamMember teamMember1 = new CaseTeamMember();
        teamMember1.ParentId = case1.Id;
        teamMember1.MemberId = users[0].Id;
        teamMember1.TeamRoleId = roleOppOwnerId;
        tmList.add(teamMember1);
        insert tmList;

        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();

        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = acctMap.get('Dragon Keepers').Id;
        e.OldOwner__c = acctMap.get('Dragon Keepers').OwnerId;
        e.NewOwner__c = users[0].Id;
        e.Object__c = 'Account';
        downstreamEvents.add(e);

        Downstream_Event__e e1 = new Downstream_Event__e();
        e1.SourceId__c = accts2[0].Id;
        e1.OldOwner__c = accts2[0].OwnerId;
        e1.NewOwner__c = users[1].Id;
        e1.Object__c = 'Account';
        downstreamEvents.add(e1);

        List<Account> updateAccts = new List<Account>();

        acctMap.get('Dragon Keepers').OwnerId = users[0].Id;
        accts2[0].OwnerId = users[1].Id;
        updateAccts.add(acctMap.get('Dragon Keepers'));
        updateAccts.add(accts2[0]);
        update updateAccts;

        Test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        Test.stopTest();

        Account acctResChild = [SELECT Id, OwnerId, ParentId FROM Account WHERE ParentId = :acctMap.get('Dragon Keepers').Id][0];
        Contact cRes = [SELECT Id, OwnerId, AccountId FROM Contact WHERE AccountId = :acctMap.get('Dragon Keepers').Id][0];
        Opportunity oppRes = [SELECT Id, OwnerId, AccountId FROM Opportunity WHERE AccountId = :acctMap.get('Dragon Keepers').Id][0];
        Project__c pRes = [SELECT Id, OwnerId, AccountId__c FROM Project__c WHERE AccountId__c = :acctMap.get('Dragon Keepers').Id][0];

        Account acct2Res = [SELECT Id, OwnerId, ParentId FROM Account WHERE Id = :accts2[0].Id][0];
        Contact c2Res = [SELECT Id, OwnerId, AccountId FROM Contact WHERE AccountId = :accts2[0].Id][0];
        Case case1Res = [
            SELECT Id, OwnerId, Contact_Match_Route_to_Sales_Owner_Flag__c
            FROM Case
            WHERE Id = :case1.Id
        ][0];
        Case case2Res = [
            SELECT Id, OwnerId, Contact_Match_Route_to_Sales_Owner_Flag__c
            FROM Case
            WHERE Id = :case2.Id
        ][0];
        Case case3Res = [
            SELECT Id, OwnerId, Contact_Match_Route_to_Sales_Owner_Flag__c
            FROM Case
            WHERE Id = :case3.Id
        ][0];
        CaseTeamMember cTeamRes = [
            SELECT Id, MemberId
            FROM CaseTeamMember
            WHERE ParentId = :case1.Id AND MemberId = :users[0].Id
        ][0];

        System.assertEquals(users[0].Id, acctResChild.OwnerId, 'Child accounts should update to new owner');
        System.assertEquals(users[0].Id, cRes.OwnerId, 'Contact should update to new owner');
        System.assertEquals(users[0].Id, oppRes.OwnerId, 'Opportunity should update to new owner');
        System.assertEquals(users[0].Id, pRes.OwnerId, 'Project should update to new owner');

        System.assertEquals(users[1].Id, acct2Res.OwnerId, 'Account should update to new owner');
        System.assertEquals(users[1].Id, c2Res.OwnerId, 'Contact should update to new owner');
        System.assertEquals(users[0].Id, case1res.OwnerId, 'Case should have new owner');
        System.assertEquals(users[2].Id, case2res.OwnerId, 'Case should have old owner');
        System.assertEquals(oldAcctOwner, case3res.OwnerId, 'Case should have old owner');
        System.assertEquals(users[0].Id, cTeamRes.MemberId, 'Case Team should have new owner');
        System.assertEquals(0, [SELECT Id FROM Audit_Trail_Error__c].size(), 'No errors should be on audit log');
    }

    @isTest
    private static void processContactOwnerChange() {

        Map<String,Account> acctMap = TestDataFactory.createTestAccountHierarchy();

        List<Contact> cList = new List<Contact>();
        Contact c1 = TestDataFactory.createContact(false, acctMap.get('Dragon Keepers'));
        Contact c2 = TestDataFactory.createContact(false, acctMap.get('Fireball Dragons'));
        Contact c3 = TestDataFactory.createContact(false, acctMap.get('HellKite Dragons'));
        cList.add(c1);
        cList.add(c2);
        cList.add(c3);
        insert cList;

        List<Quote_ERP__C> qList = new List<Quote_ERP__C>();
        Quote_ERP__c q = TestDataFactory.createQuote(
            false,
            acctMap.get('Dragon Keepers').Email_Domain__c,
            c1.FirstName,
            c1.LastName,
            c1.Email
        );
        q.Xometry_ERP_ID__C = 'Q22-4444-4444';
        qList.add(q);

        Quote_ERP__c q1 = TestDataFactory.createQuote(
            false,
            acctMap.get('Fireball Dragons').Email_Domain__c,
            c2.FirstName,
            c2.LastName,
            c2.Email
        );
        q1.Xometry_ERP_ID__C = 'Q22-4444-4443';
        qList.add(q1);
        insert qList;

        List<User> users = TestDataFactory.createTestUsersList(3);
        List<Case> cases = new List<Case>();
        // Case to swap to new owner
        Case case1 = new Case();
        case1.OwnerId = acctMap.get('Dragon Keepers').OwnerId;
        case1.AccountId = acctMap.get('Dragon Keepers').Id;
        case1.ContactID = c1.Id;
        case1.Category__c = 'Auto response';
        case1.Subject = 'test';
        cases.add(case1);
        // case should not swap to new owner because owner is not related
        Case case2 = new Case();
        case2.OwnerId = users[1].Id;
        case2.AccountId = acctMap.get('Dragon Keepers').Id;
        case2.ContactID = c1.Id;
        case2.Category__c = 'Auto response';
        case2.Subject = 'test2';
        cases.add(case2);
        // case should stay with old owner because it's closed
        Case case3 = new Case();
        case3.OwnerId = acctMap.get('Dragon Keepers').OwnerId;
        case3.Status = 'Closed';
        case3.AccountId = acctMap.get('Dragon Keepers').Id;
        case3.ContactID = c1.Id;
        case3.Category__c = 'Auto response';
        case3.Subject = 'test3';
        cases.add(case3);
        insert cases;
        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();

        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = c1.Id;
        e.OldOwner__c = c1.OwnerId;
        e.NewOwner__c = users[0].Id;
        e.Object__c = 'Contact';
        downstreamEvents.add(e);

        Downstream_Event__e e1 = new Downstream_Event__e();
        e1.SourceId__c = c2.Id;
        e1.OldOwner__c = c2.OwnerId;
        e1.NewOwner__c = users[1].Id;
        e1.Object__c = 'Contact';
        downstreamEvents.add(e1);
        List<Contact> updateContacts = new List<Contact>();

        c1.OwnerId = users[0].Id;
        c2.OwnerId = users[1].Id;
        updateContacts.add(c1);
        updateContacts.add(c2);
        update updateContacts;

        Test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        Test.stopTest();

        List<Account> acctRes = [SELECT Id, OwnerId, ParentId FROM Account WHERE OwnerId = :acctMap.get('Dragon Keepers').OwnerId];
        Opportunity oppRes1 = [
            SELECT Id, OwnerId, AccountId, Primary_Contact__c
            FROM Opportunity
            WHERE Primary_Contact__c = :c1.Id
        ][0];
        Project__c pRes1 = [
            SELECT Id, OwnerId, AccountId__c, Primary_Contact__c
            FROM Project__c
            WHERE Primary_Contact__c = :c1.Id
        ][0];

        Opportunity oppRes2 = [
            SELECT Id, OwnerId, AccountId, Primary_Contact__c
            FROM Opportunity
            WHERE Primary_Contact__c = :c2.Id
        ][0];
        Project__c pRes2 = [
            SELECT Id, OwnerId, AccountId__c, Primary_Contact__c
            FROM Project__c
            WHERE Primary_Contact__c = :c2.Id
        ][0];
        List<Contact> cRes3 = [
            SELECT Id, OwnerId, AccountId
            FROM Contact
            WHERE OwnerId NOT IN (:users[0].Id, :users[1].Id)
        ];
        Case case1Res = [
            SELECT Id, OwnerId, Contact_Match_Route_to_Sales_Owner_Flag__c
            FROM Case
            WHERE Id = :case1.Id
        ][0];
        Case case2Res = [
            SELECT Id, OwnerId, Contact_Match_Route_to_Sales_Owner_Flag__c
            FROM Case
            WHERE Id = :case2.Id
        ][0];
        Case case3Res = [
            SELECT Id, OwnerId, Contact_Match_Route_to_Sales_Owner_Flag__c
            FROM Case
            WHERE Id = :case3.Id
        ][0];
        System.assertEquals(3, acctRes.size(), 'All accounts should be old owner');
        System.assertEquals(users[0].Id, oppRes1.OwnerId, 'Opportunity should update to new owner');
        System.assertEquals(users[0].Id, pRes1.OwnerId, 'Project should update to new owner');

        System.assertEquals(users[1].Id, oppRes2.OwnerId, 'Opportunity should update to new owner');
        System.assertEquals(users[1].Id, pRes2.OwnerId, 'Project should update to new owner');

        System.assertEquals(1, cRes3.size(), 'Contact list should only have one owner not changed');
        System.assertEquals(users[0].Id, case1res.OwnerId, 'Case should have new owner');
        System.assertEquals(users[1].Id, case2res.OwnerId, 'Case should have old owner');
        System.assertEquals(acctMap.get('Dragon Keepers').OwnerId, case3res.OwnerId, 'Case should have old owner');
    }

    @isTest
    private static void processProjectOwnerChange() {
        List<User> uList = TestDataFactory.createTestUsersList(2);
        Opportunity opp1 = TestDataFactory.createOppWithAccContact(true, 'BDR');
        Opportunity opp1Q = [
            SELECT Id, Primary_Contact__c, AccountId, OwnerId, CloseDate, Project__c
            FROM Opportunity
            WHERE Id = :opp1.Id
        ];
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        Opportunity opp2 = TestDataFactory.createOpportunity(
            false,
            opp1Q.Primary_Contact__c,
            opp1Q.AccountId,
            opp1Q.OwnerId,
            opp1Q.CloseDate
        );
        Opportunity opp3 = TestDataFactory.createOpportunity(
            false,
            opp1Q.Primary_Contact__c,
            opp1Q.AccountId,
            opp1Q.OwnerId,
            opp1Q.CloseDate
        );

        opp2.Hold_Op_to_Prior_Owner__c = true;
        oppsToInsert.add(opp2);
        opp3.StageName = 'Closed Won';
        oppsToInsert.add(opp3);
        insert oppsToInsert;

        Project__c p = [SELECT Id, Primary_Contact__c, AccountId__c, OwnerId FROM Project__c][0];
        Id originalProjectOwner = p.OwnerId;

        List<Case> cases = new List<Case>();
        // Case to swap to new owner
        Case case1 = new Case();
        case1.ContactId = opp1Q.Primary_Contact__c;
        case1.AccountId = opp1Q.AccountId;
        case1.OwnerId = opp1Q.OwnerId;
        case1.Opportunity__c = opp1Q.Id;
        case1.Project__c = p.Id;
        case1.Category__c = 'Auto response';
        case1.Subject = 'test';
        cases.add(case1);
        // Case should stay with old owner
        Case case2 = new Case();
        case2.ContactId = opp1Q.Primary_Contact__c;
        case2.AccountId = opp1Q.AccountId;
        case2.OwnerId = opp1Q.OwnerId;
        case2.Opportunity__c = opp1Q.Id;
        case2.Project__c = p.Id;
        case2.Status = 'Closed';
        case2.Category__c = 'Auto response';
        case2.Subject = 'test';
        cases.add(case2);
        insert cases;

        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();

        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = p.Id;
        e.OldOwner__c = p.OwnerId;
        e.NewOwner__c = uList[0].Id;
        e.Object__c = 'Project';
        downstreamEvents.add(e);

        p.OwnerId = uList[0].Id;
        update p;

        Test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        Test.stopTest();

        Opportunity opp1Res = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :opp1.Id];
        Opportunity opp2Res = [SELECT Id, OwnerId, Hold_Op_to_Prior_Owner__c FROM Opportunity WHERE Id = :opp2.Id];
        Opportunity opp3Res = [SELECT Id, OwnerId, IsClosed FROM Opportunity WHERE Id = :opp3.Id];
        Case case1Res = [SELECT Id, OwnerId, Project__c FROM Case WHERE Id = :case1.Id][0];
        Case case2Res = [SELECT Id, OwnerId, Project__c FROM Case WHERE Id = :case2.Id][0];

        System.assertEquals(uList[0].Id, opp1Res.OwnerId, 'Should be new Owner');
        System.assertEquals(originalProjectOwner, opp2Res.OwnerId, 'Should be old owner as hold op = true');
        System.assertEquals(originalProjectOwner, opp3Res.OwnerId, 'Should be old owner as op is closed');
        System.assertEquals(uList[0].Id, case1Res.OwnerId, 'Case should be new owner');
        System.assertEquals(originalProjectOwner, case2Res.OwnerId, 'Case should be old owner because it was closed');
    }

    @isTest
    private static void processLeadAccountTeamChange() {
        
        Map<String,Account> acctMap = TestDataFactory.createTestAccountHierarchy();
        List<User> users = TestDataFactory.createTestUsersList(2);

        // Lead to swap to new owner
        Lead lead1 = new Lead();
        lead1.LastName = 'Test1';
        lead1.Company = 'Test1';
        lead1.OwnerId = acctMap.get('Fireball Dragons').OwnerId;
        lead1.Recommended_Account_LKP__c = acctMap.get('Fireball Dragons').Id;
        lead1.Email = 'client@genericdomain.com';
        lead1.Email_Domain__c = 'xometest1.com';

        // Lead to keep old owner
        Lead lead2 = new Lead();
        lead2.LastName = 'Test2';
        lead2.Company = 'Test2';
        lead2.OwnerId = AppConstants.SALES_HOUSE_USER;
        lead2.Recommended_Account_LKP__c = acctMap.get('HellKite Dragons').Id;
        lead2.Email = 'client2@genericdomain.com';
        lead2.Email_Domain__c = 'xomtest2.com';

        insert new List<Lead>{lead1, lead2};

        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = acctMap.get('Fireball Dragons').Id;
        e.OldOwner__c = acctMap.get('Fireball Dragons').OwnerId;
        e.NewOwner__c = users[1].Id;
        e.Object__c = 'Account_Team__C';
        downstreamEvents.add(e);

        Downstream_Event__e e1 = new Downstream_Event__e();
        e1.SourceId__c = acctMap.get('HellKite Dragons').Id;
        e1.OldOwner__c = acctMap.get('HellKite Dragons').OwnerId;
        e1.NewOwner__c = users[0].Id;
        e1.Object__c = 'Account_Team__C';
        downstreamEvents.add(e1);

        test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        test.stopTest();

        Map<Id,Lead> leadsResultMap = new Map<Id,Lead>([
            SELECT OwnerId
            FROM Lead
            WHERE Id IN (:lead1.Id, :lead2.Id)
        ]);

        System.assertEquals(users[1].Id, leadsResultMap.get(lead1.Id).OwnerId, 'Lead should have new owner');
        System.assertEquals(AppConstants.SALES_HOUSE_USER, leadsResultMap.get(lead2.Id).OwnerId, 'Lead should keep the old owner');

    }

    @isTest
    private static void processLeadAccountOwnerChange() {

        Map<String,Account> acctMap = TestDataFactory.createTestAccountHierarchy();
        List<User> users = TestDataFactory.createTestUsersList(2);

        // Lead to swap to new owner
        Lead lead1 = new Lead();
        lead1.LastName = 'Test1';
        lead1.Company = 'Test1';
        lead1.OwnerId = acctMap.get('Fireball Dragons').OwnerId;
        lead1.Recommended_Account_LKP__c = acctMap.get('Fireball Dragons').Id;
        lead1.Email = 'client@genericdomain.com';
        lead1.Email_Domain__c = 'xometest1.com';

        // Lead to keep old owner
        Lead lead2 = new Lead();
        lead2.LastName = 'Test2';
        lead2.Company = 'Test2';
        lead2.OwnerId = AppConstants.SALES_HOUSE_USER;
        lead2.Recommended_Account_LKP__c = acctMap.get('HellKite Dragons').Id;
        lead2.Email = 'client2@genericdomain.com';
        lead2.Email_Domain__c = 'xomtest2.com';

        insert new List<Lead>{lead1, lead2};

        Account_Team__c atmCSAM = new Account_Team__c();
        atmCSAM.Account__c = acctMap.get('HellKite Dragons').Id;
        atmCSAM.Team_Member__c = AppConstants.SALES_HOUSE_USER;
        atmCSAM.Team_Role__c = 'Enterprise Account Manager';
        insert atmCSAM;

        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();

        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = acctMap.get('Fireball Dragons').Id;
        e.OldOwner__c = acctMap.get('Fireball Dragons').OwnerId;
        e.NewOwner__c = users[0].Id;
        e.Object__c = 'Account';
        downstreamEvents.add(e);

        Downstream_Event__e e1 = new Downstream_Event__e();
        e1.SourceId__c = acctMap.get('HellKite Dragons').Id;
        e1.OldOwner__c = acctMap.get('HellKite Dragons').OwnerId;
        e1.NewOwner__c = AppConstants.SALES_API_USER;
        e1.Object__c = 'Account';
        downstreamEvents.add(e1);

        Test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        Test.stopTest();

        Map<Id,Lead> leadsResultMap = new Map<Id,Lead>([
            SELECT OwnerId
            FROM Lead
            WHERE Id IN (:lead1.Id, :lead2.Id)
        ]);

        System.assertEquals(users[0].Id, leadsResultMap.get(lead1.Id).OwnerId, 'Lead should have new owner');
        System.assertEquals(AppConstants.SALES_HOUSE_USER, leadsResultMap.get(lead2.Id).OwnerId, 'Lead should keep the old owner');
    }

    @isTest
    private static void processLeadAccountTeamDelete() {
        
        Map<String,Account> acctMap = TestDataFactory.createTestAccountHierarchy();
        List<User> users = TestDataFactory.createTestUsersList(2);

        // Lead to swap to new owner
        Lead lead1 = new Lead();
        lead1.LastName = 'Test1';
        lead1.Company = 'Test1';
        lead1.OwnerId = acctMap.get('Fireball Dragons').OwnerId;
        lead1.Recommended_Account_LKP__c = acctMap.get('Fireball Dragons').Id;
        lead1.Email = 'client@genericdomain.com';
        lead1.Email_Domain__c = 'xometest1.com';

        // Lead to keep old owner
        Lead lead2 = new Lead();
        lead2.LastName = 'Test2';
        lead2.Company = 'Test2';
        lead2.OwnerId = AppConstants.SALES_HOUSE_USER;
        lead2.Recommended_Account_LKP__c = acctMap.get('HellKite Dragons').Id;
        lead2.Email = 'client2@genericdomain.com';
        lead2.Email_Domain__c = 'xomtest2.com';

        insert new List<Lead>{lead1, lead2};

        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
        Downstream_Event__e e = new Downstream_Event__e();
        e.SourceId__c = acctMap.get('Fireball Dragons').Id;
        e.OldOwner__c = acctMap.get('Fireball Dragons').OwnerId;
        e.NewOwner__c = users[1].Id;
        e.Object__c = 'Account_Team__C_Delete';
        downstreamEvents.add(e);

        Downstream_Event__e e1 = new Downstream_Event__e();
        e1.SourceId__c = acctMap.get('HellKite Dragons').Id;
        e1.OldOwner__c = acctMap.get('HellKite Dragons').OwnerId;
        e1.NewOwner__c = users[0].Id;
        e1.Object__c = 'Account_Team__C_Delete';
        downstreamEvents.add(e1);

        test.startTest();
        DownstreamEventHelper.processEvents(downstreamEvents);
        test.stopTest();

        Map<Id,Lead> leadsResultMap = new Map<Id,Lead>([
            SELECT OwnerId
            FROM Lead
            WHERE Id IN (:lead1.Id, :lead2.Id)
        ]);

        System.assertEquals(users[1].Id, leadsResultMap.get(lead1.Id).OwnerId, 'Lead should have new owner');
        System.assertEquals(AppConstants.SALES_HOUSE_USER, leadsResultMap.get(lead2.Id).OwnerId, 'Lead should keep the old owner');

    }

}