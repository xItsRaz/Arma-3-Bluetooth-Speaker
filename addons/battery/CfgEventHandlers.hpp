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

// Every speaker is tracked by the server so charging sources can be checked
class Extended_Init_EventHandlers {
    class jbl_speaker {
        class ADDON {
            init = QUOTE(if (isServer) then { _this call FUNC(register) });
        };
    };
};
