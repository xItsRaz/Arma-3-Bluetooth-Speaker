#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Shows the battery and the time left (local hint). Everyone can use it.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]]];

if (_speaker getVariable [VAR_BROKEN, false]) exitWith { hint "This speaker is broken"; };
if (!GVAR(enabled)) exitWith { hint "Battery is turned off on this server"; };

private _percent = [_speaker] call FUNC(get);
private _rate = (_speaker getVariable [VAR_BAT, [1, 0, 0]]) select 2;
private _format = {
    params ["_seconds"];
    private _minutes = round (_seconds / 60);
    [format ["%1 min", _minutes], format ["%1 h %2 min", floor (_minutes / 60), _minutes mod 60]] select (_minutes >= 60)
};

private _text = format ["Battery %1%%", round _percent];
if ((_speaker getVariable [VAR_CHARGING, ""]) != "") then {
    _text = _text + format [" - charging (%1), full in about %2", _speaker getVariable VAR_CHARGING, [(100 - _percent) / 100 / (_rate max 0.00001)] call _format];
} else {
    if (_rate < 0) then {
        _text = _text + format [" - about %1 left", [_percent / 100 / -_rate] call _format];
    } else {
        private _drain = (0.3 + 0.7 * (_speaker getVariable [VAR_VOLUME, VOLUME_DEFAULT]) / VOLUME_MAX) / (GVAR(life) * 60);
        _text = _text + format [" - about %1 of play time at the current volume", [_percent / 100 / _drain] call _format];
    };
};
hint format ["JBL Speaker\n\n%1", _text];
