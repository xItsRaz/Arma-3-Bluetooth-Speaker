#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Owns the playback state and tells every client what to play.
 * Called by btspk_common_fnc_command after validation. For a Party Link group this is the leader;
 * every follower gets the same state.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Command <STRING> ("play", "stop", "next", "prev", "track", "volume")
 * 2: Command arguments <ANY> ("track": index, "volume": level 1-5)
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
    [_speaker] call FUNC(broadcast);
    [_speaker, _session] call FUNC(scheduleNext);
};

switch (_command) do {
    case "play": { [_index] call _startTrack; };
    case "next": { [(_index + 1) mod _count] call _startTrack; };
    case "prev": { [(_index - 1 + _count) mod _count] call _startTrack; };
    case "track": {
        if (_args isEqualType 0 && {_args >= 0} && {_args < _count}) then { [floor _args] call _startTrack; };
    };
    case "stop": {
        call _newSession;
        _speaker setVariable [VAR_PLAYING, false, true];
        [_speaker] call FUNC(broadcast);
    };
    case "volume": {
        if !(_args isEqualType 0) exitWith {};
        _speaker setVariable [VAR_VOLUME, (round _args) max 1 min VOLUME_MAX, true];
        // Players restart the song at the same moment with the new loudness
        [_speaker] call FUNC(broadcast);
    };
};
