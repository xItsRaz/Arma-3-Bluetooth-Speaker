#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side, 20 times a second. Tells the extension where you are and where you look, refreshes
 * one playing speaker per tick (so each is refreshed a few times a second), and twice a second
 * measures the room you are in for the echo.
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
"btspk_speaker" callExtension ["listener", [_eye select 0, _eye select 1, _eye select 2, _direction select 0, _direction select 1, _direction select 2]];

// The room: a roof over you and how far the walls are in 8 directions (about twice a second)
GVAR(extRoomTick) = (GVAR(extRoomTick) + 1) mod 10;
if (GVAR(extRoomTick) == 0 && {GVAR(wallEffects) > 0}) then {
    private _roofed = lineIntersectsSurfaces [_eye, _eye vectorAdd [0, 0, 12], vehicle player, objNull, true, 1] isNotEqualTo [];
    GVAR(extIndoor) = _roofed;
    private _size = 30; // open air
    if (_roofed) then {
        private _total = 0;
        for "_angle" from 0 to 315 step 45 do {
            private _end = _eye vectorAdd [40 * sin _angle, 40 * cos _angle, 0];
            private _hits = lineIntersectsSurfaces [_eye, _end, vehicle player, objNull, true, 1, "GEOM", "GEOM"];
            _total = _total + ([40, _eye distance ((_hits select 0) select 0)] select (_hits isNotEqualTo []));
        };
        // Average distance to the walls, doubled: roughly how wide the room is
        _size = (_total / 8) * 2;
    };
    if (abs (_size - GVAR(extRoomSent)) > 1) then {
        GVAR(extRoomSent) = _size;
        "btspk_speaker" callExtension ["room", [_size]];
    };
};

GVAR(extIndex) = (GVAR(extIndex) + 1) mod count GVAR(extVoices);
[GVAR(extVoices) select GVAR(extIndex), _eye] call FUNC(extUpdate);

// Debug readout for the nearest speaker (Addon Options > Bluetooth Speaker > Sound)
if (GVAR(debug)) then {
    private _distances = GVAR(extVoices) apply {player distance _x};
    private _nearest = GVAR(extVoices) select (_distances find selectMin _distances);
    private _info = _nearest getVariable ["btspk_extDebug", []];
    if (_info isNotEqualTo []) then {
        _info params ["_distance", "_walls", "_glass", "_open", "_muffle", "_gain", "_reverb"];
        hintSilent format [
            "Sound debug (nearest speaker)\nDistance: %1 m\nWalls: %2   Glass: %3   Open path: %4\nMuffle: %5   Gain: %6\nEcho: %7   Room: %8 m (%9)",
            _distance toFixed 1, _walls, _glass, ["no", "yes"] select _open, _muffle toFixed 2, _gain toFixed 2,
            _reverb toFixed 2, GVAR(extRoomSent) toFixed 0, ["outdoors", "indoors"] select GVAR(extIndoor)
        ];
    };
};
