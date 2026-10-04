#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Takes a speaker off whatever it is attached to and puts it on the ground in front
 * of a unit. It keeps playing.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Unit to put it down next to <OBJECT>
 * 2: Distance in front of the unit in metres <NUMBER> (default: 0.8)
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_unit", objNull, [objNull]], ["_distance", 0.8]];

if (isNull _speaker) exitWith {};

// Clear every link to the old mount
private _oldUnit = _speaker getVariable [VAR_CLIPPED_TO, objNull];
if (!isNull _oldUnit) then { _oldUnit setVariable [VAR_CLIPPED, objNull, true]; };
_speaker setVariable [VAR_CLIPPED_TO, objNull, true];
_speaker setVariable ["jbl_mountedOn", objNull, true];
_speaker setVariable ["jbl_wasMounted", false];
detach _speaker;

private _around = [_unit, _speaker] select isNull _unit;
private _pos = [_speaker modelToWorldWorld [0, 0, 1], _unit modelToWorldWorld [0, _distance, 1]] select !isNull _unit;
private _hits = lineIntersectsSurfaces [_pos, _pos vectorAdd [0, 0, -5], _unit, _speaker, true, 1];
if (_hits isNotEqualTo []) then {
    (_hits select 0) params ["_posASL", "_normal"];
    _speaker setPosASL _posASL;
    _speaker setVectorUp _normal;
} else {
    _speaker setPosASL (getPosASL _around);
    _speaker setVectorUp [0, 0, 1];
};
