public class contactQuoteProcessUpdates implements Queueable {
    Map<ID, manufacturingProcesses> contactIDToManuProcMap = new Map<ID, manufacturingProcesses>();

    public contactQuoteProcessUpdates(List<Quote_ERP__C> inQuoteList) {
        for (Quote_ERP__C q : inQuoteList) {
            ID lcontactID;
            if (!String.isblank(q.ContactID__C)) {
                if (!contactIDToManuProcMap.containsKey(q.ContactID__C)) {
                    lcontactID = q.ContactID__C;
                    Boolean Carbon = q.process_isCarbon__c;
                    Boolean CNC_Machining = q.process_isCNC_Machining__c;
                    Boolean Die_Casting = q.process_isDie_Casting__c;
                    Boolean Direct_Metal_Laser_Sintering = q.process_isDMLS__c;
                    Boolean Direct_Sourced = q.process_isDirect_Sourced__c;
                    Boolean Extrusion = q.process_isExtrusion__c;
                    Boolean Fused_Deposition_Modeling = q.process_isFDM__c;
                    Boolean HP_Mult_Jet_Fusion = q.process_isHPMultJetFusion__c;
                    Boolean Injection_Molding = q.process_isInjection_Molding__c;
                    Boolean PolyJet_3D = q.process_isPolyJet_3D__c;
                    Boolean Selective_Laser_Sintering = q.process_isSLS__c;
                    Boolean Sheet_Metal = q.process_isSheet_metal__c;
                    Boolean Stamping = q.process_isStamping__c;
                    Boolean Stereolithography = q.process_isSLA__c;
                    Boolean Urethane_Casting = q.process_isUrethane_Casting__c;
                    Boolean Binder_Jetting = q.process_isBinderJetting__c;
                    Boolean Sheet_Cutting = q.process_isSheetCutting__c;
                    Boolean Tube_Bending = q.process_isTubeBending__c;
                    Boolean Tube_Cutting = q.process_isTubeCutting__c;
                    Boolean Other = q.process_isOther__c;
                    Boolean Plastic_Extrusion = q.process_isPlasticExtrusion__c;
                    Boolean Other_NotIncluded = q.process_isOther_NotIncluded__c;
                    Boolean LSPc = q.process_isLSPc__c;
                    Boolean Assembly = q.process_isAssembly__c;
                    manufacturingProcesses quoteManuProcess = new manufacturingProcesses(
                        Carbon,
                        CNC_Machining,
                        Die_Casting,
                        Direct_Metal_Laser_Sintering,
                        Direct_Sourced,
                        Extrusion,
                        Fused_Deposition_Modeling,
                        HP_Mult_Jet_Fusion,
                        Injection_Molding,
                        PolyJet_3D,
                        Selective_Laser_Sintering,
                        Sheet_Metal,
                        Stamping,
                        Stereolithography,
                        Urethane_Casting,
                        Binder_Jetting,
                        Sheet_Cutting,
                        Tube_Bending,
                        Tube_Cutting,
                        Other,
                        Plastic_Extrusion,
                        Other_NotIncluded,
                        LSPc,
                        Assembly
                    );
                    contactIDToManuProcMap.put(lcontactID, quoteManuProcess);
                } else {
                    manufacturingProcesses lquoteManuProcess = contactIDToManuProcMap.get(q.ContactID__C);
                    if (lquoteManuProcess.Carbon == false) {
                        lquoteManuProcess.Carbon = q.process_isCarbon__c;
                    }
                    if (lquoteManuProcess.CNC_Machining == false) {
                        lquoteManuProcess.CNC_Machining = q.process_isCNC_Machining__c;
                    }
                    if (lquoteManuProcess.Die_Casting == false) {
                        lquoteManuProcess.Die_Casting = q.process_isDie_Casting__c;
                    }
                    if (lquoteManuProcess.Direct_Metal_Laser_Sintering == false) {
                        lquoteManuProcess.Direct_Metal_Laser_Sintering = q.process_isDMLS__c;
                    }
                    if (lquoteManuProcess.Direct_Sourced == false) {
                        lquoteManuProcess.Direct_Sourced = q.process_isDirect_Sourced__c;
                    }
                    if (lquoteManuProcess.Extrusion == false) {
                        lquoteManuProcess.Extrusion = q.process_isExtrusion__c;
                    }
                    if (lquoteManuProcess.Fused_Deposition_Modeling == false) {
                        lquoteManuProcess.Fused_Deposition_Modeling = q.process_isFDM__c;
                    }
                    if (lquoteManuProcess.HP_Mult_Jet_Fusion == false) {
                        lquoteManuProcess.HP_Mult_Jet_Fusion = q.process_isHPMultJetFusion__c;
                    }
                    if (lquoteManuProcess.Injection_Molding == false) {
                        lquoteManuProcess.Injection_Molding = q.process_isInjection_Molding__c;
                    }
                    if (lquoteManuProcess.PolyJet_3D == false) {
                        lquoteManuProcess.PolyJet_3D = q.process_isPolyJet_3D__c;
                    }
                    if (lquoteManuProcess.Selective_Laser_Sintering == false) {
                        lquoteManuProcess.Selective_Laser_Sintering = q.process_isSLS__c;
                    }
                    if (lquoteManuProcess.Sheet_Metal == false) {
                        lquoteManuProcess.Sheet_Metal = q.process_isSheet_metal__c;
                    }
                    if (lquoteManuProcess.Stamping == false) {
                        lquoteManuProcess.Stamping = q.process_isStamping__c;
                    }
                    if (lquoteManuProcess.Stereolithography == false) {
                        lquoteManuProcess.Stereolithography = q.process_isSLA__c;
                    }
                    if (lquoteManuProcess.Urethane_Casting == false) {
                        lquoteManuProcess.Urethane_Casting = q.process_isUrethane_Casting__c;
                    }
                    if (lquoteManuProcess.Binder_Jetting == false) {
                        lquoteManuProcess.Binder_Jetting = q.process_isBinderJetting__c;
                    }
                    if (lquoteManuProcess.Sheet_Cutting == false) {
                        lquoteManuProcess.Sheet_Cutting = q.process_isSheetCutting__c;
                    }
                    if (lquoteManuProcess.Tube_Bending == false) {
                        lquoteManuProcess.Tube_Bending = q.process_isTubeBending__c;
                    }
                    if (lquoteManuProcess.Tube_Cutting == false) {
                        lquoteManuProcess.Tube_Cutting = q.process_isTubeCutting__c;
                    }
                    if (lquoteManuProcess.Other == false) {
                        lquoteManuProcess.Other = q.process_isOther__c;
                    }
                    if (lquoteManuProcess.Plastic_Extrusion == false) {
                        lquoteManuProcess.Plastic_Extrusion = q.process_isPlasticExtrusion__c;
                    }
                    if (lquoteManuProcess.Other_NotIncluded == false) {
                        lquoteManuProcess.Other_NotIncluded = q.process_isOther_NotIncluded__c;
                    }
                    if (lquoteManuProcess.LSPc == false) {
                        lquoteManuProcess.LSPc = q.process_isLSPc__c;
                    }
                    if (lquoteManuProcess.Assembly == false) {
                        lquoteManuProcess.Assembly = q.process_isAssembly__c;
                    }
                    contactIDToManuProcMap.put(q.ContactID__C, lquoteManuProcess);
                }
            }
        }
    }
    public void execute(QueueableContext context) {
        System.debug('Fetching the contacts');
        //Query Contacts
        Set<ID> contactIDSet = contactIDToManuProcMap.keyset();
        // Contact Updates
        List<Contact> myContactList = [
            SELECT
                ID,
                has_quoted_Carbon__c,
                has_quoted_CNC_Machining__c,
                has_quoted_Die_Casting__c,
                has_quoted_Direct_Sourced__c,
                has_quoted_DMLS__c,
                has_quoted_Extrusion__c,
                has_quoted_FDM__c,
                has_quoted_HPMultiJetFusion__c,
                has_quoted_Injection_Molding__c,
                has_quoted_PolyJet_3D__c,
                has_quoted_Sheet_metal__c,
                has_quoted_SLA__c,
                has_quoted_SLS__c,
                has_quoted_Stamping__c,
                has_quoted_Urethane_Casting__c,
                has_quoted_BinderJetting__c,
                has_quoted_SheetCutting__c,
                has_quoted_Tube_Bending__c,
                has_quoted_Tube_Cutting__c,
                has_quoted_Other__c,
                has_quoted_PlasticExtrusion__c,
                has_quoted_Other_NotIncluded__c,
                has_quoted_LSPc__c,
                has_quoted_Assembly__c
            FROM Contact
            WHERE ID IN :contactIDSet
        ];

        for (Contact c : myContactList) {
            if (contactIDToManuProcMap.containsKey(c.ID)) {
                manufacturingProcesses lquoteManuProcess = contactIDToManuProcMap.get(c.ID);
                if (c.has_quoted_Carbon__c == false) {
                    c.has_quoted_Carbon__c = lquoteManuProcess.Carbon;
                }
                if (c.has_quoted_CNC_Machining__c == false) {
                    c.has_quoted_CNC_Machining__c = lquoteManuProcess.CNC_Machining;
                }
                if (c.has_quoted_Die_Casting__c == false) {
                    c.has_quoted_Die_Casting__c = lquoteManuProcess.Die_Casting;
                }
                if (c.has_quoted_Direct_Sourced__c == false) {
                    c.has_quoted_Direct_Sourced__c = lquoteManuProcess.Direct_Sourced;
                }
                if (c.has_quoted_DMLS__c == false) {
                    c.has_quoted_DMLS__c = lquoteManuProcess.Direct_Metal_Laser_Sintering;
                }
                if (c.has_quoted_Extrusion__c == false) {
                    c.has_quoted_Extrusion__c = lquoteManuProcess.Extrusion;
                }
                if (c.has_quoted_FDM__c == false) {
                    c.has_quoted_FDM__c = lquoteManuProcess.Fused_Deposition_Modeling;
                }
                if (c.has_quoted_HPMultiJetFusion__c == false) {
                    c.has_quoted_HPMultiJetFusion__c = lquoteManuProcess.HP_Mult_Jet_Fusion;
                }
                if (c.has_quoted_Injection_Molding__c == false) {
                    c.has_quoted_Injection_Molding__c = lquoteManuProcess.Injection_Molding;
                }
                if (c.has_quoted_PolyJet_3D__c == false) {
                    c.has_quoted_PolyJet_3D__c = lquoteManuProcess.PolyJet_3D;
                }
                if (c.has_quoted_Sheet_metal__c == false) {
                    c.has_quoted_Sheet_metal__c = lquoteManuProcess.Sheet_Metal;
                }
                if (c.has_quoted_SLA__c == false) {
                    c.has_quoted_SLA__c = lquoteManuProcess.Stereolithography;
                }
                if (c.has_quoted_SLS__c == false) {
                    c.has_quoted_SLS__c = lquoteManuProcess.Selective_Laser_Sintering;
                }
                if (c.has_quoted_Stamping__c == false) {
                    c.has_quoted_Stamping__c = lquoteManuProcess.Stamping;
                }
                if (c.has_quoted_Urethane_Casting__c == false) {
                    c.has_quoted_Urethane_Casting__c = lquoteManuProcess.Urethane_Casting;
                }
                if (c.has_quoted_BinderJetting__c == false) {
                    c.has_quoted_BinderJetting__c = lquoteManuProcess.Binder_Jetting;
                }
                if (c.has_quoted_SheetCutting__c == false) {
                    c.has_quoted_SheetCutting__c = lquoteManuProcess.Sheet_Cutting;
                }
                if (c.has_quoted_Tube_Bending__c == false) {
                    c.has_quoted_Tube_Bending__c = lquoteManuProcess.Tube_Bending;
                }
                if (c.has_quoted_Tube_Cutting__c == false) {
                    c.has_quoted_Tube_Cutting__c = lquoteManuProcess.Tube_Cutting;
                }
                if (c.has_quoted_Other__c == false) {
                    c.has_quoted_Other__c = lquoteManuProcess.Other;
                }
                if (c.has_quoted_PlasticExtrusion__c == false) {
                    c.has_quoted_PlasticExtrusion__c = lquoteManuProcess.Plastic_Extrusion;
                }
                if (c.has_quoted_Other_NotIncluded__c == false) {
                    c.has_quoted_Other_NotIncluded__c = lquoteManuProcess.Other_NotIncluded;
                }
                if (c.has_quoted_LSPc__c == false) {
                    c.has_quoted_LSPc__c = lquoteManuProcess.LSPc;
                }
                if (c.has_quoted_Assembly__c == false) {
                    c.has_quoted_Assembly__c = lquoteManuProcess.Assembly;
                }
            }
        }

        System.debug('About to start the Contact Quote Updates');
        DatabaseUtilities.saveToDatabase(
            myContactList,
            'contactQuoteProcessUpdates.execute',
            'Contact Updates in Execution Queu'
        );
    }
}