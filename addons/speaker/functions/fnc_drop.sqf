#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Takes the speaker clipped to a unit off its backpack and puts it on the ground
 * next to them. Used by "Unclip speaker", death and disconnect. It keeps playing.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Distance in front of the unit in metres <NUMBER> (default: 0.6)
 *
 * Return Value:
 * None
 */

params [["_unit", objNull, [objNull]], ["_distance", 0.6]];

private _speaker = _unit getVariable [VAR_CLIPPED, objNull];
_unit setVariable [VAR_CLIPPED, objNull, true];
if (isNull _speaker) exitWith {};

[_speaker, _unit, _distance] call FUNC(putDown);
