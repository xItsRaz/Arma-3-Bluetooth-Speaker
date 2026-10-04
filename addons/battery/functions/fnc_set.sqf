#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Sets the battery to a value (placing a speaker from a magazine).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Battery percent 0-100 <NUMBER>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_percent", 100]];

if (!isServer || {isNull _speaker}) exitWith {};

_speaker setVariable [VAR_BAT, [(_percent / 100) max 0 min 1, NOW, 0], true];
[_speaker] call FUNC(rebase);
