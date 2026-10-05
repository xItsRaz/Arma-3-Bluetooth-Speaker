class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_preInit));
    };
};

class Extended_PostInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_postInit));
    };
};

class Extended_Init_EventHandlers {
    class btspk_speaker {
        class ADDON {
            init = QUOTE(_this call FUNC(init));
        };
    };
};

class Extended_Killed_EventHandlers {
    class CAManBase {
        class ADDON {
            killed = QUOTE(_this call FUNC(dropEH));
        };
    };
};
