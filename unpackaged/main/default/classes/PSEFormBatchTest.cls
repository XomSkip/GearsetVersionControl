@isTest
public class PSEFormBatchTest {
    @TestSetup
    private static void setup() {
        Quote_ERP__c quote = new Quote_ERP__C(
            Account_Domain__C = 'SuperCompany2.com',
            ERP_PartPK__c = 'A1234-A5678',
            Quote_Price__c = 50.15,
            Xometry_ERP_ID__C = 'AAAAA-00001',
            ERP_Contact__c = 'AAAAA',
            IS_Generic__c = false,
            Quote_Email__c = 'johndoe@SuperCompany2.com',
            Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14),
            ERP_Contact_Last_Name__c = 'Doe',
            Requested_Manual_Quote_Flag__c = true,
            Requested_Manual_Quote_Time__C = dateTime.newInstanceGMT(2021, 7, 21, 0, 0, 0)
        );

        PSE_Form__c pse_withFutureQuote = new PSE_Form__c(Quote_ID__c = 'AAAAA-00001');
        PSE_Form__c pse_noQuote = new PSE_Form__c(Quote_ID__c = 'AAAAA-00002');
        PSE_Form__c pse_nullQuote = new PSE_Form__c(Quote_ID__c = null);

        insert pse_withFutureQuote;
        insert pse_noQuote;
        insert pse_nullQuote;

        insert quote;
    }

    @isTest
    static void PSEFormBatchTest() {
        Test.startTest();
        PSEFormBatch batch = new PSEFormBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<PSE_Form__c> pseForms = [
            SELECT Id, Quote_ERP__c, Quote_ID__c, Case__c
            FROM PSE_Form__c
            ORDER BY Quote_ID__c NULLS LAST
        ];

        List<Case> resultCase = [
            SELECT Id, PSE_Form__c, Opportunity__r.Last_Quote_Xometry_ERP_ID__c
            FROM Case
            WHERE Opportunity__r.Last_Quote_Xometry_ERP_ID__c = :pseForms[0].Quote_ID__c
        ];

        // future form match
        System.assertEquals('AAAAA-00001', pseForms[0].Quote_ID__c, 'Quote Id does not match');
        System.assertNotEquals(null, pseForms[0].Quote_ERP__c, 'Quote lookup should not be null');

        // future form case match
        System.assertEquals(1, resultCase.size(), 'There should only be one created Case');
        System.assertNotEquals(null, resultCase[0].PSE_Form__c, 'Lookup should not be null');
        System.assertEquals(
            pseForms[0].Id,
            resultCase[0].PSE_Form__c,
            'Form Lookup should match Form with matching id'
        );
        System.assertEquals(
            resultCase[0].Id,
            pseForms[0].Case__c,
            'Case Lookup should match Case with matching id'
        );

        // no quote no match

        System.assertEquals('AAAAA-00002', pseForms[1].Quote_ID__c, 'Quote Id does not match');
        System.assertEquals(null, pseForms[1].Quote_ERP__c, 'Quote Id should be set to null');

        // null quote no match
        System.assertEquals(null, pseForms[2].Quote_ID__c, 'Quote Id does not match');
        System.assertEquals(null, pseForms[2].Quote_ERP__c, 'Quote Id should be set to null');
    }
}