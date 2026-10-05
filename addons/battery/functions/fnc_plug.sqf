#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Plugs a speaker into the nearest generator within 5 m.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_player", objNull, [objNull]]];

private _classes = GVAR(generatorClasses) splitString ", ";
private _generators = (nearestObjects [_speaker, _classes, 5]) select {alive _x};

if (_generators isEqualTo []) exitWith {
    [_player, "No generator within 5 m"] call EFUNC(common,notify);
};

_speaker setVariable ["btspk_generator", _generators select 0, true];
[_speaker] call FUNC(update);
[_player, "Plugged into the generator"] call EFUNC(common,notify);
