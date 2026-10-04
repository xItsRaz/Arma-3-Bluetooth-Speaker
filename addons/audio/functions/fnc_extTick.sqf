#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side, 20 times a second. Tells the extension where you are and where you look, and
 * refreshes one playing speaker per tick (so each is refreshed a few times a second).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

// Forget speakers that were deleted
GVAR(extVoices) = GVAR(extVoices) select {!isNull _x};
if (GVAR(extVoices) isEqualTo []) exitWith {};

private _eye = AGLToASL positionCameraToWorld [0, 0, 0];
private _direction = (AGLToASL positionCameraToWorld [0, 0, 1]) vectorDiff _eye;
"jbl_speaker" callExtension ["listener", [_eye select 0, _eye select 1, _eye select 2, _direction select 0, _direction select 1, _direction select 2]];

GVAR(extIndex) = (GVAR(extIndex) + 1) mod count GVAR(extVoices);
[GVAR(extVoices) select GVAR(extIndex), _eye] call FUNC(extUpdate);
