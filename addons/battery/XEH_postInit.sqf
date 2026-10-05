#include "script_component.hpp"

if (isServer) then {
    // Editor speakers may have registered before this runs
    if (isNil QGVAR(registry)) then { GVAR(registry) = []; };

    // Any change to a speaker's playback goes through audio's broadcast, which asks for a rebase
    [QGVAR(rebase), LINKFUNC(rebase)] call CBA_fnc_addEventHandler;

    // Cargo: remember which vehicle holds the speaker, the loop decides if it charges
    ["ace_cargoLoaded", {
        params ["_item", "_vehicle"];
        if !(_item isKindOf "btspk_speaker") exitWith {};
        _item setVariable ["btspk_cargoVehicle", _vehicle, true];
        [_item] call FUNC(update);
    }] call CBA_fnc_addEventHandler;
    ["ace_cargoUnloaded", {
        params ["_item"];
        if !(_item isKindOf "btspk_speaker") exitWith {};
        _item setVariable ["btspk_cargoVehicle", objNull, true];
        [_item] call FUNC(update);
    }] call CBA_fnc_addEventHandler;

    // Charging sources can stop (engine off, generator destroyed): check every 10 s
    [{
        GVAR(registry) = GVAR(registry) select {!isNull _x};
        { [_x] call FUNC(update) } forEach GVAR(registry);
    }, 10] call CBA_fnc_addPerFrameHandler;
};

// A power bank (or its leftover charge) goes back to a player's inventory
[QGVAR(giveBank), LINKFUNC(giveBank)] call CBA_fnc_addEventHandler;
