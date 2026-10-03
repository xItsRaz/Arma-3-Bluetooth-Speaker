#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Stops this machine's sound for the speaker and, if it's playing,
 * restarts it at the right offset so everyone hears the same moment.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: State [playing, trackIndex, startTime, range] <ARRAY> (default: [] = read from the object)
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_state", [], [[]]]];

if (!hasInterface || {isNull _speaker}) exitWith {};

if (_state isEqualTo []) then {
    _state = [
        _speaker getVariable [VAR_PLAYING, false],
        _speaker getVariable [VAR_TRACK, 0],
        _speaker getVariable [VAR_START, 0],
        _speaker getVariable [VAR_RANGE, 100]
    ];
};
_state params ["_playing", "_index", "_start", "_range"];

private _source = _speaker getVariable [VAR_SOURCE, objNull];
if (!isNull _source) then { deleteVehicle _source; };
_speaker setVariable [VAR_SOURCE, objNull];

if (!_playing) exitWith {};

private _config = configFile >> QGVAR(playlist);
private _tracks = getArray (_config >> "tracks");
private _titles = getArray (_config >> "titles");
private _durations = getArray (_config >> "durations");
if (_index >= count _tracks) exitWith {};

private _offset = (NOW - _start) max 0;
if (_offset >= (_durations select _index)) exitWith {}; // server will advance

_source = _speaker say3D [_tracks select _index, _range, 1, false, _offset];
_speaker setVariable [VAR_SOURCE, _source];

if (player distance _speaker < _range) then {
    systemChat format ["JBL: now playing %1", _titles select _index];
};
