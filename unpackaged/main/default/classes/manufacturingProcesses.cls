public with sharing class manufacturingProcesses {
    public boolean Carbon { get; set; }
    public boolean CNC_Machining { get; set; }
    public boolean Die_Casting { get; set; }
    public boolean Direct_Metal_Laser_Sintering { get; set; }
    public boolean Direct_Sourced { get; set; }
    public boolean Extrusion { get; set; }
    public boolean Fused_Deposition_Modeling { get; set; }
    public boolean HP_Mult_Jet_Fusion { get; set; }
    public boolean Injection_Molding { get; set; }
    public boolean PolyJet_3D { get; set; }
    public boolean Selective_Laser_Sintering { get; set; }
    public boolean Sheet_Metal { get; set; }
    public boolean Stamping { get; set; }
    public boolean Stereolithography { get; set; }
    public boolean Urethane_Casting { get; set; }
    public boolean Binder_Jetting { get; set; }
    public boolean Sheet_Cutting { get; set; }
    public boolean Tube_Bending { get; set; }
    public boolean Tube_Cutting { get; set; }
    public boolean Other { get; set; }
    public boolean Plastic_Extrusion { get; set; }
    public boolean Other_NotIncluded { get; set; }
    public boolean LSPc { get; set; }
    public boolean Assembly { get; set; }

    public manufacturingProcesses() {
    }
    public manufacturingProcesses(
        Boolean Carbon,
        Boolean CNC_Machining,
        Boolean Die_Casting,
        Boolean Direct_Metal_Laser_Sintering,
        Boolean Direct_Sourced,
        Boolean Extrusion,
        Boolean Fused_Deposition_Modeling,
        Boolean HP_Mult_Jet_Fusion,
        Boolean Injection_Molding,
        Boolean PolyJet_3D,
        Boolean Selective_Laser_Sintering,
        Boolean Sheet_Metal,
        Boolean Stamping,
        Boolean Stereolithography,
        Boolean Urethane_Casting,
        Boolean Binder_Jetting,
        Boolean Sheet_Cutting,
        Boolean Tube_Bending,
        Boolean Tube_Cutting,
        Boolean Other,
        Boolean Plastic_Extrusion,
        Boolean Other_NotIncluded,
        Boolean LSPc,
        Boolean Assembly
    ) {
        this.Carbon = Carbon;
        this.CNC_Machining = CNC_Machining;
        this.Die_Casting = Die_Casting;
        this.Direct_Metal_Laser_Sintering = Direct_Metal_Laser_Sintering;
        this.Direct_Sourced = Direct_Sourced;
        this.Extrusion = Extrusion;
        this.Fused_Deposition_Modeling = Fused_Deposition_Modeling;
        this.HP_Mult_Jet_Fusion = HP_Mult_Jet_Fusion;
        this.Injection_Molding = Injection_Molding;
        this.PolyJet_3D = PolyJet_3D;
        this.Selective_Laser_Sintering = Selective_Laser_Sintering;
        this.Sheet_Metal = Sheet_Metal;
        this.Stamping = Stamping;
        this.Stereolithography = Stereolithography;
        this.Urethane_Casting = Urethane_Casting;
        this.Binder_Jetting = Binder_Jetting;
        this.Sheet_Cutting = Sheet_Cutting;
        this.Tube_Bending = Tube_Bending;
        this.Tube_Cutting = Tube_Cutting;
        this.Other = Other;
        this.Plastic_Extrusion = Plastic_Extrusion;
        this.Other_NotIncluded = Other_NotIncluded;
        this.LSPc = LSPc;
        this.Assembly = Assembly;
    }
}