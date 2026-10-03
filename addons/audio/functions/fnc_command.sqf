#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Owns the playback state and tells every client what to play.
 * Called by jbl_common_fnc_command after validation. For a PartyBoost group this is the leader;
 * every follower gets the same state.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Command <STRING> ("play", "stop", "next", "prev")
 * 2: Command arguments <ANY> (unused for now)
 *
 * Return Value:
 * None
 */

params ["_speaker", "_command", ["_args", []]];

private _tracks = getArray (configFile >> QGVAR(playlist) >> "tracks");
private _count = count _tracks;
if (_count == 0) exitWith {
    WARNING("Playlist is empty - run tools/build_playlist.py");
};

private _index = (_speaker getVariable [VAR_TRACK, 0]) min (_count - 1);

// Send the state to every player, for this speaker and its PartyBoost followers
private _broadcast = {
    private _state = [
        _speaker getVariable [VAR_PLAYING, false],
        _speaker getVariable [VAR_TRACK, 0],
        _speaker getVariable [VAR_START, 0]
    ];
    {
        if (_x != _speaker) then {
            _x setVariable [VAR_PLAYING, _state select 0, true];
            _x setVariable [VAR_TRACK, _state select 1, true];
            _x setVariable [VAR_START, _state select 2, true];
        };
        [QGVAR(sync), [_x, _state]] call CBA_fnc_globalEvent;
    } forEach ([_speaker] + ((_speaker getVariable [VAR_FOLLOWERS, []]) select {!isNull _x}));
};

// A new session id invalidates any pending auto-advance timer
private _newSession = {
    private _session = (_speaker getVariable [VAR_SESSION, 0]) + 1;
    _speaker setVariable [VAR_SESSION, _session];
    _session
};

private _startTrack = {
    params ["_newIndex"];
    private _session = call _newSession;
    _speaker setVariable [VAR_TRACK, _newIndex, true];
    _speaker setVariable [VAR_START, NOW, true];
    _speaker setVariable [VAR_PLAYING, true, true];
    call _broadcast;
    [_speaker, _session] call FUNC(scheduleNext);
};

switch (_command) do {
    case "play": { [_index] call _startTrack; };
    case "next": { [(_index + 1) mod _count] call _startTrack; };
    case "prev": { [(_index - 1 + _count) mod _count] call _startTrack; };
    case "stop": {
        call _newSession;
        _speaker setVariable [VAR_PLAYING, false, true];
        call _broadcast;
    };
};
