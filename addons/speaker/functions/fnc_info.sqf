#include "..\script_component.hpp"
/*
 * Author: Raz
 * Shows the speaker's owner, lock, PartyBoost status, volume and song (local hint).
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params ["_target"];

private _owner = _target getVariable [VAR_OWNER_NAME, ""];
private _leader = _target getVariable [VAR_LEADER, objNull];
private _followers = count ((_target getVariable [VAR_FOLLOWERS, []]) select {!isNull _x});
private _titles = getArray (configFile >> QEGVAR(audio,playlist) >> "titles");

private _link = "not linked";
if (_followers > 0) then { _link = format ["main speaker + %1 linked", _followers]; };
if (!isNull _leader) then { _link = "linked to another speaker"; };

hint format ["JBL Speaker\n\nOwner: %1\nLocked: %2\nPartyBoost: %3\nVolume: %4\nNow playing: %5",
    ["nobody", _owner] select (_owner != ""),
    ["no", "yes"] select (_owner != "" && {_target getVariable [VAR_LOCKED, true]}),
    _link,
    _target getVariable [VAR_VOLUME, VOLUME_DEFAULT],
    ["nothing", _titles param [_target getVariable [VAR_TRACK, 0], "?"]] select (_target getVariable [VAR_PLAYING, false])
];
