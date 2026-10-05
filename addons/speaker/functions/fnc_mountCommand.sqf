#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Mounting commands (permission was already checked by btspk_common_fnc_command):
 *   "mount"    args [kind, position]: kind "backpack" (position "back" | "side" | "under")
 *              or "vehicle" (position "roof" | "rear" | "front")
 *   "mountPos" args [position]: move it to another position on what it is mounted on
 *   "unmount"  put it down in front of you
 *   "nudge"    args [key]: move it a little ("x+" "x-" "y+" "y-" "z+" "z-", turn "r+" "r-")
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 * 2: Command <STRING>
 * 3: Arguments <ARRAY> (default: [])
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_player", objNull, [objNull]], ["_command", ""], ["_args", []]];

if (isNull _speaker || {!alive _player}) exitWith {};

private _tell = { params ["_text"]; [_player, _text] call EFUNC(common,notify); };
private _party = _speaker isKindOf "btspk_party";
// What it is on now: a person or a vehicle (objNull = on the ground)
private _parent = _speaker getVariable [VAR_CLIPPED_TO, objNull];
if (isNull _parent) then { _parent = _speaker getVariable ["btspk_mountedOn", objNull]; };

switch (_command) do {
    case "mount": {
        _args params [["_kind", ""], ["_position", ""]];
        if (_kind == "backpack") then {
            if (_party) then { _position = "back"; }; // the Party Speaker only mounts on the back
            if (!_party && {backpack _player == ""}) exitWith { ["You need a backpack for this speaker"] call _tell; };
            private _other = _player getVariable [VAR_CLIPPED, objNull];
            if (!isNull _other && {_other != _speaker}) exitWith { ["You already carry a speaker on your body"] call _tell; };
            [_speaker, _player, _position] call FUNC(clip);
        } else {
            // A vehicle within 6 m of where the speaker is (or of you, when it is on your back)
            private _around = [_speaker, _player] select (_parent == _player);
            private _vehicles = (nearestObjects [_around, ["LandVehicle", "Air", "Ship"], 6]) select {alive _x && {_x != _speaker}};
            if (_vehicles isEqualTo []) exitWith { ["No vehicle within 6 m"] call _tell; };
            private _vehicle = _vehicles select 0;
            ([_speaker, _vehicle, _position] call FUNC(mountPreset)) params ["_offset", "_turn", "_bone"];
            [_speaker, _vehicle, _offset, _turn, _bone, _position] call FUNC(attach);
        };
    };

    case "mountPos": {
        if (isNull _parent) exitWith {};
        private _position = _args param [0, ""];
        if (_party && {_parent isKindOf "CAManBase"}) then { _position = "back"; };
        ([_speaker, _parent, _position] call FUNC(mountPreset)) params ["_offset", "_turn", "_bone"];
        [_speaker, _parent, _offset, _turn, _bone, _position] call FUNC(attach);
    };

    case "unmount": {
        if (isNull _parent) exitWith {};
        [_speaker, _player, 0.8] call FUNC(putDown);
    };

    case "nudge": {
        if (isNull _parent) exitWith {};
        private _key = _args param [0, ""];
        private _offset = +(_speaker getVariable ["btspk_mountOffset", [0, 0, 0]]);
        private _turn = _speaker getVariable ["btspk_mountTurn", 0];
        private _step = 0.05;
        switch (_key) do {
            case "x+": { _offset set [0, (_offset select 0) + _step]; };
            case "x-": { _offset set [0, (_offset select 0) - _step]; };
            case "y+": { _offset set [1, (_offset select 1) + _step]; };
            case "y-": { _offset set [1, (_offset select 1) - _step]; };
            case "z+": { _offset set [2, (_offset select 2) + _step]; };
            case "z-": { _offset set [2, (_offset select 2) - _step]; };
            case "r+": { _turn = _turn + 15; };
            case "r-": { _turn = _turn - 15; };
        };
        [_speaker, _parent, _offset, _turn, _speaker getVariable ["btspk_mountBone", ""], _speaker getVariable ["btspk_mountPreset", ""]] call FUNC(attach);
        [format ["Position: x %1, y %2, z %3, turn %4", (_offset select 0) toFixed 2, (_offset select 1) toFixed 2, (_offset select 2) toFixed 2, _turn]] call _tell;
    };
};
