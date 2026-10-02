/*
    JBL_fnc_syncLocal
    Client side. Stops this machine's sound for the speaker and, if playing,
    restarts it at the right offset so everyone hears the same moment.
    _state = [playing, trackIndex, startTime, range]; empty = read from the object.
*/
params [["_speaker", objNull, [objNull]], ["_state", [], [[]]]];

if (!hasInterface || isNull _speaker) exitWith {};

if (_state isEqualTo []) then {
    _state = [
        _speaker getVariable ["jbl_playing", false],
        _speaker getVariable ["jbl_track", 0],
        _speaker getVariable ["jbl_start", 0],
        _speaker getVariable ["jbl_range", 100]
    ];
};
_state params ["_playing", "_idx", "_start", "_range"];

private _source = _speaker getVariable ["jbl_source", objNull];
if (!isNull _source) then { deleteVehicle _source; };
_speaker setVariable ["jbl_source", objNull];

if (!_playing) exitWith {};

private _cfg = configFile >> "JBL_Playlist";
private _tracks = getArray (_cfg >> "tracks");
private _titles = getArray (_cfg >> "titles");
private _durations = getArray (_cfg >> "durations");
if (_idx >= count _tracks) exitWith {};

private _now = [time, serverTime] select isMultiplayer;
private _offset = (_now - _start) max 0;
if (_offset >= (_durations select _idx)) exitWith {}; // server loop will advance

_source = _speaker say3D [_tracks select _idx, _range, 1, false, _offset];
_speaker setVariable ["jbl_source", _source];

if (player distance _speaker < _range) then {
    systemChat format ["JBL: now playing %1", _titles select _idx];
};
