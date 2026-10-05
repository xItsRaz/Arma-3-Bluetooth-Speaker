#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. A speaker took damage. At 50% it is "damaged" (plays slightly lower).
 * At 100% it is "broken": the music stops, nothing can control it, and it can't be picked up.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]]];

if (isNull _speaker || {_speaker getVariable [VAR_BROKEN, false]}) exitWith {};

private _damage = [damage _speaker, 1] select !alive _speaker;

if (_damage >= 1) exitWith {
    _speaker setVariable [VAR_DAMAGED, true, true];
    _speaker setVariable [VAR_BROKEN, true, true];
    [_speaker] call EFUNC(audio,halt);
    ["btspk_battery_rebase", [_speaker]] call CBA_fnc_localEvent;
    [QGVAR(brokenFx), [_speaker]] call CBA_fnc_globalEvent;
};

if (_damage >= 0.5 && {!(_speaker getVariable [VAR_DAMAGED, false])}) then {
    _speaker setVariable [VAR_DAMAGED, true, true];
    // Players restart the song with the lower pitch
    [_speaker] call EFUNC(audio,broadcast);
};
