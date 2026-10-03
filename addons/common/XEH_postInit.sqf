#include "script_component.hpp"

// All speaker commands go through the server
if (isServer) then {
    [QGVAR(command), LINKFUNC(command)] call CBA_fnc_addEventHandler;
};

// Short messages from the server to one player
if (hasInterface) then {
    [QGVAR(notify), { hintSilent (_this select 0) }] call CBA_fnc_addEventHandler;
};
