#include "script_component.hpp"

// Loaded into vehicle cargo: stop the music. It stays stopped after unloading; the owner presses Play.
if (isServer) then {
    ["ace_cargoLoaded", {
        params ["_item"];
        if !(_item isKindOf "btspk_speaker") exitWith {};
        [_item] call EFUNC(audio,halt);
    }] call CBA_fnc_addEventHandler;

    // Placing from inventory, unclipping, and dropping a clipped speaker on death / disconnect
    [QGVAR(create), LINKFUNC(create)] call CBA_fnc_addEventHandler;
    // (the smoke effect when a speaker breaks runs on every client, see below)
    [QGVAR(drop), LINKFUNC(drop)] call CBA_fnc_addEventHandler;
    // A speaker mounted on a vehicle that was destroyed or deleted falls to the ground
    [{ call FUNC(mountCheck) }, 5] call CBA_fnc_addPerFrameHandler;
    addMissionEventHandler ["HandleDisconnect", {
        params ["_unit"];
        [_unit, 0.5] call FUNC(drop);
        false
    }];
};

if (!hasInterface) exitWith {};

[QGVAR(brokenFx), LINKFUNC(brokenFx)] call CBA_fnc_addEventHandler;

// The server hands a picked-up speaker to this player as a magazine
[QGVAR(giveMag), LINKFUNC(giveMag)] call CBA_fnc_addEventHandler;

// Keybinds (Options > Controls > Configure Addons > Bluetooth Speaker). Unbound by default.
["Bluetooth Speaker", QGVAR(playStop), ["Play / stop speaker", "Nearest speaker you control (5 m)"], { ["playStop"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["Bluetooth Speaker", QGVAR(next), ["Next song", "Nearest speaker you control (5 m)"], { ["next"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["Bluetooth Speaker", QGVAR(volumeUp), ["Volume up", "Nearest speaker you control (5 m)"], { ["volumeUp"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["Bluetooth Speaker", QGVAR(volumeDown), ["Volume down", "Nearest speaker you control (5 m)"], { ["volumeDown"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["Bluetooth Speaker", QGVAR(mute), ["Mute all speakers (for me)", "Toggle. Only affects you."], { ["mute"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
