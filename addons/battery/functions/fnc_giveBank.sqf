#include "..\script_component.hpp"
/*
 * Author: Raz
 * Runs where the player is local. Gives back a power bank with the given charge.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Rounds <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_player", "_rounds"];

if (!local _player) exitWith {};
_player addMagazine ["btspk_powerbank_mag", _rounds max 1 min 100];
