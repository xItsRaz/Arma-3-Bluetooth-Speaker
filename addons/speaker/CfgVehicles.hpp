class CBA_Extended_EventHandlers_base;

class CfgVehicles {
    class Land_FMradio_F;
    // Placeholder model until the Charge-style model exists (PLAN.md section 15)
    class jbl_speaker: Land_FMradio_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JBL Speaker";
        jbl_range = 75;          // fixed cut-off distance in metres
        jbl_soundSuffix = "";    // normal loudness (the PartyBox will use "_party")
        class EventHandlers {
            class CBA_Extended_EventHandlers: CBA_Extended_EventHandlers_base {};
        };
    };
};
