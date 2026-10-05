#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Starts a speaker's track through the sound extension.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Track index in the playlist <NUMBER>
 * 2: Seconds into the track to start at <NUMBER>
 * 3: Volume level 1-5 (after your personal volume setting) <NUMBER>
 *
 * Return Value:
 * Started (false = use the built-in sound instead) <BOOL>
 */

params ["_speaker", "_index", "_offset", "_level"];

if (!GVAR(extReady) || {!GVAR(useExtension)}) exitWith {false};

private _file = getArray (configFile >> QGVAR(playlist) >> "files") param [_index, ""];
if (_file == "") exitWith {false};

private _type = configOf _speaker;
private _range = (missionNamespace getVariable [getText (_type >> "jbl_rangeSetting"), getNumber (_type >> "jbl_range")]) max 1;
// Level 1-5 -> 0.2 .. 1, scaled by the speaker type's loudness
private _gain = (0.2 * _level) * getNumber (_type >> "jbl_extensionGain") * (GVAR(extLoudness) / 100);
_speaker setVariable ["jbl_extGain", _gain];

private _position = getPosASL _speaker;
private _result = "jbl_speaker" callExtension ["play", [netId _speaker, _file, _offset, _gain, _range, _position select 0, _position select 1, _position select 2]];
if ((_result select 1) != 0 || {(_result select 0) select [0, 5] == "error"}) exitWith { false };

_speaker setVariable ["jbl_extVoice", true];
GVAR(extVoices) pushBackUnique _speaker;
true
