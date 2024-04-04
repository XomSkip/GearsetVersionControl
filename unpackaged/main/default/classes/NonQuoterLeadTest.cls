@isTest
private class NonQuoterLeadTest {
    @isTest
    static void existingDomainLeadTest() {
        /* 
        The purpose of this test is for non Quoter Non Generic Leads to Be assigned to existing Domain
        */
        boolean leadDomainMatchFlag = ApexBypassUtility.shouldRun('Lead_DomainMatching_Lead');
        if (leadDomainMatchFlag == true) {
            List<Account> testAccountList = testDataFactory.createTestAccountNonGenerics(2, 'BDR', 2);

            Account testAccount = testAccountList[0];

            ID testAccountID = testAccount.ID;
            String testDomain = testAccount.email_Domain__c;
            System.debug('The testdomain is : ' + testDomain);
            Account retTestAccount = [SELECT Owner.Name, Email_Domain__C FROM Account WHERE ID = :testAccountID];
            System.debug('The testing email domain is : ' + testDomain);
            Lead testLead = new Lead();
            testLead.company = testAccount.name;
            testLead.email = 'AbraKadabara01@' + testDomain;
            testLead.lastname = 'Kadabara';
            testLead.firstname = 'FirstName';
            testLead.LeadSource = '	Trade Show';
            testLead.RR_Flag__c = true;
            testLead.Generic_FLAG__c = false;
            test.startTest();
            System.debug('Abbout to start Lead Insert');
            insert testLead;
            test.stopTest();
            Lead retLead = [SELECT Owner.Name, email_Domain__c, RR_Stamp_OwnerID__c FROM Lead WHERE ID = :testLead.ID];
            System.debug('Ther retlead is : ' + retLead);
            System.assertEquals(retTestAccount.Owner.Name, retLead.Owner.Name, 'The owners are not equal');
            String lowAcctEmailDomain = retTestAccount.Email_Domain__c.toLowerCase();
            String lowLeadEmailDomain = retLead.Email_Domain__C.toLowerCase();
            System.assertEquals(lowAcctEmailDomain, lowLeadEmailDomain, 'The owners are not equal');
        }
    }

    @isTest
    static void sameDomainSameOwnerTest() {
        boolean leadDomainMatchFlag = ApexBypassUtility.shouldRun('Lead_DomainMatching_Lead');
        if (leadDomainMatchFlag == true) {
            List<User> testUserList = TestDataFactory.createTestUsers2();
            List<Lead> testLeadList = new List<Lead>();
            lead testLead1 = new Lead();
            testLead1.company = 'alveo';
            testLead1.email = 'JaneDoe@alveotechnologies.com';
            testLead1.lastname = 'Doe';
            testLead1.firstname = 'Jane';
            testLead1.LeadSource = '	Trade Show';
            testLead1.RR_Flag__c = true;
            testLead1.Generic_FLAG__c = false;
            lead testLead2 = new Lead();
            testLead2.company = 'Microsoft';
            testLead2.email = 'JaneDoe3@microsoft.com';
            testLead2.lastname = 'Doe3';
            testLead2.firstname = 'Jane';
            testLead2.LeadSource = '	Trade Show';
            testLead2.RR_Flag__c = true;
            testLead2.Generic_FLAG__c = false;
            lead testLead3 = new Lead();
            testLead3.company = 'alveo';
            testLead3.email = 'JaneDoe2@alVeotechnologies.com';
            testLead3.lastname = 'Doe2';
            testLead3.firstname = 'Jane';
            testLead3.LeadSource = '	Trade Show';
            testLead3.RR_Flag__c = true;
            testLead3.Generic_FLAG__c = false;
            lead testLead4 = new Lead();
            testLead4.company = 'Bananas';
            testLead4.email = 'JaneDoe50@sharkLASERS.com';
            testLead4.lastname = 'Doe50';
            testLead4.firstname = 'Jane';
            testLead4.LeadSource = '	Trade Show';
            testLead4.RR_Flag__c = true;
            testLead4.Generic_FLAG__c = false;
            testLeadList.add(testLead1);
            testLeadList.add(testLead2);
            testLeadList.add(testLead3);
            testLeadList.add(testLead4);
            Test.startTest();
            insert testLeadList;
            Test.stopTest();
            //Check that sharksLasers belongs to the queue
            Lead testLaserLead = [
                SELECT OwnerID, Owner.Name, RR_Flag__c, Domain_Match_Flag__C
                FROM Lead
                WHERE email = 'JaneDoe50@sharkLASERS.com'
            ];
            Lead testAlveo1 = [
                SELECT ID, Email, OwnerID, Owner.Name, RR_Batch_Num__C, RR_Batch_Num_Match_Group__C
                FROM Lead
                WHERE email = :testLead1.email
            ];
            System.debug(
                'The owner name of the first Alveo is : ' +
                testAlveo1.Owner.Name +
                ' : Email is : ' +
                testAlveo1.email +
                ' RR_Batch_Num__C:' +
                testAlveo1.RR_Batch_Num__C +
                ' RR_Batch_Num_Match_Group : ' +
                testAlveo1.RR_Batch_Num_Match_Group__C
            );
            Lead testAlveo2 = [
                SELECT ID, Email, OwnerID, Owner.Name, RR_Batch_Num__C, RR_Batch_Num_Match_Group__C
                FROM Lead
                WHERE email = :testLead2.email
            ];
            System.debug(
                'The owner name of the first Alveo is : ' +
                testAlveo2.Owner.Name +
                ' : Email is : ' +
                testAlveo2.email +
                ' RR_Batch_Num__C:' +
                testAlveo2.RR_Batch_Num__C +
                ' RR_Batch_Num_Match_Group : ' +
                testAlveo2.RR_Batch_Num_Match_Group__C
            );
            Lead testAlveo3 = [
                SELECT ID, Email, OwnerID, Owner.Name, RR_Batch_Num__C, RR_Batch_Num_Match_Group__C
                FROM Lead
                WHERE email = :testLead3.email
            ];
            System.debug(
                'The owner name of the first Alveo is : ' +
                testAlveo3.Owner.Name +
                ' : Email is : ' +
                testAlveo3.email +
                ' RR_Batch_Num__C:' +
                testAlveo3.RR_Batch_Num__C +
                ' RR_Batch_Num_Match_Group : ' +
                testAlveo3.RR_Batch_Num_Match_Group__C
            );
            System.debug(
                'The owner is ' +
                testLaserLead.Owner.Name +
                ' : the OwnerId is : ' +
                testLaserLead.OwnerID +
                ' : Domain_Match_Flag__C ' +
                testLaserLead.Domain_Match_Flag__C +
                ' : RR_Flag__C ' +
                testLaserLead.RR_Flag__c
            );
            System.assertEquals(
                testAlveo1.RR_Batch_Num__C,
                testAlveo3.RR_Batch_Num__C,
                'The Batch Number were not equal'
            );
            System.assertNotEquals(
                testAlveo1.RR_Batch_Num_Match_Group__C,
                testAlveo3.RR_Batch_Num_Match_Group__C,
                'The Batch numbers were equal'
            );
        }
    }
}