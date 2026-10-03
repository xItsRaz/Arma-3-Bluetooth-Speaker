#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Restarts this player's sound for every speaker, e.g. after a
 * personal setting (mute, personal volume) changed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

if (!hasInterface || {isNil QFUNC(syncLocal)}) exitWith {};
{ [_x] call FUNC(syncLocal); } forEach allMissionObjects "jbl_speaker";
