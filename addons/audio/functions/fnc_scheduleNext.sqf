#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Moves to the next track when the current one ends.
 * Does nothing if the speaker is gone or a newer command started a new session.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Session id at the time the track started <NUMBER>
 *
 * Return Value:
 * None
 */

params ["_speaker", "_session"];

private _durations = getArray (configFile >> QGVAR(playlist) >> "durations");
private _duration = _durations select (_speaker getVariable [VAR_TRACK, 0]);
private _remaining = (_speaker getVariable [VAR_START, 0]) + _duration - NOW;

[{
    params ["_speaker", "_session"];
    if (isNull _speaker || {(_speaker getVariable [VAR_SESSION, 0]) != _session}) exitWith {};
    [_speaker, objNull, "next"] call EFUNC(common,command);
}, [_speaker, _session], _remaining max 0] call CBA_fnc_waitAndExecute;
