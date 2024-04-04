@isTest
public class LeadConverterTest {
    @isTest
    static void leadConvertTest1() {
        //Test Two Quotes. Convert the Lead and Confirm Opportunity has Primary Contact
        //Confirm both Quotes have account/Contact assigned
        List<Quote_ERP__C> newQuotes = TestDataFactory.createTestQuotesToLeads(1, 2);
        Set<ID> newQuoteIDSet = new Set<ID>();
        for (Quote_ERP__C q : newQuotes) {
            newQuoteIDSet.add(q.ID);
        }
        List<Quote_ERP__C> quoteLeadInfo = [SELECT ID, LeadID__C FROM Quote_ERP__C WHERE ID IN :newQuoteIDSet];
        Set<ID> leadIDSet = new Set<ID>();

        Quote_ERP__C convertQuoteEx = newQuotes[0];
        //Create an Order
        Order_ERP__C ord = TestDataFactory.createOrderERPFromQuote(false, convertQuoteEx);

        ord.Order_Canceled_Flag__c = false;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.process_isDMLS__c = true;
        Test.startTest();
        insert ord;
        Test.stopTest();
    }
}