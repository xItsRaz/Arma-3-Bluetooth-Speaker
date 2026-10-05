#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side, once a second. Picks the nearest playing Party Speakers within 60 m and gives each a
 * local light; removes lights that are no longer needed (stopped, far away, daytime, setting off).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

private _wanted = [];
if (GVAR(quality) > 0 && {sunOrMoon < 0.5} && {!isNull player}) then {
    _wanted = (nearestObjects [player, ["btspk_party"], 60]) select {
        _x getVariable [VAR_PLAYING, false] && {!(_x getVariable [VAR_BROKEN, false])}
    };
    _wanted resize ((round GVAR(maxLights)) min count _wanted);
};

// Drop lights nobody needs
GVAR(active) = GVAR(active) select {
    _x params ["_speaker", "_light"];
    private _keep = _speaker in _wanted;
    if (!_keep) then { deleteVehicle _light; };
    _keep
};

// Add lights for new ones
private _have = GVAR(active) apply {_x select 0};
{
    if !(_x in _have) then {
        private _light = "#lightpoint" createVehicleLocal (getPosATL _x);
        _light lightAttachObject [_x, [0, 0, 0.7]];
        _light setLightAttenuation [0.5, 4, 4, 0, 2, 25];
        _light setLightAmbient [0, 0, 0];
        _light setLightBrightness 0;
        GVAR(active) pushBack [_x, _light];
    };
} forEach _wanted;
