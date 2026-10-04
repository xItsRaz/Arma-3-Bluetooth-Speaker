#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only, every few seconds. A speaker mounted on a vehicle that was destroyed or deleted
 * falls to the ground where it is.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

{
    private _speaker = _x;
    if (isNull _speaker) then { continue; };
    private _vehicle = _speaker getVariable ["jbl_mountedOn", objNull];
    if (!isNull _vehicle && {alive _vehicle}) then { continue; };
    // Mounted on something that is gone? (a null object we can't see through a variable: check the flag)
    if (isNull _vehicle && {!(_speaker getVariable ["jbl_wasMounted", false])}) then { continue; };

    detach _speaker;
    _speaker setVariable ["jbl_mountedOn", objNull, true];
    _speaker setVariable ["jbl_wasMounted", false];
    private _pos = getPosATL _speaker;
    _pos set [2, 0];
    _speaker setPosATL _pos;
    _speaker setVectorUp [0, 0, 1];
} forEach (EGVAR(battery,registry) select {!isNull (_x getVariable ["jbl_mountedOn", objNull]) || {_x getVariable ["jbl_wasMounted", false]}});
