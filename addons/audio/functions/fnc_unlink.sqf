#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. PartyBoost: takes a speaker out of its group and stops it.
 * Used on the leader, it breaks up the whole group (the leader keeps playing).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT> (for the result message, may be objNull)
 *
 * Return Value:
 * None
 */

params ["_speaker", ["_player", objNull]];

private _stop = {
    params ["_member"];
    _member setVariable [VAR_LEADER, objNull, true];
    _member setVariable [VAR_PLAYING, false, true];
    [QGVAR(sync), [_member, [false, 0, 0]]] call CBA_fnc_globalEvent;
};

private _leader = _speaker getVariable [VAR_LEADER, objNull];

if (isNull _leader) then {
    // Leader (or a speaker that isn't linked): release every follower
    private _followers = (_speaker getVariable [VAR_FOLLOWERS, []]) select {!isNull _x};
    { [_x] call _stop; } forEach _followers;
    _speaker setVariable [VAR_FOLLOWERS, [], true];
    if (_followers isNotEqualTo []) then {
        [_player, format ["PartyBoost: group ended, %1 speaker(s) unlinked", count _followers]] call EFUNC(common,notify);
    };
} else {
    // Follower: leave the group
    _leader setVariable [VAR_FOLLOWERS, (_leader getVariable [VAR_FOLLOWERS, []]) - [_speaker, objNull], true];
    [_speaker] call _stop;
    [_player, "PartyBoost: speaker unlinked"] call EFUNC(common,notify);
};
