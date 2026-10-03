#include "..\script_component.hpp"
/*
 * Author: Raz
 * Runs on the machine of the player who gets the speaker magazine.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Rounds (battery % + 1) <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_player", "_rounds"];

if (!local _player) exitWith {};
_player addMagazine [MAG_SPEAKER, _rounds max 1 min 101];
