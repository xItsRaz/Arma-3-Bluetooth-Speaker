#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server-side entry point for every speaker command. Clients send:
 *   [QEGVAR(common,command), [_speaker, _player, _command, _args]] call CBA_fnc_serverEvent
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player who sent it <OBJECT>
 * 2: Command <STRING> ("play", "stop", "next", "prev", "link", "unlink")
 * 3: Command arguments <ANY> (default: [])
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_player", objNull, [objNull]], ["_command", "", [""]], ["_args", []]];
TRACE_4("command",_speaker,_player,_command,_args);

if (!isServer || {isNull _speaker}) exitWith {};

// Session 2: permission check (owner / admin) goes here - see PLAN.md section 5

switch (_command) do {
    case "play";
    case "stop";
    case "next";
    case "prev": {
        // A linked speaker controls its whole PartyBoost group through the leader
        private _leader = _speaker getVariable [VAR_LEADER, objNull];
        if (!isNull _leader) then { _speaker = _leader; };
        [_speaker, _command, _args] call EFUNC(audio,command);
    };
    case "link": {
        [_speaker, _player] call EFUNC(audio,link);
    };
    case "unlink": {
        [_speaker, _player] call EFUNC(audio,unlink);
    };
    default {
        WARNING_1("Unknown command: %1",_command);
    };
};
