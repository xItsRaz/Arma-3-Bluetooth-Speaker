#include "..\script_component.hpp"
/*
 * Author: Raz
 * ACE insertChildren for "Pick a song": one action per song in the packed playlist.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 * 2: Action params <ANY>
 *
 * Return Value:
 * Child actions <ARRAY>
 */

params ["_target"];

private _titles = getArray (configFile >> QEGVAR(audio,playlist) >> "titles");
private _current = [-1, _target getVariable [VAR_TRACK, 0]] select (_target getVariable [VAR_PLAYING, false]);

private _children = [];
{
    private _name = [_x, format ["> %1", _x]] select (_forEachIndex == _current);
    private _action = [
        format ["jbl_speaker_track%1", _forEachIndex], _name, "",
        { params ["_target", "_player", "_index"]; [_target, _player, "track", _index] call FUNC(send); },
        { true }, {}, _forEachIndex
    ] call ace_interact_menu_fnc_createAction;
    _children pushBack [_action, [], _target];
} forEach _titles;

_children
