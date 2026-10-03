#include "script_component.hpp"

// Loaded into vehicle cargo: stop the music. It stays stopped after unloading; the owner presses Play.
if (isServer) then {
    ["ace_cargoLoaded", {
        params ["_item"];
        if !(_item isKindOf "jbl_speaker") exitWith {};
        [_item] call EFUNC(audio,unlink);
        if (_item getVariable [VAR_PLAYING, false]) then { [_item, "stop"] call EFUNC(audio,command); };
    }] call CBA_fnc_addEventHandler;

    // Placing from inventory, unclipping, and dropping a clipped speaker on death / disconnect
    [QGVAR(create), LINKFUNC(create)] call CBA_fnc_addEventHandler;
    [QGVAR(drop), LINKFUNC(drop)] call CBA_fnc_addEventHandler;
    addMissionEventHandler ["HandleDisconnect", {
        params ["_unit"];
        [_unit, 0.5] call FUNC(drop);
        false
    }];
};

if (!hasInterface) exitWith {};

// The server hands a picked-up speaker to this player as a magazine
[QGVAR(giveMag), LINKFUNC(giveMag)] call CBA_fnc_addEventHandler;

// Keybinds (Options > Controls > Configure Addons > JBL Speaker). Unbound by default.
["JBL Speaker", QGVAR(playStop), ["Play / stop speaker", "Nearest speaker you control (5 m)"], { ["playStop"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["JBL Speaker", QGVAR(next), ["Next song", "Nearest speaker you control (5 m)"], { ["next"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["JBL Speaker", QGVAR(volumeUp), ["Volume up", "Nearest speaker you control (5 m)"], { ["volumeUp"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["JBL Speaker", QGVAR(volumeDown), ["Volume down", "Nearest speaker you control (5 m)"], { ["volumeDown"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["JBL Speaker", QGVAR(mute), ["Mute all speakers (for me)", "Toggle. Only affects you."], { ["mute"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
