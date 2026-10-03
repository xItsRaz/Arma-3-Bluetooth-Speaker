#include "..\script_component.hpp"
/*
 * Author: Raz
 * ACE modifierFunction for the "Speaker" menu: shows the song and volume in its name,
 * e.g. "Speaker: Omer Adam - Tehom (vol 4)". Runs every frame while visible, so keep it cheap.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 * 2: Action params <ANY>
 * 3: Action data <ARRAY> (modified in place)
 *
 * Return Value:
 * None
 */

params ["_target", "", "", "_actionData"];

if !(_target getVariable [VAR_PLAYING, false]) exitWith {
    _actionData set [1, "Speaker"];
};

private _title = getArray (configFile >> QEGVAR(audio,playlist) >> "titles") param [_target getVariable [VAR_TRACK, 0], "?"];
_actionData set [1, format ["Speaker: %1 (vol %2)", _title, _target getVariable [VAR_VOLUME, VOLUME_DEFAULT]]];
