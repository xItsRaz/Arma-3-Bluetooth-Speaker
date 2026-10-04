#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Attaches a speaker to a person (backpack) or a vehicle at an exact offset, and
 * remembers where. Anything it was attached to before is let go. It keeps playing.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: What to attach to <OBJECT> (a person or a vehicle)
 * 2: Offset <ARRAY>
 * 3: Turn in degrees <NUMBER>
 * 4: Bone <STRING> ("spine3" on a person, "" on a vehicle)
 * 5: Position name <STRING> (for the menus, default: "")
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_parent", objNull, [objNull]], "_offset", "_turn", "_bone", ["_preset", ""]];

if (isNull _speaker || {isNull _parent}) exitWith {};

// Let go of the old mount
private _oldUnit = _speaker getVariable [VAR_CLIPPED_TO, objNull];
if (!isNull _oldUnit) then { _oldUnit setVariable [VAR_CLIPPED, objNull, true]; };
_speaker setVariable [VAR_CLIPPED_TO, objNull, true];
_speaker setVariable ["jbl_mountedOn", objNull, true];
_speaker setVariable ["jbl_wasMounted", false];

if (_bone == "") then {
    _speaker attachTo [_parent, _offset];
} else {
    _speaker attachTo [_parent, _offset, _bone, true];
};
_speaker setDir _turn; // relative to what it is attached to

_speaker setVariable ["jbl_mountOffset", _offset, true];
_speaker setVariable ["jbl_mountTurn", _turn, true];
_speaker setVariable ["jbl_mountBone", _bone, true];
_speaker setVariable ["jbl_mountPreset", _preset, true];

if (_parent isKindOf "CAManBase") then {
    _speaker setVariable [VAR_CLIPPED_TO, _parent, true];
    _parent setVariable [VAR_CLIPPED, _speaker, true];
} else {
    _speaker setVariable ["jbl_mountedOn", _parent, true];
    _speaker setVariable ["jbl_wasMounted", true];
};
