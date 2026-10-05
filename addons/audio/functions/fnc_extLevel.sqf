#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. How loud the music of a speaker is right now (0-1), for lights. Needs the sound
 * extension; independent of how far you are.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * Level 0-1, or -1 when the speaker is not played through the extension <NUMBER>
 */

params ["_speaker"];

if (isNil QGVAR(extReady) || {!(_speaker getVariable ["btspk_extVoice", false])}) exitWith {-1};

parseNumber ("btspk_speaker" callExtension ["level", [netId _speaker]] select 0)
