#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server-side entry point for every speaker command a player sends:
 *   [QEGVAR(common,command), [_speaker, _player, _command, _args]] call CBA_fnc_serverEvent
 * Checks distance and permission here, so a modified client can't skip the rules.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player who sent it <OBJECT>
 * 2: Command <STRING>
 *    Playback: "play", "stop", "next", "prev", "track" (args: index), "volume" (args: 1-5)
 *    PartyBoost: "link", "unlink"
 *    Mounting: "mount", "mountPos", "unmount", "nudge" (see jbl_speaker_fnc_mountCommand)
 *    Battery: "plug", "unplug", "bank" (args: power bank rounds)
 *    Inventory: "pickup" (stops the music), "clip" (pick up onto your backpack, keeps playing)
 *    Ownership: "claim", "lock", "unlock", "release"
 * 3: Command arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_player", objNull, [objNull]], ["_command", "", [""]], ["_args", []]];
TRACE_4("command",_speaker,_player,_command,_args);

if (!isServer || {isNull _speaker} || {isNull _player}) exitWith {};

private _isAdmin = [_player] call FUNC(isAdmin);
if (!_isAdmin && {_player distance _speaker > GVAR(maxUseDistance)}) exitWith {
    TRACE_2("too far",_player,_speaker);
};

private _owner = _speaker getVariable [VAR_OWNER, ""];
private _isOwner = _owner != "" && {_owner == getPlayerUID _player};

private _deny = {
    params ["_target"];
    private _name = _target getVariable [VAR_OWNER_NAME, ""];
    [_player, ["This speaker is admins-only", format ["This speaker belongs to %1", _name]] select (_name != "")] call FUNC(notify);
};

switch (_command) do {
    case "play";
    case "stop";
    case "next";
    case "prev";
    case "track";
    case "volume": {
        // A linked speaker controls its whole PartyBoost group through the leader
        private _target = _speaker getVariable [VAR_LEADER, objNull];
        if (isNull _target) then { _target = _speaker; };
        if !([_target, _player] call FUNC(canControl)) exitWith { [_target] call _deny; };
        // An empty battery can't start music (stop and volume still work)
        if (_command in ["play", "next", "prev", "track"] && {_target getVariable [VAR_DEAD, false]}) exitWith {
            [_player, "The battery is empty"] call FUNC(notify);
        };
        [_target, _command, _args] call EFUNC(audio,command);
    };

    case "link";
    case "unlink": {
        if !([_speaker, _player] call FUNC(canControl)) exitWith { [_speaker] call _deny; };
        [_speaker, _player] call ([EFUNC(audio,unlink), EFUNC(audio,link)] select (_command == "link"));
    };

    case "plug";
    case "unplug";
    case "bank": {
        if !([_speaker, _player] call FUNC(canControl)) exitWith { [_speaker] call _deny; };
        switch (_command) do {
            case "plug": { [_speaker, _player] call EFUNC(battery,plug); };
            case "unplug": { [_speaker, _player] call EFUNC(battery,unplug); };
            default { [_speaker, _player, _args] call EFUNC(battery,applyBank); };
        };
    };

    case "pickup": {
        if !([_speaker, _player] call FUNC(canControl)) exitWith { [_speaker] call _deny; };
        [_speaker, _player] call EFUNC(speaker,pickup);
    };

    case "mount";
    case "mountPos";
    case "unmount";
    case "nudge": {
        if !([_speaker, _player] call FUNC(canControl)) exitWith { [_speaker] call _deny; };
        [_speaker, _player, _command, _args] call EFUNC(speaker,mountCommand);
    };

    case "clip": {
        if !([_speaker, _player] call FUNC(canControl)) exitWith { [_speaker] call _deny; };
        [_speaker, _player, true] call EFUNC(speaker,pickup);
    };

    case "claim": {
        if (_owner != "") exitWith { [_speaker] call _deny; };
        if (!_isAdmin && {GVAR(unownedMode) != 0}) exitWith { [_speaker] call _deny; };
        _speaker setVariable [VAR_OWNER, getPlayerUID _player, true];
        _speaker setVariable [VAR_OWNER_NAME, name _player, true];
        _speaker setVariable [VAR_LOCKED, true, true];
        [_player, "Speaker claimed. It's locked to you."] call FUNC(notify);
    };

    case "lock";
    case "unlock": {
        if (!_isOwner && {!_isAdmin}) exitWith { [_speaker] call _deny; };
        _speaker setVariable [VAR_LOCKED, _command == "lock", true];
        [_player, ["Speaker unlocked: anyone can use it", "Speaker locked to its owner"] select (_command == "lock")] call FUNC(notify);
    };

    case "release": {
        if (!_isOwner && {!_isAdmin}) exitWith { [_speaker] call _deny; };
        _speaker setVariable [VAR_OWNER, "", true];
        _speaker setVariable [VAR_OWNER_NAME, "", true];
        _speaker setVariable [VAR_LOCKED, true, true];
        [_player, "You no longer own this speaker"] call FUNC(notify);
    };

    default {
        WARNING_1("Unknown command: %1",_command);
    };
};
