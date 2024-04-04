public with sharing class ordAggUpdates implements Queueable {
    private Set<ID> accountIDSet = new Set<ID>();
    private Set<ID> contactIDSet;
    private Date currentDate;
    private Integer currentMonth;
    private Integer currentYear;
    private Integer previousYear;
    private Integer rollingMonth;
    private Integer rollingYear;
    private Date rollingDate;
    static ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    Map<ID, manufacturingProcesses> contactIDToManuProcMap = new Map<ID, manufacturingProcesses>();

    public ordAggUpdates(List<Order_ERP__C> inOrdersList) {
        this.currentDate = Date.today();
        this.currentMonth = this.currentDate.month();
        this.currentYear = this.currentDate.year();
        this.previousYear = this.currentYear - 1;
        if (this.currentMonth == 12) {
            this.rollingMonth = 1;
            this.rollingYear = this.currentYear;
        } else {
            this.rollingMonth = this.currentMonth + 1;
            this.rollingYear = this.previousYear;
        }
        this.rollingDate = Date.newInstance(this.rollingYear, this.rollingMonth, 1);
        
        for (Order_ERP__C o : inOrdersList) {

            System.debug('We are in the order agg list lets rolls!');
            System.debug(o);
            System.debug('Here is the accountIDOutside!' + o.AccountID__c);

            if (!String.isBlank(o.AccountID__c)) {
                System.debug('Here is the accountID' + o.AccountID__c);
                accountIDSet.add(o.AccountID__c);
            }

            System.debug('We are passed the account');

            if (!String.isblank(o.ContactID__C)) {

                if (!contactIDToManuProcMap.containsKey(o.ContactID__C)) {
                    contactIDToManuProcMap.put(o.ContactID__C, new manufacturingProcesses() );
                }

                manufacturingProcesses lorderManuProcess = contactIDToManuProcMap.get(o.ContactID__C);
                if ( o.process_isCarbon__c == true ) {
                    lorderManuProcess.Carbon = o.process_isCarbon__c;
                }
                if ( o.process_isCNC_Machining__c == true ) {
                    lorderManuProcess.CNC_Machining = o.process_isCNC_Machining__c;
                }
                if ( o.process_isDie_Casting__c == true ) {
                    lorderManuProcess.Die_Casting = o.process_isDie_Casting__c;
                }
                if ( o.process_isDMLS__c == true ) {
                    lorderManuProcess.Direct_Metal_Laser_Sintering = o.process_isDMLS__c;
                }
                if ( o.process_isDirect_Sourced__c == true ) {
                    lorderManuProcess.Direct_Sourced = o.process_isDirect_Sourced__c;
                }
                if ( o.process_isExtrusion__c == true ) {
                    lorderManuProcess.Extrusion = o.process_isExtrusion__c;
                }
                if ( o.process_isFDM__c == true ) {
                    lorderManuProcess.Fused_Deposition_Modeling = o.process_isFDM__c;
                }
                if ( o.process_isHPMultJetFusion__c == true ) {
                    lorderManuProcess.HP_Mult_Jet_Fusion = o.process_isHPMultJetFusion__c;
                }
                if ( o.process_isInjection_Molding__c == true ) {
                    lorderManuProcess.Injection_Molding = o.process_isInjection_Molding__c;
                }
                if ( o.process_isPolyJet_3D__c == true ) {
                    lorderManuProcess.PolyJet_3D = o.process_isPolyJet_3D__c;
                }
                if ( o.process_isPlasticExtrusion__c == true ) {
                    lorderManuProcess.Plastic_Extrusion = o.process_isPlasticExtrusion__c;
                }
                if ( o.process_isSLS__c == true ) {
                    lorderManuProcess.Selective_Laser_Sintering = o.process_isSLS__c;
                }
                if ( o.process_isSheet_metal__c == true ) {
                    lorderManuProcess.Sheet_Metal = o.process_isSheet_metal__c;
                }
                if ( o.process_isSLS__c == true ) {
                    lorderManuProcess.Selective_Laser_Sintering = o.process_isSLS__c;
                }
                if ( o.process_isStamping__c == true ) {
                    lorderManuProcess.Stamping = o.process_isStamping__c;
                }
                if ( o.process_isSLA__c == true ) {
                    lorderManuProcess.Stereolithography = o.process_isSLA__c;
                }
                if ( o.process_isUrethane_Casting__c == true ) {
                    lorderManuProcess.Urethane_Casting = o.process_isUrethane_Casting__c;
                }
                if ( o.process_isBinderJetting__c == true ) {
                    lorderManuProcess.Binder_Jetting = o.process_isBinderJetting__c;
                }
                if ( o.process_isSheetCutting__c == true ) {
                    lorderManuProcess.Sheet_Cutting = o.process_isSheetCutting__c;
                }
                if ( o.process_isTubeBending__c == true ) {
                    lorderManuProcess.Tube_Bending = o.process_isTubeBending__c;
                }
                if ( o.process_isTubeCutting__c == true ) {
                    lorderManuProcess.Tube_Cutting = o.process_isTubeCutting__c;
                }
                if ( o.process_isOther__c == true ) {
                    lorderManuProcess.Other = o.process_isOther__c;
                }
                if ( o.process_isOther_NotIncluded__c == true ) {
                    lorderManuProcess.Other_NotIncluded = o.process_isOther_NotIncluded__c;
                }
                if ( o.process_isLSPc__c == true ) {
                    lorderManuProcess.LSPc = o.process_isLSPc__c;
                }
                if ( o.process_isAssembly__c == true ) {
                    lorderManuProcess.Assembly = o.process_isAssembly__c;
                }  
                contactIDToManuProcMap.put(o.ContactID__C, lorderManuProcess);
            }
        }
    }

    public void execute(QueueableContext context) {
        System.debug('Fetching the contacts');
        //Query Contacts
        Set<ID> contactIDSet = contactIDToManuProcMap.keyset();
        updateAccountInfo(accountIDSet, currentYear, rollingDate);
        updateContacts(contactIDSet, contactIDToManuProcMap);
    }

    private static void updateAccountInfo(Set<ID> accountIDSet, Integer currentYear, Date rollingDate) {
        System.debug('Firing Off the PostOrderAggUpdates execute method!');
        Map<ID, Account> accountsToUpdateMap = new Map<ID, Account>();
        for (ID acctID : accountIDSet) {
            Account a = new Account(ID = acctID);
            accountsToUpdateMap.put(a.ID, a);
        }

        List<Opportunity> lstOpp = [SELECT AccountID, Amount, Order_ERP_Xom_ID__c, closeDate
                                    FROM Opportunity
                                    WHERE
                                        Stagename = 'Closed Won'
                                        AND AccountID IN :accountIDSet
                                        AND RecordTypeId = :oppManufacturingServRTypeID
                                    ORDER BY AccountID];
        
        Map<ID, set<String>> accountMap_orderERP = new Map<ID, set<String>>();
        set<String> setOrderERP;
        for(Opportunity oppRecord : lstOpp)
        {
            ID lID = oppRecord.AccountID;
            Account a = accountsToUpdateMap.get(lID);

            if(!accountMap_orderERP.containsKey(lID))
            {
                setOrderERP = new set<String>();
                accountMap_orderERP.put(lID, setOrderERP);
                a.Lifetime_Spend__c = 0;
                a.YTDSpend__c = 0;
                a.Rolling_12_Spend__c = 0;
            }
            
            setOrderERP.add(oppRecord.Order_ERP_Xom_ID__c);
            a.Lifetime_Spend__c += oppRecord.Amount != null ? oppRecord.Amount : 0;
            a.Number_Orders__c = setOrderERP.size();
            
            //Calculate YTD information
            if(oppRecord.closeDate.year() == currentYear)
            {
                a.YTDSpend__c += oppRecord.Amount != null ? oppRecord.Amount : 0;                
            }
            
            //Calculate Rolling12
            if(oppRecord.closeDate >= rollingDate)
            {
                a.Rolling_12_Spend__c += oppRecord.Amount != null ? oppRecord.Amount : 0;                
            }
            
            accountsToUpdateMap.put(lID, a);
        }
        
        System.debug('About to start the Account Order Updates');
        DatabaseUtilities.saveToDatabase(
            accountsToUpdateMap.values(),
            'postOrderAggUpdates.execute',
            'Account Updates in Execution Queue'
        );
    }

    private static void updateContacts(Set<ID> contactIDSet, Map<ID, manufacturingProcesses> contactIDToManuProcMap) {
        
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact c : [
            SELECT
                ID,
                has_ordered_Carbon__c,
                has_ordered_CNC_Machining__c,
                has_ordered_Die_Casting__c,
                has_ordered_Direct_Sourced__c,
                has_ordered_DMLS__c,
                has_ordered_Extrusion__c,
                has_ordered_FDM__c,
                has_ordered_HPMultiJetFusion__c,
                has_ordered_Injection_Molding__c,
                has_ordered_PolyJet_3D__c,
                has_ordered_Sheet_metal__c,
                has_ordered_SLA__c,
                has_ordered_SLS__c,
                has_ordered_Stamping__c,
                has_ordered_Urethane_Casting__c,
                has_ordered_BinderJetting__c,
                has_ordered_SheetCutting__c,
                has_ordered_Tube_Bending__c,
                has_ordered_Tube_Cutting__c,
                has_ordered_Other__c,
                has_ordered_Other_NotIncluded__c,
                has_ordered_LSPc__c,
                has_ordered_Assembly__c
            FROM Contact
            WHERE ID IN :contactIDSet
        ]) {

            if ( contactIDToManuProcMap.containsKey(c.ID) ) {

                Boolean updateRecord = false;
                manufacturingProcesses lorderManuProcess = contactIDToManuProcMap.get(c.ID);
                
                if (c.has_ordered_Carbon__c == false && lorderManuProcess.Carbon == true ) {
                    c.has_ordered_Carbon__c = lorderManuProcess.Carbon;
                    updateRecord = true;
                }
                if (c.has_ordered_CNC_Machining__c == false && lorderManuProcess.CNC_Machining == true ) {
                    c.has_ordered_CNC_Machining__c = lorderManuProcess.CNC_Machining;
                    updateRecord = true;
                }
                if (c.has_ordered_Die_Casting__c == false && lorderManuProcess.Die_Casting == true ) {
                    c.has_ordered_Die_Casting__c = lorderManuProcess.Die_Casting;
                    updateRecord = true;
                }
                if (c.has_ordered_Direct_Sourced__c == false && lorderManuProcess.Direct_Sourced == true ) {
                    c.has_ordered_Direct_Sourced__c = lorderManuProcess.Direct_Sourced;
                    updateRecord = true;
                }
                if (c.has_ordered_DMLS__c == false && lorderManuProcess.Direct_Metal_Laser_Sintering == true ) {
                    c.has_ordered_DMLS__c = lorderManuProcess.Direct_Metal_Laser_Sintering;
                    updateRecord = true;
                }
                if (c.has_ordered_Extrusion__c == false && lorderManuProcess.Extrusion == true ) {
                    c.has_ordered_Extrusion__c = lorderManuProcess.Extrusion;
                    updateRecord = true;
                }
                if (c.has_ordered_FDM__c == false && lorderManuProcess.Fused_Deposition_Modeling == true ) {
                    c.has_ordered_FDM__c = lorderManuProcess.Fused_Deposition_Modeling;
                    updateRecord = true;
                }
                if (c.has_ordered_HPMultiJetFusion__c == false && lorderManuProcess.HP_Mult_Jet_Fusion == true ) {
                    c.has_ordered_HPMultiJetFusion__c = lorderManuProcess.HP_Mult_Jet_Fusion;
                    updateRecord = true;
                }
                if (c.has_ordered_Injection_Molding__c == false && lorderManuProcess.Injection_Molding == true ) {
                    c.has_ordered_Injection_Molding__c = lorderManuProcess.Injection_Molding;
                    updateRecord = true;
                }
                if (c.has_ordered_PolyJet_3D__c == false && lorderManuProcess.PolyJet_3D == true ) {
                    c.has_ordered_PolyJet_3D__c = lorderManuProcess.PolyJet_3D;
                    updateRecord = true;
                }
                if (c.has_ordered_Sheet_metal__c == false && lorderManuProcess.Sheet_Metal == true ) {
                    c.has_ordered_Sheet_metal__c = lorderManuProcess.Sheet_Metal;
                    updateRecord = true;
                }
                if (c.has_ordered_SLA__c == false && lorderManuProcess.Stereolithography == true ) {
                    c.has_ordered_SLA__c = lorderManuProcess.Stereolithography;
                    updateRecord = true;
                }
                if (c.has_ordered_SLS__c == false && lorderManuProcess.Selective_Laser_Sintering == true ) {
                    c.has_ordered_SLS__c = lorderManuProcess.Selective_Laser_Sintering;
                    updateRecord = true;
                }
                if (c.has_ordered_Stamping__c == false && lorderManuProcess.Stamping == true ) {
                    c.has_ordered_Stamping__c = lorderManuProcess.Stamping;
                    updateRecord = true;
                }
                if (c.has_ordered_Urethane_Casting__c == false && lorderManuProcess.Urethane_Casting == true ) {
                    c.has_ordered_Urethane_Casting__c = lorderManuProcess.Urethane_Casting;
                    updateRecord = true;
                }
                if (c.has_ordered_BinderJetting__c == false && lorderManuProcess.Binder_Jetting == true ) {
                    c.has_ordered_BinderJetting__c = lorderManuProcess.Binder_Jetting;
                    updateRecord = true;
                }
                if (c.has_ordered_SheetCutting__c == false && lorderManuProcess.Sheet_Cutting == true ) {
                    c.has_ordered_SheetCutting__c = lorderManuProcess.Sheet_Cutting;
                    updateRecord = true;
                }
                if (c.has_ordered_Tube_Bending__c == false && lorderManuProcess.Tube_Bending == true ) {
                    c.has_ordered_Tube_Bending__c = lorderManuProcess.Tube_Bending;
                    updateRecord = true;
                }
                if (c.has_ordered_Tube_Cutting__c == false && lorderManuProcess.Tube_Cutting == true ) {
                    c.has_ordered_Tube_Cutting__c = lorderManuProcess.Tube_Cutting;
                    updateRecord = true;
                }
                if (c.has_ordered_Other__c == false && lorderManuProcess.Other == true ) {
                    c.has_ordered_Other__c = lorderManuProcess.Other;
                    updateRecord = true;
                }
                if (c.has_ordered_Other_NotIncluded__c == false && lorderManuProcess.Other_NotIncluded == true ) {
                    c.has_ordered_Other_NotIncluded__c = lorderManuProcess.Other_NotIncluded;
                    updateRecord = true;
                }
                if (c.has_ordered_LSPc__c == false && lorderManuProcess.LSPc == true ) {
                    c.has_ordered_LSPc__c = lorderManuProcess.LSPc;
                    updateRecord = true;
                }
                if (c.has_ordered_Assembly__c == false && lorderManuProcess.Assembly == true ) {
                    c.has_ordered_Assembly__c = lorderManuProcess.Assembly;
                    updateRecord = true;
                }

                if( updateRecord ){
                    contactsToUpdate.add(c);
                }
            }
        }
        System.debug('About to start the Contact Order Updates');
        DatabaseUtilities.saveToDatabase(
            contactsToUpdate,
            'contactOrderProcessUpdates.execute',
            'Contact Orders in Execution Queu'
        );
    }
}