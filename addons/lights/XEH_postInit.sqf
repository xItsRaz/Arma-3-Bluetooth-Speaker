#include "script_component.hpp"

if (!hasInterface) exitWith {};

GVAR(active) = []; // [speaker, light] pairs, local to this machine

// Once a second: which PartyBoxes near me are playing (needs a night and the setting on)
[{ call FUNC(scan) }, 1] call CBA_fnc_addPerFrameHandler;

// About 15 times a second: pulse the lights
[{ call FUNC(animate) }, 0.066] call CBA_fnc_addPerFrameHandler;
