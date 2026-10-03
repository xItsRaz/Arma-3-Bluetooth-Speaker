#include "..\script_component.hpp"
/*
 * Author: Raz
 * Speaker object init. Runs on every machine, including players who join late.
 * The menu itself is ACE config (CfgVehicles.hpp).
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

// Late joiners: catch up with whatever is already playing
[{ [_this] call EFUNC(audio,syncLocal); }, _speaker, 1] call CBA_fnc_waitAndExecute;
