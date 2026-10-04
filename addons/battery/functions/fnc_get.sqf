#include "..\script_component.hpp"
/*
 * Author: Raz
 * Current battery of a speaker in percent. Works on every machine: it is computed from the
 * [charge, time, rate] the server stored, so nothing is sent while a speaker just plays.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * Battery percent 0-100 <NUMBER>
 */

params [["_speaker", objNull, [objNull]]];

if (!GVAR(enabled) || {_speaker isKindOf "jbl_partybox" && {!GVAR(partyboxBattery)}}) exitWith {100};

(_speaker getVariable [VAR_BAT, [1, 0, 0]]) params ["_charge", "_time", "_rate"];
((((_charge + _rate * (NOW - _time)) max 0) min 1) * 100)
