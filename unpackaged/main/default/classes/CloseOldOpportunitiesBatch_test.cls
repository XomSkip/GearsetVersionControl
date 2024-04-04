@isTest
private class CloseOldOpportunitiesBatch_test {
    
    @isTest
    private static void closeOpportunity() {
        Id rtOppSupplies = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Supplies').getRecordTypeId();

        Account testAccount = new Account(Name = 'Test', Email_Domain__c = 'Test@test.com');
        insert testAccount;
        
        Contact testContact = new Contact(FirstName ='Contact', LastName ='Test', Email = 'TestContact@test.com', Phone = '123456789', MobilePhone = '987654321', AccountId = testAccount.Id);
        insert testContact;
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            Primary_Contact__c = testContact.Id,
            StageName = 'New',
            CloseDate = System.Today().addDays(15),
            RecordTypeId = rtOppSupplies
        );
        insert testOpportunity;

        Datetime oldDate = Datetime.now().addDays(-61);
        Test.setCreatedDate(testOpportunity.Id, oldDate);

        Opportunity testOpportunity2 = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id, 
            Primary_Contact__c = testContact.Id, 
            StageName = 'New', 
            CloseDate = System.Today().addDays(15),
            RecordTypeId = rtOppSupplies
        );
        insert testOpportunity2;

        Datetime oldDate2 = Datetime.now().addDays(-59);
        Test.setCreatedDate(testOpportunity2.Id, oldDate2);

        List<Opportunity> lstNewOpportunities = [SELECT Id FROM Opportunity WHERE StageName = 'New'];
        System.assertEquals(2, lstNewOpportunities.size(), 'There should be 2 opportunities with Stage new');

        Test.startTest();
            Database.executeBatch(new CloseOldOpportunitiesBatch());
        Test.stopTest();

        List<Opportunity> lstNewOppAfterBatch = [SELECT Id FROM Opportunity WHERE StageName = 'New'];
        System.assertEquals(1, lstNewOppAfterBatch.size(), 'There should be only 1 oppotunity with Stage Open');

        List<Opportunity> lstCloseOppAfterBatch = [SELECT Id FROM Opportunity WHERE IsClosed = true];
        System.assertEquals(1, lstCloseOppAfterBatch.size(), 'There should be only 1 oppotunity closed ');
        System.assertEquals(testOpportunity.Id, lstCloseOppAfterBatch[0].Id, 'The wrong opportunity is being closed');
    }
}