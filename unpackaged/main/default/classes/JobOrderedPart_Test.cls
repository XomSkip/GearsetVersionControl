@isTest
public with sharing class JobOrderedPart_Test {
    @isTest
    static void renameOnCreateTest() {
        Job__c j = new Job__c();
        j.Name = 'J321034';
        j.XometryJobID__c = 'J321034';
        j.Stage__c = 'Accepted';
        j.ORDERED_PART_Ids_String__c = 'AAABBBCCaeidhgt';

        Test.startTest();
        insert j;
        Test.stopTest();

        JobOrderedPart__c jopRes = [SELECT Id, Name FROM JobOrderedPart__c][0];
        String uKey = j.XometryJobId__c + ' : AAABBBCCaeidhgt';
        System.assertEquals(uKey, jopRes.Name, 'name should be the unique key');
    }
}