public with sharing class accountTeamHandler {
    /**
     * @description Sets a Unique Key that will be validate by SF at transaction commit based on a combination of fields
     * This is an alternative way to create a unique index since SF does not have that functionality
     * @param newAcctTeamList a list of Account_Team records to be inserted/updated
     */
    public static void setUK(List<Account_Team__C> newAcctTeamList) {
        for (Account_Team__C aTeam : newAcctTeamList) {
            aTeam.Unique_Key__c = aTeam.Account__C + '-' + aTeam.Team_Member__c + '-' + aTeam.Team_Role__c;
        }
    }
    /**
     * @description For any CSAMs being added confirm that a CSAM does not already exist on the Account_Team__c
     * @param newAcctTeamList a list of Account_Team records to be inserted/updated
     */
    public static void acctTeamValidation(List<Account_Team__C> newAcctTeamList) {
        SET<ID> accountIDSet = new Set<ID>();
        SET<ID> accountTeamIDset = new Set<ID>();
        for (Account_Team__c aTeam : newAcctTeamList) {
            if (!String.isblank(aTeam.Account__C)) {
                accountIDSet.add(aTeam.Account__C);
            }
            if (Trigger.isUpdate) {
                accountTeamIDset.add(aTeam.ID);
            }
        }
        List<Account_Team__c> validateUniqueMemberRoleList = new List<Account_Team__c>();
        if (!accountIDSet.isEmpty()) {
            if (Trigger.isInsert) {
                validateUniqueMemberRoleList = [
                    SELECT ID, Account__c, Team_Member__c, Team_Role__c
                    FROM Account_Team__c
                    WHERE Account__c IN :accountIDSet AND IsDeleted = FALSE
                ];
            }
            //if The Trigger is an Update then exclude the edited record from violating itself as a duplicate
            if (Trigger.isUpdate) {
                validateUniqueMemberRoleList = [
                    SELECT ID, Account__c, Team_Member__c, Team_Role__c
                    FROM Account_Team__c
                    WHERE Account__c IN :accountIDSet AND IsDeleted = FALSE AND ID NOT IN :accountTeamIDset
                ];
            }
        }

        Map<ID, List<Account_Team__c>> accountToTeamMemberMap = new Map<ID, List<Account_Team__c>>();
        Map<Id, Account_Team__c> AcctIDCSAMTeamMap = new Map<Id, Account_Team__c>();
        for (Account_Team__c aTeam : validateUniqueMemberRoleList) {
            if (accountToTeamMemberMap.containsKey(aTeam.Account__c)) {
                List<Account_Team__c> myAccountTeamList = accountToTeamMemberMap.get(aTeam.Account__C);
                myAccountTeamList.add(aTeam);
                accountToTeamMemberMap.put(aTeam.Account__C, myAccountTeamList);
            } else {
                List<Account_Team__c> myAccountTeamList = new List<Account_Team__c>();
                myAccountTeamList.add(aTeam);
                accountToTeamMemberMap.put(aTeam.Account__C, myAccountTeamList);
            }
            if (aTeam.Team_Role__c == AppConstants.CSAM_NAME)
                AcctIDCSAMTeamMap.put(aTeam.Account__c, aTeam);
        }
        //Stop mulitple CSAMS on the same account on the same insert
        Set<Id> accountHasCsamSet = new Set<Id>();

        for (Account_Team__c aTeam : newAcctTeamList) {
            if (aTeam.Team_Role__c == AppConstants.CSAM_NAME) {
                if (accountHasCsamSet.contains(aTeam.Account__c)) {
                    aTeam.addError('Cannot have more then one CSAM per Account');
                } else {
                    accountHasCsamSet.add(aTeam.Account__c);
                }
            }
            //if no record exists for the Account. No need to check anything.
            if (accountToTeamMemberMap.containsKey(aTeam.Account__c)) {
                List<Account_Team__c> currentAccountTeamList = accountToTeamMemberMap.get(aTeam.Account__c);
                //Unique index check do not allow a duplicate of the same Account,User,Role, Ignoring Division at this time
                for (Account_Team__c existingATeamURow : currentAccountTeamList) {
                    if (
                        aTeam.Team_Member__c == existingATeamURow.Team_Member__c &&
                        aTeam.Team_Role__c == existingATeamURow.Team_Role__c
                    ) {
                        aTeam.addError('This exact Account Team configuration already exists. No duplicates allowed');
                    }
                }
                //Adding a new CSAM to Account and the CSAM already exists then throw an error.
                if (aTeam.Team_Role__c == AppConstants.CSAM_NAME) {
                    //Extra check that if you are updating current CSAM User record itself then its ok
                    if (AcctIDCSAMTeamMap.containsKey(aTeam.Account__c)) {
                        if (AcctIDCSAMTeamMap.get(aTeam.Account__c).Team_Member__c != aTeam.Team_Member__c) {
                            aTeam.addError('A CSAM already exists on this Account');
                        }
                    }
                }
            }
        }
    }

    /**
     * @description Loads changed Account Team Member Account and New owner onto the event bus to change everything owned by one CSAM to another
     * or if the Role is active in the Apply_Downstream_Logic from Ateam_Downstream__mdt
     * @param updatedAcctTeamList a list of Account Team Records that were deleted
     */

    public static void aTeamOwnerChange(
        List<Account_Team__c> updatedAcctTeamList,
        Map<Id, Account_Team__c> oldAcctTeamMap
    ) {
        Set<ID> accountIDSet = new Set<ID>();
        List<Ateam_Downstream__mdt> aTeamDownstreamRoleList = [
            SELECT teamRole__c
            FROM Ateam_Downstream__mdt
            WHERE Apply_Downstream_Logic__c = TRUE
        ];
        Set<String> aTeamRoleMdtSet = new Set<String>();
        for (Ateam_Downstream__mdt aTmMdt : aTeamDownstreamRoleList) {
            aTeamRoleMdtSet.add(aTmMdt.teamRole__c);
        }
        List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
        for (Account_Team__C acctTeam : updatedAcctTeamList) {
            if (aTeamRoleMdtSet.contains(acctTeam.Team_Role__c)) {
                Account_Team__C oldAcctTeam = oldAcctTeamMap.get(acctTeam.ID);
                //If the change was one CSAM to another CSAM then load onto the bus a CSAM downstreamEvent
                if (
                    aTeamRoleMdtSet.contains(acctTeam.Team_Role__c) &&
                    oldAcctTeam.Team_Member__c != acctTeam.Team_Member__c
                ) {
                    Downstream_Event__e e = new Downstream_Event__e();
                    e.SourceId__c = acctTeam.Account__c;
                    e.OldOwner__c = oldAcctTeam.Team_Member__c;
                    e.NewOwner__c = acctTeam.Team_Member__c;
                    e.Object__c = 'Account_Team__C';
                    downstreamEvents.add(e);
                }
            }
        }
        if (!downstreamEvents.isEmpty()) {
            EventBus.publish(downstreamEvents);
        }
    }

    /**
     * @description Loads the Deleted Account Team Member Account onto the event bus to return everything owned by the Account Team CSAM
     * @param deleletedAcctTeamList a list of Account Team Records that were deleted
     */
    public static void acctDeleteDownstream(List<Account_Team__C> deleletedAcctTeamList) {
        Set<ID> accountIDSet = new Set<ID>();
        for (Account_Team__C acctTeam : deleletedAcctTeamList) {
            accountIDSet.add(acctTeam.Account__c);
        }
        Map<ID, Account> existingAccountMap = new Map<ID, Account>(
            [SELECT id, ownerid FROM account WHERE id IN :accountIDSet AND owner.isActive = TRUE]
        );
        Set<String> teamRoleStringSet = getAteamDownstreamRoles();
        if (!existingAccountMap.isEmpty()) {
            //Get the Deleted Account Teams Account Owner and fire a Downstream event. Which will reset the Objects to the main Account Owner
            List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();
            for (Account_Team__C acctTeam : deleletedAcctTeamList) {
                //IF the Delete is because of the Master Account being deleted then do not connect them
                if (
                    (existingAccountMap.containsKey(acctTeam.Account__c) &&
                    teamRoleStringSet.contains(acctTeam.Team_Role__c))
                ) {
                    Account existingAccount = existingAccountMap.get(acctTeam.Account__C);
                    Downstream_Event__e e = new Downstream_Event__e();
                    e.SourceId__c = existingAccount.Id;
                    e.OldOwner__c = acctTeam.Team_Member__c;
                    e.NewOwner__c = existingAccount.OwnerId;
                    e.Object__c = 'Account_Team__C_Delete';
                    downstreamEvents.add(e);
                }
                EventBus.publish(downstreamEvents);
            }
        }
    }
    /**
     * @description Builds map of new AccountTeamMembers by AccountId
     * @param accountAndParentAcctIDSet - set containing account and parent account ids post update
     * @return accountTeamCSAMMap - map of account's Team Members by Account Id
     */
    public static Map<ID, Account_Team__C> createAccountTeamCSAMMap(Set<Id> accountAndParentAcctIDSet) {
        Map<ID, Account_Team__C> accountTeamCSAMMap = new Map<ID, Account_Team__C>();
        List<Account_Team__C> accountTeamMemberCSAMList = new List<Account_Team__C>();
        accountTeamMemberCSAMList = [
            SELECT ID, Account__c, Team_Member__c, Team_Role__c
            FROM Account_Team__C
            WHERE
                Account__c IN :accountAndParentAcctIDSet
                AND ISDeleted = FALSE
                AND Team_Role__c = :AppConstants.CSAM_NAME
        ];
        for (Account_Team__C atm : accountTeamMemberCSAMList) {
            accountTeamCSAMMap.put(atm.Account__c, atm);
        }
        return accountTeamCSAMMap;
    }

    /**
     * @description Builds map of new AccountTeamMembers by AccountId
     * @param accountAndParentAcctIDSet - set containing account and parent account ids post update
     * @param Set<String> teamRoleStringSet - team roles to check against
     * @return accountTeamByAccountMap - map of account's Team Members by Account Id
     */
    public static Map<ID, List<Account_Team__C>> createAccountTeamDownstreamApplyMap(
        Set<Id> accountAndParentAcctIDSet,
        Set<String> teamRoleStringSet
    ) {
        Map<ID, List<Account_Team__C>> accountTeamByAccountMap = new Map<ID, List<Account_Team__C>>();
        List<Account_Team__C> accountTeamMemberList = new List<Account_Team__C>();

        accountTeamMemberList = [
            SELECT ID, Account__c, Team_Member__c, Team_Role__c
            FROM Account_Team__C
            WHERE Account__c IN :accountAndParentAcctIDSet AND ISDeleted = FALSE AND Team_Role__c = :teamRoleStringSet
        ];
        for (Account_Team__C atm : accountTeamMemberList) {
            if (!accountTeamByAccountMap.containsKey(atm.Account__c)) {
                accountTeamByAccountMap.put(atm.Account__c, new List<Account_Team__C>());
            }
            accountTeamByAccountMap.get(atm.Account__c).add(atm);
        }
        return accountTeamByAccountMap;
    }

    public static Set<String> getAteamDownstreamRoles() {
        Set<String> aTeamRoleMdtSet = new Set<String>();
        for (Ateam_Downstream__mdt atmd : [
            SELECT teamRole__c
            FROM Ateam_Downstream__mdt
            WHERE Apply_Downstream_Logic__c = TRUE
        ]) {
            aTeamRoleMdtSet.add(atmd.teamRole__c);
        }

        return aTeamRoleMdtSet;
    }
}