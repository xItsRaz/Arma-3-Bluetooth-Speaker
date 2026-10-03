#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Attaches a speaker to a unit's backpack. It keeps playing.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNull _speaker || {isNull _unit}) exitWith {};

// Offset is in the spine3 bone space - tune in game
_speaker attachTo [_unit, GVAR(clipOffset), "spine3", true];
_speaker setVariable [VAR_CLIPPED_TO, _unit, true];
_unit setVariable [VAR_CLIPPED, _speaker, true];
