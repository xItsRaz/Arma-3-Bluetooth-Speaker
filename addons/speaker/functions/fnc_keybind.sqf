#include "..\script_component.hpp"
/*
 * Author: Raz
 * Keybind handler. Acts on the nearest speaker (within 5 m) you're allowed to control.
 *
 * Arguments:
 * 0: Action <STRING> ("playStop", "next", "volumeUp", "volumeDown", "mute")
 *
 * Return Value:
 * Handled <BOOL>
 */

params ["_action"];

if (_action == "mute") exitWith {
    private _mute = !EGVAR(audio,muteAll);
    [QEGVAR(audio,muteAll), _mute] call CBA_settings_fnc_set;
    hintSilent (["Speakers unmuted", "All speakers muted (only for you)"] select _mute);
    true
};

private _speaker = ((nearestObjects [player, ["btspk_speaker"], 5]) select {
    [_x, player] call EFUNC(common,canControl)
}) param [0, objNull];
if (isNull _speaker) exitWith {false};

switch (_action) do {
    case "playStop": {
        [_speaker, player, ["play", "stop"] select (_speaker getVariable [VAR_PLAYING, false])] call FUNC(send);
    };
    case "next": {
        [_speaker, player, "next"] call FUNC(send);
    };
    case "volumeUp";
    case "volumeDown": {
        private _volume = (_speaker getVariable [VAR_VOLUME, VOLUME_DEFAULT]) + ([-1, 1] select (_action == "volumeUp"));
        [_speaker, player, "volume", _volume max 1 min VOLUME_MAX] call FUNC(send);
        hintSilent format ["Speaker volume: %1", _volume max 1 min VOLUME_MAX];
    };
};
true
