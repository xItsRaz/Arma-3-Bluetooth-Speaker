#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Moves charge from a power bank into the speaker (instantly) and returns the
 * unused part of the power bank to the player.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 * 2: Power bank rounds <NUMBER>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_player", objNull, [objNull]], ["_rounds", 0]];

if !(_rounds isEqualType 0) exitWith {};
_rounds = (round _rounds) max 0 min 100;

private _current = [_speaker] call FUNC(get);
private _used = _rounds min (100 - _current);
[_speaker, _current + _used] call FUNC(set);

private _left = _rounds - _used;
if (_left > 0) then { [QGVAR(giveBank), [_player, _left], _player] call CBA_fnc_targetEvent; };

[_player, format ["Charged +%1%%", round _used]] call EFUNC(common,notify);
