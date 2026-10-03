#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server side. Shows a short message to one player (hint on their screen).
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Message <STRING>
 *
 * Return Value:
 * None
 */

params [["_player", objNull, [objNull]], ["_message", "", [""]]];

if (isNull _player || {!isPlayer _player}) exitWith {};
[QGVAR(notify), [_message], _player] call CBA_fnc_targetEvent;
