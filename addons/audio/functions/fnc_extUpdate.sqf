#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Works out how one speaker should sound for you right now and sends it to the
 * sound extension: position, muffling through walls, echo indoors, and sound that reaches you
 * through an open door or window.
 *
 * Open paths: when something blocks the straight line to the speaker, we look for a spot a few
 * metres around the speaker that the speaker can "see" and that you can "see". The sound then
 * comes from that spot, with the extra distance the detour costs. Walls and echo are cheaper
 * (setting "Walls, echo and open doors").
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
private _gain = _speaker getVariable ["jbl_extGain", 0.7];
private _source = (getPosASL _speaker) vectorAdd [0, 0, 0.25];
private _virtual = _source;
private _muffle = 0;
private _reverb = 0;
private _extra = 0;

private _distance = _eye distance _source;
private _mode = GVAR(wallEffects);

// Nothing to work out when it is out of earshot or effects are off
if (_mode > 0 && {_distance < _range}) then {
    private _ignore = [vehicle player, _speaker];
    private _blocked = lineIntersectsSurfaces [_eye, _source, _ignore select 0, _speaker, true, 3];

    if (_blocked isNotEqualTo []) then {
        // A wall: quieter and muffled by default
        private _walls = count _blocked;
        _muffle = (0.6 + 0.2 * (_walls - 1)) min 1;
        _gain = _gain * (0.55 / _walls);

        if (_mode > 1) then {
            // Look for an open path: points around the speaker, closest total detour wins
            private _best = [];
            private _bestLength = 1e9;
            {
                private _offset = _x;
                private _candidate = _source vectorAdd _offset;
                private _clearFromSpeaker = lineIntersectsSurfaces [_source, _candidate, _speaker, objNull, false, 1] isEqualTo [];
                if (_clearFromSpeaker) then {
                    private _clearToListener = lineIntersectsSurfaces [_candidate, _eye, _ignore select 0, _speaker, false, 1] isEqualTo [];
                    if (_clearToListener) then {
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
                // Heard through the opening: the detour makes it quieter and a little dull, not muffled
                _virtual = _best select 0;
                _extra = _best select 1;
                _muffle = 0.3;
                _gain = (_speaker getVariable ["jbl_extGain", 0.7]) * 0.8;
            };
        };
    };

    // Echo: you or the speaker are under a roof or ceiling
    private _roofed = {
        params ["_position"];
        lineIntersectsSurfaces [_position, _position vectorAdd [0, 0, 12], vehicle player, objNull, true, 1] isNotEqualTo []
    };
    if ([_eye] call _roofed) then { _reverb = _reverb + 0.3; };
    if ([_source] call _roofed) then { _reverb = _reverb + 0.2; };
};

"jbl_speaker" callExtension ["voice", [netId _speaker, _virtual select 0, _virtual select 1, _virtual select 2, _gain, _range, _muffle, _reverb min 0.6, _extra]];
