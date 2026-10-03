#include "script_component.hpp"

// All speaker commands go through the server
if (isServer) then {
    [QGVAR(command), LINKFUNC(command)] call CBA_fnc_addEventHandler;
};
