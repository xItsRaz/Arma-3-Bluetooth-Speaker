#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Turns a placed speaker into a magazine in the player's inventory.
 * Permission was already checked by jbl_common_fnc_command.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 * 2: Keep playing: clip it to the player's backpack instead of taking it into the inventory <BOOL> (default: false)
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_player", objNull, [objNull]], ["_keepPlaying", false]];

if (isNull _speaker || {!alive _player}) exitWith {};

// Pick up and keep playing: it goes on your backpack, state and owner unchanged
if (_keepPlaying) exitWith {
    if (backpack _player == "") exitWith { [_player, "You need a backpack to carry it"] call EFUNC(common,notify); };
    if (!isNull (_player getVariable [VAR_CLIPPED, objNull])) exitWith { [_player, "You already carry a speaker on your backpack"] call EFUNC(common,notify); };
    if (!isNull (_speaker getVariable [VAR_CLIPPED_TO, objNull])) exitWith {};
    [_speaker, _player] call FUNC(clip);
};

if !(_player canAdd [MAG_SPEAKER, 1]) exitWith {
    [_player, "No room in your inventory. Carry it instead."] call EFUNC(common,notify);
};

private _battery = _speaker getVariable [VAR_BATTERY, 100];

// Stop the music everywhere, then remove the object
[_speaker] call EFUNC(audio,unlink);
if (_speaker getVariable [VAR_PLAYING, false]) then { [_speaker, "stop"] call EFUNC(audio,command); };

private _unit = _speaker getVariable [VAR_CLIPPED_TO, objNull];
if (!isNull _unit) then { _unit setVariable [VAR_CLIPPED, objNull, true]; };
deleteVehicle _speaker;

// addMagazine only works where the unit is local
[QGVAR(giveMag), [_player, round _battery + 1], _player] call CBA_fnc_targetEvent;
