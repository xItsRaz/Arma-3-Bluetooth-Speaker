#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Works out how one speaker should sound for you right now and sends it to the
 * sound extension: position, muffling through walls and glass, echo, and sound that reaches you
 * through an open door or window.
 *
 * What is in the way (two rays, one against each kind of geometry):
 *   - view geometry: walls, closed doors, big props. Counts as a WALL (about -15 dB, very muffled).
 *   - collision geometry minus view geometry: windows and glass doors. Counts as GLASS (about
 *     -5 dB, dull but clearly audible).
 * Open paths: when a wall is in the way, look for a spot a few metres around the speaker that the
 * speaker can reach and that you can reach with nothing in between (an open door or window). The
 * sound then comes from that spot, plus the detour distance.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Your eye position <ARRAY> (ASL)
 *
 * Return Value:
 * None
 */

params ["_speaker", "_eye"];

private _type = configOf _speaker;
private _range = (missionNamespace getVariable [getText (_type >> "jbl_rangeSetting"), getNumber (_type >> "jbl_range")]) max 1;
private _baseGain = _speaker getVariable ["jbl_extGain", 0.45];
private _gain = _baseGain;
private _source = (getPosASL _speaker) vectorAdd [0, 0, 0.25];
private _virtual = _source;
private _muffle = 0;
private _reverb = 0;
private _extra = 0;
private _walls = 0;
private _glass = 0;
private _openPath = false;

private _distance = _eye distance _source;
private _mode = GVAR(wallEffects);

if (_mode > 0 && {_distance < _range}) then {
    private _listener = vehicle player;

    // [walls, glass] between two points
    private _between = {
        params ["_from", "_to"];
        private _opaque = count lineIntersectsSurfaces [_from, _to, _listener, _speaker, false, 4, "VIEW", "VIEW"];
        private _solid = count lineIntersectsSurfaces [_from, _to, _listener, _speaker, false, 4, "GEOM", "GEOM"];
        [_opaque min 3, ((_solid - _opaque) max 0) min 3]
    };

    ([_eye, _source] call _between) params ["_w", "_g"];
    _walls = _w;
    _glass = _g;

    if (_walls > 0) then {
        _muffle = (0.9 + 0.05 * (_walls - 1)) min 1;
        _gain = _baseGain * (0.18 ^ _walls) * (0.6 ^ _glass);

        if (_mode > 1) then {
            // Look for an open path: points around the speaker, the shortest detour wins
            private _best = [];
            private _bestLength = 1e9;
            {
                private _candidate = _source vectorAdd _x;
                if (count lineIntersectsSurfaces [_source, _candidate, _listener, _speaker, false, 1, "GEOM", "GEOM"] == 0) then {
                    if (count lineIntersectsSurfaces [_candidate, _eye, _listener, _speaker, false, 1, "GEOM", "GEOM"] == 0) then {
                        private _length = (_candidate distance _source) + (_candidate distance _eye);
                        if (_length < _bestLength) then { _bestLength = _length; _best = [_candidate, _candidate distance _source]; };
                    };
                };
            } forEach [
                [3, 0, 0.6], [-3, 0, 0.6], [0, 3, 0.6], [0, -3, 0.6],
                [2.1, 2.1, 0.6], [-2.1, 2.1, 0.6], [2.1, -2.1, 0.6], [-2.1, -2.1, 0.6],
                [6, 0, 0.8], [-6, 0, 0.8], [0, 6, 0.8], [0, -6, 0.8]
            ];
            if (_best isNotEqualTo []) then {
                // Heard through the opening: the detour makes it quieter and a little dull
                _openPath = true;
                _virtual = _best select 0;
                _extra = _best select 1;
                _muffle = 0.25;
                _gain = _baseGain * 0.8;
            };
        };
    } else {
        if (_glass > 0) then {
            // Only glass: dull and quieter, but still clearly there
            _muffle = (0.4 + 0.1 * (_glass - 1)) min 0.7;
            _gain = _baseGain * (0.55 ^ _glass);
        };
    };

    // Echo comes with being indoors (the room is measured in extTick)
    private _speakerIndoors = lineIntersectsSurfaces [_source, _source vectorAdd [0, 0, 12], _listener, _speaker, true, 1] isNotEqualTo [];
    if (GVAR(extIndoor)) then {
        _reverb = 0.45 + ([0, 0.15] select _speakerIndoors);
    } else {
        if (_speakerIndoors) then { _reverb = 0.15; };
    };
};

_speaker setVariable ["jbl_extDebug", [_distance, _walls, _glass, _openPath, _muffle, _gain, _reverb], false];

"jbl_speaker" callExtension ["voice", [netId _speaker, _virtual select 0, _virtual select 1, _virtual select 2, _gain, _range, _muffle, _reverb, _extra]];
