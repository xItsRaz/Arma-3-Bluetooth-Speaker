#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Attaches a speaker to a unit's backpack. It keeps playing.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Unit <OBJECT>
 * 2: Position <STRING> ("back", "side" or "under", default: "back")
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_unit", objNull, [objNull]], ["_preset", "back"]];

if (isNull _speaker || {isNull _unit}) exitWith {};

([_speaker, _unit, _preset] call FUNC(mountPreset)) params ["_offset", "_turn", "_bone"];
[_speaker, _unit, _offset, _turn, _bone, _preset] call FUNC(attach);
