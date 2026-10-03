#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. Places a speaker from your inventory.
 * With a preview: LMB place, RMB cancel, mouse wheel rotate. Clip mode skips the preview and
 * attaches the speaker to your backpack.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Clip to backpack <BOOL> (default: false)
 *
 * Return Value:
 * None
 */

params ["_player", ["_clip", false]];

if (!isNil QGVAR(previewActive)) exitWith {};
if !(MAG_SPEAKER in magazines _player) exitWith {};

// Takes the fullest magazine out of the inventory and returns its rounds
private _takeMagazine = {
    params ["_player"];
    private _all = (magazinesAmmo _player) select {(_x select 0) == MAG_SPEAKER};
    private _rounds = selectMax (_all apply {_x select 1});
    _player removeMagazines MAG_SPEAKER;
    private _removed = false;
    {
        if (!_removed && {(_x select 1) == _rounds}) then { _removed = true; } else { _player addMagazine [MAG_SPEAKER, _x select 1]; };
    } forEach _all;
    _rounds
};

if (_clip) exitWith {
    if (backpack _player == "" || {!isNull (_player getVariable [VAR_CLIPPED, objNull])}) exitWith {};
    private _rounds = [_player] call _takeMagazine;
    [QGVAR(create), [_player, getPosASL _player, getDir _player, [0, 0, 1], _rounds, true]] call CBA_fnc_serverEvent;
};

GVAR(previewActive) = true;
GVAR(previewDir) = getDir _player;
GVAR(previewValid) = false;

private _ghost = createSimpleObject ["Land_FMradio_F", [0, 0, 0], true];
private _display = findDisplay 46;

private _end = {
    params ["_handle", "_ghost", "_display", "_downId", "_zoomId"];
    [_handle] call CBA_fnc_removePerFrameHandler;
    _display displayRemoveEventHandler ["MouseButtonDown", _downId];
    _display displayRemoveEventHandler ["MouseZChanged", _zoomId];
    deleteVehicle _ghost;
    hintSilent "";
    GVAR(previewActive) = nil;
};

private _downId = _display displayAddEventHandler ["MouseButtonDown", {
    params ["_display", "_button"];
    if (_button == 0) then { GVAR(previewConfirm) = true; };
    if (_button == 1) then { GVAR(previewCancel) = true; };
    true
}];
private _zoomId = _display displayAddEventHandler ["MouseZChanged", {
    params ["_display", "_zoom"];
    GVAR(previewDir) = GVAR(previewDir) + (_zoom * 15);
    true
}];

GVAR(previewConfirm) = false;
GVAR(previewCancel) = false;
hint parseText "<t size='1.1'>Place speaker</t><br/>Left click: place<br/>Right click: cancel<br/>Mouse wheel: rotate";

[{
    params ["_args", "_handle"];
    _args params ["_player", "_ghost", "_display", "_downId", "_zoomId", "_end", "_takeMagazine"];

    private _abort = GVAR(previewCancel) || {!alive _player} || {!isNull objectParent _player} || {_player getVariable ["ACE_isUnconscious", false]};

    // Aim point 1.2 m in front of you, snapped to the surface below it
    private _from = _player modelToWorldWorld [0, 1.2, 1];
    private _hits = lineIntersectsSurfaces [_from, _from vectorAdd [0, 0, -3], _player, _ghost, true, 1];
    GVAR(previewValid) = _hits isNotEqualTo [];
    if (GVAR(previewValid)) then {
        (_hits select 0) params ["_posASL", "_normal"];
        _ghost setDir GVAR(previewDir);
        _ghost setPosASL _posASL;
        _ghost setVectorUp _normal;
        GVAR(previewPos) = _posASL;
        GVAR(previewNormal) = _normal;
    };
    _ghost hideObject !GVAR(previewValid);

    if (_abort) exitWith { [_handle, _ghost, _display, _downId, _zoomId] call _end; };

    if (GVAR(previewConfirm) && {GVAR(previewValid)}) exitWith {
        private _posASL = GVAR(previewPos);
        private _normal = GVAR(previewNormal);
        private _dir = GVAR(previewDir);
        [_handle, _ghost, _display, _downId, _zoomId] call _end;
        private _rounds = [_player] call _takeMagazine;
        [QGVAR(create), [_player, _posASL, _dir, _normal, _rounds, false]] call CBA_fnc_serverEvent;
    };
    GVAR(previewConfirm) = false;
}, 0, [_player, _ghost, _display, _downId, _zoomId, _end, _takeMagazine]] call CBA_fnc_addPerFrameHandler;
