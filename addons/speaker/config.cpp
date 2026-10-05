#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        name = COMPONENT_NAME;
        author = "Raz";
        units[] = {"btspk_speaker", "btspk_party"};
        weapons[] = {};
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"btspk_audio", "btspk_battery", "ace_interact_menu", "ace_interaction", "ace_dragging", "ace_cargo"};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"
#include "CfgMagazines.hpp"
#include "CfgVehicles.hpp"
