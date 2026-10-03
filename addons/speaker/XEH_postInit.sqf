#include "script_component.hpp"

if (!hasInterface) exitWith {};

// Keybinds (Options > Controls > Configure Addons > JBL Speaker). Unbound by default.
["JBL Speaker", QGVAR(playStop), ["Play / stop speaker", "Nearest speaker you control (5 m)"], { ["playStop"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["JBL Speaker", QGVAR(next), ["Next song", "Nearest speaker you control (5 m)"], { ["next"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["JBL Speaker", QGVAR(volumeUp), ["Volume up", "Nearest speaker you control (5 m)"], { ["volumeUp"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["JBL Speaker", QGVAR(volumeDown), ["Volume down", "Nearest speaker you control (5 m)"], { ["volumeDown"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
["JBL Speaker", QGVAR(mute), ["Mute all speakers (for me)", "Toggle. Only affects you."], { ["mute"] call FUNC(keybind) }] call CBA_fnc_addKeybind;
