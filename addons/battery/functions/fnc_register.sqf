#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Object init for a speaker: remember it so charging sources are checked,
 * and start its battery state.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]]];

if (isNull _speaker) exitWith {};
if (isNil QGVAR(registry)) then { GVAR(registry) = []; };
GVAR(registry) pushBackUnique _speaker;
[_speaker] call FUNC(rebase);
