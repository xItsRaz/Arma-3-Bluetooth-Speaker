#include "..\script_component.hpp"
/*
 * Author: Raz
 * Can this player control the speaker? Used by the menu conditions (to show or hide
 * controls) and again by the server before it runs any command.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 *
 * Return Value:
 * Allowed <BOOL>
 */

params [["_speaker", objNull, [objNull]], ["_player", objNull, [objNull]]];

if (isNull _speaker || {isNull _player}) exitWith {false};
if (_speaker getVariable ["btspk_broken", false]) exitWith {false};
if ([_player] call FUNC(isAdmin)) exitWith {true};
if (GVAR(controlMode) == 1) exitWith {true};

private _owner = _speaker getVariable [VAR_OWNER, ""];
if (_owner == "") exitWith {GVAR(unownedMode) == 1};
if (_owner == getPlayerUID _player) exitWith {true};

// Owned by someone else: only if they unlocked it
!(_speaker getVariable [VAR_LOCKED, true])
