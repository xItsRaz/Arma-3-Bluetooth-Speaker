#include "..\script_component.hpp"
/*
 * Author: Raz
 * Killed event handler for every man: if a speaker is clipped to them, ask the server to drop it.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 */

params ["_unit"];

if (isNull (_unit getVariable [VAR_CLIPPED, objNull])) exitWith {};
[QGVAR(drop), [_unit, 0.5]] call CBA_fnc_serverEvent;
