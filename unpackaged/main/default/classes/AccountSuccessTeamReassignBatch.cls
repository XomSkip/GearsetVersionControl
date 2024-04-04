global class AccountSuccessTeamReassignBatch implements Database.Batchable<sObject> {

    global User objSuccessTeamUser = [SELECT Id FROM User WHERE Name = 'Success Team'];

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id
                FROM Account
                WHERE 
                    ParentId = null AND 
                    Success_Team__c = TRUE AND 
                    OwnerId !=: objSuccessTeamUser.Id
            ]
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> accountList) {
        Map<String, Account> mapAccountReassing = new Map<String,Account>(accountList);
        Set<String> setAccountId = mapAccountReassing.keySet();
        Date dtSevenDaysAgo = System.today().addDays(-7);

        List<Project__c> lstProjects = [SELECT Top_Account_Id__c 
                                        FROM Project__c 
                                        WHERE   
                                            Top_Account_Id__c IN: setAccountId AND        
                                            (
                                                Stage__c IN ('Pending Payment') OR
                                                (
                                                    (NOT Stage__c IN ('Closed Won', 'Closed Lost', 'Pending Payment')) AND 
                                                    (
                                                        Primary_Contact_Last_Activity_Date_AM__c >=: dtSevenDaysAgo OR
                                                        Primary_Contact_Next_Activity_Date_AM__c >=: System.Today() OR
                                                        CreatedDate >=: dtSevenDaysAgo
                                                    )
                                                )
                                            )                                                   
                                        ];
        
        for(Project__c objProject : lstProjects)
        {
            mapAccountReassing.remove(objProject.Top_Account_Id__c);
        }
        
        for(Account objAccount : mapAccountReassing.values())
        {
            System.debug('objAccount.Id ::: '+objAccount.Id);
            objAccount.Batch_Reassign__c = objSuccessTeamUser.Id;
        }

        DatabaseUtilities.saveToDatabase(mapAccountReassing.values(), 'AccountSuccessTeamReassignBatch.execute', 'Reassign accounts to Success Team User');
    }

    global void finish(Database.BatchableContext bc) {
    }
}