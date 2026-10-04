#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. A speaker just broke: a puff of smoke.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_speaker", objNull, [objNull]]];

if (!hasInterface || {isNull _speaker}) exitWith {};

// The music of this speaker has stopped on its own; just add the effect
private _smoke = "#particlesource" createVehicleLocal (getPosATL _speaker);
_smoke setParticleParams [
    ["\A3\data_f\ParticleEffects\Universal\Universal", 16, 12, 13, 0], "", "Billboard", 1, 3,
    [0, 0, 0.1], [0, 0, 0.6], 0, 1.2, 1.0, 0.1, [0.15, 0.5],
    [[0.3, 0.3, 0.3, 0.6], [0.5, 0.5, 0.5, 0.3], [0.6, 0.6, 0.6, 0]], [0.8], 1, 0, "", "", _speaker
];
_smoke setParticleRandom [0.5, [0.05, 0.05, 0.05], [0.1, 0.1, 0.2], 0.3, 0.2, [0, 0, 0, 0], 0, 0];
_smoke setDropInterval 0.08;
[{ deleteVehicle _this; }, _smoke, 6] call CBA_fnc_waitAndExecute;
