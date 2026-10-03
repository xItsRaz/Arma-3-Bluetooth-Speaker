#include "..\script_component.hpp"
/*
 * Author: Raz
 * Is this player allowed to control every speaker? True in single player, for Zeus,
 * for a logged-in server admin, and for the host of a hosted game.
 * Works on the player's own machine and on the server.
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * Admin <BOOL>
 */

params [["_player", objNull, [objNull]]];

if (!isMultiplayer) exitWith {true};
if (isNull _player) exitWith {false};
if (!isNull getAssignedCuratorLogic _player) exitWith {true};
if (_player == player) exitWith {serverCommandAvailable "#kick"};
if (isServer) exitWith {(admin owner _player) > 0};
false
