#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Call whenever something changes the speed of the battery (play, stop, volume,
 * charging). Saves the current charge as the new starting point, stores the new rate, and
 * schedules the next event (10%, empty, full). Old timers are ignored through a token.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]]];

if (!isServer || {isNull _speaker}) exitWith {};

private _fraction = ([_speaker] call FUNC(get)) / 100;
private _rate = 0;

if (GVAR(enabled) && {!(_speaker isKindOf "btspk_party") || {GVAR(partyBattery)}}) then {
    private _volume = _speaker getVariable [VAR_VOLUME, VOLUME_DEFAULT];
    if (_speaker getVariable [VAR_PLAYING, false] && {!(_speaker getVariable [VAR_BROKEN, false])}) then {
        // Full to empty in btspk_battery_life minutes at volume 5, slower at lower volumes
        _rate = _rate - (0.3 + 0.7 * _volume / VOLUME_MAX) / (GVAR(life) * 60);
    };
    if ((_speaker getVariable [VAR_CHARGING, ""]) != "") then {
        _rate = _rate + 1 / (GVAR(chargeTime) * 60);
    };
};

_speaker setVariable [VAR_BAT, [_fraction, NOW, _rate], true];

// Empty speakers stay off until they are above 5%
if (_fraction <= 0) then { _speaker setVariable [VAR_DEAD, true, true]; };
if (_fraction > 0.05 && {_speaker getVariable [VAR_DEAD, false]}) then { _speaker setVariable [VAR_DEAD, false, true]; };
private _low = GVAR(enabled) && {_fraction <= 0.1};
if (_low != (_speaker getVariable [VAR_LOW, false])) then { _speaker setVariable [VAR_LOW, _low, true]; };

private _token = (_speaker getVariable ["btspk_batToken", 0]) + 1;
_speaker setVariable ["btspk_batToken", _token];

private _schedule = {
    params ["_seconds", "_event"];
    [LINKFUNC(event), [_speaker, _token, _event], _seconds max 0.5] call CBA_fnc_waitAndExecute;
};

if (_rate < 0) then {
    if (_fraction > 0.1) then { [(_fraction - 0.1) / -_rate, "low"] call _schedule; };
    [_fraction / -_rate, "empty"] call _schedule;
};
if (_rate > 0 && {_fraction < 1}) then { [(1 - _fraction) / _rate, "full"] call _schedule; };
