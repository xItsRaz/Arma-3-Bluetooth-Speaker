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

detach _speaker;
_speaker setVariable [VAR_CLIPPED_TO, objNull, true];

private _pos = _unit modelToWorldWorld [0, _distance, 1];
private _hits = lineIntersectsSurfaces [_pos, _pos vectorAdd [0, 0, -4], _unit, _speaker, true, 1];
if (_hits isNotEqualTo []) then {
    (_hits select 0) params ["_posASL", "_normal"];
    _speaker setPosASL _posASL;
    _speaker setVectorUp _normal;
} else {
    _speaker setPosASL (getPosASL _unit);
    _speaker setVectorUp [0, 0, 1];
};
