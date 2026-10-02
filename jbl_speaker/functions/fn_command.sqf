/*
    JBL_fnc_command
    Server only. Owns the speaker state and tells every client what to play.
    Commands: "play", "stop", "next", "prev", "range"
*/
params [["_speaker", objNull, [objNull]], ["_cmd", "", [""]]];

if (!isServer || isNull _speaker) exitWith {};

private _tracks = getArray (configFile >> "JBL_Playlist" >> "tracks");
private _count = count _tracks;
if (_count == 0) exitWith {};

private _idx = (_speaker getVariable ["jbl_track", 0]) min (_count - 1);
private _range = _speaker getVariable ["jbl_range", 100];
private _playing = _speaker getVariable ["jbl_playing", false];
private _now = [time, serverTime] select isMultiplayer;

private _broadcast = {
    private _state = [
        _speaker getVariable ["jbl_playing", false],
        _speaker getVariable ["jbl_track", 0],
        _speaker getVariable ["jbl_start", 0],
        _speaker getVariable ["jbl_range", 100]
    ];
    [_speaker, _state] remoteExecCall ["JBL_fnc_syncLocal", 0];
};

private _startTrack = {
    params ["_newIdx"];
    private _session = (_speaker getVariable ["jbl_session", 0]) + 1;
    _speaker setVariable ["jbl_session", _session];
    _speaker setVariable ["jbl_track", _newIdx, true];
    _speaker setVariable ["jbl_start", _now, true];
    _speaker setVariable ["jbl_playing", true, true];
    call _broadcast;
    [_speaker, _session] spawn JBL_fnc_trackLoop;
};

switch (_cmd) do {
    case "play": { [_idx] call _startTrack; };
    case "next": { [(_idx + 1) mod _count] call _startTrack; };
    case "prev": { [(_idx - 1 + _count) mod _count] call _startTrack; };
    case "stop": {
        _speaker setVariable ["jbl_session", (_speaker getVariable ["jbl_session", 0]) + 1];
        _speaker setVariable ["jbl_playing", false, true];
        call _broadcast;
    };
    case "range": {
        private _ranges = [25, 50, 100, 200];
        private _i = _ranges find _range;
        _speaker setVariable ["jbl_range", _ranges select ((_i + 1) mod count _ranges), true];
        // say3D range can't change mid-sound, so clients restart at the current offset
        if (_playing) then { call _broadcast; };
    };
};
