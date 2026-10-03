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

private _hasTracks = "count getArray (configFile >> 'jbl_audio_playlist' >> 'tracks') > 0";
private _isPlaying = "_target getVariable ['jbl_playing', false]";

_speaker addAction ["<t color='#ff7a00'>Play</t>", _send, "play", 6, true, true, "", format ["!(%1) && {%2}", _isPlaying, _hasTracks], 3];
_speaker addAction ["Stop", _send, "stop", 6, true, true, "", _isPlaying, 3];
_speaker addAction ["Next track", _send, "next", 5, false, true, "", _isPlaying, 3];
_speaker addAction ["Previous track", _send, "prev", 5, false, true, "", _isPlaying, 3];

// PartyBoost (link several speakers so they play in sync)
private _isFollower = "!isNull (_target getVariable ['jbl_linkLeader', objNull])";
private _isLeader = "(_target getVariable ['jbl_linkFollowers', []]) isNotEqualTo []";
_speaker addAction ["<t color='#3fa9f5'>PartyBoost: link nearby speakers</t>", _send, "link", 3, false, true, "", format ["!(%1)", _isFollower], 3];
_speaker addAction ["<t color='#3fa9f5'>PartyBoost: unlink all</t>", _send, "unlink", 2, false, true, "", _isLeader, 3];
_speaker addAction ["<t color='#3fa9f5'>PartyBoost: unlink this speaker</t>", _send, "unlink", 2, false, true, "", _isFollower, 3];

// Late joiners: catch up with whatever is already playing
[{ [_this] call EFUNC(audio,syncLocal); }, _speaker, 1] call CBA_fnc_waitAndExecute;
