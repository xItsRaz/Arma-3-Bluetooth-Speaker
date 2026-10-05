#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Stops a speaker's voice in the sound extension (does nothing if it has none).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params ["_speaker"];

if (isNil QGVAR(extReady) || {!(_speaker getVariable ["btspk_extVoice", false])}) exitWith {};

"btspk_speaker" callExtension ["stop", [netId _speaker]];
_speaker setVariable ["btspk_extVoice", false];
GVAR(extVoices) deleteAt (GVAR(extVoices) find _speaker);
