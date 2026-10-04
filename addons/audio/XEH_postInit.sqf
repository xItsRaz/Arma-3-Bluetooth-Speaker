#include "script_component.hpp"

// Each player plays the sound locally when the server says the state changed
if (hasInterface) then {
    [QGVAR(sync), LINKFUNC(syncLocal)] call CBA_fnc_addEventHandler;
    call FUNC(extInit);
};
