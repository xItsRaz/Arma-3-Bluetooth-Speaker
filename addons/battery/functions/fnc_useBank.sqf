#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Takes the fullest power bank out of your inventory and asks the server to
 * charge the speaker with it. The server hands back whatever the speaker could not take.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 *
 * Return Value:
 * None
 */

params ["_speaker", "_player"];

private _all = (magazinesAmmo _player) select {(_x select 0) == "jbl_powerbank_mag"};
if (_all isEqualTo []) exitWith {};

private _rounds = selectMax (_all apply {_x select 1});
_player removeMagazines "jbl_powerbank_mag";
private _removed = false;
{
    if (!_removed && {(_x select 1) == _rounds}) then { _removed = true; } else { _player addMagazine ["jbl_powerbank_mag", _x select 1]; };
} forEach _all;

[QEGVAR(common,command), [_speaker, _player, "bank", _rounds]] call CBA_fnc_serverEvent;
