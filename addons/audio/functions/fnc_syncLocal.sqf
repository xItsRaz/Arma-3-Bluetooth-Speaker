#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Stops this machine's sound for the speaker and, if it's playing,
 * restarts it at the right offset so everyone hears the same moment.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: State [playing, trackIndex, startTime] <ARRAY> (default: [] = read from the object)
 *
 * Range and loudness are fixed per speaker type, from its config:
 *   jbl_rangeSetting (CBA setting with the range), jbl_range (fallback, metres),
 *   jbl_soundSuffix (e.g. "_party" for the louder sound classes)
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
        _speaker getVariable [VAR_START, 0]
    ];
};
_state params ["_playing", "_index", "_start"];

private _source = _speaker getVariable [VAR_SOURCE, objNull];
if (!isNull _source) then { deleteVehicle _source; };
_speaker setVariable [VAR_SOURCE, objNull];

if (!_playing || {GVAR(muteAll)}) exitWith {};

private _config = configFile >> QGVAR(playlist);
private _tracks = getArray (_config >> "tracks");
private _titles = getArray (_config >> "titles");
private _durations = getArray (_config >> "durations");
if (_index >= count _tracks) exitWith {};

private _offset = (NOW - _start) max 0;
if (_offset >= (_durations select _index)) exitWith {}; // server will advance

private _type = configOf _speaker;
// Range comes from a CBA setting named in the config, with the config value as fallback
private _range = (missionNamespace getVariable [getText (_type >> "jbl_rangeSetting"), getNumber (_type >> "jbl_range")]) max 1;
private _soundClass = (_tracks select _index) + getText (_type >> "jbl_soundSuffix");
if (!isClass (configFile >> "CfgSounds" >> _soundClass)) then { _soundClass = _tracks select _index; };

_source = _speaker say3D [_soundClass, _range, 1, false, _offset];
_speaker setVariable [VAR_SOURCE, _source];

if (EGVAR(common,notifications) > 0 && {player distance _speaker < _range}) then {
    private _message = format ["JBL: now playing %1", _titles select _index];
    if (EGVAR(common,notifications) == 1) then { systemChat _message } else { hintSilent _message };
};
