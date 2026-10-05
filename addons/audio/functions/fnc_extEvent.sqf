#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side. ExtensionCallback event from the sound extension ("started", "ended", "error").
 * On "error" (a file the extension can't play) that speaker falls back to the built-in sound.
 *
 * Arguments:
 * 0: Extension name <STRING>
 * 1: Function <STRING>
 * 2: Data <STRING> (the speaker's net id, for "error": "netId|reason")
 *
 * Return Value:
 * None
 */

params ["_name", "_function", "_data"];

if (_name != "btspk_speaker" || {_function != "error"}) exitWith {};

private _parts = _data splitString "|";
private _speaker = objectFromNetId (_parts param [0, ""]);
diag_log format ["Bluetooth Speaker: extension error: %1", _data];

if (isNull _speaker) exitWith {};
if (EGVAR(common,notifications) > 0) then {
    systemChat format ["Speaker: the sound extension could not play this track (%1). Using the built-in sound.", _parts param [1, "unknown error"]];
};
[_speaker, [], true] call FUNC(syncLocal);
