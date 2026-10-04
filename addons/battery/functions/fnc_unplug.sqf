#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. Unplugs a speaker from its generator.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Player <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]], ["_player", objNull, [objNull]]];

_speaker setVariable ["jbl_generator", objNull, true];
[_speaker] call FUNC(update);
[_player, "Unplugged"] call EFUNC(common,notify);
