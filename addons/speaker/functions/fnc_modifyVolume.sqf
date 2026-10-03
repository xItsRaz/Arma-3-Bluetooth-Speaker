#include "..\script_component.hpp"
/*
 * Author: Raz
 * ACE modifierFunction for the "Volume" menu: shows the current level, e.g. "Volume (4)".
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

_actionData set [1, format ["Volume (%1)", _target getVariable [VAR_VOLUME, VOLUME_DEFAULT]]];
