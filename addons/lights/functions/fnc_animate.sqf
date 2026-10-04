#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side, about 15 times a second. Pulses each light on the beat and cycles its colour.
 * The beat is computed from the song's start time, so every player sees the same beat.
 * With the sound extension the light follows the real loudness of the music instead.
 * (Without it every song is 120 BPM.)
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

private _bpm = 120;

{
    _x params ["_speaker", "_light"];
    private _beats = (NOW - (_speaker getVariable [VAR_START, 0])) * _bpm / 60;
    private _phase = _beats mod 1;

    // Colour: one full turn of the colour wheel every 8 beats (HSV with full saturation)
    private _hue = ((_beats / 8) mod 1) * 6;
    private _sector = floor _hue;
    private _fade = _hue - _sector;
    private _color = [[1, _fade, 0], [1 - _fade, 1, 0], [0, 1, _fade], [0, 1 - _fade, 1], [_fade, 0, 1], [1, 0, 1 - _fade]] select _sector;

    // Bright flash on the beat that fades out before the next one
    private _brightness = 0.3 + 3 * (1 - _phase) ^ 3;
    private _level = [_speaker] call EFUNC(audio,extLevel);
    if (_level >= 0) then { _brightness = 0.3 + 5 * (_level min 0.6); };

    _light setLightColor _color;
    _light setLightBrightness _brightness;
} forEach GVAR(active);
