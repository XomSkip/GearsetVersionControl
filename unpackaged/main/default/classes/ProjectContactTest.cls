@isTest
public class ProjectContactTest {
    @isTest
    static void projectContactTest_insertNewPrimary() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact oldContact = [SELECT ID FROM Contact][0];
        Contact newContact = [SELECT ID FROM Contact][1];

        Project__c project = new Project__c();
        project.Primary_Contact__c = oldContact.Id;
        project.AccountId__c = a.Id;
        project.Project__c = 'PreInserted Project';
        insert project;

        Project_Contact__c newPrimary = new Project_Contact__c();
        newPrimary.Primary__c = true;
        newPrimary.Project__c = project.Id;
        newPrimary.Contact__c = newContact.Id;

        Test.startTest();
        insert newPrimary;
        Test.stopTest();

        Project__c resultProject = [SELECT Id, Primary_Contact__c FROM Project__c WHERE Id = :project.Id];

        System.assertNotEquals(
            resultProject.Primary_Contact__c,
            oldContact.Id,
            'Project primary contact still set to original junction'
        );
        System.assertEquals(true, newPrimary.Primary__c, 'New Junction primary flag not set to true');
        System.assertEquals(
            resultProject.Primary_Contact__c,
            newPrimary.Contact__c,
            'Project Primary Contact should be set to new primary contact'
        );
    }

    @isTest
    static void projectContactTest_insertNoNewPrimary() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact oldContact = [SELECT ID FROM Contact][0];
        Contact newContact = [SELECT ID FROM Contact][1];

        Project__c project = new Project__c();
        project.Primary_Contact__c = oldContact.Id;
        project.AccountId__c = a.Id;
        project.Project__c = 'PreInserted Project';
        insert project;

        Project_Contact__c newPrimary = new Project_Contact__c();
        newPrimary.Primary__c = false;
        newPrimary.Project__c = project.Id;
        newPrimary.Contact__c = newContact.Id;

        Test.startTest();
        insert newPrimary;
        Test.stopTest();

        Project__c resultProject = [SELECT Id, Primary_Contact__c FROM Project__c WHERE Id = :project.Id];
        Project_Contact__c originalJunction = [
            SELECT Id, Primary__c, Contact__c
            FROM Project_Contact__c
            WHERE Contact__c = :oldContact.Id
        ];

        System.assertEquals(
            resultProject.Primary_Contact__c,
            originalJunction.Contact__c,
            'Project primary contact still set to original junction'
        );
        System.assertEquals(true, originalJunction.Primary__c, 'Original Junction primary flag not set to false');
        System.assertEquals(
            resultProject.Primary_Contact__c,
            originalJunction.Contact__c,
            'Project Primary Contact should be set to new primary contact'
        );
    }

    @isTest
    static void projectContactTest_updatePrimary() {
        map<String, List<SObject>> mapResult = TestDataFactory.createMultipleDataProjectContact(false, 2, false);
        Project__c project = (Project__c) mapResult.get('Project__c')[0];
        Project_Contact__c originalPrimary = (Project_Contact__c) mapResult.get('Project_Contact__c')[0];
        insert originalPrimary;
        Project_Contact__c newPrimary = (Project_Contact__c) mapResult.get('Project_Contact__c')[1];
        insert newPrimary;

        newPrimary.Primary__c = true;

        Test.startTest();
        update newPrimary;
        Test.stopTest();

        Project__c resultProject = [SELECT Id, Primary_Contact__c FROM Project__c WHERE Id = :project.Id];
        Project_Contact__c originalJunction = [
            SELECT Id, Primary__c, Contact__c
            FROM Project_Contact__c
            WHERE Id = :originalPrimary.Id
        ];
        Project_Contact__c newJunction = [
            SELECT Id, Primary__c, Contact__c
            FROM Project_Contact__c
            WHERE Id = :newPrimary.Id
        ];

        System.assertEquals(false, originalJunction.Primary__c, 'Original Junction primary flag not set to false');
        System.assertEquals(true, newJunction.Primary__c, 'New Junction primary flag not set to false');

        System.assertNotEquals(
            resultProject.Primary_Contact__c,
            originalJunction.Contact__c,
            'Project primary contact still set to original junction'
        );
        System.assertEquals(
            resultProject.Primary_Contact__c,
            newPrimary.Contact__c,
            'Project Primary Contact should be set to new primary contact'
        );
    }

    @isTest
    static void projectContactTest_noUpdatePrimary() {
        map<String, List<SObject>> mapResult = TestDataFactory.createMultipleDataProjectContact(false, 2, false);
        Project__c project = (Project__c) mapResult.get('Project__c')[0];
        Project_Contact__c originalPrimary = (Project_Contact__c) mapResult.get('Project_Contact__c')[0];
        insert originalPrimary;

        Project_Contact__c newPrimary = (Project_Contact__c) mapResult.get('Project_Contact__c')[1];
        Test.startTest();
        insert newPrimary;
        Test.stopTest();

        Project__c resultProject = [SELECT Id, Primary_Contact__c FROM Project__c WHERE Id = :project.Id];
        Project_Contact__c originalJunction = [
            SELECT Id, Primary__c, Contact__c
            FROM Project_Contact__c
            WHERE Id = :originalPrimary.Id
        ];
        Project_Contact__c newJunction = [
            SELECT Id, Primary__c, Contact__c
            FROM Project_Contact__c
            WHERE Id = :newPrimary.Id
        ];

        System.assertEquals(true, originalJunction.Primary__c, 'Original Junction primary flag not set to true');
        System.assertEquals(false, newJunction.Primary__c, 'New Junction primary flag not set to false');

        System.assertEquals(
            resultProject.Primary_Contact__c,
            originalJunction.Contact__c,
            'Project primary contact still set to original junction'
        );
        System.assertNotEquals(
            resultProject.Primary_Contact__c,
            newPrimary.Contact__c,
            'Project Primary Contact should be set to new primary contact'
        );
    }

    @isTest
    static void projectContactTest_error_contactAddedInSameRoleTwice() {
        map<String, List<SObject>> mapResult = TestDataFactory.createMultipleDataProjectContact(false, 2, true);
        Project_Contact__c originalPrimary = (Project_Contact__c) mapResult.get('Project_Contact__c')[0];
        insert originalPrimary;

        Project_Contact__c sameRole = (Project_Contact__c) mapResult.get('Project_Contact__c')[1];

        boolean exceptionThrown = false;

        Test.startTest();
        try {
            insert sameRole;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'Exception not encountered, contact was added to a project with the same role more than once'
        );
    }

    @isTest
    static void projectContactTest_error_multipleContacts_oneContactAddedInSameRoleTwice() {
        map<String, List<SObject>> mapResult = TestDataFactory.createMultipleDataProjectContact(false, 3, true);

        Contact newContact = (Contact) mapResult.get('Contact')[0];
        Contact newContactTwo = (Contact) mapResult.get('Contact')[1];

        Project_Contact__c originalRole = (Project_Contact__c) mapResult.get('Project_Contact__c')[0];
        insert originalRole;

        Project_Contact__c otherContact = (Project_Contact__c) mapResult.get('Project_Contact__c')[1];
        otherContact.Contact__c = newContactTwo.Id;
        Project_Contact__c sameRole = (Project_Contact__c) mapResult.get('Project_Contact__c')[2];

        List<Project_Contact__c> contactsToInsert = new List<Project_Contact__c>();
        contactsToInsert.add(otherContact);
        contactsToInsert.add(sameRole);

        boolean exceptionThrown = false;

        Test.startTest();
        try {
            insert contactsToInsert;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'Exception not encountered, contact was added to a project with the same role more than once'
        );
        //System.assertNotEquals(null, newJunction.Id, 'Valid Project Contact Junction not inserted');
        //System.assertEquals('Buyer', newJunction.Contact_Role__c, 'The PCJ created is incorrect');
    }

    @isTest
    static void projectContactTest_multipleContacts_diffContactsInSameRole() {
        map<String, List<SObject>> mapResult = TestDataFactory.createMultipleDataProjectContact(false, 2, true);

        Contact newContact = (Contact) mapResult.get('Contact')[0];
        Contact newContactTwo = (Contact) mapResult.get('Contact')[1];

        Project_Contact__c originalRole = (Project_Contact__c) mapResult.get('Project_Contact__c')[0];
        insert originalRole;

        Project_Contact__c contactTwo = (Project_Contact__c) mapResult.get('Project_Contact__c')[1];
        contactTwo.Contact__c = newContactTwo.Id;

        boolean exceptionThrown = false;

        Test.startTest();
        try {
            insert contactTwo;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(
            false,
            exceptionThrown,
            'Exception encountered, multiple contacts were not added in the same role'
        );
    }

    @isTest
    static void projectContactTest_error_multipleContacts_contactsInSameAndDiffRoles() {
        map<String, List<SObject>> mapResult = TestDataFactory.createMultipleDataProjectContact(false, 4, true);

        Contact newContact = (Contact) mapResult.get('Contact')[0];
        Contact newContactTwo = (Contact) mapResult.get('Contact')[1];

        Project_Contact__c contactOne = (Project_Contact__c) mapResult.get('Project_Contact__c')[0];
        insert contactOne;

        Project_Contact__c contactTwo = (Project_Contact__c) mapResult.get('Project_Contact__c')[1];
        contactTwo.Contact__c = newContactTwo.Id;
        insert contactTwo;

        Project_Contact__c contactOneAgain = (Project_Contact__c) mapResult.get('Project_Contact__c')[2];
        contactOneAgain.Contact__c = newContact.Id;
        contactOneAgain.Contact_Role__c = 'Designer/Consultant';

        Project_Contact__c contactTwoAgain = (Project_Contact__c) mapResult.get('Project_Contact__c')[3];
        contactTwoAgain.Contact__c = newContactTwo.Id;

        List<Project_Contact__c> contactsToInsert = new List<Project_Contact__c>();
        contactsToInsert.add(contactOneAgain);
        contactsToInsert.add(contactTwoAgain);

        boolean exceptionThrown = false;

        Test.startTest();
        try {
            insert contactsToInsert;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception not encountered');
    }

    @isTest
    static void projectContactTest_sameContactInMultipleRoles() {
        map<String, List<SObject>> mapResult = TestDataFactory.createMultipleDataProjectContact(false, 2, true);

        Contact newContact = (Contact) mapResult.get('Contact')[0];
        Contact newContactTwo = (Contact) mapResult.get('Contact')[1];

        Project_Contact__c contactOneBuyer = (Project_Contact__c) mapResult.get('Project_Contact__c')[0];
        insert contactOneBuyer;

        Project_Contact__c contactOneDesigner = (Project_Contact__c) mapResult.get('Project_Contact__c')[1];
        contactOneDesigner.Contact_Role__c = 'Designer/Consultant';

        boolean exceptionThrown = false;

        Test.startTest();
        try {
            insert contactOneDesigner;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(
            false,
            exceptionThrown,
            'Exception encountered, contact was not added to project in multiple roles'
        );
    }
}