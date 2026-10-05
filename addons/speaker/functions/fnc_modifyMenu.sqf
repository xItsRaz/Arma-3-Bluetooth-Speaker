#include "..\script_component.hpp"
/*
 * Author: Raz
 * ACE modifierFunction for the "Speaker" menu: shows the song and volume in its name,
 * e.g. "Speaker: Omer Adam - Tehom (vol 4, 64%)". Runs every frame while visible, so keep it cheap.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 * 2: Action params <ANY>
 * 3: Action data <ARRAY> (modified in place)
 *
 * Return Value:
 * None
 */

params ["_target", "", "", "_actionData"];

// In the self menu the target is the player: use the speaker clipped to them
if (_target isKindOf "CAManBase") then { _target = _target getVariable [VAR_CLIPPED, objNull]; };
if (isNull _target) exitWith {};

if (_target getVariable [VAR_BROKEN, false]) exitWith {
    _actionData set [1, "Speaker (broken)"];
};

private _battery = "";
if (btspk_battery_enabled) then { _battery = format ["%1%%", round ([_target] call btspk_battery_fnc_get)]; };

if !(_target getVariable [VAR_PLAYING, false]) exitWith {
    _actionData set [1, ["Speaker", format ["Speaker (%1)", _battery]] select (_battery != "")];
};

private _title = getArray (configFile >> QEGVAR(audio,playlist) >> "titles") param [_target getVariable [VAR_TRACK, 0], "?"];
_actionData set [1, format ["Speaker: %1 (vol %2%3)", _title, _target getVariable [VAR_VOLUME, VOLUME_DEFAULT], [", " + _battery, ""] select (_battery == "")]];
