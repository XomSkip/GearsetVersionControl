public with sharing class roundRobinDist {
    public static void lead_round_robin_NonGeneric_BDRDomainSet(List<SET<ID>> listsetDomainLeadsToRR) {
        System.debug('Starting the BDR Lead Non Generic Domain Set Round Robin Process');
        LIST<User> eligible_RR_USERS = new List<User>();
        String leadRRNonGenericBDRDomain = 'Lead RR NonGeneric BDR Domain';

        eligible_RR_USERS = [
            SELECT ID
            FROM User
            WHERE NonGeneric_BDR_RR_FLAG__C = TRUE AND ISACTIVE = TRUE
            ORDER BY ID
        ];
        Integer sizeUsers = eligible_RR_USERS.size();
        // If the size if is less then 1 then break
        if (sizeUsers > 0) {
            Integer sizeUsers_shift = sizeUsers - 1;
            System.debug('The shift size is : ' + sizeUsers_shift);
            //Convert Users into List of IDS
            LIST<ID> eligible_RR_UsersIDList = new List<ID>();
            for (User u : eligible_RR_USERS) {
                eligible_RR_UsersIDList.add(u.ID);
                System.debug('Adding User of ID : ' + u.ID);
            }

            // Get the last time an lead had the round robin and who it was assigned to
            datetime mydate = datetime.now();
            datetime filterDate = mydate.addhours(-24);
            //Get the ID
            // System.debug('The OwnerID has been returned:' + last_Owner_Assignment);
            List<RR_Owner__c> last_Owner_Assignment = [
                SELECT UserId__c
                FROM RR_Owner__c
                WHERE Method__c = :leadRRNonGenericBDRDomain
            ];
            Map<String, RR_Owner__c> rrOwnerUpdateMap = new Map<String, RR_Owner__c>();

            ID last_Owner_Assignment_ID;
            if (last_Owner_Assignment.size() > 0) {
                last_Owner_Assignment_ID = last_Owner_Assignment[0].UserId__c;
                rrOwnerUpdateMap.put(leadRRNonGenericBDRDomain, last_Owner_Assignment[0]);
                System.debug('The last owner assignment id is : ' + last_Owner_Assignment_ID);
                System.debug('The rrOwnerUpdateMap is : ' + rrOwnerUpdateMap);
            }

            //Check if last assignment was found otherwise start with 0
            // Start one above the last owner
            Integer l_assign_index;

            if (eligible_RR_UsersIDList.contains(last_Owner_Assignment_ID)) {
                System.debug('Marker 1 Inside eligbile RR Users!');
                l_assign_index = eligible_RR_UsersIDList.indexOf(last_Owner_Assignment_ID);
                System.debug('The l_assign_index is : ' + l_assign_index);
                //If last person in SET start at the begining
                if (sizeUsers_shift == l_assign_index) {
                    System.debug('We are inside the shift');
                    l_assign_index = 0;
                } else {
                    //Move to the next person in the set
                    System.debug('Moving on to the next person');
                    l_assign_index = l_assign_index + 1;
                    System.debug('New assigned Index is : ' + l_assign_index);
                }
            } else {
                //Last User assigned is not eligible start at the begining
                l_assign_index = 0;
                System.debug('We  were in the outer else');
            }

            System.debug('Assigning Lead to BDR Non Generics');
            List<Lead> leadsToUpdateList = new List<Lead>();
            Integer lrr_batchNum = 0;
            Integer lrr_batchNumMatchGroup = 0;
            for (SET<ID> sldSET : listsetDomainLeadsToRR) {
                //For the Set of IDs
                // Batch Number
                //NonGeneric_BDR_RR_FLAG__C TRUE
                //RR_ssignedDate__C
                lrr_batchNum = lrr_batchNum + 1;
                System.debug('The index is : ' + l_assign_index);
                lrr_batchNumMatchGroup = 0;
                //All Leads with same domain receive same RR value
                for (ID b : sldSET) {
                    Lead a = new Lead();
                    lrr_batchNumMatchGroup = lrr_batchNumMatchGroup + 1;
                    a.ID = b;
                    a.OWNERID = eligible_RR_UsersIDList.get(l_assign_index);
                    a.RR_Stamp_OwnerID__C = eligible_RR_UsersIDList.get(l_assign_index);
                    a.RR_Batch_Num__C = lrr_batchNum;
                    a.NonGeneric_BDR_RR_FLAG__C = true;
                    a.RR_AssignedDate__C = datetime.now();
                    a.RR_Batch_Num_Match_Group__C = lrr_batchNumMatchGroup;
                    leadsToUpdateList.add(a);
                    if (rrOwnerUpdateMap.containsKey(leadRRNonGenericBDRDomain)) {
                        RR_Owner__c rrOwner = rrOwnerUpdateMap.get(leadRRNonGenericBDRDomain);
                        rrOwner.Method__c = leadRRNonGenericBDRDomain;
                        rrOwner.UserId__c = eligible_RR_UsersIDList.get(l_assign_index);
                        rrOwnerUpdateMap.put(leadRRNonGenericBDRDomain, rrOwner);
                    } else {
                        RR_Owner__c rrOwner = new RR_Owner__c();
                        rrOwner.Method__c = leadRRNonGenericBDRDomain;
                        rrOwner.UserId__c = eligible_RR_UsersIDList.get(l_assign_index);
                        rrOwnerUpdateMap.put(leadRRNonGenericBDRDomain, rrOwner);
                    }
                }

                if (sizeUsers_shift == l_assign_index) {
                    System.debug('We are assigning reseting the index back to 0');
                    l_assign_index = 0;
                } else {
                    l_assign_index = l_assign_index + 1;
                    System.debug(' Else Clause: The index is : ' + l_assign_index);
                }
            }

            //Update Lead Object  with new owners and owner time of BDR assignement
            System.debug('About to Update the Lead with BDR Non Generic');
            System.debug('The Leads to be Updated are ' + leadsToUpdateList);
            DatabaseUtilities.saveToDatabase(
                leadsToUpdateList,
                'roundRobinDist.lead_rr_NonGeneric_BDRDomainSet',
                'Non Generic Lead BDR Round Robin Domain Set'
            );
            DatabaseUtilities.upsertToDatabase(
                rrOwnerUpdateMap.values(),
                'roundRobinDist.lead_rr_NonGeneric_BDRDomainSet',
                'roundRobinOwner updates'
            );
        } else {
            System.debug('No Users are founds! Owner will be default owner');
        }
    }

    public static void lead_round_robin_NonGeneric_BDR(SET<ID> leads_To_Be_RR) {
        //Round Robin V1
        //Get all users eliigible for this round robin at this time.
        System.debug('Starting the BDR Lead Non Generic Round Robin Process');
        LIST<User> eligible_RR_USERS = new List<User>();
        String leadRRNonGenericBDR = 'Lead RR NonGeneric BDR';

        eligible_RR_USERS = [
            SELECT ID
            FROM User
            WHERE NonGeneric_BDR_RR_FLAG__C = TRUE AND ISACTIVE = TRUE
            ORDER BY ID
        ];
        Integer sizeUsers = eligible_RR_USERS.size();
        // If the size if is less then 1 then break
        if (sizeUsers > 0) {
            Integer sizeUsers_shift = sizeUsers - 1;
            System.debug('The shift size is : ' + sizeUsers_shift);
            //Convert Users into List of IDS
            LIST<ID> eligible_RR_UsersIDList = new List<ID>();
            for (User u : eligible_RR_USERS) {
                eligible_RR_UsersIDList.add(u.ID);
                System.debug('Adding User of ID : ' + u.ID);
            }

            // Get the last time an lead had the round robin and who it was assigned to
            datetime mydate = datetime.now();
            datetime filterDate = mydate.addhours(-24);
            List<RR_Owner__c> last_Owner_Assignment = [
                SELECT UserId__c
                FROM RR_Owner__c
                WHERE Method__c = :leadRRNonGenericBDR
            ];
            Map<String, RR_Owner__c> rrOwnerUpdateMap = new Map<String, RR_Owner__c>();

            ID last_Owner_Assignment_ID;
            if (last_Owner_Assignment.size() > 0) {
                last_Owner_Assignment_ID = last_Owner_Assignment[0].UserId__c;
                rrOwnerUpdateMap.put(leadRRNonGenericBDR, last_Owner_Assignment[0]);
                System.debug('The last owner assignment id is : ' + last_Owner_Assignment_ID);
                System.debug('The rrOwnerUpdateMap is : ' + rrOwnerUpdateMap);
            }

            //Check if last assignment was found otherwise start with 0
            // Start one above the last owner
            Integer l_assign_index;

            if (eligible_RR_UsersIDList.contains(last_Owner_Assignment_ID)) {
                System.debug('Marker 1 Inside eligbile RR Users!');
                l_assign_index = eligible_RR_UsersIDList.indexOf(last_Owner_Assignment_ID);
                System.debug('The l_assign_index is : ' + l_assign_index);
                //If last person in SET start at the begining
                if (sizeUsers_shift == l_assign_index) {
                    System.debug('We are inside the shift');
                    l_assign_index = 0;
                } else {
                    //Move to the next person in the set
                    System.debug('Moving on to the next person');
                    l_assign_index = l_assign_index + 1;
                    System.debug('New assigned Index is : ' + l_assign_index);
                }
            } else {
                //Last User assigned is not eligible start at the begining
                l_assign_index = 0;
                System.debug('We  were in the outer else');
            }

            System.debug('Assigning Lead to BDR Non Generics');
            List<Lead> leadsToUpdateList = new List<Lead>();
            Integer lrr_batchNum = 0;
            for (ID b : leads_To_Be_RR) {
                Lead a = new Lead();
                lrr_batchNum = lrr_batchNum + 1;
                a.ID = b;
                System.debug('The index is : ' + l_assign_index);
                a.OWNERID = eligible_RR_UsersIDList.get(l_assign_index);
                a.RR_Stamp_OwnerID__C = eligible_RR_UsersIDList.get(l_assign_index);
                a.RR_Batch_Num__C = lrr_batchNum;
                a.RR_Batch_Num_Match_Group__C = 1;
                a.NonGeneric_BDR_RR_FLAG__C = true;
                a.RR_AssignedDate__C = datetime.now();
                leadsToUpdateList.add(a);
                if (rrOwnerUpdateMap.containsKey(leadRRNonGenericBDR)) {
                    RR_Owner__c rrOwner = rrOwnerUpdateMap.get(leadRRNonGenericBDR);
                    rrOwner.Method__c = leadRRNonGenericBDR;
                    rrOwner.UserId__c = eligible_RR_UsersIDList.get(l_assign_index);
                    rrOwnerUpdateMap.put(leadRRNonGenericBDR, rrOwner);
                } else {
                    RR_Owner__c rrOwner = new RR_Owner__c();
                    rrOwner.Method__c = leadRRNonGenericBDR;
                    rrOwner.UserId__c = eligible_RR_UsersIDList.get(l_assign_index);
                    rrOwnerUpdateMap.put(leadRRNonGenericBDR, rrOwner);
                }
                if (sizeUsers_shift == l_assign_index) {
                    System.debug('We are assigning reseting the index back to 0');
                    l_assign_index = 0;
                } else {
                    l_assign_index = l_assign_index + 1;
                    System.debug(' Else Clause: The index is : ' + l_assign_index);
                }
            }

            //Update Lead Object  with new owners and owner time of BDR assignement
            System.debug('About to Update the Lead with BDR Non Generic');
            System.debug('The Leads to be Updated are ' + leadsToUpdateList);
            DatabaseUtilities.saveToDatabase(
                leadsToUpdateList,
                'roundRobinDist.lead_round_robin_NonGeneric_BDR',
                'Non Generic Lead BDR Round Robin'
            );
            DatabaseUtilities.upsertToDatabase(
                rrOwnerUpdateMap.values(),
                'roundRobinDist.lead_round_robin_NonGeneric_BDR',
                'roundRobinOwner updates'
            );
        } else {
            System.debug('No Users are founds! Owner will be default owner');
        }
    }

    public static void lead_round_robin_Generic_BDR(SET<ID> leads_To_Be_RR) {
        // Round Robin V1
        // Get all users eligible for this round robin at this time.
        System.debug('Starting the Lead BDR Generic Round Robin Process');
        LIST<User> eligible_RR_USERS = new List<User>();
        String leadRRGenericBDR = 'Lead RR Generic BDR';

        eligible_RR_USERS = [SELECT ID FROM User WHERE Generic_BDR_RR_FLAG__C = TRUE AND ISACTIVE = TRUE ORDER BY ID];
        System.debug(eligible_RR_USERS);
        Integer sizeUsers = eligible_RR_USERS.size();
        // If the size if is less then 1 then break
        if (sizeUsers > 0) {
            Integer sizeUsers_shift = sizeUsers - 1;
            //Convert Users into List of IDS
            LIST<ID> eligible_RR_UsersIDList = new List<ID>();
            for (User u : eligible_RR_USERS) {
                eligible_RR_UsersIDList.add(u.ID);
            }

            // Get the last time a generic account had the round robin and who it was assigned to
            datetime mydate = datetime.now();
            datetime filterDate = mydate.addhours(-24);
            //Get the ID
            List<RR_Owner__c> last_Owner_Assignment = [
                SELECT UserId__c
                FROM RR_Owner__c
                WHERE Method__c = :leadRRGenericBDR
            ];
            Map<String, RR_Owner__c> rrOwnerUpdateMap = new Map<String, RR_Owner__c>();

            ID last_Owner_Assignment_ID;
            if (last_Owner_Assignment.size() > 0) {
                last_Owner_Assignment_ID = last_Owner_Assignment[0].UserId__c;
                rrOwnerUpdateMap.put(leadRRGenericBDR, last_Owner_Assignment[0]);
                System.debug('The last owner assignment id is : ' + last_Owner_Assignment_ID);
                System.debug('The rrOwnerUpdateMap is : ' + rrOwnerUpdateMap);
            }

            //Check if last assignment was found otherwise start with 0
            // Start one above the last owner
            Integer l_assign_index;

            if (eligible_RR_UsersIDList.contains(last_Owner_Assignment_ID)) {
                l_assign_index = eligible_RR_UsersIDList.indexOf(last_Owner_Assignment_ID);
                //If last person in SET start at the begining
                if (sizeUsers_shift == l_assign_index) {
                    l_assign_index = 0;
                } else {
                    //Move to the next person in the set
                    l_assign_index = l_assign_index + 1;
                }
            } else {
                //Last User assigned is not eligible start at the begining
                l_assign_index = 0;
            }

            System.debug('Assigning Leads to BDR Generics');
            List<Lead> leadsToUpdateList = new List<Lead>();
            Integer lrr_batchNum = 0;
            for (ID b : leads_To_Be_RR) {
                Lead a = new Lead();
                lrr_batchNum = lrr_batchNum + 1;
                a.ID = b;
                a.OWNERID = eligible_RR_UsersIDList.get(l_assign_index);
                a.RR_Stamp_OwnerID__C = eligible_RR_UsersIDList.get(l_assign_index);
                a.RR_Batch_Num__C = lrr_batchNum;
                a.Generic_BDR_RR_FLAG__C = true;
                a.RR_AssignedDate__C = datetime.now();
                leadsToUpdateList.add(a);
                if (rrOwnerUpdateMap.containsKey(leadRRGenericBDR)) {
                    RR_Owner__c rrOwner = rrOwnerUpdateMap.get(leadRRGenericBDR);
                    rrOwner.Method__c = leadRRGenericBDR;
                    rrOwner.UserId__c = eligible_RR_UsersIDList.get(l_assign_index);
                    rrOwnerUpdateMap.put(leadRRGenericBDR, rrOwner);
                } else {
                    RR_Owner__c rrOwner = new RR_Owner__c();
                    rrOwner.Method__c = leadRRGenericBDR;
                    rrOwner.UserId__c = eligible_RR_UsersIDList.get(l_assign_index);
                    rrOwnerUpdateMap.put(leadRRGenericBDR, rrOwner);
                }
                if (sizeUsers_shift == l_assign_index) {
                    l_assign_index = 0;
                } else {
                    l_assign_index = l_assign_index + 1;
                }
            }

            //Update Account Object  with new owners and owner time of BDR assignement
            System.debug('About to Update the Leads with Generic Owners');
            System.debug('The Leads to be Updated are ' + leadsToUpdateList);
            DatabaseUtilities.saveToDatabase(
                leadsToUpdateList,
                'roundRobinDist.account_round_robin_NonGeneric_BDR',
                'Non Generic Account BDR Round Robin'
            );
            System.debug('About to Update the rrOwners for Leads');
            System.debug('The rrOwners to be Updated are ' + rrOwnerUpdateMap);

            DatabaseUtilities.upsertToDatabase(
                rrOwnerUpdateMap.values(),
                'roundRobinDist.account_round_robin_NonGeneric_BDR',
                'roundRobinOwner updates'
            );
        } else {
            // Break
            System.debug('No Users are found! Using default owner.');
        }
    }

    public static void account_round_robin_NonGeneric_BDR(SET<ID> accounts_To_Be_RR) {
        // Round Robin V1
        // Get all users eligible for this round robin at this time.
        System.debug('Starting the BDR Non Generic Round Robin Process');
        EventBusBypass.ByPass('accountDownstream');
        LIST<User> eligible_RR_USERS = new List<User>();

        eligible_RR_USERS = [
            SELECT ID
            FROM User
            WHERE NonGeneric_BDR_RR_FLAG__C = TRUE AND ISACTIVE = TRUE
            ORDER BY ID
        ];
        Integer sizeUsers = eligible_RR_USERS.size();
        // If the size if is less then 1 then break
        if (sizeUsers > 0) {
            Integer sizeUsers_shift = sizeUsers - 1;
            //Convert Users into List of IDS
            LIST<ID> eligible_RR_UsersIDList = new List<ID>();
            for (User u : eligible_RR_USERS) {
                eligible_RR_UsersIDList.add(u.ID);
            }

            // Get the last time an account had the round robin and who it was assigned to
            datetime mydate = datetime.now();
            datetime filterdate = mydate.addhours(-24);
            List<Account> last_Owner_Assignment = [
                SELECT RR_Stamp_OwnerID__C, RR_Stamp_OwnerID__R.Name
                FROM Account
                WHERE NonGeneric_BDR_RR_FLAG__C = TRUE AND RR_AssignedDate__C > :filterdate
                ORDER BY
                    RR_AssignedDate__C DESC NULLS LAST,
                    RR_Batch_Num__C DESC NULLS LAST,
                    RR_Batch_Num_Match_Group__C DESC NULLS LAST
                LIMIT 10
            ];
            //Get the ID
            System.debug('The OwnerID has been returned:' + last_Owner_Assignment);
            ID last_Owner_Assignment_ID;
            if (last_Owner_Assignment.size() > 0) {
                last_Owner_Assignment_ID = last_Owner_Assignment[0].RR_Stamp_OwnerID__C;
            }

            //Check if last assignment was found otherwise start with 0
            // Start one above the last owner
            Integer l_assign_index;

            if (eligible_RR_UsersIDList.contains(last_Owner_Assignment_ID)) {
                l_assign_index = eligible_RR_UsersIDList.indexOf(last_Owner_Assignment_ID);
                //If last person in SET start at the begining
                if (sizeUsers_shift == l_assign_index) {
                    l_assign_index = 0;
                } else {
                    //Move to the next person in the set
                    l_assign_index = l_assign_index + 1;
                }
            } else {
                //Last User assigned is not eligible start at the begining
                l_assign_index = 0;
            }

            System.debug('Assigning Accounts to BDR Non Generics');
            List<Account> accountsToUpdateList = new List<Account>();
            Integer lrr_batchNum = 0;
            Integer lrr_batchNumMatchGroup = 0;
            for (ID b : accounts_To_Be_RR) {
                Account a = new Account();
                lrr_batchNum = lrr_batchNum + 1;
                a.ID = b;
                a.OWNERID = eligible_RR_UsersIDList.get(l_assign_index);
                a.RR_Stamp_OwnerID__C = eligible_RR_UsersIDList.get(l_assign_index);
                a.NonGeneric_BDR_RR_FLAG__C = true;
                a.RR_AssignedDate__C = datetime.now();
                a.RR_Batch_Num__C = lrr_batchNum;
                a.RR_Batch_Num_Match_Group__C = 1;
                accountsToUpdateList.add(a);
                if (sizeUsers_shift == l_assign_index) {
                    l_assign_index = 0;
                } else {
                    l_assign_index = l_assign_index + 1;
                }
            }

            //Update Account Object  with new owners and owner time of BDR assignement
            System.debug('About to Update the Accounts with BDR Non Generic');
            System.debug('The accounts to be Updated are ' + accountsToUpdateList);
            DatabaseUtilities.saveToDatabase(
                accountsToUpdateList,
                'roundRobinDist.account_round_robin_NonGeneric_BDR',
                'Non Generic Account BDR Round Robin'
            );
            EventBusBypass.UndoByPass('accountDownstream');
        } else {
            System.debug('No Users are founds! Owner will be default owner');
        }
    }

    public static void account_round_robin_Generic_BDR(SET<ID> accounts_To_Be_RR) {
        // Round Robin V1
        // Get all users eligible for this round robin at this time.
        System.debug('Starting the BDR Generic Round Robin Process');
        EventBusBypass.ByPass('accountDownstream');
        LIST<User> eligible_RR_USERS = new List<User>();

        eligible_RR_USERS = [SELECT ID FROM User WHERE Generic_BDR_RR_FLAG__C = TRUE AND ISACTIVE = TRUE ORDER BY ID];
        Integer sizeUsers = eligible_RR_USERS.size();
        // If the size if is less then 1 then break
        if (sizeUsers > 0) {
            Integer sizeUsers_shift = sizeUsers - 1;
            //Convert Users into List of IDS
            LIST<ID> eligible_RR_UsersIDList = new List<ID>();
            for (User u : eligible_RR_USERS) {
                eligible_RR_UsersIDList.add(u.ID);
            }

            // Get the last time a generic account had the round robin and who it was assigned to
            datetime mydate = datetime.now();
            datetime filterdate = mydate.addhours(-24);
            List<Account> last_Owner_Assignment = [
                SELECT OwnerID
                FROM Account
                WHERE Generic_BDR_RR_FLAG__C = TRUE AND RR_AssignedDate__C > :filterdate
                ORDER BY
                    RR_AssignedDate__C DESC NULLS LAST,
                    RR_Batch_Num__C DESC NULLS LAST,
                    RR_Batch_Num_Match_Group__C DESC NULLS LAST
                LIMIT 10
            ];
            //Get the ID
            System.debug('The OwnerID has been returned:' + last_Owner_Assignment);
            ID last_Owner_Assignment_ID;
            if (last_Owner_Assignment.size() > 0) {
                last_Owner_Assignment_ID = last_Owner_Assignment[0].OwnerID;
            }

            //Check if last assignment was found otherwise start with 0
            // Start one above the last owner
            Integer l_assign_index;

            if (eligible_RR_UsersIDList.contains(last_Owner_Assignment_ID)) {
                l_assign_index = eligible_RR_UsersIDList.indexOf(last_Owner_Assignment_ID);
                //If last person in SET start at the begining
                if (sizeUsers_shift == l_assign_index) {
                    l_assign_index = 0;
                } else {
                    //Move to the next person in the set
                    l_assign_index = l_assign_index + 1;
                }
            } else {
                //Last User assigned is not eligible start at the begining
                l_assign_index = 0;
            }

            System.debug('Assigning Accounts to BDR Generics');
            List<Account> accountsToUpdateList = new List<Account>();
            Integer lrr_batchNum = 0;
            Integer lrr_batchNumMatchGroup = 0;
            for (ID b : accounts_To_Be_RR) {
                Account a = new Account();
                lrr_batchNum = lrr_batchNum + 1;
                a.ID = b;
                a.OWNERID = eligible_RR_UsersIDList.get(l_assign_index);
                a.RR_Stamp_OwnerID__C = eligible_RR_UsersIDList.get(l_assign_index);
                a.Generic_BDR_RR_FLAG__C = true;
                a.RR_Batch_Num__C = lrr_batchNum;
                a.RR_Batch_Num_Match_Group__C = 1;
                a.RR_AssignedDate__C = datetime.now();
                accountsToUpdateList.add(a);
                if (sizeUsers_shift == l_assign_index) {
                    l_assign_index = 0;
                } else {
                    l_assign_index = l_assign_index + 1;
                }
            }

            //Update Account Object  with new owners and owner time of BDR assignement
            System.debug('About to Update the Accounts with Generic Owners');
            System.debug('The accounts to be Updated are ' + accountsToUpdateList);
            DatabaseUtilities.saveToDatabase(
                accountsToUpdateList,
                'roundRobinDist.account_round_robin_NonGeneric_BDR',
                'Non Generic Account BDR Round Robin'
            );
            EventBusBypass.UndoByPass('accountDownstream');
        }
        {
            // Break
            System.debug('No Users are found! Using default owner.');
        }
    }
    /**
     * @description assigns an OwnerID based on Users eligible for Round Robin
     * Opps on the same account get the same OwnerId
     * @param oppsToRR a list of Opportunity to Round Robin
     */
    public static List<Opportunity> oppRoundRobinSuppliesHouse(List<Opportunity> oppsToRR) {
        // Get all users eligible for this round robin at this time.
        System.debug('Starting the Supplies Round Robin Process');
        EventBusBypass.ByPass('accountDownstream');
        LIST<User> eligible_RR_USERS = new List<User>();
        eligible_RR_USERS = [SELECT ID FROM User WHERE Supplies_RR_Flag__c = TRUE AND ISACTIVE = TRUE ORDER BY ID];
        Integer sizeUsers = eligible_RR_USERS.size();
        // If there are no reps Flagged for Supplies Round Robin then do nothing
        if (sizeUsers > 0) {
            Map<ID, ID> accountsToRR = new Map<ID, ID>();
            Set<ID> accounts_To_Be_RR = new Set<ID>();
            for (Opportunity opp : oppsToRR) {
                if (opp.AccountID != null)
                    accounts_To_Be_RR.add(opp.AccountID);
            }
            Integer sizeUsers_shift = sizeUsers - 1;
            //Convert Users into List of IDS
            LIST<ID> eligible_RR_UsersIDList = new List<ID>();
            for (User u : eligible_RR_USERS) {
                eligible_RR_UsersIDList.add(u.ID);
            }

            // Get the last time a generic account had the round robin and who it was assigned to
            datetime filterdate = datetime.now().addhours(-24);
            List<Account> last_Owner_Assignment = [
                SELECT Non_Managed_Services_RR_OwnerID__c
                FROM Account
                WHERE Supplies_RR_Flag__c = TRUE AND RR_AssignedDate__C > :filterdate
                ORDER BY
                    RR_AssignedDate__C DESC NULLS LAST,
                    RR_Batch_Num__C DESC NULLS LAST,
                    RR_Batch_Num_Match_Group__C DESC NULLS LAST
                LIMIT 10
            ];
            //Get the ID
            System.debug('The OwnerID has been returned:' + last_Owner_Assignment);
            ID last_Owner_Assignment_ID;
            if (last_Owner_Assignment.size() > 0) {
                last_Owner_Assignment_ID = last_Owner_Assignment[0].Non_Managed_Services_RR_OwnerID__c;
            }

            //Check if last assignment was found otherwise start with 0
            // Start one above the last owner
            Integer l_assign_index;

            if (eligible_RR_UsersIDList.contains(last_Owner_Assignment_ID)) {
                l_assign_index = eligible_RR_UsersIDList.indexOf(last_Owner_Assignment_ID);
                //If last person in SET start at the begining
                if (sizeUsers_shift == l_assign_index) {
                    l_assign_index = 0;
                } else {
                    //Move to the next person in the set
                    l_assign_index = l_assign_index + 1;
                }
            } else {
                //Last User assigned is not eligible start at the begining
                l_assign_index = 0;
            }

            System.debug('Assigning Accounts to Supplies Owners');
            List<Account> accountsToUpdateList = new List<Account>();
            Map<ID, Account> accountToSuppliesRRMap = new Map<ID, Account>();
            Integer lrr_batchNum = 0;
            Integer lrr_batchNumMatchGroup = 0;
            for (ID b : accounts_To_Be_RR) {
                Account a = new Account();
                lrr_batchNum = lrr_batchNum + 1;
                a.ID = b;
                a.Non_Managed_Services_RR_OwnerID__c = eligible_RR_UsersIDList.get(l_assign_index);
                a.Supplies_RR_Flag__c = true;
                a.RR_Batch_Num__C = lrr_batchNum;
                a.RR_Batch_Num_Match_Group__C = 1;
                a.RR_AssignedDate__C = datetime.now();
                accountsToUpdateList.add(a);
                accountToSuppliesRRMap.put(a.ID, a);
                if (sizeUsers_shift == l_assign_index) {
                    l_assign_index = 0;
                } else {
                    l_assign_index = l_assign_index + 1;
                }
            }

            //Update Account Object  with new owners and owner time of BDR assignement
            System.debug('About to Update the Accounts with the Supplies Owner');
            System.debug('The accounts to be Updated are ' + accountsToUpdateList);
            DatabaseUtilities.saveToDatabase(
                accountsToUpdateList,
                'roundRobinDist.oppRoundRobinSuppliesHouse',
                'Supplies RR'
            );
            EventBusBypass.UndoByPass('accountDownstream');
            for (Opportunity opp : oppsToRR) {
                if (accountToSuppliesRRMap.containsKey(opp.AccountID)) {
                    opp.OwnerID = accountToSuppliesRRMap.get(opp.AccountID).Non_Managed_Services_RR_OwnerID__c;
                }
            }
        } else {
            system.debug('No eligible users at this time so the House Account remains the default');
            for (Opportunity opp : oppsToRR) {
                if (opp.OwnerId == null) {
                    opp.OwnerId = AppConstants.SUPPLIES_HOUSE_USER;
                }
            }
        }
        return oppsToRR;
    }
}