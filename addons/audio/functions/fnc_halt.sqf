#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Stops a speaker for good reason (loaded into a vehicle, picked up, broken,
 * battery empty): takes it out of its PartyBoost group and stops the music.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]]];

if (!isServer || {isNull _speaker}) exitWith {};

[_speaker] call FUNC(unlink);
if (_speaker getVariable [VAR_PLAYING, false]) then { [_speaker, "stop"] call FUNC(command); };
