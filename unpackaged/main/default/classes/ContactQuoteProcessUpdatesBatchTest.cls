@isTest
private class ContactQuoteProcessUpdatesBatchTest {

    @isTest
    static void ExecuteTest() {
        
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        Contact myretContact = [
            SELECT ID, FirstName, OwnerID, LastName, Email, has_quoted_CNC_Machining__c
            FROM Contact
            WHERE AccountID = :retAccounts[0].ID
            ORDER BY Name
        ];

        Quote_ERP__c myQuote = TestDataFactory.createQuote(
            false,
            myTestAccount.Email_Domain__c,
            myretContact.FirstName,
            myretContact.LastName,
            myretContact.email
        );
        //BDR Opps for Days
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.IS_Generic__c = false;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 8, 28);
        myQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 8, 28, 4, 5, 50);
        myQuote.ContactID__C = myretContact.Id;
        myQuote.process_isUrethane_Casting__c = false;
        myQuote.process_isCarbon__c = true;
        myQuote.process_isCNC_Machining__c = true;
        myQuote.process_isDie_Casting__c = true;
        myQuote.process_isDMLS__c = true;
        myQuote.process_isDirect_Sourced__c = true;
        myQuote.process_isExtrusion__c = true;

        Quote_ERP__c myQuote2 = myQuote.clone();
        myQuote2.Xometry_ERP_ID__C = 'Q12-3333-4445';
        myQuote2.process_isFDM__c = true;
        myQuote2.process_isHPMultJetFusion__c = true;
        myQuote2.process_isInjection_Molding__c = true;
        myQuote2.process_isPolyJet_3D__c = true;
        myQuote2.process_isSLS__c = true;
        myQuote2.process_isSheet_metal__c = true;
        myQuote2.process_isStamping__c = true;
        myQuote2.process_isSLA__c = true;
        myQuote2.process_isUrethane_Casting__c = true;
        myQuote2.process_isBinderJetting__c = true;
        myQuote2.process_isSheetCutting__c = true;
        myQuote2.process_isTubeBending__c = true;
        myQuote2.process_isTubeCutting__c = true;
        myQuote2.process_isPlasticExtrusion__c = true;
        myQuote2.process_isOther__c = true;
        myQuote2.process_isOther_NotIncluded__c = true;
        myQuote2.process_isLSPc__c = true;
        myQuote2.process_isAssembly__c = true;
        myQuote2.ContactID__C = myretContact.Id;
        insert new List<Quote_ERP__c>{myQuote,myQuote2};

        
        Contact contactTest = [SELECT has_quoted_CNC_Machining__c,has_quoted_Carbon__c FROM Contact WHERE Id = :myretContact.Id];
        Assert.areEqual(false, contactTest.has_quoted_CNC_Machining__c, 'the default field should be false');
        Assert.areEqual(false, contactTest.has_quoted_Carbon__c, 'the default field should be false');

        Test.startTest();

        Database.executeBatch(new ContactQuoteProcessUpdatesBatch());

        Test.stopTest();

        Contact contactTestResult = [SELECT has_quoted_CNC_Machining__c,has_quoted_Carbon__c FROM Contact WHERE Id = :myretContact.Id];
        Assert.areEqual(true, contactTestResult.has_quoted_CNC_Machining__c, 'Contact should be updated');
        Assert.areEqual(true, contactTestResult.has_quoted_Carbon__c, 'Contact should be updated');

    }

    @isTest
    public static void SchedulerTest() {

        //once each 6 hour
        String CRON_EXP = '0 0 */6 * * ? *';

        Test.startTest();
        String jobID = System.schedule(
            'ContactQuoteProcessUpdatesSchedulerTest',
            CRON_EXP,
            new ContactQuoteProcessUpdatesScheduler()
        );
        Test.stopTest();

        Assert.areNotEqual(null, jobID, 'Job id is not null');
    }

}