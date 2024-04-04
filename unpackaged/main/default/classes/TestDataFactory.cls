@isTest
public class TestDataFactory {
    static final ID caseDefaultRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('PSE_Case')
        .getRecordTypeID();
    static final ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();

    /*
    @param inRouteUsers will create a Zipcodes for Each User in List
    @param businessEntity the Business Entity for the Rep Router
    @param Intenger inExtra the number of ZipCodes that the first user in the inRouteUsers will have extra zipcodes for.
    Should be 9 or less
    */
    public static List<Rep_Router__c> createRepRouterTestData(
        List<User> inRouteUsers,
        String businessEntity,
        Integer inExtra
    ) {
        List<Rep_Router__c> testRepRouterList = new List<Rep_Router__c>();
        Integer i = 0;
        for (User us : inRouteUsers) {
            Rep_Router__c rRouter = new Rep_Router__c();
            rRouter.ZipCode__c = '2022' + i;
            rRouter.User__c = us.ID;
            rRouter.Business_Entity__C = businessEntity;
            testRepRouterList.add(rRouter);
            i++;
        }
        if (inExtra > 0) {
            for (Integer j = 0; j < inExtra; j++) {
                Rep_Router__c rRouter = new Rep_Router__c();
                rRouter.ZipCode__c = '3033' + i;
                rRouter.User__c = inRouteUsers[0].ID;
                rRouter.Business_Entity__C = businessEntity;
                testRepRouterList.add(rRouter);
            }
        }
        insert testRepRouterList;
        return testRepRouterList;
    }

    public static List<User> createSupTestReps(
        Integer numUsers,
        String inRoleName,
        String inProfileName,
        Boolean rrCheck
    ) {
        //Default to the Inside Sales Rep for Seller Marketplace
        String searchRoleName = 'InsideSalesTeam';
        String searchProfileName = 'Xometry Seller Marketplace';
        if (!String.isBlank(inRoleName)) {
            searchRoleName = inRoleName;
        }
        if (!String.isBlank(inProfileName)) {
            searchProfileName = inProfileName;
        }
        List<User> createTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = :searchProfileName][0];
        UserRole r = [SELECT ID FROM UserRole WHERE DeveloperName = :searchRoleName];
        String randoNumLet = '4567441234aabb';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            //Added a Dummy letter of s for supplies allowing to mix existing test methods with additional supplies users
            for (Integer i = 0; i < numUsers; i++) {
                User lUser = new User();
                lUser.firstname = 'sJohn' + i;
                lUser.lastname = 'sRepTest' + i;
                lUser.Username = 'sJohnRepTest' + i + randoNumLet + '@test' + orgID + '.org';
                lUser.Alias = 'sjRepT' + i;
                lUser.CommunityNickname = 'sjRepTest' + i;
                lUser.NonGeneric_BDR_RR_FLAG__C = false;
                lUser.Generic_BDR_RR_FLAG__C = false;
                lUser.Supplies_RR_Flag__c = rrCheck;
                lUser.email = 'sJohnRepTest' + i + randoNumLet + '@test' + orgID + '.org';
                lUser.EmailEncodingKey = 'UTF-8';
                lUser.TimeZoneSidKey = 'America/New_York';
                lUser.LocaleSidKey = 'en_US';
                lUser.LanguageLocaleKey = 'en_US';
                lUser.ProfileID = p.ID;
                lUser.UserRoleId = r.ID;
                lUser.Supplies_Sales_Rep__c = true;

                createTestUserList.add(lUser);
            }
            insert createTestUserList;
        }
        return createTestUserList;
    }

    public static List<User> createTestUsers() {
        List<User> newTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'][0];
        UserRole r = [SELECT ID FROM UserRole WHERE Name = 'BDR'];
        String randoNumLet = '4567441234aabb';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User lUser = new User();
            lUser.firstname = 'John';
            lUser.lastname = 'RepTest';
            lUser.Username = 'JohnRepTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.Alias = 'jRepT';
            lUser.CommunityNickname = 'jRepTest';
            lUser.NonGeneric_BDR_RR_FLAG__C = true;
            lUser.Generic_BDR_RR_FLAG__C = true;
            lUser.email = 'JohnRepTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.EmailEncodingKey = 'UTF-8';
            lUser.TimeZoneSidKey = 'America/New_York';
            lUser.LocaleSidKey = 'en_US';
            lUser.LanguageLocaleKey = 'en_US';
            lUser.ProfileID = p.ID;
            lUser.UserRoleId = r.ID;
            insert lUser;
            newTestUserList.add(lUser);
        }
        return newTestUserList;
    }

    public static List<User> createTestUserSecond() {
        List<User> newTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'][0];
        UserRole r = [SELECT ID FROM UserRole WHERE Name = 'BDR'];
        String randoNumLet = '4567441234aabb';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User lUser = new User();
            lUser.firstname = 'Bob';
            lUser.lastname = 'Jenkins';
            lUser.Username = 'BobJenkinsTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.Alias = 'bJenT';
            lUser.CommunityNickname = 'jJenTest';
            lUser.NonGeneric_BDR_RR_FLAG__C = true;
            lUser.Generic_BDR_RR_FLAG__C = true;
            lUser.email = 'BobJenkinsTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.EmailEncodingKey = 'UTF-8';
            lUser.TimeZoneSidKey = 'America/New_York';
            lUser.LocaleSidKey = 'en_US';
            lUser.LanguageLocaleKey = 'en_US';
            lUser.ProfileID = p.ID;
            lUser.UserRoleId = r.ID;
            insert lUser;
            newTestUserList.add(lUser);
        }
        return newTestUserList;
    }

    //Overloaded method to specify a non default BDR UserRole Name
    public static List<User> createTestUserSecond(String inUserRoleName) {
        List<User> newTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'][0];
        UserRole r = [SELECT ID FROM UserRole WHERE Name = :inUserRoleName];
        String randoNumLet = '4567441234aabb';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User lUser = new User();
            lUser.firstname = 'Bob';
            lUser.lastname = 'Jenkins';
            lUser.Username = 'BobJenkinsTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.Alias = 'bJenT';
            lUser.CommunityNickname = 'jJenTest';
            lUser.NonGeneric_BDR_RR_FLAG__C = true;
            lUser.Generic_BDR_RR_FLAG__C = true;
            lUser.email = 'BobJenkinsTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.EmailEncodingKey = 'UTF-8';
            lUser.TimeZoneSidKey = 'America/New_York';
            lUser.LocaleSidKey = 'en_US';
            lUser.LanguageLocaleKey = 'en_US';
            lUser.ProfileID = p.ID;
            lUser.UserRoleId = r.ID;
            insert lUser;
            newTestUserList.add(lUser);
        }
        return newTestUserList;
    }
    //Post Account Post CSAM Users
    public static List<User> createTestUsersThree(String inUserRoleName) {
        List<User> newTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'][0];
        UserRole r = [SELECT ID FROM UserRole WHERE Name = :inUserRoleName];
        String randoNumLet = '4567441234aabc';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User lUser = new User();
            lUser.firstname = 'sarah';
            lUser.lastname = 'RepTest';
            lUser.Username = 'sarahRepTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.Alias = 'sRepT';
            lUser.CommunityNickname = 'sRepTest';
            lUser.NonGeneric_BDR_RR_FLAG__C = true;
            lUser.Generic_BDR_RR_FLAG__C = true;
            lUser.email = 'SarahRepTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.EmailEncodingKey = 'UTF-8';
            lUser.TimeZoneSidKey = 'America/New_York';
            lUser.LocaleSidKey = 'en_US';
            lUser.LanguageLocaleKey = 'en_US';
            lUser.ProfileID = p.ID;
            lUser.UserRoleId = r.ID;
            insert lUser;
            newTestUserList.add(lUser);
        }
        return newTestUserList;
    }
    //Overloaded method to specify a non default BDR UserRole Name
    public static List<User> createTestUsers(String inUserRoleName) {
        List<User> newTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'][0];
        UserRole r = [SELECT ID FROM UserRole WHERE Name = :inUserRoleName];
        String randoNumLet = '4567441234aabb';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User lUser = new User();
            lUser.firstname = 'John';
            lUser.lastname = 'RepTest';
            lUser.Username = 'JohnRepTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.Alias = 'jRepT';
            lUser.CommunityNickname = 'jRepTest';
            lUser.NonGeneric_BDR_RR_FLAG__C = true;
            lUser.Generic_BDR_RR_FLAG__C = true;
            lUser.email = 'JohnRepTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.EmailEncodingKey = 'UTF-8';
            lUser.TimeZoneSidKey = 'America/New_York';
            lUser.LocaleSidKey = 'en_US';
            lUser.LanguageLocaleKey = 'en_US';
            lUser.ProfileID = p.ID;
            lUser.UserRoleId = r.ID;
            insert lUser;
            newTestUserList.add(lUser);
        }
        return newTestUserList;
    }

    public static List<User> createTestUsers2() {
        List<User> newTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'][0];
        String randoNumLet = '4567441234aabb';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User lUser = new User();
            lUser.firstname = 'John';
            lUser.lastname = 'RepTest';
            lUser.Username = 'JohnRepTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.Alias = 'jRepT';
            lUser.CommunityNickname = 'jRepTest';
            lUser.NonGeneric_BDR_RR_FLAG__C = true;
            lUser.Generic_BDR_RR_FLAG__C = true;
            lUser.email = 'JohnRepTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.EmailEncodingKey = 'UTF-8';
            lUser.TimeZoneSidKey = 'America/New_York';
            lUser.LocaleSidKey = 'en_US';
            lUser.LanguageLocaleKey = 'en_US';
            lUser.ProfileID = p.ID;
            insert lUser;
            User lUser2 = new User();
            lUser2.firstname = 'Travis';
            lUser2.lastname = 'Raptor';
            lUser2.Username = 'TravisRaptor' + randoNumLet + '@test' + orgID + '.org';
            lUser2.Alias = 'tRapt';
            lUser2.CommunityNickname = 'tRapTest';
            lUser2.NonGeneric_BDR_RR_FLAG__C = true;
            lUser2.Generic_BDR_RR_FLAG__C = true;
            lUser2.email = 'TravisRaptor' + randoNumLet + '@test' + orgID + '.org';
            lUser2.EmailEncodingKey = 'UTF-8';
            lUser2.TimeZoneSidKey = 'America/New_York';
            lUser2.LocaleSidKey = 'en_US';
            lUser2.LanguageLocaleKey = 'en_US';
            lUser2.ProfileID = p.ID;
            insert lUser2;
            newTestUserList.add(lUser2);
            User lUser3 = new User();
            lUser3.firstname = 'Apple';
            lUser3.lastname = 'Pie';
            lUser3.Username = 'ApplePie' + randoNumLet + '@test' + orgID + '.org';
            lUser3.Alias = 'apPie';
            lUser3.CommunityNickname = 'apPie';
            lUser3.NonGeneric_BDR_RR_FLAG__C = true;
            lUser3.Generic_BDR_RR_FLAG__C = true;
            lUser3.email = 'ApplePie' + randoNumLet + '@test' + orgID + '.org';
            lUser3.EmailEncodingKey = 'UTF-8';
            lUser3.TimeZoneSidKey = 'America/New_York';
            lUser3.LocaleSidKey = 'en_US';
            lUser3.LanguageLocaleKey = 'en_US';
            lUser3.ProfileID = p.ID;
            insert lUser3;
            newTestUserList.add(lUser3);
        }
        return newTestUserList;
    }

    public static List<User> createCaseManager() {
        List<User> newCaseManagerList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Service User'][0];
        UserRole r = [SELECT ID FROM UserRole WHERE Name = 'Case Management'];
        String randoNumLet = '4567441234aabb';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User lUser = new User();
            lUser.firstname = 'Case';
            lUser.lastname = 'Manager';
            lUser.Username = 'caseManager' + randoNumLet + '@test' + orgID + '.org';
            lUser.Alias = 'Cmgmt';
            lUser.CommunityNickname = 'CMTest';
            lUser.NonGeneric_BDR_RR_FLAG__C = true;
            lUser.Generic_BDR_RR_FLAG__C = true;
            lUser.email = 'CMTestTest' + randoNumLet + '@test' + orgID + '.org';
            lUser.EmailEncodingKey = 'UTF-8';
            lUser.TimeZoneSidKey = 'America/New_York';
            lUser.LocaleSidKey = 'en_US';
            lUser.LanguageLocaleKey = 'en_US';
            lUser.ProfileID = p.ID;
            lUser.UserRoleId = r.ID;
            insert lUser;
            newCaseManagerList.add(lUser);
        }
        return newCaseManagerList;
    }

    public static List<User> createTestUsersList(Integer numOfUsers) {
        List<User> newTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'][0];
        UserRole r = [SELECT ID FROM UserRole WHERE Name = 'BDR'];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            for (Integer i = 0; i < numOfUsers; i++) {
                String randoNumLet = String.valueOf(Math.round((Math.random() * (900000) + 100000)));
                User lUser = new User();
                lUser.firstname = 'John';
                lUser.lastname = 'RepTest' + randoNumLet;
                lUser.Username = 'JohnRepTest' + randoNumLet + '@test' + orgID + '.org';
                lUser.Alias = 'jRepT';
                lUser.CommunityNickname = randoNumLet;
                lUser.NonGeneric_BDR_RR_FLAG__C = true;
                lUser.Generic_BDR_RR_FLAG__C = true;
                lUser.email = 'JohnRepTest' + randoNumLet + '@test' + orgID + '.org';
                lUser.EmailEncodingKey = 'UTF-8';
                lUser.TimeZoneSidKey = 'America/New_York';
                lUser.LocaleSidKey = 'en_US';
                lUser.LanguageLocaleKey = 'en_US';
                lUser.ProfileID = p.ID;
                lUser.UserRoleId = r.ID;
                newTestUserList.add(lUser);
            }
            insert newTestUserList;
        }
        return newTestUserList;
    }

    public static Map<String,Account> createTestAccountHierarchy() {
        String orgId = UserInfo.getOrganizationId();
        List<User> newUserList = createTestUsers();
        User lUser = newUserList[0];

        Map<String,Account> testAccountMap = new Map<String,Account>();

        Account myparent = new Account();
        myparent.name = 'Dragon Keepers';
        myparent.OwnerID = luser.Id;
        myparent.Email_Domain__c = 'dragonkeepers.com';
        myparent.Generic_Account__c = false;
        myparent.Hierarchy_Type__c = 'Corporate Parent';
        myparent.RR_Flag__c = false;

        testAccountMap.put('Dragon Keepers', myparent);

        //Parent Account
        //Create Corporate Parent Account -- dragonkeeper

        //Create account subdivison -- fireball
        Account acctSubdivison1 = new Account();
        acctSubdivison1.name = 'Fireball Dragons';
        acctSubdivison1.OwnerID = luser.Id;
        acctSubdivison1.Email_Domain__c = 'fireball.com';
        acctSubdivison1.Generic_Account__c = false;
        // acctSubdivison1.Hierarchy_Type__c = 'Account Subdivision';
        // acctSubdivison1.parentID = myparent.ID;
        acctSubdivison1.RR_Flag__c = false;
        testAccountMap.put('Fireball Dragons', acctSubdivison1);

        // Create account subdivision b -  hellkite
        Account acctSubdivison2 = new Account();
        acctSubdivison2.name = 'HellKite Dragons';
        acctSubdivison2.OwnerID = luser.Id;
        acctSubdivison2.Email_Domain__c = 'hellkitedragons.com';
        acctSubdivison2.Generic_Account__c = false;
        // acctSubdivison2.Hierarchy_Type__c = 'Account Subdivision';
        // acctSubdivison2.parentID = myparent.ID;
        acctSubdivison2.RR_Flag__c = false;
        testAccountMap.put('HellKite Dragons', acctSubdivison2);
        
        insert testAccountMap.values();

        acctSubdivison1.parentID = myparent.Id;
        acctSubdivison1.Hierarchy_Type__c = 'Account Subdivision';
        acctSubdivison2.parentID = myparent.Id;
        acctSubdivison2.Hierarchy_Type__c = 'Account Subdivision';

        update testAccountMap.values();

        return testAccountMap;
    }

    public static List<Quote_ERP__C> createTestQuotesToLeads(Integer inNumLeads, Integer inNumQuotesToLeads) {
        //Create a number of nonGeneric Leads assigned to test User
        String orgID = UserInfo.getOrganizationId();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Quote_ERP__C> insertQuoteList = new List<Quote_ERP__C>();
        System.runAs(thisUser) {
            List<User> newUserList = createTestUsers();
            User lUser = newUserList[0];
            //Create Unique email Quotes for each lead
            for (Integer i = 0; i < inNumLeads; i++) {
                for (Integer j = 0; j < inNumQuotesToLeads; j++) {
                    Quote_ERP__C q = new Quote_ERP__C();
                    q.Account_Domain__C = 'SuperCompany' + string.valueOf(i) + '.com';
                    q.ERP_User_Company_Name__C = 'SuperCompany' + string.valueOf(i);
                    q.ERP_PartPK__c = 'A1234-A000' + String.valueOf(j);
                    q.Quote_Price__c = 1200.15;
                    q.Xometry_ERP_ID__C = 'Q12-333' + String.valueOf(i) + '-444' + String.valueOf(j);
                    q.ERP_Contact__c = 'AAAA' + String.valueOf(i);
                    q.IS_Generic__c = false;
                    q.Quote_Email__c = 'johndoe@SuperCompany' + String.valueOf(i) + '.com';
                    q.Quote_ERP_Created_Date__c = Date.newInstance(2019, 6, 14);
                    q.ERP_Contact_Last_Name__c = 'Doe';
                    q.ERP_Contact_First_Name__c = 'John';
                    q.process_isSLS__c = true;
                    insertQuoteList.add(q);
                }
            }
            insert insertQuoteList;
        }
        return insertQuoteList;
    }

    public static List<Account> createTestAccountNonGenerics(
        Integer inNumAccts,
        String inAcctOwnerType,
        Integer inNumContacts
    ) {
        String orgID = UserInfo.getOrganizationId();

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Account> retAcctList = new List<Account>();
        System.runAs(thisUser) {
            List<User> newUserList = createTestUsers();
            User lUser = newUserList[0];
            System.debug('The id of the User is:  ' + lUser.ID);
            ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeID();
            Set<Account> newAccountSet = new Set<Account>();
            for (Integer i = 0; i < inNumAccts; i++) {
                Account a = new Account();
                a.Name = 'TestAccount' + string.valueOf(i);
                System.debug(a.Name);
                a.Email_Domain__c = 'SuperCompany' + string.valueOf(i) + '.com';
                a.recordTypeID = accountCustomerRecordTypeID;
                a.Generic_Account__c = false;
                a.Account_Owner_Type__c = inAcctOwnerType;
                a.OwnerID = lUser.ID;
                newAccountSet.add(a);
            }

            retAcctList.addAll(newAccountSet);
            insert retAcctList;
            List<Contact> inContactList = new List<Contact>();
            if (inNumContacts > 0) {
                for (Account a : retAcctList) {
                    for (integer j = 0; j < inNumContacts; j++) {
                        Contact c = new Contact();
                        c.Firstname = 'John';
                        c.LastName = 'Doe' + String.valueOf(j);
                        c.email = 'JohnDoe' + String.valueOf(j) + '@' + a.Email_Domain__c;
                        c.OwnerID = a.OwnerID;
                        c.AccountID = a.ID;
                        inContactList.add(c);
                    }
                }
                System.debug('Time to Insert the Contacts');
                System.debug(inContactList);
                insert inContactList;
            }
        }
        return retAcctList;
    }

    public static List<Account> createTestAccountNonGenericsTop20(
        Integer inNumAccts,
        String inAcctOwnerType,
        Integer inNumContacts
    ) {
        String orgID = UserInfo.getOrganizationId();

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Account> retAcctList = new List<Account>();
        System.runAs(thisUser) {
            List<User> newUserList = createTestUsers();
            User lUser = newUserList[0];
            System.debug('The id of the User is:  ' + lUser.ID);
            ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeID();
            Set<Account> newAccountSet = new Set<Account>();
            for (Integer i = 0; i < inNumAccts; i++) {
                Account a = new Account();
                a.Name = 'TestAccount' + string.valueOf(i);
                System.debug(a.Name);
                a.Email_Domain__c = 'SuperCompany' + string.valueOf(i) + '.com';
                a.recordTypeID = accountCustomerRecordTypeID;
                a.Generic_Account__c = false;
                a.Account_Owner_Type__c = inAcctOwnerType;
                a.OwnerID = lUser.ID;
                if (i == 0) {
                    a.Ops_Top_20_Customer__c = true;
                }
                newAccountSet.add(a);
            }

            retAcctList.addAll(newAccountSet);
            insert retAcctList;
            List<Contact> inContactList = new List<Contact>();
            if (inNumContacts > 0) {
                for (Account a : retAcctList) {
                    for (integer j = 0; j < inNumContacts; j++) {
                        Contact c = new Contact();
                        c.Firstname = 'John';
                        c.LastName = 'Doe' + String.valueOf(j);
                        c.email = 'JohnDoe' + String.valueOf(j) + '@' + a.Email_Domain__c;
                        c.OwnerID = a.OwnerID;
                        c.AccountID = a.ID;
                        inContactList.add(c);
                    }
                }
                System.debug('Time to Insert the Contacts');
                System.debug(inContactList);
                insert inContactList;
            }
        }
        return retAcctList;
    }
    public static List<Account> createTestAccountNonGenerics(
        Integer inNumAccts,
        String inAcctOwnerType,
        Integer inNumContacts,
        Integer intStartAccount
    ) {
        String orgID = UserInfo.getOrganizationId();

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Account> retAcctList = new List<Account>();
        System.runAs(thisUser) {
            List<User> newUserList = createTestUserSecond();
            User lUser = newUserList[0];
            System.debug('The id of the User is:  ' + lUser.ID);
            ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeID();
            Set<Account> newAccountSet = new Set<Account>();
            for (Integer i = intStartAccount; i < (intStartAccount + inNumAccts); i++) {
                Account a = new Account();
                a.Name = 'TestAccount' + string.valueOf(i);
                System.debug(a.Name);
                a.Email_Domain__c = 'SuperCompany' + string.valueOf(i) + '.com';
                a.recordTypeID = accountCustomerRecordTypeID;
                a.Generic_Account__c = false;
                a.Account_Owner_Type__c = inAcctOwnerType;
                a.OwnerID = lUser.ID;
                newAccountSet.add(a);
            }

            retAcctList.addAll(newAccountSet);
            insert retAcctList;
            List<Contact> inContactList = new List<Contact>();
            if (inNumContacts > 0) {
                for (Account a : retAcctList) {
                    for (integer j = 0; j < inNumContacts; j++) {
                        Contact c = new Contact();
                        c.Firstname = 'John';
                        c.LastName = 'Doe' + String.valueOf(j);
                        c.email = 'JohnDoe' + String.valueOf(j) + '@' + a.Email_Domain__c;
                        c.OwnerID = a.OwnerID;
                        c.AccountID = a.ID;
                        inContactList.add(c);
                    }
                }
                System.debug('Time to Insert the Contacts');
                System.debug(inContactList);
                insert inContactList;
            }
        }
        return retAcctList;
    }

    public static List<Account> createTestAccountNonGenerics(
        Integer inNumAccts,
        String inAcctOwnerType,
        Integer inNumContacts,
        String userRole
    ) {
        String orgID = UserInfo.getOrganizationId();

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Account> retAcctList = new List<Account>();
        System.runAs(thisUser) {
            List<User> newUserList = createTestUsers(userRole);
            User lUser = newUserList[0];
            System.debug('The id of the User is:  ' + lUser.ID);
            ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeID();
            Set<Account> newAccountSet = new Set<Account>();
            for (Integer i = 0; i < inNumAccts; i++) {
                Account a = new Account();
                a.Name = 'TestAccount' + string.valueOf(i);
                System.debug(a.Name);
                a.Email_Domain__c = 'SuperCompany' + string.valueOf(i) + '.com';
                a.recordTypeID = accountCustomerRecordTypeID;
                a.Generic_Account__c = false;
                a.Account_Owner_Type__c = inAcctOwnerType;
                a.OwnerID = lUser.ID;
                newAccountSet.add(a);
            }

            retAcctList.addAll(newAccountSet);
            insert retAcctList;
            List<Contact> inContactList = new List<Contact>();
            if (inNumContacts > 0) {
                for (Account a : retAcctList) {
                    for (integer j = 0; j < inNumContacts; j++) {
                        Contact c = new Contact();
                        c.Firstname = 'John';
                        c.LastName = 'Doe' + String.valueOf(j);
                        c.email = 'JohnDoe' + String.valueOf(j) + '@' + a.Email_Domain__c;
                        c.OwnerID = a.OwnerID;
                        c.AccountID = a.ID;
                        inContactList.add(c);
                    }
                }
                System.debug('Time to Insert the Contacts');
                System.debug(inContactList);
                insert inContactList;
            }
        }
        return retAcctList;
    }

    public static List<Account> createTestAccountNonGenericsNonUS(
        Integer inNumAccts,
        String inAcctOwnerType,
        Integer inNumContacts
    ) {
        String orgID = UserInfo.getOrganizationId();

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Account> retAcctList = new List<Account>();
        System.runAs(thisUser) {
            List<User> newUserList = createTestUsers();
            User lUser = newUserList[0];
            System.debug('The id of the User is:  ' + lUser.ID);
            ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeID();
            Set<Account> newAccountSet = new Set<Account>();
            for (Integer i = 0; i < inNumAccts; i++) {
                Account a = new Account();
                a.Name = 'TestAccount' + string.valueOf(i);
                System.debug(a.Name);
                a.Email_Domain__c = 'SuperCompany' + string.valueOf(i) + '.com';
                a.recordTypeID = accountCustomerRecordTypeID;
                a.Generic_Account__c = false;
                a.Account_Owner_Type__c = inAcctOwnerType;
                a.OwnerID = lUser.ID;
                a.BillingCountry = 'Canada';
                a.BillingState = 'Ontario';
                //a.BillingAddress = '08 Rue Saint-Lazare, 75008 Paris, France';
                newAccountSet.add(a);
            }

            retAcctList.addAll(newAccountSet);
            insert retAcctList;
            List<Contact> inContactList = new List<Contact>();
            if (inNumContacts > 0) {
                for (Account a : retAcctList) {
                    for (integer j = 0; j < inNumContacts; j++) {
                        Contact c = new Contact();
                        c.Firstname = 'John';
                        c.LastName = 'Doe' + String.valueOf(j);
                        c.email = 'JohnDoe' + String.valueOf(j) + '@' + a.Email_Domain__c;
                        c.OwnerID = a.OwnerID;
                        c.AccountID = a.ID;
                        inContactList.add(c);
                    }
                }
                System.debug('Time to Insert the Contacts');
                System.debug(inContactList);
                insert inContactList;
            }
        }
        return retAcctList;
    }

    public static List<Account> createTestAccountGenerics(Integer inNumAccts, String inAcctOwnerType) {
        String orgID = UserInfo.getOrganizationId();

        List<User> newUserList = createTestUsers('SAM');
        User lUser = newUserList[0];
        System.debug('The id of the User is:  ' + lUser.ID);
        ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Customer')
            .getRecordTypeID();
        Set<Account> newAccountSet = new Set<Account>();
        for (Integer i = 0; i < inNumAccts; i++) {
            Account a = new Account();
            a.Name = 'TestAccount' + string.valueOf(i);
            System.debug(a.Name);
            a.Email_Domain__c = 'JohnDoeTester' + string.valueOf(i) + '.com';
            a.recordTypeID = accountCustomerRecordTypeID;
            a.Generic_Account__c = true;
            a.Account_Owner_Type__c = inAcctOwnerType;
            a.OwnerID = lUser.ID;
            newAccountSet.add(a);
        }
        List<Account> retAcctList = new List<Account>();
        retAcctList.addAll(newAccountSet);

        insert retAcctList;

        List<Contact> inContactList = new List<Contact>();

        for (Account a : retAcctList) {
            for (integer j = 0; j < 3; j++) {
                Contact c = new Contact();
                c.Firstname = 'John';
                c.LastName = 'Doe' + String.valueOf(j);
                c.email = 'JohnDoe' + String.valueOf(j) + '@' + a.Email_Domain__c;
                c.OwnerID = a.OwnerID;
                c.AccountID = a.ID;
                inContactList.add(c);
            }
        }
        System.debug('Time to Insert the Contacts');
        System.debug(inContactList);
        insert inContactList;

        return retAcctList;
    }

    /** *Making an assumption that creation of testusers method has already been called
     This method creates a set of cases that are not linked to any Contact or Account on Creation
    * @param inNumCases - the number of Cases you would like the Method to create
    * @param inOrigin - the Case Origin you would like to use. A picklist field in Salesforce
    * @param inRecordTypeName - The type of case you would like to make. pass in the Api Name Example PSE_Case
    */
    public static List<Case> createTestCases(Integer inNumCases, String inOrigin, String inRecordTypeName) {
        ID caseRecordTypeID;
        if (inRecordTypeName == null) {
            caseRecordTypeID = caseDefaultRecordTypeID;
        } else {
            caseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get(inRecordTypeName)
                .getRecordTypeID();
        }
        List<Case> testCaseList = new List<Case>();
        for (integer i = 0; i < inNumCases; i++) {
            Case testCase = new Case(
                recordTypeID = caseRecordTypeID,
                origin = inOrigin,
                Subject = 'Test cases for Testing',
                Comments = 'I need a part'
            );
            testCaseList.add(testCase);
        }
        insert testCaseList;
        return testCaseList;
    }

    public static List<Account> createTestAccountNonGenericsStaffUser(
        Integer inNumAccts,
        String inAcctOwnerType,
        Integer inNumContacts
    ) {
        String orgID = UserInfo.getOrganizationId();

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        List<Account> retAcctList = new List<Account>();
        System.runAs(thisUser) {
            List<User> newUserList = createTestUsersStaff();
            User lUser = newUserList[0];
            System.debug('The id of the User is:  ' + lUser.ID);
            ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get('Customer')
                .getRecordTypeID();
            Set<Account> newAccountSet = new Set<Account>();
            for (Integer i = 0; i < inNumAccts; i++) {
                Account a = new Account();
                a.Name = 'TestAccount' + string.valueOf(i);
                System.debug(a.Name);
                a.Email_Domain__c = 'SuperCompany' + string.valueOf(i) + '.com';
                a.recordTypeID = accountCustomerRecordTypeID;
                a.Generic_Account__c = false;
                a.Account_Owner_Type__c = inAcctOwnerType;
                a.OwnerID = lUser.ID;
                newAccountSet.add(a);
            }

            retAcctList.addAll(newAccountSet);
            insert retAcctList;
            List<Contact> inContactList = new List<Contact>();
            if (inNumContacts > 0) {
                for (Account a : retAcctList) {
                    for (integer j = 0; j < inNumContacts; j++) {
                        Contact c = new Contact();
                        c.Firstname = 'John';
                        c.LastName = 'Doe' + String.valueOf(j);
                        c.email = 'JohnDoe' + String.valueOf(j) + '@' + a.Email_Domain__c;
                        c.OwnerID = a.OwnerID;
                        c.AccountID = a.ID;
                        inContactList.add(c);
                    }
                }
                System.debug('Time to Insert the Contacts');
                System.debug(inContactList);
                insert inContactList;
            }
        }
        return retAcctList;
    }

    public static List<User> createTestUsersStaff() {
        List<User> newTestUserList = new List<User>();
        String orgID = UserInfo.getOrganizationId();
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'][0];
        UserRole r = [SELECT ID FROM UserRole WHERE Name = 'BDR'];
        String randoNumLet = '4567441234aabb';
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User lUser = new User();
            lUser.firstname = 'John';
            lUser.lastname = 'RepTest';
            lUser.Username = 'JohnRepTest' + randoNumLet + orgID + '@xometry.com';
            lUser.Alias = 'jRepT';
            lUser.CommunityNickname = 'jRepTest';
            lUser.NonGeneric_BDR_RR_FLAG__C = true;
            lUser.Generic_BDR_RR_FLAG__C = true;
            lUser.email = 'JohnRepTest' + randoNumLet + orgID + '@xometry.com';
            lUser.EmailEncodingKey = 'UTF-8';
            lUser.TimeZoneSidKey = 'America/New_York';
            lUser.LocaleSidKey = 'en_US';
            lUser.LanguageLocaleKey = 'en_US';
            lUser.ProfileID = p.ID;
            lUser.UserRoleId = r.ID;
            insert lUser;
            newTestUserList.add(lUser);
        }
        return newTestUserList;
    }

    public static List<Id> AccountChangeEventPrep() {
        //Create a quote and then an order for a DIFFERENT quote
        List<Id> IdList = new List<Id>();
        Map<String,Account> testAccounts = TestDataFactory.createTestAccountHierarchy();
        Account testAccount = testAccounts.get('Dragon Keepers');
        Quote_ERP__C testQuote = new Quote_ERP__C();
        testQuote.Account_Domain__C = testAccount.Email_Domain__c;
        testQuote.ERP_User_Company_Name__C = testAccount.Name;
        testQuote.ERP_PartPK__c = 'A1234-A000' + String.valueOf(0);
        testQuote.Quote_Price__c = 1200.15;
        testQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        testQuote.ERP_Contact__c = 'AAAA' + String.valueOf(0);
        testQuote.IS_Generic__c = false;
        testQuote.Quote_Email__c = 'johndoe@' + testAccount.Email_Domain__c;
        testQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        testQuote.ERP_Contact_Last_Name__c = 'Doe';
        testQuote.ERP_Contact_First_Name__c = 'John';
        testQuote.process_isSLS__c = true;
        insert testQuote;
        IdList.add(testQuote.Id);
        Order_ERP__C testOrder = new Order_ERP__C();
        testOrder.Xometry_Quote_ID__c = 'Q12-3333-4445';
        testOrder.Account_Domain__c = testQuote.Account_Domain__C;
        testOrder.ERP_Company_Name__C = testQuote.ERP_User_Company_Name__C;
        testOrder.ERP_Contact_First_Name__c = testQuote.ERP_Contact_First_Name__c;
        testOrder.ERP_Contact_Last_Name__c = testQuote.ERP_Contact_Last_Name__c;
        testOrder.ERP_Contact__C = testQuote.ERP_Contact__C;
        testOrder.ERP_PartPk__c = testQuote.ERP_PartPK__c;
        testOrder.Is_Generic__c = testQuote.IS_Generic__c;
        testOrder.Order_Canceled_Flag__c = false;
        testOrder.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        testOrder.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        testOrder.Order_Email__c = testQuote.Quote_Email__c;
        testOrder.Order_Subtotal__c = 4500.00;
        testOrder.Order_Total__c = 5000.50;
        testOrder.Payment_Type__c = 'credit_card';
        testOrder.Xometry_ERP_ID__c = 'AAAA' + String.valueOf(0) + '-1000' + String.valueOf(0);
        testOrder.process_isDMLS__c = true;
        insert testOrder;
        IdList.add(testOrder.Id);

        return IdList;
    }
    public static map<String, List<SObject>> createHierarchyTestCustomATeam(
        Boolean blnInsertChildOrder,
        Boolean blnInsertAccTeamMember
    ) {
        map<String, List<SObject>> mapReturn = new Map<String, List<SObject>>();

        Map<String,Account> accTestMap = TestDataFactory.createTestAccountHierarchy();

        List<Account> hierarchyAccountList = accTestMap.values();
        for (Account a : hierarchyAccountList) {
            a.Account_Owner_Type__C = 'AM';
        }
        update hierarchyAccountList;

        Account accountChild = accTestMap.get('Fireball Dragons');
        Account accountParent = accTestMap.get('Dragon Keepers');

        //Create an Order on the Parent and the Child from over a two years ago to flip the Contacts to Retention
        Order_ERP__C parentOrder = new ORDER_ERP__C();
        parentOrder.Account_Domain__C = accountParent.Email_Domain__C;
        parentOrder.Is_Generic__c = accountParent.Generic_Account__c;
        parentOrder.Order_Email__c = 'mrsmith01@' + accountParent.Email_Domain__C;
        parentOrder.Order_ERP_CreatedDate__c = date.newInstance(2019, 6, 30);
        parentOrder.Order_ERP_Time__c = dateTime.newInstanceGMT(2019, 6, 30, 18, 0, 0);
        parentOrder.Line_of_Business__c = 'Instant Quote';
        parentOrder.Xometry_Quote_ID__c = 'Q12-3333-4444';
        parentOrder.Xometry_ERP_ID__c = 'AAA22-00022';
        parentOrder.Order_Subtotal__c = 5000;
        parentOrder.Order_Total__c = 5000;
        parentOrder.process_isSLS__c = true;
        parentOrder.ERP_PartPk__c = '1111A';
        parentOrder.ERP_Contact__c = 'AAA22';
        parentOrder.ERP_Contact_First_Name__c = 'Michael';
        parentOrder.ERP_Contact_Last_Name__c = 'Smith';
        insert parentOrder;

        Order_ERP__C childOrder = new ORDER_ERP__C();
        childOrder.Account_Domain__C = accountChild.Email_Domain__C;
        childOrder.Is_Generic__c = accountChild.Generic_Account__c;
        childOrder.Order_Email__c = 'msbetty01@' + accountChild.Email_Domain__C;
        childOrder.Order_ERP_CreatedDate__c = date.newInstance(2019, 6, 30);
        childOrder.Order_ERP_Time__c = dateTime.newInstanceGMT(2019, 6, 30, 18, 0, 0);
        childOrder.Line_of_Business__c = 'Instant Quote';
        childOrder.Xometry_Quote_ID__c = 'Q12-3333-5555';
        childOrder.Xometry_ERP_ID__c = 'AAA23-00022';
        childOrder.Order_Subtotal__c = 5000;
        childOrder.Order_Total__c = 5000;
        childOrder.process_isSLS__c = true;
        childOrder.ERP_PartPk__c = '1112A';
        childOrder.ERP_Contact__c = 'AAA23';
        childOrder.ERP_Contact_First_Name__c = 'Betty';
        childOrder.ERP_Contact_Last_Name__c = 'Rocket';
        if (blnInsertChildOrder) {
            insert childOrder;
        }

        User CSAMUser = TestDataFactory.createTestUserSecond()[0];
        Account_Team__c atmCSAM = new Account_Team__c();
        atmCSAM.Account__c = accountParent.ID;
        atmCSAM.Team_Member__c = CSAMUser.ID;
        atmCSAM.Team_Role__c = 'Enterprise Account Manager';
        if (blnInsertAccTeamMember) {
            insert atmCSAM;
        }

        mapReturn.put('Account', new List<SObject>{ accountParent, accountChild });
        mapReturn.put('Order_ERP__C', new List<SObject>{ parentOrder, childOrder });
        mapReturn.put('Account_Team__c', new List<SObject>{ atmCSAM });
        mapReturn.put('User', new List<SObject>{ CSAMUser });

        return mapReturn;
    }

    public static Job__c createJobWithSupplier() {
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P-Test';
        s.SupplierCompanyName__c = 'P-Test';
        s.EmailAddress__c = 'email@tester.com';
        s.LastName__c = 'Supplier';

        insert s;

        Job__c objJob = new Job__c();
        objJob.Name = 'Test-Job';
        objJob.XometryJobID__c = 'Test-Job';
        objJob.XometryOpsOrderID__c = '1234';

        return objJob;
    }

    public static List<Job__c> createJobsWithSupplier(Boolean blnInsertOpsOrder) {
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P-Test';
        s.SupplierCompanyName__c = 'P-Test';
        s.EmailAddress__c = 'email@tester.com';
        s.LastName__c = 'Supplier';

        insert s;

        if (blnInsertOpsOrder) {
            Ops_Order__c o = new Ops_Order__c();
            o.XometryOpsOrderId__c = '1234';
            o.Name = '1234';

            insert o;
        }

        List<Job__c> insertList = new List<Job__c>();

        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = '1234';
        j.OrderDueDate__c = Date.today() + 7;
        j.AcceptedPartnerID__c = 'P-Test';
        insertList.add(j);

        Job__c j1 = new Job__c();
        j1.Name = 'TestJob1';
        j1.XometryJobID__c = 'TestJob1';
        j1.XometryOpsOrderID__c = '2345';
        j1.OrderDueDate__c = Date.today() + 8;
        j1.AcceptedPartnerID__c = 'P-Test';
        insertList.add(j1);

        Job__c j2 = new Job__c();
        j2.Name = 'TestJob2';
        j2.XometryJobID__c = 'TestJob2';
        j2.XometryOpsOrderID__c = '3456';
        j2.OrderDueDate__c = Date.today() + 9;
        insertList.add(j2);

        return insertList;
    }

    public static map<String, List<SObject>> createAllDataProjectContact() {
        map<String, List<SObject>> mapReturn = new Map<String, List<SObject>>();

        List<Account> lstAcc = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1);
        List<Contact> lstContact = [SELECT ID FROM Contact];

        Project__c project = new Project__c();
        project.AccountId__c = lstAcc[0].Id;
        project.Project__c = 'PreInserted Project';
        insert project;

        Project_Contact__c originalRole = new Project_Contact__c();
        originalRole.Project__c = project.Id;
        originalRole.Contact__c = lstContact[0].Id;
        originalRole.Contact_Role__c = 'Buyer';
        insert originalRole;

        mapReturn.put('Account', lstAcc);
        mapReturn.put('Contact', lstContact);
        mapReturn.put('Project__c', new List<SObject>{ project });
        mapReturn.put('Project_Contact__c', new List<SObject>{ originalRole });

        return mapReturn;
    }

    public static map<String, List<SObject>> createMultipleDataProjectContact(
        Boolean blnInsert,
        Integer intQuantityProjContac,
        Boolean blnSameContact
    ) {
        map<String, List<SObject>> mapReturn = new Map<String, List<SObject>>();

        List<Account> lstAcc = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1);
        List<Contact> lstContact = [SELECT ID FROM Contact];

        Project__c project = new Project__c();
        project.AccountId__c = lstAcc[0].Id;
        project.Primary_Contact__c = blnSameContact ? null : lstContact[intQuantityProjContac].Id;
        project.Project__c = 'PreInserted Project';
        insert project;

        List<Project_Contact__c> lstProjContact = new List<Project_Contact__c>();
        for (Integer i = 0; i < intQuantityProjContac; i++) {
            Project_Contact__c objProjContact = new Project_Contact__c();
            objProjContact.Primary__c = !blnSameContact && (i == 0);
            objProjContact.Project__c = project.Id;
            objProjContact.Contact__c = blnSameContact ? lstContact[0].Id : lstContact[i].Id;
            objProjContact.Contact_Role__c = blnSameContact ? 'Buyer' : null;
            lstProjContact.add(objProjContact);
        }

        if (blnInsert) {
            insert lstProjContact;
        }

        mapReturn.put('Account', lstAcc);
        mapReturn.put('Contact', lstContact);
        mapReturn.put('Project__c', new List<SObject>{ project });
        mapReturn.put('Project_Contact__c', lstProjContact);

        return mapReturn;
    }

    public static map<String, List<SObject>> createOppWithProject(Account testAccount) {
        map<String, List<SObject>> mapReturn = new Map<String, List<SObject>>();

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            Primary_Email__c = 'test@test123.com',
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert testContact;
        Project__c testProject = new Project__c(
            AccountId__c = testAccount.Id,
            Name = 'Test Project',
            Stage__c = 'New',
            Primary_Contact__c = testContact.Id
        );
        insert testProject;
        Opportunity testOpp = new Opportunity(
            Name = 'Test',
            CloseDate = Date.today(),
            StageName = 'Open',
            Project__c = testProject.Id
        );
        insert testOpp;

        mapReturn.put('Contact', new List<SObject>{ testContact });
        mapReturn.put('Project__c', new List<SObject>{ testProject });
        mapReturn.put('Opportunity', new List<SObject>{ testOpp });

        return mapReturn;
    }

    public static map<String, List<SObject>> createOppWithProjAndOrder(
        String strProjectStage,
        String strLineBusiness,
        Boolean blnOrderHasLineOfBussiness,
        Boolean blnProjectLocked,
        Integer intQuantityProject,
        Boolean blnProjectInSameMoment,
        Boolean blnInsertProjects
    ) {
        map<String, List<SObject>> mapReturn = new Map<String, List<SObject>>();

        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        Contact c = [SELECT Id, Name FROM Contact LIMIT 1];

        Order_ERP__c oppOrder = new Order_ERP__c();
        oppOrder.AccountID__c = a.Id;
        oppOrder.ContactID__c = c.Id;
        oppOrder.Account_Domain__c = 'test@yahoo.com';
        oppOrder.Xometry_ERP_ID__c = 'BBBBB-34567';
        oppOrder.Xometry_Quote_ID__c = 'Q12-3333-4444';
        oppOrder.Line_of_Business__c = blnOrderHasLineOfBussiness ? strLineBusiness : null;
        insert oppOrder;

        List<Project__c> lstProjects = new List<Project__c>();
        for (Integer i = 0; i < intQuantityProject; i++) {
            Project__c associatedProject = new Project__c();
            associatedProject.Stage__c = strProjectStage;
            associatedProject.Close_Date__c = Date.newInstance(2019, 6, 14);
            associatedProject.Primary_Contact__c = c.Id;
            associatedProject.AccountId__c = a.Id;
            associatedProject.Project__c = 'PreInserted Project';
            associatedProject.Line_of_Business__c = strLineBusiness;
            associatedProject.Locked__c = blnProjectLocked;

            if (!blnProjectInSameMoment && blnInsertProjects) {
                insert associatedProject;
            }
            lstProjects.add(associatedProject);
        }

        if (blnProjectInSameMoment && blnInsertProjects) {
            insert lstProjects;
        }

        Opportunity newOpp = new Opportunity();
        newOpp.StageName = 'Open';
        newOpp.AccountId = a.Id;
        newOpp.Primary_Contact__C = c.Id;
        newOpp.CloseDate = Date.newInstance(2019, 6, 14);
        newOpp.Line_of_Business__c = strLineBusiness;
        newOpp.Name = 'TestOpp';

        mapReturn.put('Account', new List<SObject>{ a });
        mapReturn.put('Contact', new List<SObject>{ c });
        mapReturn.put('Order_ERP__c', new List<SObject>{ oppOrder });
        mapReturn.put('Project__c', lstProjects);
        mapReturn.put('Opportunity', new List<SObject>{ newOpp });

        return mapReturn;
    }

    public static Opportunity createOppOwnerUnLockedChange() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        Contact myTestContact = [SELECT ID FROM Contact WHERE accountID = :retAccounts[0].ID LIMIT 1];
        Opportunity testOpp = new Opportunity();
        testOpp.name = 'TestOpp';
        testOpp.stagename = 'Open';
        testOpp.AccountID = retAccounts[0].ID;
        testOpp.Primary_Contact__c = myTestContact.ID;
        testOpp.OwnerID = retAccounts[0].OwnerID;
        testOpp.Amount = 400;
        testOpp.CloseDate = Date.today() + 5;
        testOpp.RecordTypeId = oppManufacturingServRTypeID;
        insert testOpp;

        //Attempt to Change Opportunity Owner it should now change since it is unlocked
        List<User> userList = TestDataFactory.createTestUserSecond();
        User newOwner = userList[0];
        testOpp.OwnerID = newOwner.ID;
        testOpp.Hold_Op_to_Prior_Owner__c = false;
        testOpp.Amount = 600;

        return testOpp;
    }

    public static Opportunity createOppWithAccContact(Boolean blnInsert, String strInAcctOwnerType) {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, strInAcctOwnerType, 1)[0];
        Contact c = [SELECT ID FROM Contact LIMIT 1];

        Opportunity newOpp = new Opportunity();
        newOpp.Name = 'TestOpp';
        newOpp.StageName = 'Open';
        newOpp.AccountId = a.Id;
        newOpp.Primary_Contact__C = c.Id;
        newOpp.CloseDate = Date.newInstance(2019, 6, 14);
        newOpp.Line_of_Business__c = 'Instant Quote';

        if (blnInsert) {
            insert newOpp;
        }

        return newOpp;
    }

    public static Opportunity createOppWithProjectAcc(
        Boolean blnInsert,
        String strInAcctOwnerType,
        String strProjectStage,
        String strOppStage,
        Double dbProjectAmount,
        Double dbOppAmount
    ) {
        Account a = TestDataFactory.createTestAccountNonGenerics(5, strInAcctOwnerType, 1)[0];
        Contact c = [SELECT ID FROM Contact LIMIT 1];

        Project__c projectToUpdate = new Project__c();
        projectToUpdate.Primary_Contact__c = c.Id;
        projectToUpdate.AccountId__c = a.Id;
        projectToUpdate.Project__c = 'PreInserted Project';
        projectToUpdate.Stage__c = strProjectStage;
        projectToUpdate.Amount__c = dbProjectAmount;
        insert projectToUpdate;

        Opportunity newOpp = new Opportunity();
        newOpp.StageName = strOppStage;
        newOpp.AccountId = a.Id;
        newOpp.Primary_Contact__C = c.Id;
        newOpp.CloseDate = Date.newInstance(2019, 6, 14);
        newOpp.Name = 'TestOpp';
        newOpp.Project__c = projectToUpdate.Id;
        newOpp.Amount = dbOppAmount;

        if (blnInsert) {
            insert newOpp;
        }

        return newOpp;
    }

    public static Contact createContact(Boolean blnIsInsert, Account testAccount) {
        Contact testContact = new Contact();
        testContact.FirstName = 'John';
        testContact.LastName = 'Doe' + String.valueOf(0);
        testContact.Email = 'JohnDoe' + String.valueOf(0) + '@' + testAccount.Email_Domain__c;
        testContact.Primary_Email__c = 'JohnDoe' + String.valueOf(0) + '@' + testAccount.Email_Domain__c;
        testContact.OwnerId = testAccount.OwnerId;
        testContact.AccountId = testAccount.Id;

        if (blnIsInsert) {
            insert testContact;
        }

        return testContact;
    }

    public static Opportunity createOpportunity(
        Boolean blnIsInsert,
        Id idPrimaryContact,
        Id idAccount,
        Id idOwner,
        Date dtClosedDate
    ) {
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'TestCSAMOPP';
        testOpp.StageName = 'Open';
        testOpp.Amount = 500.50;

        testOpp.Primary_Contact__C = idPrimaryContact;
        testOpp.AccountID = idAccount;
        testOpp.CloseDate = dtClosedDate;
        if (idOwner != null)
            testOpp.OwnerID = idOwner;

        if (blnIsInsert) {
            insert testOpp;
        }

        return testOpp;
    }

    public static Project__c createProject(
        Boolean blnIsInsert,
        Id idPrimaryContact,
        Id idAccount,
        Id idOwner,
        String strProject,
        String strStage
    ) {
        Project__c testProject = new Project__c();
        testProject.Name = 'TestProject';
        testProject.Stage__c = strStage;
        testProject.Primary_Contact__c = idPrimaryContact;
        testProject.AccountId__c = idAccount;
        testProject.Project__c = strProject;
        if (idOwner != null)
            testProject.OwnerId = idOwner;
        if (blnIsInsert) {
            insert testProject;
        }

        return testProject;
    }

    public static Project__c createProjectwithLB(
        Boolean blnIsInsert,
        Id idPrimaryContact,
        Id idAccount,
        Id idOwner,
        String strProject,
        String strStage,
        String lineOfBusiness
    ) {
        Project__c testProject = new Project__c();
        testProject.Name = 'TestProject';
        testProject.Stage__c = strStage;
        testProject.Primary_Contact__c = idPrimaryContact;
        testProject.AccountId__c = idAccount;
        testProject.Project__c = strProject;
        if (idOwner != null)
            testProject.OwnerId = idOwner;
        if (!String.isblank(lineOfBusiness)) {
            testProject.Line_of_Business__c = lineOfBusiness;
        }
        if (blnIsInsert) {
            insert testProject;
        }

        return testProject;
    }

    public static Supplier__c createSupplier(Boolean blnInsert) {
        Supplier__c objSupplier = new Supplier__c();
        objSupplier.PartnerID__c = 'P0000';
        objSupplier.EmailAddress__c = 'supplier@gmail.com';
        objSupplier.AccountDomain__c = 'supplier@gmail.com';
        objSupplier.SupplierCompanyName__c = 'Generic Supplier';
        objSupplier.LastName__c = 'Supplier';
        objSupplier.FirstName__c = 'Generic';
        objSupplier.Phone__c = '1234567890';
        objSupplier.IsGeneric__c = true;

        if (blnInsert) {
            insert objSupplier;
        }

        return objSupplier;
    }

    public static Supplier__c createSupplier(
        Boolean blnInsert,
        String strPartner,
        String EmailAddress,
        String strAccountDomain,
        String strSupplierCompanyName,
        String strLastName,
        String strFirstName
    ) {
        Supplier__c objSupplier = new Supplier__c();
        objSupplier.PartnerID__c = strPartner;
        objSupplier.EmailAddress__c = EmailAddress;
        objSupplier.AccountDomain__c = strAccountDomain;
        objSupplier.SupplierCompanyName__c = strSupplierCompanyName;
        objSupplier.LastName__c = strLastName;
        objSupplier.FirstName__c = strFirstName;
        objSupplier.Phone__c = '1234567890';
        objSupplier.IsGeneric__c = true;

        if (blnInsert) {
            insert objSupplier;
        }

        return objSupplier;
    }

    public static map<String, List<SObject>> createLVTWithAccount() {
        map<String, List<SObject>> mapReturn = new Map<String, List<SObject>>();

        String testCustomerEmail = 'test@test.com';

        Account testAccount = new Account();
        testAccount.Name = 'domain.com';
        testAccount.Email_Domain__c = 'domain.com';
        testAccount.LTV_LKP__c = null;
        insert testAccount;

        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = 'LTV_' + testAccount.Email_Domain__c;
        associatedLtv.Account_Domain__c = testAccount.Email_Domain__c;
        associatedLtv.LTV__c = 1234.00;

        mapReturn.put('Account', new List<SObject>{ testAccount });
        mapReturn.put('LTV__c', new List<SObject>{ associatedLtv });

        return mapReturn;
    }

    public static map<String, List<SObject>> createLVTWithContact() {
        map<String, List<SObject>> mapReturn = new Map<String, List<SObject>>();

        String testCustomerEmail = 'test@test.com';

        Contact nullLtvContact = new Contact();
        nullLtvContact.FirstName = 'TestMan';
        nullLtvContact.LastName = 'LastNamington';
        nullLtvContact.Primary_Email__c = testCustomerEmail;
        nullLtvContact.LTV_LKP__c = null;
        insert nullLtvContact;

        //create new ltv
        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = testCustomerEmail;
        associatedLtv.Customer_Email__c = testCustomerEmail;
        associatedLtv.LTV__c = 1234.00;

        mapReturn.put('Contact', new List<SObject>{ nullLtvContact });
        mapReturn.put('LTV__c', new List<SObject>{ associatedLtv });

        return mapReturn;
    }

    public static Order_ERP__C createDefaultOrderERP(Boolean blnIsInsert) {
        Order_ERP__C objOrderERP = new Order_ERP__C();
        objOrderERP.Account_Domain__c = 'superaccount.com';
        objOrderERP.ERP_Company_Name__C = '';
        objOrderERP.ERP_Contact_First_Name__c = 'John';
        objOrderERP.ERP_Contact_Last_Name__c = 'Doe';
        objOrderERP.ERP_Contact__C = 'BBBBB';
        objOrderERP.ERP_PartPk__c = '56564-55667';
        objOrderERP.Is_Generic__c = false;
        objOrderERP.Order_Canceled_Flag__c = false;
        objOrderERP.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        objOrderERP.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        objOrderERP.Order_Email__c = 'johndoe@superaccount.com';
        objOrderERP.Order_Subtotal__c = 4500.00;
        objOrderERP.Order_Total__c = 5000.50;
        objOrderERP.Payment_Type__c = 'credit_card';
        objOrderERP.Xometry_ERP_ID__c = 'BBBBB-34567';
        objOrderERP.Xometry_Quote_ID__c = 'Q12-3333-4444';
        objOrderERP.process_isPolyJet_3D__c = true;

        if (blnIsInsert) {
            insert objOrderERP;
        }

        return objOrderERP;
    }

    public static Order_ERP__C createOrderERP(
        Boolean blnIsInsert,
        String XometryQuoteERPID,
        String XometryOrderERPId,
        String accountDomain,
        String ERPCompanyName,
        String strEmail,
        Boolean blnProcessIsCNCMachining,
        Boolean blnProcessIsSLS
    ) {
        Integer thisYear = Date.today().year();

        Order_ERP__C objOrderERP = new Order_ERP__C();
        objOrderERP.ERP_PartPk__c = '44444-55555';
        objOrderERP.ERP_Contact__c = 'AAAAC';
        objOrderERP.ERP_Contact_First_Name__c = 'Amy';
        objOrderERP.ERP_Contact_Last_Name__c = 'Adams';
        objOrderERP.Order_ERP_CreatedDate__c = date.newInstance(thisYear - 1, 12, 5);
        objOrderERP.Order_ERP_Time__c = datetime.newInstanceGMT(thisYear - 1, 12, 5, 18, 0, 0);
        objOrderERP.Order_Subtotal__c = 450.00;
        objOrderERP.Order_Total__c = 500.00;
        objOrderERP.Shipping__c = 50.00;
        objOrderERP.Is_Generic__c = false;
        objOrderERP.Xometry_Quote_ID__c = XometryQuoteERPId;
        objOrderERP.Xometry_ERP_ID__c = XometryOrderERPId;
        objOrderERP.process_isCNC_Machining__c = blnProcessIsCNCMachining;
        objOrderERP.process_isSLS__c = blnProcessIsSLS;
        objOrderERP.Account_Domain__C = accountDomain;
        objOrderERP.ERP_Company_Name__c = ERPCompanyName;
        objOrderERP.Order_Email__c = strEmail;

        if (blnIsInsert) {
            insert objOrderERP;
        }

        return objOrderERP;
    }

    public static Order_ERP__C createOrderERPFromQuote(Boolean blnIsInsert, Quote_ERP__C testQuote) {
        Order_ERP__C testOrder = new Order_ERP__C();
        testOrder.Account_Domain__c = testQuote.Account_Domain__C;
        testOrder.ERP_Company_Name__C = testQuote.ERP_User_Company_Name__C;
        testOrder.ERP_Contact_First_Name__c = testQuote.ERP_Contact_First_Name__c;
        testOrder.ERP_Contact_Last_Name__c = testQuote.ERP_Contact_Last_Name__c;
        testOrder.ERP_Contact__C = testQuote.ERP_Contact__C;
        testOrder.ERP_PartPk__c = testQuote.ERP_PartPK__c;
        testOrder.Is_Generic__c = testQuote.IS_Generic__c;

        testOrder.Order_Email__c = testQuote.Quote_Email__c;
        testOrder.Xometry_Quote_ID__c = testQuote.Xometry_ERP_ID__C;
        testOrder.Xometry_ERP_ID__c = 'BBBBB-34567';

        testOrder.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        testOrder.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);

        if (blnIsInsert) {
            insert testOrder;
        }

        return testOrder;
    }

    public static Order_ERP__C createOrderERPFromAccContact(
        Boolean blnIsInsert,
        String strXomQuoteERPId,
        String strXomOrderERPId,
        String strPartPk,
        Account testAccount,
        Contact myretContact,
        Date dtCreatedDate,
        DateTime dtTime
    ) {
        Order_ERP__C testOrder = new Order_ERP__C();
        testOrder.Xometry_Quote_ID__c = strXomQuoteERPId;
        testOrder.Xometry_ERP_ID__c = strXomOrderERPId;
        testOrder.ERP_PartPk__c = strPartPk;
        testOrder.Order_ERP_CreatedDate__c = dtCreatedDate;
        testOrder.Order_ERP_Time__c = dtTime;

        testOrder.Account_Domain__c = testAccount.Email_Domain__c;
        testOrder.ERP_Company_Name__C = testAccount.Name + 'Blue';

        testOrder.ERP_Contact_First_Name__c = myretContact.FirstName;
        testOrder.ERP_Contact_Last_Name__c = myretContact.LastName;
        testOrder.Order_Email__c = myretContact.Email;

        testOrder.ERP_Contact__C = 'BBBBB';
        testOrder.Is_Generic__c = false;
        testOrder.Order_Canceled_Flag__c = false;
        testOrder.Order_Subtotal__c = 4500.00;
        testOrder.Order_Total__c = 5000.00;
        testOrder.Payment_Type__c = 'credit_card';
        testOrder.process_isPolyJet_3D__c = true;

        if (blnIsInsert) {
            insert testOrder;
        }

        return testOrder;
    }

    public static Order_ERP__C setTrueProcessFieldsQuote(Order_ERP__C objOrder) {
        objOrder.process_isCarbon__c = true;
        objOrder.process_isCNC_Machining__c = true;
        objOrder.process_isDie_Casting__c = true;
        objOrder.process_isDirect_Sourced__c = true;
        objOrder.process_isDMLS__c = true;
        objOrder.process_isExtrusion__c = true;
        objOrder.process_isFDM__c = true;
        objOrder.process_isHPMultJetFusion__c = true;
        objOrder.process_isInjection_Molding__c = true;
        objOrder.process_isPolyJet_3D__c = true;
        objOrder.process_isSheet_metal__c = true;
        objOrder.process_isSLA__c = true;
        objOrder.process_isSLS__c = true;
        objOrder.process_isStamping__c = true;
        objOrder.process_isUrethane_Casting__c = true;
        objOrder.process_isBinderJetting__c = true;
        objOrder.process_isSheetCutting__c = true;
        objOrder.process_isTubeBending__c = true;
        objOrder.process_isTubeCutting__c = true;
        objOrder.process_isOther__c = true;
        objOrder.process_isPlasticExtrusion__c = true;
        objOrder.process_isOther_NotIncluded__c = true;
        objOrder.process_isLSPc__c = true;
        objOrder.process_isAssembly__c = true;
        return objOrder;
    }

    public static Quote_ERP__c createQuoteWithAcc(Boolean blnInsert, String strInAcctOwnerType) {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, strInAcctOwnerType, 1);
        Account myTestAccount = retAccounts[0];

        //Create a Quote
        Quote_ERP__C testQuote = new Quote_ERP__C();
        testQuote.Account_Domain__C = myTestAccount.Email_Domain__C;
        testQuote.Quote_Email__c = 'samSmith@' + myTestAccount.Email_Domain__C;
        testQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        testQuote.ERP_PartPK__c = '4444A';
        testQuote.process_isSLA__c = true;
        testQuote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 3);
        testQuote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 3, 10, 0, 30);
        testQuote.Quote_Price__c = 500;

        if (blnInsert) {
            insert testQuote;
        }

        return testQuote;
    }

    public static Quote_ERP__c createQuote(Boolean blnIsInsert) {
        Quote_ERP__c objQuote = new Quote_ERP__c();
        objQuote.Account_Domain__c = 'SuperCompany2.com';
        objQuote.ERP_PartPK__c = 'A1234-A5678';
        objQuote.Quote_Price__c = 50.15;
        objQuote.ERP_Contact__c = 'AAAAA';
        objQuote.IS_Generic__c = false;
        objQuote.Quote_Email__c = 'johndoe@SuperCompany2.com';
        objQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        objQuote.process_isCarbon__c = true;

        if (blnIsInsert) {
            insert objQuote;
        }

        return objQuote;
    }

    public static Quote_ERP__c createQuote(
        Boolean blnIsInsert,
        String strDomain,
        String strFirstName,
        String strLastName,
        String strEmail
    ) {
        Quote_ERP__c objQuote = new Quote_ERP__c();
        objQuote.ERP_PartPK__c = 'A1234-A5679';
        objQuote.Quote_Price__c = 5005;
        objQuote.ERP_Contact__c = 'AAAAA';
        objQuote.Account_Domain__C = strDomain;
        objQuote.ERP_Contact_First_Name__c = strFirstName;
        objQuote.ERP_Contact_Last_Name__c = strLastName;
        objQuote.Quote_Email__c = strEmail;
        objQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 8, 27);
        objQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 8, 27, 13, 0, 40);
        objQuote.process_isUrethane_Casting__c = true;

        if (blnIsInsert) {
            insert objQuote;
        }

        return objQuote;
    }

    public static Quote_ERP__c createPreFissionQuote(Boolean blnIsInsert) {
        Quote_ERP__c objQuote = new Quote_ERP__c();
        objQuote.Xometry_ERP_ID__c = '461AC-15028';
        objQuote.Account_Domain__c = 'SuperCompany2.com';
        objQuote.ERP_PartPK__c = 'A1234-A5678';
        objQuote.Quote_Price__c = 50.15;
        objQuote.ERP_Contact__c = 'AAAAA';
        objQuote.IS_Generic__c = false;
        objQuote.Quote_Email__c = 'johndoe@SuperCompany2.com';
        objQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        objQuote.process_isCarbon__c = true;

        if (blnIsInsert) {
            insert objQuote;
        }

        return objQuote;
    }

    public static Quote_ERP__c setTrueProcessFieldsQuote(Quote_ERP__c objQuote) {
        objQuote.process_isCarbon__c = true;
        objQuote.process_isCNC_Machining__c = true;
        objQuote.process_isDie_Casting__c = true;
        objQuote.process_isDirect_Sourced__C = true;
        objQuote.process_isDMLS__c = true;
        objQuote.process_isExtrusion__c = true;
        objQuote.process_isFDM__c = true;
        objQuote.process_isHPMultJetFusion__c = true;
        objQuote.process_isInjection_Molding__c = true;
        objQuote.process_isPolyJet_3D__c = true;
        objQuote.process_isSheet_metal__c = true;
        objQuote.process_isSLA__c = true;
        objQuote.process_isSLS__c = true;
        objQuote.process_isStamping__c = true;
        objQuote.process_isSheetCutting__c = true;
        objQuote.process_isUrethane_Casting__c = true;
        objQuote.process_isBinderJetting__c = true;
        objQuote.process_isTubeBending__c = true;
        objQuote.process_isTubeCutting__c = true;
        objQuote.process_isOther__c = true;
        objQuote.process_isPlasticExtrusion__c = true;
        objQuote.process_isOther_NotIncluded__c = true;
        objQuote.process_isLSPc__c = true;
        objQuote.process_isAssembly__c = true;
        return objQuote;
    }

    public static Lead createLead(
        Boolean blnInsert,
        String strCompany,
        String strFirstName,
        String strLastName,
        String strEmail,
        String strLeadSource,
        Boolean blnRRFlag,
        Boolean blnGenericFlag
    ) {
        lead testLead = new Lead();
        testLead.company = strCompany;
        testLead.firstname = strFirstName;
        testLead.lastname = strLastName;
        testLead.email = strEmail;
        testLead.LeadSource = strLeadSource;
        testLead.RR_Flag__c = blnRRFlag;
        testLead.Generic_FLAG__c = blnGenericFlag;

        if (blnInsert) {
            insert testLead;
        }

        return testLead;
    }

    public static Supplies_Quote__C createSuppliesQuote(
        Boolean blnIsInsert,
        String strEmail,
        String strDomain,
        String strFirstName,
        String strLastname,
        Date dtCreatedDate,
        Datetime dtLastUpdatedTime
    ) {
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = strEmail;
        sQuoteTest.Account_Domain__c = strDomain;
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = strFirstName;
        sQuoteTest.P21_Contact_Last_Name__c = strLastname;
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Processing';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = dtCreatedDate;
        sQuoteTest.Quote_P21_Last_Updated_Time__c = dtLastUpdatedTime;
        sQuoteTest.Quote_Price__c = 500;
        if (blnIsInsert) {
            insert sQuoteTest;
        }

        return sQuoteTest;
    }

    public static List<User> createUsersForEnterpriseTest() {
        UserRole oneRole = [SELECT ID FROM UserRole WHERE DeveloperName = 'EAM'];
        UserRole AERole = [SELECT ID FROM UserRole WHERE DeveloperName LIKE 'AE%'][0];
        Profile p = [SELECT ID FROM Profile WHERE Name = 'Xometry Sales User'];
        String orgID = UserInfo.getOrganizationId();
        String randoNumLet = '4567441234aabb';
        List<User> usersToCreateList = new List<User>();
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User user1 = new User();
            user1.firstname = 'Jeff';
            user1.lastname = 'D';
            user1.Username = 'jeffDTest' + randoNumLet + '@test' + orgID + '.org';
            user1.Alias = 'jeffDT';
            user1.CommunityNickname = 'jeffDTest';
            user1.NonGeneric_BDR_RR_FLAG__C = false;
            user1.Generic_BDR_RR_FLAG__C = false;
            user1.email = 'jeffDTest@test.org';
            user1.EmailEncodingKey = 'UTF-8';
            user1.TimeZoneSidKey = 'America/New_York';
            user1.LocaleSidKey = 'en_US';
            user1.LanguageLocaleKey = 'en_US';
            user1.ProfileID = p.ID;
            user1.UserRoleId = AERole.ID;
            user1.Supplies_Sales_Rep__c = true;
            usersToCreateList.add(user1);

            User user2 = new User();
            user2.firstname = 'Jesse';
            user2.lastname = 'Test';
            user2.Username = 'JesseTest' + randoNumLet + '@test' + orgID + '.org';
            user2.Alias = 'JesseT';
            user2.CommunityNickname = 'JesseTest';
            user2.NonGeneric_BDR_RR_FLAG__C = false;
            user2.Generic_BDR_RR_FLAG__C = false;
            user2.email = 'JesseTest@test.org';
            user2.EmailEncodingKey = 'UTF-8';
            user2.TimeZoneSidKey = 'America/New_York';
            user2.LocaleSidKey = 'en_US';
            user2.LanguageLocaleKey = 'en_US';
            user2.ProfileID = p.ID;
            user2.UserRoleId = AERole.ID;
            user2.Supplies_Sales_Rep__c = true;
            usersToCreateList.add(user2);

            User user3 = new User();
            user3.firstname = 'Bob';
            user3.lastname = 'Test';
            user3.Username = 'BobTest' + randoNumLet + '@test' + orgID + '.org';
            user3.Alias = 'BobT';
            user3.CommunityNickname = 'BobTest';
            user3.NonGeneric_BDR_RR_FLAG__C = false;
            user3.Generic_BDR_RR_FLAG__C = false;
            user3.email = 'BobTest@test.org';
            user3.EmailEncodingKey = 'UTF-8';
            user3.TimeZoneSidKey = 'America/New_York';
            user3.LocaleSidKey = 'en_US';
            user3.LanguageLocaleKey = 'en_US';
            user3.ProfileID = p.ID;
            user3.UserRoleId = oneRole.ID;
            user3.Supplies_Sales_Rep__c = true;
            usersToCreateList.add(user3);

            User user4 = new User();
            user4.firstname = 'Alfred';
            user4.lastname = 'Test';
            user4.Username = 'Alfred' + randoNumLet + '@test' + orgID + '.org';
            user4.Alias = 'AlfredT';
            user4.CommunityNickname = 'AlfredTest';
            user4.NonGeneric_BDR_RR_FLAG__C = false;
            user4.Generic_BDR_RR_FLAG__C = false;
            user4.email = 'AlfredTest@test.org';
            user4.EmailEncodingKey = 'UTF-8';
            user4.TimeZoneSidKey = 'America/New_York';
            user4.LocaleSidKey = 'en_US';
            user4.LanguageLocaleKey = 'en_US';
            user4.ProfileID = p.ID;
            user4.UserRoleId = oneRole.ID;
            user4.Supplies_Sales_Rep__c = true;
            usersToCreateList.add(user4);

            User user5 = new User();
            user5.firstname = 'Bruce';
            user5.lastname = 'Test';
            user5.Username = 'Bruce' + randoNumLet + '@test' + orgID + '.org';
            user5.Alias = 'BruceT';
            user5.CommunityNickname = 'BruceTest';
            user5.NonGeneric_BDR_RR_FLAG__C = false;
            user5.Generic_BDR_RR_FLAG__C = false;
            user5.email = 'BruceTest@test.org';
            user5.EmailEncodingKey = 'UTF-8';
            user5.TimeZoneSidKey = 'America/New_York';
            user5.LocaleSidKey = 'en_US';
            user5.LanguageLocaleKey = 'en_US';
            user5.ProfileID = p.ID;
            user5.UserRoleId = AERole.ID;
            user5.Supplies_Sales_Rep__c = true;
            usersToCreateList.add(user5);

            User user6 = new User();
            user6.firstname = 'Selena';
            user6.lastname = 'Test';
            user6.Username = 'Selena' + randoNumLet + '@test' + orgID + '.org';
            user6.Alias = 'BruceT';
            user6.CommunityNickname = 'SelenaTest';
            user6.NonGeneric_BDR_RR_FLAG__C = false;
            user6.Generic_BDR_RR_FLAG__C = false;
            user6.email = 'SelenaTest@test.org';
            user6.EmailEncodingKey = 'UTF-8';
            user6.TimeZoneSidKey = 'America/New_York';
            user6.LocaleSidKey = 'en_US';
            user6.LanguageLocaleKey = 'en_US';
            user6.ProfileID = p.ID;
            user6.UserRoleId = AERole.ID;
            user6.Supplies_Sales_Rep__c = true;
            usersToCreateList.add(user6);

            insert usersToCreateList;
        }
        return usersToCreateList;
    }

    /*
    @param a string that represents an Account Team Specialist Role. 
    */
    public static Map<String, List<sObject>> createDataForEnterpriseTest(String aTeamSpecialistRole) {
        List<User> usersList = createUsersForEnterpriseTest();
        Map<String, List<sObject>> returnObjMap = new Map<String, List<sObject>>();
        Account testAccount = new Account();
        testAccount.name = 'SpaceX';
        testAccount.OwnerID = usersList[1].Id;
        testAccount.Email_Domain__c = 'spacex.com';
        testAccount.Generic_Account__c = false;
        testAccount.Hierarchy_Type__c = 'Corporate Parent';
        testAccount.RR_Flag__c = false;
        insert testAccount;
        List<Account> testAccountList = new List<Account>();
        testAccountList.add(testAccount);

        List<Account_Team__c> ateamMemberInsertList = new List<Account_Team__c>();
        //Insert the specialist
        Account_Team__c atmSpec = new Account_Team__c();
        atmSPEC.Account__c = testAccount.ID;
        atmSPEC.Team_Member__c = usersList[2].ID;
        atmSPEC.Team_Role__c = aTeamSpecialistRole;
        ateamMemberInsertList.add(atmSpec);
        //Insert the CSAM
        Account_Team__c atmSpec1 = new Account_Team__c();
        atmSpec1.Account__c = testAccount.ID;
        atmSpec1.Team_Member__c = usersList[5].ID;
        atmSpec1.Team_Role__c = 'Enterprise Account Manager';
        ateamMemberInsertList.add(atmSpec1);
        insert ateamMemberInsertList;
        List<Account_Team__C> atmSPECList = new List<Account_Team__C>();
        atmSPECList.addAll(ateamMemberInsertList);

        List<Contact> contactsToInsertList = new List<Contact>();

        Contact testContact1 = new Contact();
        testContact1.Firstname = 'Patty';
        testContact1.LastName = 'Test';
        testContact1.email = 'patty@spacex.com';
        testContact1.OwnerID = usersList[1].Id;
        testContact1.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact1);

        Contact testContact2 = new Contact();
        testContact2.Firstname = 'Jamie';
        testContact2.LastName = 'Test';
        testContact2.email = 'jamie@spacex.com';
        testContact2.OwnerID = usersList[2].Id;
        testContact2.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact2);

        Contact testContact3 = new Contact();
        testContact3.Firstname = 'Joe';
        testContact3.LastName = 'Test';
        testContact3.email = 'joe@spacex.com';
        testContact3.OwnerID = usersList[2].Id;
        testContact3.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact3);

        Contact testContact4 = new Contact();
        testContact4.Firstname = 'Samantha';
        testContact4.LastName = 'Test';
        testContact4.email = 'samantha@spacex.com';
        testContact4.OwnerID = usersList[1].Id;
        testContact4.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact4);

        Contact testContact5 = new Contact();
        testContact5.Firstname = 'Rudolf';
        testContact5.LastName = 'Test';
        testContact5.email = 'rudolf@spacex.com';
        testContact5.OwnerID = usersList[0].Id;
        testContact5.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact5);

        Contact testContact6 = new Contact();
        testContact6.Firstname = 'Hilary';
        testContact6.LastName = 'Test';
        testContact6.email = 'hilary@spacex.com';
        testContact6.OwnerID = usersList[5].Id;
        testContact6.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact6);

        insert contactsToInsertList;

        List<Project__c> projectsToInsertList = new List<Project__c>();

        Project__c project1 = new Project__c();
        project1.AccountId__c = testAccount.Id;
        project1.Primary_Contact__c = testContact4.Id;
        project1.OwnerId = usersList[1].Id;
        project1.Project__c = 'Rocket';
        projectsToInsertList.add(project1);

        Project__c project2 = new Project__c();
        project2.AccountId__c = testAccount.Id;
        project2.Primary_Contact__c = testContact4.Id;
        project2.OwnerId = usersList[2].Id;
        project2.Project__c = 'Pencil';
        projectsToInsertList.add(project2);

        Project__c project3 = new Project__c();
        project3.AccountId__c = testAccount.Id;
        project3.Primary_Contact__c = testContact4.Id;
        project3.OwnerId = usersList[0].Id;
        project3.Project__c = 'Pencil2';
        projectsToInsertList.add(project3);

        insert projectsToInsertList;
        returnObjMap.put('User', usersList);
        returnObjMap.put('Account', testAccountList);
        returnObjMap.put('Account_Team__C', atmSPECList);
        returnObjMap.put('Contact', contactsToInsertList);
        returnObjMap.put('Project__C', projectsToInsertList);
        return returnObjMap;
    }

    public static Map<String, List<sObject>> createDataForEnterpriseTest() {
        List<User> usersList = createUsersForEnterpriseTest();
        Map<String, List<sObject>> returnObjMap = new Map<String, List<sObject>>();
        Account testAccount = new Account();
        testAccount.name = 'SpaceX';
        testAccount.OwnerID = usersList[1].Id;
        testAccount.Email_Domain__c = 'spacex.com';
        testAccount.Generic_Account__c = false;
        testAccount.Hierarchy_Type__c = 'Corporate Parent';
        testAccount.RR_Flag__c = false;
        insert testAccount;
        List<Account> testAccountList = new List<Account>();
        testAccountList.add(testAccount);

        Account_Team__c atmCSAM = new Account_Team__c();
        atmCSAM.Account__c = testAccount.ID;
        atmCSAM.Team_Member__c = usersList[2].ID;
        atmCSAM.Team_Role__c = 'Enterprise Account Manager';
        insert atmCSAM;
        List<Account_Team__C> atmCSAMList = new List<Account_Team__C>();
        atmCSAMList.add(atmCSAM);

        List<Contact> contactsToInsertList = new List<Contact>();

        Contact testContact1 = new Contact();
        testContact1.Firstname = 'Patty';
        testContact1.LastName = 'Test';
        testContact1.email = 'patty@spacex.com';
        testContact1.OwnerID = usersList[1].Id;
        testContact1.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact1);

        Contact testContact2 = new Contact();
        testContact2.Firstname = 'Jamie';
        testContact2.LastName = 'Test';
        testContact2.email = 'jamie@spacex.com';
        testContact2.OwnerID = usersList[2].Id;
        testContact2.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact2);

        Contact testContact3 = new Contact();
        testContact3.Firstname = 'Joe';
        testContact3.LastName = 'Test';
        testContact3.email = 'joe@spacex.com';
        testContact3.OwnerID = usersList[2].Id;
        testContact3.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact3);

        Contact testContact4 = new Contact();
        testContact4.Firstname = 'Samantha';
        testContact4.LastName = 'Test';
        testContact4.email = 'samantha@spacex.com';
        testContact4.OwnerID = usersList[1].Id;
        testContact4.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact4);

        Contact testContact5 = new Contact();
        testContact5.Firstname = 'Rudolf';
        testContact5.LastName = 'Test';
        testContact5.email = 'rudolf@spacex.com';
        testContact5.OwnerID = usersList[0].Id;
        testContact5.AccountID = testAccount.ID;
        contactsToInsertList.add(testContact5);

        insert contactsToInsertList;

        List<Project__c> projectsToInsertList = new List<Project__c>();

        Project__c project1 = new Project__c();
        project1.AccountId__c = testAccount.Id;
        project1.Primary_Contact__c = testContact4.Id;
        project1.OwnerId = usersList[1].Id;
        project1.Project__c = 'Rocket';
        projectsToInsertList.add(project1);

        Project__c project2 = new Project__c();
        project2.AccountId__c = testAccount.Id;
        project2.Primary_Contact__c = testContact4.Id;
        project2.OwnerId = usersList[2].Id;
        project2.Project__c = 'Pencil';
        projectsToInsertList.add(project2);

        Project__c project3 = new Project__c();
        project3.AccountId__c = testAccount.Id;
        project3.Primary_Contact__c = testContact4.Id;
        project3.OwnerId = usersList[0].Id;
        project3.Project__c = 'Pencil2';
        projectsToInsertList.add(project3);

        insert projectsToInsertList;
        returnObjMap.put('User', usersList);
        returnObjMap.put('Account', testAccountList);
        returnObjMap.put('Account_Team__C', atmCSAMList);
        returnObjMap.put('Contact', contactsToInsertList);
        returnObjMap.put('Project__C', projectsToInsertList);
        return returnObjMap;
    }

    /*
    @params numJobsPerOrder this value should be 9 or less
    */
    public static Map<String, Ops_Order__c> createLargeOrderTestData(
        Integer inNumLargeOrders,
        Integer numChildOrders,
        Integer numJobsPerOrder,
        List<Order_ERP__c> smallOrderList
    ) {
        //Create a Larger Order through the Order ETL with a Related Child Orders and NumberofJobsPerOrder. Jobs are a mix of high risk
        // and non high risks
        // The List always puts the Large Order Parent at the Top
        Date orderCreatedDate = Date.today();
        Datetime orderCreatedTime = Datetime.now();
        Map<String, Ops_Order__c> largeOrderandChildMap = new Map<String, Ops_Order__c>();
        Map<String, String> onlyChildrenMap = new Map<String, String>();
        Set<String> OrderIdStrings = new Set<String>();
        //Get the minimum value to cross over the Large Order Threshold
        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;
        List<Order_ERP__C> ordersToInsertList = new List<Order_ERP__C>();
        for (integer i = 0; i < inNumLargeOrders; i++) {
            Order_ERP__C testLargeOrder = new Order_ERP__C();
            if (i < 10) {
                testLargeOrder.Xometry_ERP_ID__c = 'AAAA1-1230' + String.valueOf(i);
            } else if (i < 100) {
                testLargeOrder.Xometry_ERP_ID__c = 'AAAA1-123' + String.valueOf(i);
            }
            OrderIdStrings.add(testLargeOrder.Xometry_ERP_ID__C);
            testLargeOrder.Account_Domain__c = 'pizzamakers.com';
            testLargeOrder.ERP_Company_Name__C = 'Ninja Pizza';
            testLargeOrder.ERP_Contact_First_Name__c = 'Hamato';
            testLargeOrder.ERP_Contact_Last_Name__c = 'Yoshi';
            testLargeOrder.ERP_Contact__C = 'BBBBB';
            testLargeOrder.ERP_PartPk__c = '56564-55667';
            testLargeOrder.Is_Generic__c = false;
            testLargeOrder.Order_Canceled_Flag__c = false;
            testLargeOrder.Order_ERP_CreatedDate__c = orderCreatedDate;
            testLargeOrder.Order_ERP_Time__c = orderCreatedTime;
            testLargeOrder.Order_Email__c = 'splinterspizza@pizzamakers.com';
            testLargeOrder.Order_Subtotal__c = largeOrderAmount + 1;
            testLargeOrder.Order_Total__c = largeOrderAmount + 1;
            testLargeOrder.AllOrdersTotal__c = largeOrderAmount * 2;
            testLargeOrder.Payment_Type__c = 'credit_card';
            testLargeOrder.process_isPolyJet_3D__c = true;
            ordersToInsertList.add(testLargeOrder);
            for (integer j = 0; j < numChildOrders; j++) {
                Order_ERP__C childOrder = new Order_ERP__C();
                if (j < 10) {
                    childOrder.Xometry_ERP_ID__c = 'AAAA1-' + String.valueof(i) + 'AB0' + String.valueOf(j);
                } else if (j < 100) {
                    childOrder.Xometry_ERP_ID__c = 'AAAA1-' + String.valueof(i) + 'AB' + String.valueOf(j);
                }
                OrderIdStrings.add(childOrder.Xometry_ERP_ID__c);
                childOrder.ParentOpsOrderID__c = testLargeOrder.Xometry_ERP_ID__c;
                childOrder.Account_Domain__c = testLargeOrder.Account_Domain__c;
                childOrder.ERP_Company_Name__C = testLargeOrder.ERP_Company_Name__C;
                childOrder.ERP_Contact_First_Name__c = testLargeOrder.ERP_Contact_First_Name__c;
                childOrder.ERP_Contact_Last_Name__c = testLargeOrder.ERP_Contact_Last_Name__c;
                childOrder.ERP_Contact__C = testLargeOrder.ERP_Contact__C;
                childOrder.ERP_PartPk__c = testLargeOrder.ERP_PartPk__c;
                childOrder.Is_Generic__c = testLargeOrder.Is_Generic__c;
                childOrder.Order_Canceled_Flag__c = testLargeOrder.Order_Canceled_Flag__c;
                childOrder.Order_ERP_CreatedDate__c = orderCreatedDate;
                childOrder.Order_ERP_Time__c = orderCreatedTime;
                childOrder.Order_Email__c = testLargeOrder.Order_Email__c;
                childOrder.Order_Subtotal__c = largeOrderAmount / 2;
                childOrder.Order_Total__c = largeOrderAmount / 2;
                childOrder.AllOrdersTotal__c = largeOrderAmount * 2;
                childOrder.Payment_Type__c = testLargeOrder.Payment_Type__c;
                childOrder.process_isPolyJet_3D__c = true;
                ordersToInsertList.add(childOrder);
                onlyChildrenMap.put(childOrder.Xometry_ERP_ID__c, childOrder.ParentOpsOrderID__c);
            }
        }
        System.debug(ordersToInsertList);
        if (!smallOrderList.isEmpty()) {
            ordersToInsertList.addAll(smallOrderList);
        }

        insert ordersToInsertList;

        //System.debug('Here are my query limits' + Limits.getQueries());
        if (numJobsPerOrder > 0) {
            List<Job__c> jobsToInsertList = new List<Job__C>();
            Integer jobOrderMarker = 1;
            for (Order_ERP__C ord : ordersToInsertList) {
                //Start with high risk and flip the value through the loop
                boolean highRisk = true;
                for (integer i = 0; i < numJobsPerOrder; i++) {
                    Job__C testJob = new Job__C();
                    testJob.Stage__c = 'Accepted';
                    testJob.Name = 'TestJob -' + String.valueof(i);
                    testJob.RiskFactor__c = highRisk ? 'High' : 'Low';
                    testJob.XometryJobID__c = 'J0' + String.valueOf(jobOrderMarker) + '3E87' + String.valueOf(i);
                    testJob.ShippingService__C = 'Fedex';
                    testJob.ShippingMethod__c = 'Two Day Air';
                    testJob.Order_IDs_String__c = ord.Xometry_ERP_ID__c + ';';
                    testJob.XometryOpsOrderID__c = ord.Xometry_ERP_ID__c;
                    testJob.ordered_part_ids_string__c =
                        'uniqueAAAA' +
                        String.valueOf(jobOrderMarker) +
                        String.valueOf(i);
                    testJob.acceptedpartnerid__c = 'P30939';
                    jobsToInsertList.add(testJob);
                    highRisk = highRisk ? false : true;
                }
                jobOrderMarker++;
            }
            insert jobsToInsertList;
        }

        List<Ops_Order__c> createdOpsOrders = [
            SELECT
                ID,
                Is_Large_Order__c,
                Large_Order_Tier__c,
                AllOrdersTotal__c,
                LargeOrderStatus__c,
                XometryOpsOrderID__c,
                ParentOpsOrder__c,
                ParentOpsOrder__r.XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c IN :OrderIdStrings
        ];
        for (Ops_Order__C ord : createdOpsOrders) {
            largeOrderandChildMap.put(ord.XometryOpsOrderID__c, ord);
        }

        return largeOrderandChildMap;
    }

    /*
    @params numJobsPerOrder this value should be 9 or less
    */
    public static Map<String, Ops_Order__c> createLargeOpsOrderTestData(
        Integer inNumLargeOrders,
        Integer numChildOrders,
        Integer numJobsPerOrder,
        List<Ops_Order__c> smallOrderList
    ) {
        //Create a Large Ops Order (bypassing he Order ETL due to SOQL limits) with a Related Child Orders and NumberofJobsPerOrder. Jobs are a mix of high risk
        // and non high risks
        // The List always puts the Large Order Parent at the Top
        Date orderCreatedDate = Date.today();
        Datetime orderCreatedTime = Datetime.now();
        Map<String, Ops_Order__c> largeOrderandChildMap = new Map<String, Ops_Order__c>();
        Map<String, String> onlyChildrenMap = new Map<String, String>();
        Set<String> OrderIdStrings = new Set<String>();
        //Get the minimum value to cross over the Large Order Threshold
        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;
        List<Ops_Order__c> ordersToInsertList = new List<Ops_Order__c>();
        for (integer i = 0; i < inNumLargeOrders; i++) {
            Ops_Order__c testLargeOpsOrder = new Ops_Order__c();
            if (i < 10) {
                testLargeOpsOrder.XometryOpsOrderID__c = 'AAAA1-1230' + String.valueOf(i);
            } else if (i < 100) {
                testLargeOpsOrder.XometryOpsOrderID__c = 'AAAA1-123' + String.valueOf(i);
            }
            OrderIdStrings.add(testLargeOpsOrder.XometryOpsOrderID__c);
            testLargeOpsOrder.Order_Date__c = orderCreatedDate;
            testLargeOpsOrder.Order_DateTime__c = orderCreatedTime;
            testLargeOpsOrder.OrderTotal__c = largeOrderAmount + 1;
            testLargeOpsOrder.AllOrdersTotal__c = largeOrderAmount * 2;
            ordersToInsertList.add(testLargeOpsOrder);
            for (integer j = 0; j < numChildOrders; j++) {
                Ops_Order__c childOpsOrder = new Ops_Order__c();
                if (j < 10) {
                    childOpsOrder.XometryOpsOrderID__c = 'AAAA1-' + String.valueof(i) + 'AB0' + String.valueOf(j);
                } else if (j < 100) {
                    childOpsOrder.XometryOpsOrderID__c = 'AAAA1-' + String.valueof(i) + 'AB' + String.valueOf(j);
                }
                OrderIdStrings.add(childOpsOrder.XometryOpsOrderID__c);
                childOpsOrder.ParentOpsOrderID__c = testLargeOpsOrder.XometryOpsOrderID__c;
                childOpsOrder.Order_Date__c = orderCreatedDate;
                childOpsOrder.Order_DateTime__c = orderCreatedTime;
                childOpsOrder.OrderTotal__c = largeOrderAmount + 1;
                childOpsOrder.AllOrdersTotal__c = largeOrderAmount * 2;
                ordersToInsertList.add(childOpsOrder);
                onlyChildrenMap.put(childOpsOrder.XometryOpsOrderID__c, childOpsOrder.ParentOpsOrderID__c);
            }
        }
        System.debug(ordersToInsertList);
        if (!smallOrderList.isEmpty()) {
            ordersToInsertList.addAll(smallOrderList);
        }

        insert ordersToInsertList;

        //System.debug('Here are my query limits' + Limits.getQueries());
        if (numJobsPerOrder > 0) {
            List<Job__c> jobsToInsertList = new List<Job__C>();
            Integer jobOrderMarker = 1;
            for (Ops_Order__c ord : ordersToInsertList) {
                //Start with high risk and flip the value through the loop
                boolean highRisk = true;
                for (integer i = 0; i < numJobsPerOrder; i++) {
                    Job__C testJob = new Job__C();
                    testJob.Stage__c = 'Accepted';
                    testJob.Name = 'TestJob -' + String.valueof(i);
                    testJob.RiskFactor__c = highRisk ? 'High' : 'Low';
                    testJob.XometryJobID__c = 'J0' + String.valueOf(jobOrderMarker) + '3E87' + String.valueOf(i);
                    testJob.ShippingService__C = 'Fedex';
                    testJob.ShippingMethod__c = 'Two Day Air';
                    testJob.Order_IDs_String__c = ord.XometryOpsOrderID__c + ';';
                    testJob.XometryOpsOrderID__c = ord.XometryOpsOrderID__c;
                    testJob.ordered_part_ids_string__c =
                        'uniqueAAAA' +
                        String.valueOf(jobOrderMarker) +
                        String.valueOf(i);
                    testJob.acceptedpartnerid__c = 'P30939';
                    jobsToInsertList.add(testJob);
                    highRisk = highRisk ? false : true;
                }
                jobOrderMarker++;
            }
            insert jobsToInsertList;
        }

        List<Ops_Order__c> createdOpsOrders = [
            SELECT
                ID,
                Is_Large_Order__c,
                Large_Order_Tier__c,
                AllOrdersTotal__c,
                LargeOrderStatus__c,
                XometryOpsOrderID__c,
                ParentOpsOrder__c,
                ParentOpsOrder__r.XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c IN :OrderIdStrings
        ];
        for (Ops_Order__C ord : createdOpsOrders) {
            largeOrderandChildMap.put(ord.XometryOpsOrderID__c, ord);
        }

        return largeOrderandChildMap;
    }

    public static List<Job__c> createJobsForLargeOrders(
        boolean childOnlyJobs,
        integer numJobsPerOrder,
        List<Ops_Order__c> opsOrderList
    ) {
        //System.debug('Here are my query limits' + Limits.getQueries());
        List<Job__c> jobsToInsertList = new List<Job__C>();
        Integer jobOrderMarker = 1;
        integer opUnique = 1;
        for (Ops_Order__c ord : opsOrderList) {
            opUnique += 1;
            boolean createJobsForOrder = true;
            if (childOnlyJobs && ord.ParentOpsOrder__r.XometryOpsOrderID__c == null) {
                createJobsForOrder = false;
            }
            System.debug('Are we getting here');
            //Start with high risk and flip the value through the loop
            boolean highRisk = true;
            if (createJobsForOrder == true) {
                for (integer i = 0; i < numJobsPerOrder; i++) {
                    Job__C testJob = new Job__C();
                    testJob.Stage__c = 'Accepted';
                    testJob.Name = 'TestJob -' + String.valueof(i);
                    testJob.RiskFactor__c = highRisk ? 'High' : 'Low';
                    testJob.XometryJobID__c = 'J0' + String.valueOf(jobOrderMarker) + '3E87' + String.valueOf(i);
                    testJob.ShippingService__C = 'Fedex';
                    testJob.ShippingMethod__c = 'Two Day Air';
                    testJob.Order_IDs_String__c = ord.XometryOpsOrderID__c + ';';
                    testJob.XometryOpsOrderID__c = ord.XometryOpsOrderID__c;
                    testJob.ordered_part_ids_string__c = 'uniqueAAAA' + String.valueOf(opUnique) + String.valueOf(i);
                    testJob.acceptedpartnerid__c = 'P30939';
                    System.debug(testJob);
                    jobsToInsertList.add(testJob);
                    highRisk = highRisk ? false : true;
                }
            }
            jobOrderMarker++;
        }
        insert jobsToInsertList;
        System.debug('POST JOB CREATION');
        System.debug(jobsToInsertList.size());
        System.debug(jobsToInsertList);
        return jobsToInsertList;
    }

    //Can Extract this test class to demo largeOrders for Stakeholders and provide end to end test scenario starting with Order
    //This can be extended in the furture for Quotes and Quoted Parts
    /*
    @description This method creates a Large Order with an Ordered Part, a Job and Job Ordered Part that are all linked together
    */
    public static Map<String, List<sObject>> largeOrderDemoDataBasic() {
        Map<String, List<sObject>> returnObjMap = new Map<String, List<sObject>>();
        DateTime AcceptedDT = DateTime.now();
        Date OrderPlacedDate = Date.today();
        Date OrderDueDateDT = Date.today();
        List<Order_Erp__c> ordersToInsert = new List<Order_ERP__C>();
        List<Ordered_Part__c> orderedPartToInsertList = new List<Ordered_Part__c>();
        List<Job__C> jobList = new List<Job__C>();
        // PARENT ORDER

        //Quick reference
        /*
        Large Order = 4D742-15005
        Ordered Part for Large Order =  62a1405d3c75b6ada38326ac , 62a1405d3c75b6ada38326ad
        Job for Large Order =  J0091641

       */
        Order_ERP__c simpleLORD = new Order_ERP__c(
            xometry_erp_id__c = '4D742-15005',
            xometry_quote_id__c = 'Q90-2978-2623',
            account_domain__c = 'us.navy.mil',
            certifications__c = 0.0,
            discount__c = 0.0,
            erp_company_name__c = 'US navy',
            erp_contact__c = '4D742',
            erp_contact_first_name__c = 'John',
            erp_contact_last_name__c = 'Doe',
            erp_contact_phone__c = '5555556667',
            erp_partpk__c = '0329EEC-0329EED',
            erp_status__c = 'In Progress',
            is_generic__c = false,
            order_canceled_flag__c = false,
            order_email__c = 'johndoe@us.navy.mil',
            order_subtotal__c = 45000.0,
            order_total__c = 45000.0,
            payment_type__c = 'purchase_order',
            points_earned__c = 0.0,
            process_iscarbon__c = false,
            process_iscnc_machining__c = true,
            process_isdie_casting__c = false,
            process_isdirect_sourced__c = false,
            process_isdmls__c = false,
            process_isextrusion__c = false,
            process_isfdm__c = false,
            process_ishpmultjetfusion__c = false,
            process_isinjection_molding__c = false,
            process_ispolyjet_3d__c = false,
            process_issheet_metal__c = false,
            process_issla__c = false,
            process_issls__c = false,
            process_isstamping__c = false,
            process_isurethane_casting__c = false,
            quote_type__c = 'Manually-Quoted',
            redeemed_points__c = 0.0,
            redeemed_points_value__c = 0.0,
            shipping__c = 0.0,
            shipping_discount__c = 0.0,
            tax__c = 0.0,
            erp_billing_zip_code__c = '37830',
            erp_billing_state_or_province__c = 'Tennessee',
            erp_billing_country__c = 'United States',
            erp_billing_city__c = 'OAK RIDGE',
            erp_billing_address__c = '151 LAFAYETTE DRIVE',
            erp_shipping_address__c = '28 Jacome Way',
            Erp_shipping_city__c = 'Middletown',
            erp_shipping_country__c = 'United States',
            erp_shipping_state_or_province__c = 'Rhode Island',
            erp_shipping_zip_code__c = '02842',
            ordered_total_amt_carbon__c = 0.0,
            ordered_total_qty_carbon__c = 0,
            ordered_total_qty_cnc__c = 4,
            ordered_total_amt_cnc__c = 45000.0,
            ordered_total_amt_diecasting__c = 0.0,
            ordered_total_qty_diecasting__c = 0,
            ordered_total_qty_directsourced__c = 0,
            ordered_total_amt_directsourced__c = 0.0,
            ordered_total_qty_dmls__c = 0,
            ordered_total_amt_dmls__c = 0.0,
            ordered_total_amt_extrusion__c = 0.0,
            ordered_total_qty_extrusion__c = 0,
            ordered_total_qty_fdm__c = 0,
            ordered_total_qty_hpmultjetfusion__c = 0,
            ordered_total_qty_injectionmolding__c = 0,
            ordered_total_qty_polyjet3d__c = 0,
            ordered_total_qty_sheetmetal__c = 0,
            ordered_total_qty_sla__c = 0,
            ordered_total_qty_sls__c = 0,
            ordered_total_qty_stamping__c = 0,
            ordered_total_qty_urethanecasting__c = 0,
            ordered_total_amt_fdm__c = 0.0,
            ordered_total_amt_hpmuljetfusion__c = 0.0,
            ordered_total_amt_injectionmolding__c = 0.0,
            ordered_total_amt_polyjet3d__c = 0.0,
            ordered_total_amt_sheetmetal__c = 0.0,
            ordered_total_amt_sla__c = 0.0,
            ordered_total_amt_sls__c = 0.0,
            ordered_total_amt_stamping__c = 0.0,
            ordered_total_amt_urethanecasting__c = 0.0,
            process_isinjectionmoldingtool__c = false,
            ordered_total_qty_injectionmoldingtool__c = 0,
            ordered_total_amt_injectionmoldingtool__c = 0.0,
            lineitemcount__c = 2,
            Casemanager__c = 'D\'Arron Dixon',
            customernotes__c = 'DUE 45BD AFTER ACCEPTING JOB',
            madeinchina__c = false,
            orderduedate__c = OrderDueDateDT,
            originalduedate__c = OrderDueDateDT,
            ponumber__c = 'P010265543',
            robooutsource__c = false,
            shippingmethod__c = 'Ground',
            shippingservice__c = 'Fedex',
            pod__c = 'Atomic Rocks',
            ordered_total_amt_sheetcutting__c = 0.0,
            ordered_total_qty_sheetcutting__c = 0,
            process_issheetcutting__c = false,
            process_isbinderjetting__c = false,
            ordered_total_qty_binderjetting__c = 0,
            ordered_total_amt_binderjetting__c = 0.0,
            itar__c = true,
            material_cert__c = 'DFARS Compliant Material Cert',
            material_traceability_cert__c = false,
            conformance_cert__c = true,
            Erp_order_last_modifieddate__c = OrderDueDateDT,
            hardware_cert__c = false,
            originatedinfusion360__c = false,
            pricingtier__c = 'standard',
            isstainlesssteel_mat__c = false,
            isalum_mat__c = true,
            eud_hascase__c = false,
            eud_htscode__c = false,
            eud_importreason__c = false,
            eud_industry__c = false,
            eud_missingendusedata__c = false,
            eud_lineitembreakdown__c = '0329EEC = Import Reason, Industry, Description, HTS Code; 0329EED = Import Reason, Industry, Description, HTS Code',
            eud_partdescription__c = false,
            allorderstotal__c = 45000.00,
            ordered_total_amt_other__c = 0.0,
            ordered_total_amt_tube_bending__c = 0.0,
            ordered_total_amt_tube_cutting__c = 0.0,
            ordered_total_qty_tube_cutting__c = 0,
            ordered_total_qty_tube_bending__c = 0,
            ordered_total_qty_other__c = 0,
            process_isother__c = false,
            process_istubebending__c = false,
            process_istubecutting__c = false,
            Order_ERP_CreatedDate__C = OrderPlacedDate
        );

        ordersToInsert.add(simpleLORD);

        List<Ordered_Part__c> orderedParts = new List<Ordered_Part__c>();
        Ordered_Part__c partOne = new Ordered_Part__c(
            alljobids__c = 'J0091641',
            casemanager__c = 'D\'Arron Dixon',
            currentjobid__c = 'J0091641',
            customerpartid__c = '0308E9B',
            customerprice__c = 2250000,
            finish__c = 'Standard',
            finishgroup__c = 'Standard',
            inspectiontype__c = 'cmm',
            isconf__c = true,
            isdfars__c = true,
            isdomestic__c = false,
            isitar__c = true,
            ismanuallyquoted__c = true,
            ismaterial__c = false,
            ismaterialtraceability__c = false,
            material__c = 'Aluminum 6061-T6',
            materialgroup__c = 'Aluminum',
            materialtype__c = 'metal',
            mqprice__c = 22500.0,
            orderduedate__c = OrderDueDateDT,
            ordereddate__c = OrderPlacedDate,
            originalorderduedate__c = OrderDueDateDT,
            outsourcepartnergroup__c = 'Ultra Premium Group',
            partstatus__c = 'Materials Received',
            pod__c = 'Atomic Rocks',
            process__c = 'CNC',
            quantityordered__c = 2,
            revisionnum__c = 0,
            selectedpricetier__c = 'standard',
            sheetmetaltype__c = 'None',
            surfaceroughness__c = 0,
            surfaceroughness_finish__c = '016Ra',
            surfaceroughness_quantity__c = 0,
            tolerance_precision__c = 0.001,
            tolerance_quantity__c = 2,
            unique_ordered_part_id__c = '62a1405d3c75b6ada38326ac',
            unique_quoted_part_id__c = '6272e33301ef2fd65bce0f63',
            vendor_finishgroup__c = 'Standard',
            vendorfinish__c = 'Standard',
            xometry_order_id__c = '4D742-15005',
            xometry_quote_id__c = 'Q90-2978-2623',
            xometry_ordered_part_ID__c = '12322AB3',
            xometry_quoted_part_id__c = '0308E9B',
            name = '0308E9B'
        );

        orderedPartToInsertList.add(partOne);

        Ordered_Part__c partTwo = new Ordered_Part__c(
            alljobids__c = 'J0091641',
            casemanager__c = 'D\'Arron Dixon',
            currentjobid__c = 'J0091641',
            customerpartid__c = '0308E9F',
            customerprice__c = 2250000,
            finish__c = 'Standard',
            finishgroup__c = 'Standard',
            inspectiontype__c = 'cmm',
            isconf__c = true,
            isdfars__c = true,
            isdomestic__c = false,
            isitar__c = true,
            ismanuallyquoted__c = true,
            ismaterial__c = false,
            ismaterialtraceability__c = false,
            material__c = 'Aluminum 6061-T6',
            materialgroup__c = 'Aluminum',
            materialtype__c = 'metal',
            mqprice__c = 22500.0,
            orderduedate__c = OrderDueDateDT,
            ordereddate__c = OrderPlacedDate,
            originalorderduedate__c = OrderDueDateDT,
            outsourcepartnergroup__c = 'Ultra Premium Group',
            partstatus__c = 'Materials Received',
            pod__c = 'Atomic Rocks',
            process__c = 'CNC',
            quantityordered__c = 2,
            revisionnum__c = 0,
            selectedpricetier__c = 'standard',
            sheetmetaltype__c = 'None',
            surfaceroughness__c = 0,
            surfaceroughness_finish__c = '016Ra',
            surfaceroughness_quantity__c = 0,
            tolerance_precision__c = 0.001,
            tolerance_quantity__c = 2,
            unique_ordered_part_id__c = '62a1405d3c75b6ada38326ad',
            unique_quoted_part_id__c = '6272e34496789bc79d1f7e9d',
            vendor_finishgroup__c = 'Standard',
            vendorfinish__c = 'Standard',
            xometry_order_id__c = '4D742-15005',
            xometry_quote_id__c = 'Q90-2978-2623',
            xometry_ordered_part_ID__c = '12322AB4',
            xometry_quoted_part_id__c = '0308E9F',
            name = '0308E9F'
        );
        orderedPartToInsertList.add(partTwo);

        Job__c jobForSimpleLORD = new Job__c(
            inspectionrequirement__c = 'cmm, std+r',
            jobmargin__c = 90.0,
            name = 'J0091641',
            outsourcepartnergroup__c = 'Ultra Premium',
            processes__c = 'CNC',
            riskfactor__c = 'High',
            stage__c = 'Accepted',
            duedate__c = OrderDueDateDT,
            accepteddatetime__c = AcceptedDT,
            acceptedpartnerid__c = 'P30939',
            xometryjobid__c = 'J0091641',
            acceptedprice__c = 36000.0,
            xometryopsorderid__c = '4D742-15005',
            orderduedate__c = OrderDueDateDT,
            quotetype__c = 'Manual',
            itar__c = true,
            shippingmethod__c = 'Ground',
            shippingservice__c = 'Fedex',
            gno_customerprice__c = 360000.0,
            madeinchina__c = false,
            repeatwork__c = false,
            isalum_mat__c = true,
            isstainlesssteel_mat__c = false,
            hasdelrinmat__c = false,
            hastitaniummat__c = false,
            ordered_part_ids_string__c = '62a1405d3c75b6ada38326ac;62a1405d3c75b6ada38326ad',
            order_ids_string__c = '4D742-15005'
        );
        jobList.add(jobForSimpleLORD);
        returnObjMap.put('order', ordersToInsert);
        returnObjMap.put('orderedPart', orderedPartToInsertList);
        returnObjMap.put('job', jobList);

        return returnObjMap;
    }

    /*
    @description This creates a Large order with a Child with an Ordered Part for each Order, a Job for each and an Ordered Part for each.
    */
    public static Map<String, List<sObject>> largeOrderDemoDatawithChild() {
        Map<String, List<sObject>> returnObjMap = new Map<String, List<sObject>>();
        DateTime AcceptedDT = DateTime.now();
        Date OrderPlacedDate = Date.today();
        Date OrderDueDateDT = Date.today();
        List<Order_Erp__c> ordersToInsert = new List<Order_ERP__C>();
        // PARENT ORDER

        //Quick reference
        /*
        Parent Order = 451CD-1501F
        Ordered Part for Parent =  62a1405d3c75b6ada38326ac
        Job for Parent =  J0091641
        Child Order = 451CD-15018
        Ordered Part for Child = 62a1405d3c75b6ada38326ad
        Job for Child =J009164A

       */
        Order_ERP__c parentOrder = new Order_ERP__c(
            xometry_erp_id__c = '451CD-1501F',
            xometry_quote_id__c = '451CD-1501F',
            account_domain__c = 'spacex.com',
            certifications__c = 0.0,
            discount__c = 0.0,
            erp_company_name__c = 'SpaceX',
            erp_contact__c = '451CD',
            erp_contact_first_name__c = 'John',
            erp_contact_last_name__c = 'Doed',
            erp_contact_phone__c = '5555556065',
            erp_partpk__c = '02D7315',
            erp_status__c = 'In Progress',
            is_generic__c = false,
            order_canceled_flag__c = false,
            order_email__c = 'johndoed@spacex.com',
            order_subtotal__c = 3286.24,
            order_total__c = 3286.24,
            payment_type__c = 'purchase_order',
            points_earned__c = 0.0,
            process_iscarbon__c = false,
            process_iscnc_machining__c = true,
            process_isdie_casting__c = false,
            process_isdirect_sourced__c = false,
            process_isdmls__c = false,
            process_isextrusion__c = false,
            process_isfdm__c = false,
            process_ishpmultjetfusion__c = false,
            process_isinjection_molding__c = false,
            process_ispolyjet_3d__c = false,
            process_issheet_metal__c = false,
            process_issla__c = false,
            process_issls__c = false,
            process_isstamping__c = false,
            process_isurethane_casting__c = false,
            quote_type__c = 'Manually-Quoted',
            redeemed_points__c = 0.0,
            redeemed_points_value__c = 0.0,
            shipping__c = 0.0,
            shipping_discount__c = 0.0,
            tax__c = 0.0,
            erp_billing_zip_code__c = '90250',
            erp_billing_state_or_province__c = 'California',
            erp_billing_country__c = 'United States',
            erp_billing_city__c = 'Hawthorne',
            erp_billing_address__c = '1 Rocket Road',
            erp_shipping_address__c = '3901 Jack Northrop Ave',
            Erp_shipping_city__c = 'Hawthorne',
            erp_shipping_country__c = 'United States',
            erp_shipping_state_or_province__c = 'California',
            erp_shipping_zip_code__c = '90250',
            ordered_total_amt_carbon__c = 0.0,
            ordered_total_qty_carbon__c = 0,
            ordered_total_qty_cnc__c = 184,
            ordered_total_amt_cnc__c = 3286.24,
            ordered_total_amt_diecasting__c = 0.0,
            ordered_total_qty_diecasting__c = 0,
            ordered_total_qty_directsourced__c = 0,
            ordered_total_amt_directsourced__c = 0.0,
            ordered_total_qty_dmls__c = 0,
            ordered_total_amt_dmls__c = 0.0,
            ordered_total_amt_extrusion__c = 0.0,
            ordered_total_qty_extrusion__c = 0,
            ordered_total_qty_fdm__c = 0,
            ordered_total_qty_hpmultjetfusion__c = 0,
            ordered_total_qty_injectionmolding__c = 0,
            ordered_total_qty_polyjet3d__c = 0,
            ordered_total_qty_sheetmetal__c = 0,
            ordered_total_qty_sla__c = 0,
            ordered_total_qty_sls__c = 0,
            ordered_total_qty_stamping__c = 0,
            ordered_total_qty_urethanecasting__c = 0,
            ordered_total_amt_fdm__c = 0.0,
            ordered_total_amt_hpmuljetfusion__c = 0.0,
            ordered_total_amt_injectionmolding__c = 0.0,
            ordered_total_amt_polyjet3d__c = 0.0,
            ordered_total_amt_sheetmetal__c = 0.0,
            ordered_total_amt_sla__c = 0.0,
            ordered_total_amt_sls__c = 0.0,
            ordered_total_amt_stamping__c = 0.0,
            ordered_total_amt_urethanecasting__c = 0.0,
            process_isinjectionmoldingtool__c = false,
            ordered_total_qty_injectionmoldingtool__c = 0,
            ordered_total_amt_injectionmoldingtool__c = 0.0,
            lineitemcount__c = 18,
            Casemanager__c = 'Melissa Clem',
            customernotes__c = 'BY ACCEPTING THIS JOB PARTNER AGREES TO PURCHASE MATERIAL FROM XOMETRY SUPPLIES.  PARTNER TO COMMENCE TRANSACTION BY EMAILING SUPPLIES@XOMETRY.COM WITH YOUR JOB NUMBER IN THE SUBJECT LINE',
            madeinchina__c = false,
            orderduedate__c = OrderDueDateDT,
            originalduedate__c = OrderDueDateDT,
            ponumber__c = '1850474',
            robooutsource__c = false,
            shippingmethod__c = 'Ground',
            shippingservice__c = 'Fedex',
            pod__c = 'SpaceTechs',
            ordered_total_amt_sheetcutting__c = 0.0,
            ordered_total_qty_sheetcutting__c = 0,
            process_issheetcutting__c = false,
            process_isbinderjetting__c = false,
            ordered_total_qty_binderjetting__c = 0,
            ordered_total_amt_binderjetting__c = 0.0,
            itar__c = true,
            material_cert__c = 'DFARS Compliant Material Cert',
            material_traceability_cert__c = true,
            conformance_cert__c = true,
            Erp_order_last_modifieddate__c = OrderDueDateDT,
            hardware_cert__c = false,
            originatedinfusion360__c = false,
            pricingtier__c = 'standard',
            isstainlesssteel_mat__c = true,
            isalum_mat__c = true,
            eud_hascase__c = false,
            eud_htscode__c = false,
            eud_importreason__c = false,
            eud_industry__c = false,
            eud_missingendusedata__c = false,
            eud_lineitembreakdown__c = '02D7315 = Import Reason, Industry, Description, HTS Code',
            eud_partdescription__c = false,
            AllOrdersTotal__c = 47008.36,
            ordered_total_amt_other__c = 0.0,
            ordered_total_amt_tube_bending__c = 0.0,
            ordered_total_amt_tube_cutting__c = 0.0,
            ordered_total_qty_tube_cutting__c = 0,
            ordered_total_qty_tube_bending__c = 0,
            ordered_total_qty_other__c = 0,
            process_isother__c = false,
            process_istubebending__c = false,
            process_istubecutting__c = false,
            Order_ERP_CreatedDate__C = OrderPlacedDate
        );

        ordersToInsert.add(parentOrder);
        Order_ERP__c childOrder = new Order_ERP__c(
            xometry_erp_id__c = '451CD-15018',
            xometry_quote_id__c = '451CD-15018',
            account_domain__c = 'spacex.com',
            certifications__c = 0.0,
            discount__c = 0.0,
            erp_company_name__c = 'SpaceX',
            erp_contact__c = '451CD',
            erp_contact_first_name__c = 'John',
            erp_contact_last_name__c = 'Doe',
            erp_contact_phone__c = '5555556064',
            erp_partpk__c = '02D72CD-02D72C4-02D72C6-02D72D2-02D72CB-02D72CF-02D72CC-02D72CA-02D72C8-02D72C9-02D72D4-02D72D5-02D72D3-02D72CE-02D72D7-02D72C5-02D72E8-02D7315',
            erp_status__c = 'In Progress',
            is_generic__c = false,
            order_canceled_flag__c = false,
            order_email__c = 'johndoed@spacex.com',
            order_subtotal__c = 43722.12,
            order_total__c = 43722.12,
            payment_type__c = 'purchase_order',
            points_earned__c = 0.0,
            process_iscarbon__c = false,
            process_iscnc_machining__c = true,
            process_isdie_casting__c = false,
            process_isdirect_sourced__c = false,
            process_isdmls__c = false,
            process_isextrusion__c = false,
            process_isfdm__c = false,
            process_ishpmultjetfusion__c = false,
            process_isinjection_molding__c = false,
            process_ispolyjet_3d__c = false,
            process_issheet_metal__c = false,
            process_issla__c = false,
            process_issls__c = false,
            process_isstamping__c = false,
            process_isurethane_casting__c = false,
            quote_type__c = 'Manually-Quoted',
            redeemed_points__c = 0.0,
            redeemed_points_value__c = 0.0,
            shipping__c = 0.0,
            shipping_discount__c = 0.0,
            tax__c = 0.0,
            erp_billing_zip_code__c = '90250',
            erp_billing_state_or_province__c = 'California',
            erp_billing_country__c = 'United States',
            erp_billing_city__c = 'Hawthorne',
            erp_billing_address__c = '1 Rocket Road',
            erp_shipping_address__c = '3901 Jack Northrop Ave',
            Erp_shipping_city__c = 'Hawthorne',
            erp_shipping_country__c = 'United States',
            erp_shipping_state_or_province__c = 'California',
            erp_shipping_zip_code__c = '90250',
            ordered_total_amt_carbon__c = 0.0,
            ordered_total_qty_carbon__c = 0,
            ordered_total_qty_cnc__c = 613,
            ordered_total_amt_cnc__c = 42331.08,
            ordered_total_amt_diecasting__c = 0.0,
            ordered_total_qty_diecasting__c = 0,
            ordered_total_qty_directsourced__c = 0,
            ordered_total_amt_directsourced__c = 0.0,
            ordered_total_qty_dmls__c = 0,
            ordered_total_amt_dmls__c = 0.0,
            ordered_total_amt_extrusion__c = 0.0,
            ordered_total_qty_extrusion__c = 0,
            ordered_total_qty_fdm__c = 0,
            ordered_total_qty_hpmultjetfusion__c = 0,
            ordered_total_qty_injectionmolding__c = 0,
            ordered_total_qty_polyjet3d__c = 0,
            ordered_total_qty_sheetmetal__c = 0,
            ordered_total_qty_sla__c = 0,
            ordered_total_qty_sls__c = 0,
            ordered_total_qty_stamping__c = 0,
            ordered_total_qty_urethanecasting__c = 0,
            ordered_total_amt_fdm__c = 0.0,
            ordered_total_amt_hpmuljetfusion__c = 0.0,
            ordered_total_amt_injectionmolding__c = 0.0,
            ordered_total_amt_polyjet3d__c = 0.0,
            ordered_total_amt_sheetmetal__c = 0.0,
            ordered_total_amt_sla__c = 0.0,
            ordered_total_amt_sls__c = 0.0,
            ordered_total_amt_stamping__c = 0.0,
            ordered_total_amt_urethanecasting__c = 0.0,
            process_isinjectionmoldingtool__c = false,
            ordered_total_qty_injectionmoldingtool__c = 0,
            ordered_total_amt_injectionmoldingtool__c = 0.0,
            lineitemcount__c = 18,
            Casemanager__c = 'Melissa Clem',
            customernotes__c = 'BY ACCEPTING THIS JOB PARTNER AGREES TO PURCHASE MATERIAL FROM XOMETRY SUPPLIES.  PARTNER TO COMMENCE TRANSACTION BY EMAILING SUPPLIES@XOMETRY.COM WITH YOUR JOB NUMBER IN THE SUBJECT LINE',
            madeinchina__c = false,
            orderduedate__c = OrderDueDateDT,
            originalduedate__c = OrderDueDateDT,
            ponumber__c = '1850474',
            robooutsource__c = false,
            shippingmethod__c = 'Ground',
            shippingservice__c = 'Fedex',
            pod__c = 'SpaceTechs',
            ordered_total_amt_sheetcutting__c = 1391.04,
            ordered_total_qty_sheetcutting__c = 184,
            process_issheetcutting__c = false,
            process_isbinderjetting__c = false,
            ordered_total_qty_binderjetting__c = 0,
            ordered_total_amt_binderjetting__c = 0.0,
            itar__c = true,
            material_cert__c = 'DFARS Compliant Material Cert',
            material_traceability_cert__c = true,
            conformance_cert__c = true,
            Erp_order_last_modifieddate__c = OrderDueDateDT,
            hardware_cert__c = false,
            originatedinfusion360__c = false,
            pricingtier__c = 'standard',
            isstainlesssteel_mat__c = true,
            isalum_mat__c = true,
            eud_hascase__c = false,
            eud_htscode__c = false,
            eud_importreason__c = false,
            eud_industry__c = false,
            eud_missingendusedata__c = false,
            eud_lineitembreakdown__c = '0329EEC = Import Reason, Industry, Description, HTS Code; 0329EED = Import Reason, Industry, Description, HTS Code',
            eud_partdescription__c = false,
            allorderstotal__c = 47008.36,
            ordered_total_amt_other__c = 0.0,
            ordered_total_amt_tube_bending__c = 0.0,
            ordered_total_amt_tube_cutting__c = 0.0,
            ordered_total_qty_tube_cutting__c = 0,
            ordered_total_qty_tube_bending__c = 0,
            ordered_total_qty_other__c = 0,
            process_isother__c = false,
            process_istubebending__c = false,
            process_istubecutting__c = false,
            parentopsorderid__c = '451CD-1501F',
            Order_ERP_CreatedDate__C = OrderPlacedDate
        );

        ordersToInsert.add(childOrder);

        List<Ordered_Part__c> orderedParts = new List<Ordered_Part__c>();
        Ordered_Part__c partOne = new Ordered_Part__c(
            alljobids__c = 'J0091641',
            casemanager__c = 'D\'Arron Dixon',
            currentjobid__c = 'J0091641',
            customerpartid__c = '0308E9B',
            customerprice__c = 2250000,
            finish__c = 'Standard',
            finishgroup__c = 'Standard',
            inspectiontype__c = 'cmm',
            isconf__c = true,
            isdfars__c = true,
            isdomestic__c = false,
            isitar__c = true,
            ismanuallyquoted__c = true,
            ismaterial__c = false,
            ismaterialtraceability__c = false,
            material__c = 'Aluminum 6061-T6',
            materialgroup__c = 'Aluminum',
            materialtype__c = 'metal',
            mqprice__c = 22500.0,
            orderduedate__c = OrderDueDateDT,
            ordereddate__c = OrderPlacedDate,
            originalorderduedate__c = OrderDueDateDT,
            outsourcepartnergroup__c = 'Ultra Premium Group',
            partstatus__c = 'Materials Received',
            pod__c = 'Atomic Rocks',
            process__c = 'CNC',
            quantityordered__c = 2,
            revisionnum__c = 0,
            selectedpricetier__c = 'standard',
            sheetmetaltype__c = 'None',
            surfaceroughness__c = 0,
            surfaceroughness_finish__c = '016Ra',
            surfaceroughness_quantity__c = 0,
            tolerance_precision__c = 0.001,
            tolerance_quantity__c = 2,
            unique_ordered_part_id__c = '62a1405d3c75b6ada38326ac',
            unique_quoted_part_id__c = '6272e33301ef2fd65bce0f63',
            vendor_finishgroup__c = 'Standard',
            vendorfinish__c = 'Standard',
            xometry_order_id__c = '451CD-1501F',
            xometry_quote_id__c = 'Q90-2978-2623',
            xometry_ordered_part_ID__c = '12322AB1',
            xometry_quoted_part_id__c = '0308E9B',
            name = '0308E9B'
        );

        orderedParts.add(partOne);

        Ordered_Part__c partTwo = new Ordered_Part__c(
            alljobids__c = 'J009164A',
            casemanager__c = 'D\'Arron Dixon',
            currentjobid__c = 'J009164A',
            customerpartid__c = '0308E9F',
            customerprice__c = 2250000,
            finish__c = 'Standard',
            finishgroup__c = 'Standard',
            inspectiontype__c = 'cmm',
            isconf__c = true,
            isdfars__c = true,
            isdomestic__c = false,
            isitar__c = true,
            ismanuallyquoted__c = true,
            ismaterial__c = false,
            ismaterialtraceability__c = false,
            material__c = 'Aluminum 6061-T6',
            materialgroup__c = 'Aluminum',
            materialtype__c = 'metal',
            mqprice__c = 22500.0,
            orderduedate__c = OrderDueDateDT,
            ordereddate__c = OrderPlacedDate,
            originalorderduedate__c = OrderDueDateDT,
            outsourcepartnergroup__c = 'Ultra Premium Group',
            partstatus__c = 'Materials Received',
            pod__c = 'Atomic Rocks',
            process__c = 'CNC',
            quantityordered__c = 2,
            revisionnum__c = 0,
            selectedpricetier__c = 'standard',
            sheetmetaltype__c = 'None',
            surfaceroughness__c = 0,
            surfaceroughness_finish__c = '016Ra',
            surfaceroughness_quantity__c = 0,
            tolerance_precision__c = 0.001,
            tolerance_quantity__c = 2,
            unique_ordered_part_id__c = '62a1405d3c75b6ada38326ad',
            unique_quoted_part_id__c = '6272e34496789bc79d1f7e9d',
            vendor_finishgroup__c = 'Standard',
            vendorfinish__c = 'Standard',
            xometry_order_id__c = '451CD-15018',
            xometry_quote_id__c = 'Q90-2978-2623',
            xometry_ordered_part_ID__c = '12322AB2',
            xometry_quoted_part_id__c = '0308E9F',
            name = '0308E9F'
        );
        orderedParts.add(partTwo);

        // Jobs
        List<Job__c> jobsList = new List<Job__C>();

        Job__c jobForChild = new Job__c(
            inspectionrequirement__c = 'cmm, std+r',
            jobmargin__c = 90.0,
            name = 'J009164A',
            outsourcepartnergroup__c = 'Ultra Premium',
            processes__c = 'CNC',
            riskfactor__c = 'High',
            stage__c = 'Accepted',
            duedate__c = OrderDueDateDT,
            accepteddatetime__c = AcceptedDT,
            acceptedpartnerid__c = 'P30939',
            xometryjobid__c = 'J009164A',
            acceptedprice__c = 1000.0,
            xometryopsorderid__c = '451CD-15018',
            orderduedate__c = OrderDueDateDT,
            quotetype__c = 'Manual',
            itar__c = true,
            shippingmethod__c = 'Ground',
            shippingservice__c = 'Fedex',
            gno_customerprice__c = 1000.0,
            madeinchina__c = false,
            repeatwork__c = false,
            isalum_mat__c = true,
            isstainlesssteel_mat__c = false,
            hasdelrinmat__c = false,
            hastitaniummat__c = false,
            ordered_part_ids_string__c = '62a1405d3c75b6ada38326ad',
            order_ids_string__c = '451CD-15018'
        );
        jobsList.add(jobForChild);

        Job__c jobForParent = new Job__c(
            inspectionrequirement__c = 'cmm, std+r',
            jobmargin__c = 90.0,
            name = 'J0091641',
            outsourcepartnergroup__c = 'Ultra Premium',
            processes__c = 'CNC',
            riskfactor__c = 'Medium',
            stage__c = 'Accepted',
            duedate__c = OrderDueDateDT,
            accepteddatetime__c = AcceptedDT,
            acceptedpartnerid__c = 'P30939',
            xometryjobid__c = 'J0091641',
            acceptedprice__c = 1000.0,
            xometryopsorderid__c = '451CD-1501F',
            orderduedate__c = OrderDueDateDT,
            quotetype__c = 'Manual',
            itar__c = true,
            shippingmethod__c = 'Ground',
            shippingservice__c = 'Fedex',
            gno_customerprice__c = 1000.0,
            madeinchina__c = false,
            repeatwork__c = false,
            isalum_mat__c = true,
            isstainlesssteel_mat__c = false,
            hasdelrinmat__c = false,
            hastitaniummat__c = false,
            ordered_part_ids_string__c = '62a1405d3c75b6ada38326ac',
            order_ids_string__c = '451CD-1501F'
        );

        jobsList.add(jobForParent);
        returnObjMap.put('order', ordersToInsert);
        returnObjMap.put('orderedPart', orderedParts);
        returnObjMap.put('job', jobsList);
        return returnObjMap;
    }

    public static Map<String, Order_ERP__C> createMissingEUDOrders(Integer numberOfOrders, boolean blnIsInsert) {
        Map<String, Order_ERP__C> returnOrderMap = new Map<String, Order_ERP__C>();
        Integer firstGroup = numberOfOrders / 3;
        Integer secondGroup = numberOfOrders / 3 + firstGroup;
        Integer thirdGroup = numberOfOrders / 3 + secondGroup;
        System.debug('firstGroup: ' + firstGroup + ' secondGroup: ' + secondGroup + ' thirdGroup: ' + thirdGroup);

        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(3, 'BDR', 1);
        Contact myretContact1 = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :retAccounts[0].Id
            ORDER BY Name
        ];
        Contact myretContact2 = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :retAccounts[1].Id
            ORDER BY Name
        ];
        Contact myretContact3 = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :retAccounts[2].Id
            ORDER BY Name
        ];
        List<Order_ERP__C> testOrders = new List<Order_ERP__C>();
        for (integer i = 0; i < numberOfOrders; i++) {
            Order_ERP__C ord = new Order_ERP__C();
            ord.Account_Domain__c = retAccounts[0].Email_Domain__c;
            ord.ERP_Company_Name__c = retAccounts[0].Name;
            ord.ERP_Contact_First_Name__c = myretContact1.FirstName;
            ord.ERP_Contact_Last_Name__c = myretContact1.LastName;
            ord.Order_Email__c = myretContact1.Email;
            ord.ERP_Contact__C = 'AAAAA';
            if (i >= firstGroup && i < secondGroup) {
                ord.Account_Domain__c = retAccounts[1].Email_Domain__c;
                ord.ERP_Company_Name__c = retAccounts[1].Name;
                ord.ERP_Contact_First_Name__c = myretContact2.FirstName;
                ord.ERP_Contact_Last_Name__c = myretContact2.LastName;
                ord.Order_Email__c = myretContact2.Email;
                ord.ERP_Contact__C = 'BBBBB';
            }
            if (i >= secondGroup && i < thirdGroup) {
                ord.Account_Domain__c = retAccounts[2].Email_Domain__c;
                ord.ERP_Company_Name__c = retAccounts[2].Name;
                ord.ERP_Contact_First_Name__c = myretContact3.FirstName;
                ord.ERP_Contact_Last_Name__c = myretContact3.LastName;
                ord.Order_Email__c = myretContact3.Email;
                ord.ERP_Contact__C = 'CCCCC';
            }
            ord.ERP_PartPk__c = '56564-55' + String.valueOf(i);
            ord.Is_Generic__c = false;
            ord.Order_Canceled_Flag__c = false;
            ord.Order_ERP_CreatedDate__c = date.newInstance(2022, 4, 15);
            ord.Order_ERP_Time__c = dateTime.newInstance(2022, 4, 15, 10, 0, 30);
            ord.Order_Subtotal__c = 4500.00;
            ord.Order_Total__c = 5000.50;
            ord.Payment_Type__c = 'credit_card';
            ord.Xometry_ERP_ID__c = 'BBBBB-34' + String.valueOf(i);
            ord.process_isPolyJet_3D__c = true;
            ord.EUD_MissingEndUseData__c = true;
            ord.EUD_HasCase__c = false;
            ord.EUD_ImportReason__c = true;
            ord.EUD_Industry__c = true;
            ord.EUD_HTSCode__c = true;
            ord.EUD_PartDescription__c = false;
            ord.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';
            testOrders.add(ord);
            returnOrderMap.put(ord.Xometry_ERP_ID__c, ord);
        }
        if (blnIsInsert) {
            insert testOrders;
        }
        return returnOrderMap;
    }

    public static Ordered_Part__c createOrderedPart(
        Boolean blnIsInsert,
        String partStatus,
        String opsOrderID,
        Boolean hasOpsOrder,
        Boolean blnOpsOrdIsInsert
    ) {
        if (hasOpsOrder) {
            Ops_Order__c opsOrder = new Ops_Order__c();
            opsOrder.XometryOpsOrderID__c = opsOrderID;
            if (blnOpsOrdIsInsert) {
                insert opsOrder;
            }
        }

        Ordered_Part__c part = new Ordered_Part__c();
        part.Unique_Ordered_Part_ID__c = '0123456789ABC';
        part.Xometry_Ordered_Part_ID__c = '00123AB9';
        part.Xometry_Order_ID__c = opsOrderID;
        part.CustomerPartID__c = '12345678';
        part.PartStatus__c = partStatus;
        if (blnIsInsert) {
            insert part;
        }

        return part;
    }

    /**
     * @description To create the components of the ideal path for Bad Outcomes
     */
    public static Map<String, List<SObject>> badOutcomesIdealPath() {
        Map<String, List<SObject>> returnObjMap = new Map<String, List<SObject>>();
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccountTop20 = retAccounts[0];
        Account myTestAccountNoTop20 = retAccounts[1];
        //Top 20 Customer Criteria
        myTestAccountTop20.Ops_Top_20_Customer__c = true;
        update myTestAccountTop20;

        // insert orders
        Order_ERP__c ord1 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord2 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord3 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord4 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord5 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord6 = TestDataFactory.createDefaultOrderERP(false);

        // Order event should be created for top 20, marked as initial
        // Order event should be bad outcomes
        ord1.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord1.processGroup_isMixed__c = true;
        ord1.Xometry_ERP_ID__c = '00000-00001';
        ord1.Bad_Outcomes_Highest_Probability__c = .5111;
        ord1.Bad_Outcomes_Manage_Result__c = 'Manage';
        ord1.Bad_Outcomes_Type__c = 'LATE';
        ord1.Bad_Outcomes_Daily_Tier__c = 'High';
        ord1.Xometry_Quote_ID__c = 'Q12-3333-4445';
        ord1.ERP_Status__c = 'Ordered';

        // Order event should be created for bad outcomes, marked as initial
        ord2.Account_Domain__c = myTestAccountNoTop20.Email_Domain__c;
        ord2.processGroup_isMixed__c = true;
        ord2.Xometry_ERP_ID__c = '00000-00002';
        ord2.Bad_Outcomes_Highest_Probability__c = .5111;
        ord2.Bad_Outcomes_Manage_Result__c = 'Manage';
        ord2.Bad_Outcomes_Type__c = 'LATE';
        ord2.Bad_Outcomes_Daily_Tier__c = 'Medium';
        ord2.Xometry_Quote_ID__c = 'Q12-3333-4446';
        ord2.ERP_Status__c = 'Ordered';

        // Order event should be created for top 20, marked as initial
        // Order event should be created for bad outcomes
        ord3.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord3.processGroup_isMixed__c = true;
        ord3.Xometry_ERP_ID__c = '00000-00003';
        ord3.Bad_Outcomes_Highest_Probability__c = .0111;
        ord3.Bad_Outcomes_Manage_Result__c = 'Do Not Manage';
        ord3.Bad_Outcomes_Type__c = 'LATE';
        ord3.Bad_Outcomes_Daily_Tier__c = 'Low';
        ord3.Xometry_Quote_ID__c = 'Q12-3333-4447';
        ord3.ERP_Status__c = 'Ordered';

        // Order event should be created for top 20
        // Ordered part below will change inital from top 20 to manufacturing process
        ord4.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord4.processGroup_isMixed__c = true;
        ord4.Xometry_ERP_ID__c = '00000-00004';
        ord4.Bad_Outcomes_Highest_Probability__c = null;
        ord4.Bad_Outcomes_Manage_Result__c = 'Daily Score Not Calculated Yet';
        ord4.Bad_Outcomes_Type__c = null;
        ord4.Bad_Outcomes_Daily_Tier__c = 'High';
        ord4.Xometry_Quote_ID__c = 'Q12-3333-4448';
        ord4.ERP_Status__c = 'Ordered';

        // Order should have Additive Only & Past Due Order Event
        ord5.Account_Domain__c = myTestAccountNoTop20.Email_Domain__c;
        ord5.OrderDueDate__c = Date.today() - 1;
        ord5.processGroup_isAdditiveOnly__c = true;
        ord5.Xometry_ERP_ID__c = '00000-00005';
        ord5.Xometry_Quote_ID__c = 'Q12-3333-4449';
        ord5.ERP_Status__c = 'Ordered';

        List<Order_Erp__C> ordersToInsertList = new List<Order_Erp__C>();
        ordersToInsertList.add(ord1);
        ordersToInsertList.add(ord2);
        ordersToInsertList.add(ord3);
        ordersToInsertList.add(ord4);
        ordersToInsertList.add(ord5);

        insert ordersToInsertList;
        returnObjMap.put('Order', ordersToInsertList);

        // insert orderedParts
        String xomOrderID = '00000-00004';
        String xomJobID = 'J0012345';

        // Should have orderedPart event with type expiered, Non-standard Expection, and Manufacturing Process
        // Should have order event with type offer expiered, Non-standard Expection, and Manufacturing Process
        // Currently will not have initial criteria of Manufacturing Process becuase it's from the ordered part
        Ordered_Part__c part = createOrderedPart(false, 'All Offers Expired', xomOrderID, true, false);
        part.Process__c = 'Die Casting';
        part.InspectionType__c = 'cust';
        part.CurrentJobID__c = xomJobID;

        insert part;
        returnObjMap.put('Part', new List<Ordered_Part__c>{ part });

        // insert jobs
        List<Job__c> insertList = createJobsWithSupplier(true);
        Event_Threshold__mdt additiveQualAmount = [
            SELECT ID, DeveloperName, Currency_Ref_Value__c
            FROM Event_Threshold__mdt
            WHERE DeveloperName = 'additiveJob_EventQualAmount'
        ];

        Job__c j = insertList[0];
        j.XometryJobID__c = xomJobID;

        j.Order_IDs_String__c = '00000-00004;00000-00005';
        j.XometryOpsOrderID__c = '00000-00004';
        // Should have job event created with New ECD
        // Should have job event created with Additive Only and over the Qualifying Amount
        j.EstimatedCompletionDate__c = date.newInstance(2022, 11, 11);
        j.processGroup_isAdditiveOnly__c = true;
        j.AcceptedPrice__c = additiveQualAmount.Currency_Ref_Value__c + 1;

        insert j;
        returnObjMap.put('Job', new List<Job__c>{ j });

        return returnObjMap;
    }

    /**
     * @description To create the components of the delayed path for Bad Outcomes
     */
    public static Map<String, List<SObject>> badOutcomesDelayPath() {
        Map<String, List<SObject>> returnObjMap = new Map<String, List<SObject>>();
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenericsTop20(2, 'BDR', 1);
        // top 20 acount generated with new method
        Account myTestAccountTop20 = retAccounts[0];
        Account myTestAccountNoTop20 = retAccounts[1];

        // insert orderedParts
        String xomOrderID = '00000-00004';
        String xomJobID = 'J0012345';

        // Should have orderedPart event with type expiered, Non-standard Expection, and Manufacturing Process
        // Should have order event with type offer expiered, Non-standard Expection, and Manufacturing Process
        // Currently will not have initial criteria of Manufacturing Process becuase it's from the ordered part
        Ordered_Part__c part = createOrderedPart(false, 'All Offers Expired', xomOrderID, true, false);
        part.Process__c = 'Die Casting';
        part.InspectionType__c = 'cust';
        part.CurrentJobID__c = xomJobID;

        insert part;
        returnObjMap.put('Part', new List<Ordered_Part__c>{ part });

        // insert jobs
        List<Job__c> insertList = createJobsWithSupplier(true);
        Event_Threshold__mdt additiveQualAmount = [
            SELECT ID, DeveloperName, Currency_Ref_Value__c
            FROM Event_Threshold__mdt
            WHERE DeveloperName = 'additiveJob_EventQualAmount'
        ];

        Job__c j = insertList[0];
        j.XometryJobID__c = xomJobID;

        j.Order_IDs_String__c = '00000-00004;00000-00005';
        j.XometryOpsOrderID__c = '00000-00004';
        // Should have job event created with New ECD
        // Should have job event created with Additive Only and over the Qualifying Amount
        j.EstimatedCompletionDate__c = date.newInstance(2022, 11, 11);
        j.processGroup_isAdditiveOnly__c = true;
        j.AcceptedPrice__c = additiveQualAmount.Currency_Ref_Value__c + 1;

        insert j;
        returnObjMap.put('Job', new List<Job__c>{ j });

        // insert orders
        Order_ERP__c ord1 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord2 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord3 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord4 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord5 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord6 = TestDataFactory.createDefaultOrderERP(false);

        // Order event should be created for top 20, marked as initial
        // Order event should be bad outcomes
        ord1.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord1.processGroup_isMixed__c = true;
        ord1.Xometry_ERP_ID__c = '00000-00001';
        ord1.Bad_Outcomes_Highest_Probability__c = .5111;
        ord1.Bad_Outcomes_Manage_Result__c = 'Manage';
        ord1.Bad_Outcomes_Type__c = 'LATE';
        ord1.Bad_Outcomes_Daily_Tier__c = 'High';
        ord1.Xometry_Quote_ID__c = 'Q12-3333-4445';
        ord1.ERP_Status__c = 'Ordered';

        // Order event should be created for bad outcomes, marked as initial
        ord2.Account_Domain__c = myTestAccountNoTop20.Email_Domain__c;
        ord2.processGroup_isMixed__c = true;
        ord2.Xometry_ERP_ID__c = '00000-00002';
        ord2.Bad_Outcomes_Highest_Probability__c = .5111;
        ord2.Bad_Outcomes_Manage_Result__c = 'Manage';
        ord2.Bad_Outcomes_Type__c = 'LATE';
        ord2.Bad_Outcomes_Daily_Tier__c = 'Medium';
        ord2.Xometry_Quote_ID__c = 'Q12-3333-4446';
        ord2.ERP_Status__c = 'Ordered';

        // Order event should be created for top 20, marked as initial
        // Order event should be created for bad outcomes
        ord3.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord3.processGroup_isMixed__c = true;
        ord3.Xometry_ERP_ID__c = '00000-00003';
        ord3.Bad_Outcomes_Highest_Probability__c = .0111;
        ord3.Bad_Outcomes_Manage_Result__c = 'Do Not Manage';
        ord3.Bad_Outcomes_Type__c = 'LATE';
        ord3.Bad_Outcomes_Daily_Tier__c = 'Low';
        ord3.Xometry_Quote_ID__c = 'Q12-3333-4447';
        ord3.ERP_Status__c = 'Ordered';

        // Order event should be created for top 20
        // Ordered part below will change inital from top 20 to manufacturing process
        ord4.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord4.processGroup_isMixed__c = true;
        ord4.Xometry_ERP_ID__c = '00000-00004';
        ord4.Bad_Outcomes_Highest_Probability__c = null;
        ord4.Bad_Outcomes_Manage_Result__c = 'Daily Score Not Calculated Yet';
        ord4.Bad_Outcomes_Type__c = null;
        ord4.Bad_Outcomes_Daily_Tier__c = 'High';
        ord4.Xometry_Quote_ID__c = 'Q12-3333-4448';
        ord4.ERP_Status__c = 'Ordered';

        // Order should have Additive Only & Past Due Order Event
        ord5.Account_Domain__c = myTestAccountNoTop20.Email_Domain__c;
        ord5.OrderDueDate__c = Date.today() - 1;
        ord5.processGroup_isAdditiveOnly__c = true;
        ord5.Xometry_ERP_ID__c = '00000-00005';
        ord5.Xometry_Quote_ID__c = 'Q12-3333-4449';
        ord5.ERP_Status__c = 'Ordered';

        List<Order_Erp__C> ordersToInsertList = new List<Order_Erp__C>();
        ordersToInsertList.add(ord1);
        ordersToInsertList.add(ord2);
        ordersToInsertList.add(ord3);
        ordersToInsertList.add(ord4);
        ordersToInsertList.add(ord5);

        insert ordersToInsertList;
        returnObjMap.put('Order', ordersToInsertList);

        return returnObjMap;
    }

    /**
     * @description To create the components of the delayed path for Bad Outcomes
     */
    public static Map<String, List<SObject>> badOutcomesNoOrderCriteriaPath() {
        Map<String, List<SObject>> returnObjMap = new Map<String, List<SObject>>();
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);

        // insert orderedParts
        String xomOrderID = '00000-00004';
        String xomJobID = 'J0012345';

        // Should create order event with type Non-Standard Inspection marked as initial criteria
        // should create order event with type expired
        Ordered_Part__c part = createOrderedPart(false, 'All Offers Expired', xomOrderID, true, false);
        part.Process__c = 'CNC';
        part.InspectionType__c = 'cust';
        part.CurrentJobID__c = xomJobID;

        insert part;
        returnObjMap.put('Part', new List<Ordered_Part__c>{ part });

        // insert jobs
        List<Job__c> insertList = createJobsWithSupplier(true);
        Event_Threshold__mdt additiveQualAmount = [
            SELECT ID, DeveloperName, Currency_Ref_Value__c
            FROM Event_Threshold__mdt
            WHERE DeveloperName = 'additiveJob_EventQualAmount'
        ];

        Job__c j = insertList[0];
        j.XometryJobID__c = xomJobID;

        j.Order_IDs_String__c = '00000-00004;00000-00005';
        j.XometryOpsOrderID__c = '00000-00004';
        // for both orders in Order_IDs_String
        // Should have job event created with New ECD
        // Should have job event created with Additive Only and over the Qualifying Amount
        // initial criteres should be ECD for 00000-00005
        j.EstimatedCompletionDate__c = date.newInstance(2022, 11, 11);
        j.processGroup_isAdditiveOnly__c = true;
        j.AcceptedPrice__c = additiveQualAmount.Currency_Ref_Value__c + 1;

        insert j;
        returnObjMap.put('Job', new List<Job__c>{ j });

        // insert orders
        Order_ERP__c ord1 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord2 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord3 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord4 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord5 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord6 = TestDataFactory.createDefaultOrderERP(false);

        ord1.Account_Domain__c = retAccounts[0].Email_Domain__c;
        ord1.processGroup_isMixed__c = true;
        ord1.Xometry_ERP_ID__c = '00000-00001';
        ord1.Bad_Outcomes_Highest_Probability__c = .5111;
        ord1.Bad_Outcomes_Manage_Result__c = 'Manage';
        ord1.Bad_Outcomes_Type__c = 'LATE';
        ord1.Bad_Outcomes_Daily_Tier__c = 'High';
        ord1.Xometry_Quote_ID__c = 'Q12-3333-4445';
        ord1.ERP_Status__c = 'Ordered';

        ord2.Account_Domain__c = retAccounts[1].Email_Domain__c;
        ord2.processGroup_isMixed__c = true;
        ord2.Xometry_ERP_ID__c = '00000-00002';
        ord2.Xometry_Quote_ID__c = 'Q12-3333-4446';
        ord2.ERP_Status__c = 'Ordered';

        ord3.Account_Domain__c = retAccounts[0].Email_Domain__c;
        ord3.processGroup_isMixed__c = true;
        ord3.Xometry_ERP_ID__c = '00000-00003';
        ord3.Xometry_Quote_ID__c = 'Q12-3333-4447';
        ord3.ERP_Status__c = 'Ordered';

        ord4.Account_Domain__c = retAccounts[0].Email_Domain__c;
        ord4.processGroup_isMixed__c = true;
        ord4.Xometry_ERP_ID__c = '00000-00004';
        ord4.Xometry_Quote_ID__c = 'Q12-3333-4448';
        ord4.ERP_Status__c = 'Ordered';

        ord5.Account_Domain__c = retAccounts[1].Email_Domain__c;
        ord5.OrderDueDate__c = Date.today() + 3;
        ord5.processGroup_isAdditiveOnly__c = true;
        ord5.Xometry_ERP_ID__c = '00000-00005';
        ord5.Xometry_Quote_ID__c = 'Q12-3333-4449';
        ord5.ERP_Status__c = 'Ordered';

        List<Order_Erp__C> ordersToInsertList = new List<Order_Erp__C>();
        ordersToInsertList.add(ord1);
        ordersToInsertList.add(ord2);
        ordersToInsertList.add(ord3);
        ordersToInsertList.add(ord4);
        ordersToInsertList.add(ord5);

        insert ordersToInsertList;
        returnObjMap.put('Order', ordersToInsertList);

        return returnObjMap;
    }
}