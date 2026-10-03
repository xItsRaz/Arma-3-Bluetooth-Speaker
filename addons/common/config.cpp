#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        author = "Raz";
        units[] = {};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"jbl_main"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
