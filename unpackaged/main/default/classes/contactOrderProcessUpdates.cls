public class contactOrderProcessUpdates implements Queueable {
    Map<ID, manufacturingProcesses> contactIDToManuProcMap = new Map<ID, manufacturingProcesses>();
    public contactOrderProcessUpdates(List<Order_ERP__C> inOrdersList) {
        for (Order_ERP__C o : inOrdersList) {
            ID lcontactID;
            if (!String.isblank(o.ContactID__C)) {
                if (!contactIDToManuProcMap.containsKey(o.ContactID__C)) {
                    lcontactID = o.ContactID__C;
                    Boolean Carbon = o.process_isCarbon__c;
                    Boolean CNC_Machining = o.process_isCNC_Machining__c;
                    Boolean Die_Casting = o.process_isDie_Casting__c;
                    Boolean Direct_Metal_Laser_Sintering = o.process_isDMLS__c;
                    Boolean Direct_Sourced = o.process_isDirect_Sourced__c;
                    Boolean Extrusion = o.process_isExtrusion__c;
                    Boolean Fused_Deposition_Modeling = o.process_isFDM__c;
                    Boolean HP_Mult_Jet_Fusion = o.process_isHPMultJetFusion__c;
                    Boolean Injection_Molding = o.process_isInjection_Molding__c;
                    Boolean PolyJet_3D = o.process_isPolyJet_3D__c;
                    Boolean Selective_Laser_Sintering = o.process_isSLS__c;
                    Boolean Sheet_Metal = o.process_isSheet_metal__c;
                    Boolean Stamping = o.process_isStamping__c;
                    Boolean Stereolithography = o.process_isSLA__c;
                    Boolean Urethane_Casting = o.process_isUrethane_Casting__c;
                    Boolean Binder_Jetting = o.process_isBinderJetting__c;
                    Boolean Sheet_Cutting = o.process_isSheetCutting__c;
                    Boolean Tube_Bending = o.process_isTubeBending__c;
                    Boolean Tube_Cutting = o.process_isTubeCutting__c;
                    Boolean Other = o.process_isOther__c;
                    Boolean Plastic_Extrusion = o.process_isPlasticExtrusion__c;
                    Boolean Other_NotIncluded = o.process_isOther_NotIncluded__c;
                    Boolean LSPc = o.process_isLSPc__c;
                    Boolean Assembly = o.process_isAssembly__c;
                    manufacturingProcesses orderManuProcess = new manufacturingProcesses(
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
                    contactIDToManuProcMap.put(lcontactID, orderManuProcess);
                } else {
                    manufacturingProcesses lorderManuProcess = contactIDToManuProcMap.get(o.ContactID__C);
                    if (lorderManuProcess.Carbon == false) {
                        lorderManuProcess.Carbon = o.process_isCarbon__c;
                    }
                    if (lorderManuProcess.CNC_Machining == false) {
                        lorderManuProcess.CNC_Machining = o.process_isCNC_Machining__c;
                    }
                    if (lorderManuProcess.Die_Casting == false) {
                        lorderManuProcess.Die_Casting = o.process_isDie_Casting__c;
                    }
                    if (lorderManuProcess.Direct_Metal_Laser_Sintering == false) {
                        lorderManuProcess.Direct_Metal_Laser_Sintering = o.process_isDMLS__c;
                    }
                    if (lorderManuProcess.Direct_Sourced == false) {
                        lorderManuProcess.Direct_Sourced = o.process_isDirect_Sourced__c;
                    }
                    if (lorderManuProcess.Extrusion == false) {
                        lorderManuProcess.Extrusion = o.process_isExtrusion__c;
                    }
                    if (lorderManuProcess.Fused_Deposition_Modeling == false) {
                        lorderManuProcess.Fused_Deposition_Modeling = o.process_isFDM__c;
                    }
                    if (lorderManuProcess.HP_Mult_Jet_Fusion == false) {
                        lorderManuProcess.HP_Mult_Jet_Fusion = o.process_isHPMultJetFusion__c;
                    }
                    if (lorderManuProcess.Injection_Molding == false) {
                        lorderManuProcess.Injection_Molding = o.process_isInjection_Molding__c;
                    }
                    if (lorderManuProcess.PolyJet_3D == false) {
                        lorderManuProcess.PolyJet_3D = o.process_isPolyJet_3D__c;
                    }
                    if (lorderManuProcess.Selective_Laser_Sintering == false) {
                        lorderManuProcess.Selective_Laser_Sintering = o.process_isSLS__c;
                    }
                    if (lorderManuProcess.Sheet_Metal == false) {
                        lorderManuProcess.Sheet_Metal = o.process_isSheet_metal__c;
                    }
                    if (lorderManuProcess.Selective_Laser_Sintering == false) {
                        lorderManuProcess.Selective_Laser_Sintering = o.process_isSLS__c;
                    }
                    if (lorderManuProcess.Stamping == false) {
                        lorderManuProcess.Stamping = o.process_isStamping__c;
                    }
                    if (lorderManuProcess.Stereolithography == false) {
                        lorderManuProcess.Stereolithography = o.process_isSLA__c;
                    }
                    if (lorderManuProcess.Urethane_Casting == false) {
                        lorderManuProcess.Urethane_Casting = o.process_isUrethane_Casting__c;
                    }
                    if (lorderManuProcess.Binder_Jetting == false) {
                        lorderManuProcess.Binder_Jetting = o.process_isBinderJetting__c;
                    }
                    if (lorderManuProcess.Sheet_Cutting == false) {
                        lorderManuProcess.Sheet_Cutting = o.process_isSheetCutting__c;
                    }
                    if (lorderManuProcess.Tube_Bending == false) {
                        lorderManuProcess.Tube_Bending = o.process_isTubeBending__c;
                    }
                    if (lorderManuProcess.Tube_Cutting == false) {
                        lorderManuProcess.Tube_Cutting = o.process_isTubeCutting__c;
                    }
                    if (lorderManuProcess.Other == false) {
                        lorderManuProcess.Other = o.process_isOther__c;
                    }
                    if (lorderManuProcess.Plastic_Extrusion == false) {
                        lorderManuProcess.Plastic_Extrusion = o.process_isPlasticExtrusion__c;
                    }
                    if (lorderManuProcess.Other_NotIncluded == false) {
                        lorderManuProcess.Other_NotIncluded = o.process_isOther_NotIncluded__c;
                    }
                    if (lorderManuProcess.LSPc == false) {
                        lorderManuProcess.LSPc = o.process_isLSPc__c;
                    }
                    if (lorderManuProcess.Assembly == false) {
                        lorderManuProcess.Assembly = o.process_isAssembly__c;
                    }
                    contactIDToManuProcMap.put(o.ContactID__C, lorderManuProcess);
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
                has_ordered_PlasticExtrusion__c,
                has_ordered_Other_NotIncluded__c,
                has_ordered_LSPc__c,
                has_ordered_Assembly__c
            FROM Contact
            WHERE ID IN :contactIDSet
        ];

        for (Contact c : myContactList) {
            if (contactIDToManuProcMap.containsKey(c.ID)) {
                manufacturingProcesses lorderManuProcess = contactIDToManuProcMap.get(c.ID);
                if (c.has_ordered_Carbon__c == false) {
                    c.has_ordered_Carbon__c = lorderManuProcess.Carbon;
                }
                if (c.has_ordered_CNC_Machining__c == false) {
                    c.has_ordered_CNC_Machining__c = lorderManuProcess.CNC_Machining;
                }
                if (c.has_ordered_Die_Casting__c == false) {
                    c.has_ordered_Die_Casting__c = lorderManuProcess.Die_Casting;
                }
                if (c.has_ordered_Direct_Sourced__c == false) {
                    c.has_ordered_Direct_Sourced__c = lorderManuProcess.Direct_Sourced;
                }
                if (c.has_ordered_DMLS__c == false) {
                    c.has_ordered_DMLS__c = lorderManuProcess.Direct_Metal_Laser_Sintering;
                }
                if (c.has_ordered_Extrusion__c == false) {
                    c.has_ordered_Extrusion__c = lorderManuProcess.Extrusion;
                }
                if (c.has_ordered_FDM__c == false) {
                    c.has_ordered_FDM__c = lorderManuProcess.Fused_Deposition_Modeling;
                }
                if (c.has_ordered_HPMultiJetFusion__c == false) {
                    c.has_ordered_HPMultiJetFusion__c = lorderManuProcess.HP_Mult_Jet_Fusion;
                }
                if (c.has_ordered_Injection_Molding__c == false) {
                    c.has_ordered_Injection_Molding__c = lorderManuProcess.Injection_Molding;
                }
                if (c.has_ordered_PolyJet_3D__c == false) {
                    c.has_ordered_PolyJet_3D__c = lorderManuProcess.PolyJet_3D;
                }
                if (c.has_ordered_Sheet_metal__c == false) {
                    c.has_ordered_Sheet_metal__c = lorderManuProcess.Sheet_Metal;
                }
                if (c.has_ordered_SLA__c == false) {
                    c.has_ordered_SLA__c = lorderManuProcess.Stereolithography;
                }
                if (c.has_ordered_SLS__c == false) {
                    c.has_ordered_SLS__c = lorderManuProcess.Selective_Laser_Sintering;
                }
                if (c.has_ordered_Stamping__c == false) {
                    c.has_ordered_Stamping__c = lorderManuProcess.Stamping;
                }
                if (c.has_ordered_Urethane_Casting__c == false) {
                    c.has_ordered_Urethane_Casting__c = lorderManuProcess.Urethane_Casting;
                }
                if (c.has_ordered_BinderJetting__c == false) {
                    c.has_ordered_BinderJetting__c = lorderManuProcess.Binder_Jetting;
                }
                if (c.has_ordered_SheetCutting__c == false) {
                    c.has_ordered_SheetCutting__c = lorderManuProcess.Sheet_Cutting;
                }
                if (c.has_ordered_Tube_Bending__c == false) {
                    c.has_ordered_Tube_Bending__c = lorderManuProcess.Tube_Bending;
                }
                if (c.has_ordered_Tube_Cutting__c == false) {
                    c.has_ordered_Tube_Cutting__c = lorderManuProcess.Tube_Cutting;
                }
                if (c.has_ordered_Other__c == false) {
                    c.has_ordered_Other__c = lorderManuProcess.Other;
                }
                if (c.has_ordered_PlasticExtrusion__c == false) {
                    c.has_ordered_PlasticExtrusion__c = lorderManuProcess.Plastic_Extrusion;
                }
                if (c.has_ordered_Other_NotIncluded__c == false) {
                    c.has_ordered_Other_NotIncluded__c = lorderManuProcess.Other_NotIncluded;
                }
                if (c.has_ordered_LSPc__c == false) {
                    c.has_ordered_LSPc__c = lorderManuProcess.LSPc;
                }
                if (c.has_ordered_Assembly__c == false) {
                    c.has_ordered_Assembly__c = lorderManuProcess.Assembly;
                }
            }
        }
        System.debug('About to start the Contact Order Updates');
        DatabaseUtilities.saveToDatabase(
            myContactList,
            'contactOrderProcessUpdates.execute',
            'Contact Orders in Execution Queu'
        );
    }
}