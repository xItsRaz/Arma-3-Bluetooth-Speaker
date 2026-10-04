#include "..\script_component.hpp"
/*
 * Author: Raz
 * Sends a command for the speaker clipped to this player's backpack (self menu).
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Command <STRING>
 * 2: Command arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 */

params ["_player", "_command", ["_args", []]];

private _speaker = _player getVariable [VAR_CLIPPED, objNull];
if (isNull _speaker) exitWith {};

[_speaker, _player, _command, _args] call FUNC(send);
