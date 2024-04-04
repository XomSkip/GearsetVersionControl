@isTest
public class quoteToOppHelperTest {
    @isTest
    static void quoteToOppCreationTest() {
        //Create an Account AM
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        List<Contact> myContactList = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccountID
        ];
        Contact testContact = myContactList[0];

        //Create an Order on a Contact
        Order_ERP__C testOrder = TestDataFactory.createDefaultOrderERP(false);
        testOrder.Account_Domain__c = testAccount.Email_Domain__C;
        testOrder.ERP_Company_Name__C = testAccount.Name;
        testOrder.ERP_Contact_First_Name__c = testContact.FirstName;
        testOrder.ERP_Contact_Last_Name__c = testContact.LastName;
        testOrder.Order_ERP_CreatedDate__c = date.newInstance(2021, 12, 2);
        testOrder.Order_ERP_Time__c = dateTime.newInstance(2021, 12, 2, 10, 0, 0);
        testOrder.Order_Email__c = testContact.Email;
        testOrder.process_isCNC_Machining__c = true;
        insert testOrder;

        Quote_ERP__C testQuote = new Quote_ERP__C();
        testQuote.Account_Domain__C = testAccount.Email_Domain__C;
        testQuote.ERP_PartPK__c = 'A1234-A5678';
        testQuote.Quote_Price__c = 1;
        testQuote.Xometry_ERP_ID__C = 'Q12-3333-5555';
        testQuote.ERP_Contact__c = 'BBBBB';
        testQuote.IS_Generic__c = false;
        testQuote.Quote_Email__c = testContact.Email;
        testQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 12, 2);
        //Create a quote for less than $250 CNC
        insert testQuote;

        ID testQuoteID = testQuote.ID;
        Test.StartTest();
        Quote_ERP__C insertedQuote = [SELECT ID, OpportunityID__C FROM Quote_ERP__C WHERE ID = :testQuoteID];
        boolean beforeApexOpp;
        if (String.isblank(insertedQuote.OpportunityID__C)) {
            beforeApexOpp = false;
        } else {
            beforeApexOpp = true;
        }
        System.assertEquals(true, beforeApexOpp, 'The Quote has an Opportunity!');
        quoteToOppHelper.createOppFromQuoteSubmit(testQuoteID);
        Test.StopTest();
        //Confirm no OpportunityID
        Quote_ERP__C afterApexQuote = [SELECT ID, OpportunityID__C FROM Quote_ERP__C WHERE ID = :testQuoteID];
        boolean newOppQuote;
        if (!String.isblank(afterApexQuote.OpportunityID__C)) {
            newOppQuote = true;
        }
        System.debug('Here is the OpportunityID : ' + afterApexQuote.OpportunityID__C);
        System.assertEquals(newOppQuote, true);
        //Call Apex
        // Confirm Quote now has an OpportunityID
    }
}