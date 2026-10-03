#include "..\script_component.hpp"
/*
 * Author: Raz
 * Sends a speaker command from this player to the server (which checks permission).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 * 2: Command <STRING>
 * 3: Command arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 */

params ["_speaker", "_player", "_command", ["_args", []]];

[QEGVAR(common,command), [_speaker, _player, _command, _args]] call CBA_fnc_serverEvent;
