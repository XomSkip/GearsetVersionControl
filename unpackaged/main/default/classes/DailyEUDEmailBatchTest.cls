@isTest
public with sharing class DailyEUDEmailBatchTest {
    @isTest
    public static void emailEUDWithNoReachOut() {
        String orderId = '12345-12345';
        Group eudGroup = [SELECT ID FROM Group WHERE DeveloperName = 'EUD_Queue'][0];
        List<Case> eudCaseList = new List<Case>();
        Case eudCase = new Case();
        eudCase.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        eudCase.OwnerId = eudGroup.Id;
        eudCase.Subject = orderId + ' Missing End Use Data';
        eudCase.OrderID__c = orderId;
        eudCase.ShadowXometryOrderID__c = orderId;
        eudCase.Shadow_Xometry_ERP_ID__c = 'Q12-3424-1244';
        eudCase.SuppliedEmail = 'email@test.com';
        eudCase.Origin = 'Internal';
        eudCase.Category__c = 'End-use definition';
        eudCase.EUD_MissingEndUseData__c = true;
        eudCase.EUD_HTSCode__c = true;
        eudCase.EUD_ImportReason__c = true;
        eudCase.EUD_Industry__c = true;
        eudCase.EUD_PartDescription__c = false;
        eudCase.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';
        eudCase.EUD_Work_Stage__c = 'No Reach Out Yet';
        eudCase.Category__c = 'End-use definition';
        eudCase.Status = 'Open';
        eudCaseList.add(eudCase);

        String orderId2 = '23456-23456';
        Case eudCase2 = new Case();
        eudCase2.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        eudCase2.OwnerId = eudGroup.Id;
        eudCase2.Subject = orderId2 + ' Missing End Use Data';
        eudCase2.OrderID__c = orderId2;
        eudCase2.ShadowXometryOrderID__c = orderId2;
        eudCase2.Shadow_Xometry_ERP_ID__c = 'Q12-4246-1246';
        eudCase2.SuppliedEmail = 'email@test.com';
        eudCase2.Origin = 'Internal';
        eudCase2.Category__c = 'End-use definition';
        eudCase2.EUD_MissingEndUseData__c = true;
        eudCase2.EUD_HTSCode__c = true;
        eudCase2.EUD_ImportReason__c = true;
        eudCase2.EUD_Industry__c = true;
        eudCase2.EUD_PartDescription__c = false;
        eudCase2.EUD_LineItemBreakdown__c = '02E3CD3: HTS Code';
        eudCase2.EUD_Work_Stage__c = 'No Reach Out Yet';
        eudCase2.Category__c = 'End-use definition';
        eudCase2.Status = 'Open';
        eudCase2.EUD_Email_Count__c = 2;
        eudCaseList.add(eudCase2);

        insert eudCaseList;

        Test.startTest();
        DailyEUDEmailBatch batch = new DailyEUDEmailBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Case> caseResults = [SELECT Id, EUD_Work_Stage__c, EUD_Email_Count__c, ShadowXometryOrderID__c FROM Case];
        for (Case c : caseResults) {
            if (c.ShadowXometryOrderID__c == orderId) {
                System.assertEquals('1st Attempt Sent', c.EUD_Work_Stage__c, 'EUD Work Stage was not updated');
                System.assertEquals(1, c.EUD_Email_Count__c, 'count should be increased');
            }
            if (c.ShadowXometryOrderID__c == orderId2) {
                System.assertEquals(2, c.EUD_Email_Count__c, 'count should have stayed the same');
            }
        }
    }
}