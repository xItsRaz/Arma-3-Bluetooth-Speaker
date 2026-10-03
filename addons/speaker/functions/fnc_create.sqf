#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Creates a speaker from a magazine the player just placed. The placer owns it.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Position <ARRAY> (ASL)
 * 2: Direction <NUMBER>
 * 3: Surface normal <ARRAY>
 * 4: Magazine rounds (battery % + 1) <NUMBER>
 * 5: Clip to backpack <BOOL> (default: false)
 *
 * Return Value:
 * None
 */

params [["_player", objNull, [objNull]], "_posASL", "_dir", "_normal", "_rounds", ["_clip", false]];

if (!isServer || {!alive _player}) exitWith {};

// Refuse bad requests and give the magazine back
if ((getPosASL _player) distance _posASL > 8 || {_clip && {!isNull (_player getVariable [VAR_CLIPPED, objNull])}}) exitWith {
    [QGVAR(giveMag), [_player, _rounds], _player] call CBA_fnc_targetEvent;
};

private _speaker = createVehicle ["jbl_speaker", [0, 0, 0], [], 0, "CAN_COLLIDE"];
_speaker setDir _dir;
_speaker setPosASL _posASL;
_speaker setVectorUp _normal;

_speaker setVariable [VAR_OWNER, getPlayerUID _player, true];
_speaker setVariable [VAR_OWNER_NAME, name _player, true];
_speaker setVariable [VAR_LOCKED, true, true];
_speaker setVariable [VAR_BATTERY, ((_rounds - 1) max 0) min 100, true];

if (_clip) then {
    [_speaker, _player] call FUNC(clip);
};
