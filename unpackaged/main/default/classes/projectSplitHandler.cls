public with sharing class projectSplitHandler {
    @AuraEnabled(cacheable=true)
    public static List<Project__c> getOpenProjects(String projectID){

        // List <Project__c> projectPrimaryContact = [
        //     SELECT Primary_Contact__C
        //     FROM Project__c
        //     WHERE Id = :projectID
        // ];

        // return [
        //     SELECT Id, Project__c, Primary_Contact__c
        //     FROM Project__c
        //     WHERE Stage__C='Open' and Primary_Contact__c= :projectPrimaryContact

        // ];

        throw new AuraHandledException('Forced error');
    }
}