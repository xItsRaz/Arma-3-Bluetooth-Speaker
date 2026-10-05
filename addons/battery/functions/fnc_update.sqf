#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Works out how a speaker should be charging right now and changes it if needed:
 * "vehicle" (cargo or on the backpack of someone in a vehicle, engine on), "generator" (plugged
 * in, generator alive and within 6 m) or "" (not charging).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]]];

if (isNull _speaker) exitWith {};

private _desired = "";

if (GVAR(enabled) && {!(_speaker getVariable [VAR_BROKEN, false])}) then {
    private _vehicle = _speaker getVariable ["btspk_cargoVehicle", objNull];
    if (isNull _vehicle) then { _vehicle = _speaker getVariable ["btspk_mountedOn", objNull]; };
    private _unit = _speaker getVariable [VAR_CLIPPED_TO, objNull];
    if (isNull _vehicle && {!isNull _unit}) then { _vehicle = objectParent _unit; };
    if (GVAR(chargeInVehicles) && {!isNull _vehicle} && {alive _vehicle} && {isEngineOn _vehicle}) then {
        _desired = "vehicle";
    };

    private _generator = _speaker getVariable ["btspk_generator", objNull];
    if (!isNull _generator) then {
        if (alive _generator && {_generator distance _speaker < 6}) then {
            if (_desired == "") then { _desired = "generator"; };
        } else {
            _speaker setVariable ["btspk_generator", objNull, true];
        };
    };
};

if (_desired != (_speaker getVariable [VAR_CHARGING, ""])) then {
    _speaker setVariable [VAR_CHARGING, _desired, true];
    [_speaker] call FUNC(rebase);
};
