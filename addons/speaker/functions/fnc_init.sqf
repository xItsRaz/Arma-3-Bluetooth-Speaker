#include "..\script_component.hpp"
/*
 * Author: Raz
 * Speaker object init. Runs on every machine, including players who join late.
 * The scroll-menu actions are temporary: Session 3 replaces them with ACE actions.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]]];

if (isNull _speaker || {_speaker getVariable [QGVAR(initDone), false]}) exitWith {};
_speaker setVariable [QGVAR(initDone), true];

// PartyBoost: a deleted speaker leaves its group (a deleted leader ends it)
if (isServer) then {
    _speaker addEventHandler ["Deleted", { [_this select 0] call EFUNC(audio,unlink); }];
};

if (!hasInterface) exitWith {};

private _send = {
    params ["_target", "_caller", "", "_command"];
    [QEGVAR(common,command), [_target, _caller, _command]] call CBA_fnc_serverEvent;
};

// Conditions are strings evaluated every frame while you look at the speaker: keep them cheap.
// _target = speaker, _this = you. The server checks permission again on every command.
private _can = "[_target, _this] call jbl_common_fnc_canControl";
private _hasTracks = "count getArray (configFile >> 'jbl_audio_playlist' >> 'tracks') > 0";
private _isPlaying = "_target getVariable ['jbl_playing', false]";
private _only = { format ["(%1) && {%2}", _can, _this] };

_speaker addAction ["<t color='#ff7a00'>Play</t>", _send, "play", 6, true, true, "", format ["!(%1) && {%2}", _isPlaying, _hasTracks] call _only, 3];
_speaker addAction ["Stop", _send, "stop", 6, true, true, "", _isPlaying call _only, 3];
_speaker addAction ["Next track", _send, "next", 5, false, true, "", _isPlaying call _only, 3];
_speaker addAction ["Previous track", _send, "prev", 5, false, true, "", _isPlaying call _only, 3];

// PartyBoost (link several speakers so they play in sync)
private _isFollower = "!isNull (_target getVariable ['jbl_linkLeader', objNull])";
private _isLeader = "(_target getVariable ['jbl_linkFollowers', []]) isNotEqualTo []";
_speaker addAction ["<t color='#3fa9f5'>PartyBoost: link nearby speakers</t>", _send, "link", 3, false, true, "", format ["!(%1)", _isFollower] call _only, 3];
_speaker addAction ["<t color='#3fa9f5'>PartyBoost: unlink all</t>", _send, "unlink", 2, false, true, "", _isLeader call _only, 3];
_speaker addAction ["<t color='#3fa9f5'>PartyBoost: unlink this speaker</t>", _send, "unlink", 2, false, true, "", _isFollower call _only, 3];

// Ownership
private _owned = "(_target getVariable ['jbl_owner', '']) != ''";
private _ownerOrAdmin = "((_target getVariable ['jbl_owner', '']) == getPlayerUID _this || {[_this] call jbl_common_fnc_isAdmin})";
private _ownerRules = "jbl_common_controlMode == 0";
_speaker addAction ["<t color='#9be564'>Claim speaker</t>", _send, "claim", 1, false, true, "",
    format ["%1 && {!(%2)} && {jbl_common_unownedMode == 0 || {[_this] call jbl_common_fnc_isAdmin}}", _ownerRules, _owned], 3];
_speaker addAction ["<t color='#9be564'>Unlock (let anyone use it)</t>", _send, "unlock", 1, false, true, "",
    format ["%1 && {%2} && {_target getVariable ['jbl_locked', true]} && {%3}", _ownerRules, _owned, _ownerOrAdmin], 3];
_speaker addAction ["<t color='#9be564'>Lock to owner</t>", _send, "lock", 1, false, true, "",
    format ["%1 && {%2} && {!(_target getVariable ['jbl_locked', true])} && {%3}", _ownerRules, _owned, _ownerOrAdmin], 3];
_speaker addAction ["<t color='#9be564'>Give up ownership</t>", _send, "release", 0, false, true, "",
    format ["%1 && {%2} && {%3}", _ownerRules, _owned, _ownerOrAdmin], 3];

// Info for everyone: owner, lock, PartyBoost, song
_speaker addAction ["Speaker info", {
    params ["_target"];
    private _owner = _target getVariable [VAR_OWNER_NAME, ""];
    private _leader = _target getVariable [VAR_LEADER, objNull];
    private _followers = count ((_target getVariable [VAR_FOLLOWERS, []]) select {!isNull _x});
    private _titles = getArray (configFile >> QEGVAR(audio,playlist) >> "titles");
    private _track = _target getVariable [VAR_TRACK, 0];
    private _link = "not linked";
    if (_followers > 0) then { _link = format ["main speaker + %1 linked", _followers]; };
    if (!isNull _leader) then { _link = "linked to another speaker"; };
    hint format ["JBL Speaker\n\nOwner: %1\nLocked: %2\nPartyBoost: %3\nNow playing: %4",
        ["nobody", _owner] select (_owner != ""),
        ["no", "yes"] select (_owner != "" && {_target getVariable [VAR_LOCKED, true]}),
        _link,
        ["nothing", _titles param [_track, "?"]] select (_target getVariable [VAR_PLAYING, false])
    ];
}, nil, 0, false, true, "", "true", 3];

// Late joiners: catch up with whatever is already playing
[{ [_this] call EFUNC(audio,syncLocal); }, _speaker, 1] call CBA_fnc_waitAndExecute;
