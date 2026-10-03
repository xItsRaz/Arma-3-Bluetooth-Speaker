#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. PartyBoost: links nearby speakers to this one so they all play
 * the same song at the same moment. This speaker becomes the group's leader
 * (or, if it's already linked, its leader adds them).
 *
 * Arguments:
 * 0: Speaker the player used <OBJECT>
 * 1: Player <OBJECT> (for the result message, may be objNull)
 *
 * Return Value:
 * Number of speakers newly linked <NUMBER>
 */

params ["_speaker", ["_player", objNull]];

private _leader = _speaker getVariable [VAR_LEADER, objNull];
if (isNull _leader) then { _leader = _speaker; };

private _followers = (_leader getVariable [VAR_FOLLOWERS, []]) select {!isNull _x};

// Speakers that aren't already in a group (no leader, no followers of their own)
private _candidates = (nearestObjects [_speaker, ["jbl_speaker"], LINK_RADIUS]) select {
    _x != _leader
    && {!(_x in _followers)}
    && {isNull (_x getVariable [VAR_LEADER, objNull])}
    && {(_x getVariable [VAR_FOLLOWERS, []]) isEqualTo []}
};
_candidates resize ((LINK_MAX - 1 - count _followers) min count _candidates max 0);

{
    // Cancel anything the speaker was doing on its own
    _x setVariable [VAR_SESSION, (_x getVariable [VAR_SESSION, 0]) + 1];
    _x setVariable [VAR_LEADER, _leader, true];
} forEach _candidates;

_followers append _candidates;
_leader setVariable [VAR_FOLLOWERS, _followers, true];

// Bring the new followers in line with what the leader is doing right now
if (_candidates isNotEqualTo []) then {
    private _state = [
        _leader getVariable [VAR_PLAYING, false],
        _leader getVariable [VAR_TRACK, 0],
        _leader getVariable [VAR_START, 0]
    ];
    {
        _x setVariable [VAR_PLAYING, _state select 0, true];
        _x setVariable [VAR_TRACK, _state select 1, true];
        _x setVariable [VAR_START, _state select 2, true];
        [QGVAR(sync), [_x, _state]] call CBA_fnc_globalEvent;
    } forEach _candidates;
};

[_player, format ["PartyBoost: %1 speaker(s) linked (%2 of %3 in group)",
    count _candidates, 1 + count _followers, LINK_MAX]] call EFUNC(common,notify);

count _candidates
