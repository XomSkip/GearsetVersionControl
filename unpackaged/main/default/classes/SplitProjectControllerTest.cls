@isTest
public with sharing class SplitProjectControllerTest {
    @isTest
    private static void getProjectList_returnProjectList() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Project__c p2 = new Project__c();
        p2.accountId__c = a.Id;
        p2.Primary_Contact__c = c.Id;
        p2.Project__c = 'test two';

        insert p2;

        Test.startTest();
        List<Project__c> returnedProjects = SplitProjectController.getProjectList(c.Id, p.Id);
        Test.stopTest();

        System.assert(returnedProjects.size() != 0, 'nothing returned');
    }

    @isTest
    private static void getOppList_returnOppList() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Opportunity o = new Opportunity();
        o.Name = 'Opp Test Name';
        o.StageName = 'Open';
        o.CloseDate = Date.newInstance(1999, 1, 1);
        o.Project__c = p.Id;

        insert o;

        Test.startTest();
        List<Opportunity> returnedOpps = SplitProjectController.getOppList(p.Id);
        Test.stopTest();

        System.assert(returnedOpps.size() != 0, 'nothing returned');
    }

    @isTest
    private static void getProjectDetails_returnProject() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Test.startTest();
        Project__c returnedProject = SplitProjectController.getProjectDetails(p.Id);
        Test.stopTest();

        System.assertNotEquals(returnedProject, null, 'nothing returned');
    }

    @isTest
    private static void reassignOpps_returnString() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Opportunity o = new Opportunity();
        o.Name = 'Opp Test Name';
        o.StageName = 'Open';
        o.CloseDate = Date.newInstance(1999, 1, 1);
        o.Project__c = p.Id;

        Opportunity o2 = new Opportunity();
        o2.Name = 'Opp Test Name';
        o2.StageName = 'Open';
        o2.CloseDate = Date.newInstance(1999, 1, 1);
        o2.Project__c = p.Id;

        insert o;
        insert o2;

        List<Id> oppList = new List<Id>();
        oppList.add(o.Id);
        oppList.add(o2.Id);

        Test.startTest();
        String returnString = SplitProjectController.reassignOpps(p.Id, oppList);
        Test.stopTest();

        System.assertEquals(returnString, 'success', 'nothing returned');
    }

    @isTest
    private static void mergeProject_returnString() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Opportunity o = new Opportunity();
        o.Name = 'Opp Test Name';
        o.StageName = 'Open';
        o.CloseDate = Date.newInstance(1999, 1, 1);
        o.Project__c = p.Id;

        Opportunity o2 = new Opportunity();
        o2.Name = 'Opp Test Name';
        o2.StageName = 'Open';
        o2.CloseDate = Date.newInstance(1999, 1, 1);
        o2.Project__c = p.Id;

        insert o;
        insert o2;

        Project__c p2 = new Project__c();
        p2.accountId__c = a.Id;
        p2.Primary_Contact__c = c.Id;
        p2.Project__c = 'test';

        insert p2;

        Test.startTest();
        String returnString = SplitProjectController.mergeProject(p.Id, p2.Id);
        Test.stopTest();

        List<Project__c> returnedProjects = [SELECT Id, Project__c FROM Project__c WHERE Id = :p.Id OR Id = :p2.Id];

        List<Project_Contact__c> projectContactList = [SELECT Id FROM Project_Contact__c];
        List<Project_Account__c> projectAccountList = [SELECT Id FROM Project_Account__c];

        System.assertEquals(returnString, 'success', 'nothing returned');
    }

    @isTest
    private static void mergeProject_removeJunctions() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Opportunity o = new Opportunity();
        o.Name = 'Opp Test Name';
        o.StageName = 'Open';
        o.CloseDate = Date.newInstance(1999, 1, 1);
        o.Project__c = p.Id;

        Opportunity o2 = new Opportunity();
        o2.Name = 'Opp Test Name';
        o2.StageName = 'Open';
        o2.CloseDate = Date.newInstance(1999, 1, 1);
        o2.Project__c = p.Id;

        insert o;
        insert o2;

        Project__c p2 = new Project__c();
        p2.accountId__c = a.Id;
        p2.Primary_Contact__c = c.Id;
        p2.Project__c = 'test';

        insert p2;

        Project_Account__c deletedProjectAccountJunction = new Project_Account__c();
        deletedProjectAccountJunction.Project__c = p.Id;
        deletedProjectAccountJunction.account__c = a.Id;
        insert deletedProjectAccountJunction;

        Test.startTest();
        String returnString = SplitProjectController.mergeProject(p.Id, p2.Id);
        Test.stopTest();

        List<Project__c> returnedProjects = [SELECT Id, Project__c FROM Project__c WHERE Id = :p.Id OR Id = :p2.Id];

        List<Project_Contact__c> projectContactList = [SELECT Id FROM Project_Contact__c];
        List<Project_Account__c> projectAccountList = [SELECT Id FROM Project_Account__c];

        System.assertEquals(returnString, 'success', 'nothing returned');
        System.assertEquals(projectContactList.size(), 1, 'Only One Junction should be removed');
        System.assertEquals(projectAccountList.size(), 0, 'Junction should be removed');
    }

    @isTest
    private static void mergeProject_keepJunctions() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Opportunity o = new Opportunity();
        o.Name = 'Opp Test Name';
        o.StageName = 'Open';
        o.CloseDate = Date.newInstance(1999, 1, 1);
        o.Project__c = p.Id;

        Opportunity o2 = new Opportunity();
        o2.Name = 'Opp Test Name';
        o2.StageName = 'Open';
        o2.CloseDate = Date.newInstance(1999, 1, 1);
        o2.Project__c = p.Id;

        insert o;
        insert o2;

        Project__c p2 = new Project__c();
        p2.accountId__c = a.Id;
        p2.Primary_Contact__c = c.Id;
        p2.Project__c = 'test';

        insert p2;

        Project_Account__c deletedProjectAccountJunction = new Project_Account__c();
        deletedProjectAccountJunction.Project__c = p2.Id;
        deletedProjectAccountJunction.account__c = a.Id;
        insert deletedProjectAccountJunction;

        Test.startTest();
        String returnString = SplitProjectController.mergeProject(p.Id, p2.Id);
        Test.stopTest();

        List<Project__c> returnedProjects = [SELECT Id, Project__c FROM Project__c WHERE Id = :p.Id OR Id = :p2.Id];

        List<Project_Contact__c> projectContactList = [SELECT Id FROM Project_Contact__c];
        List<Project_Account__c> projectAccountList = [SELECT Id FROM Project_Account__c];

        System.assertEquals('success', returnString, 'nothing returned');
        System.assertEquals(1, projectContactList.size(), 'Junction should not be removed');
        System.assertEquals(1, projectAccountList.size(), 'Junction should not be removed');
    }

    @isTest
    private static void mergeProject_keepTasks() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Project__c p2 = new Project__c();
        p2.accountId__c = a.Id;
        p2.Primary_Contact__c = c.Id;
        p2.Project__c = 'test two';

        insert p2;

        Task t = new Task();
        t.Status = 'Open';
        t.Priority = 'Normal';
        t.WhatId = p.Id;
        insert t;

        Test.startTest();
        SplitProjectController.mergeProject(p.Id, p2.Id);
        Test.stopTest();

        Task taskResRelated = [SELECT Id, WhatId FROM Task WHERE WhatId = :p2.Id][0];

        System.assertEquals(p2.Id, taskResRelated.WhatId, 'Expect task to be related to merged project.');
    }

    @isTest
    private static void mergeProject_keepAllTasks() {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT ID FROM Contact][0];

        Project__c p = new Project__c();
        p.accountId__c = a.Id;
        p.Primary_Contact__c = c.Id;
        p.Project__c = 'test';

        insert p;

        Project__c p2 = new Project__c();
        p2.accountId__c = a.Id;
        p2.Primary_Contact__c = c.Id;
        p2.Project__c = 'test two';

        insert p2;

        Task t = new Task();
        t.Status = 'Open';
        t.Priority = 'Normal';
        t.WhatId = p.Id;
        insert t;

        Task t2 = new Task();
        t2.Status = 'Open';
        t2.Priority = 'Normal';
        t2.WhatId = p.Id;
        insert t2;

        Test.startTest();
        SplitProjectController.mergeProject(p.Id, p2.Id);
        Test.stopTest();

        List<Task> taskResRelated = [SELECT Id, WhatId FROM Task WHERE WhatId = :p2.Id];

        System.assertEquals(p2.Id, taskResRelated[0].WhatId, 'Expect task to be related to merged project.');
        System.assertEquals(p2.Id, taskResRelated[1].WhatId, 'Expect task to be related to merged project.');
    }
}