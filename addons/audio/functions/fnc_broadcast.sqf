#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Copies a speaker's playback state to its Party Link followers and
 * tells every player to (re)start the sound.
 *
 * Arguments:
 * 0: Speaker (the group leader) <OBJECT>
 * 1: Only these members <ARRAY> (default: [] = the speaker and all its followers)
 *
 * Return Value:
 * None
 */

params ["_speaker", ["_members", []]];

private _state = [
    _speaker getVariable [VAR_PLAYING, false],
    _speaker getVariable [VAR_TRACK, 0],
    _speaker getVariable [VAR_START, 0],
    _speaker getVariable [VAR_VOLUME, VOLUME_DEFAULT]
];

if (_members isEqualTo []) then {
    _members = [_speaker] + ((_speaker getVariable [VAR_FOLLOWERS, []]) select {!isNull _x});
};

{
    if (_x != _speaker) then {
        _x setVariable [VAR_PLAYING, _state select 0, true];
        _x setVariable [VAR_TRACK, _state select 1, true];
        _x setVariable [VAR_START, _state select 2, true];
        _x setVariable [VAR_VOLUME, _state select 3, true];
    };
    [QGVAR(sync), [_x, _state]] call CBA_fnc_globalEvent;
    // The battery drains at a different speed now
    ["btspk_battery_rebase", [_x]] call CBA_fnc_localEvent;
} forEach _members;
