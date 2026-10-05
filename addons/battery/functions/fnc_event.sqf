#include "..\script_component.hpp"
/*
 * Author: Raz
 * Server only. A scheduled battery event fired: "low" (10%), "empty" or "full".
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: Token <NUMBER>
 * 2: Event <STRING>
 *
 * Return Value:
 * None
 */

params ["_speaker", "_token", "_event"];

if (isNull _speaker || {(_speaker getVariable ["btspk_batToken", 0]) != _token}) exitWith {};

private _owner = _speaker getVariable [VAR_OWNER, ""];
private _tell = {
    params ["_message"];
    { if (getPlayerUID _x == _owner) then { [_x, _message] call EFUNC(common,notify); }; } forEach allPlayers;
};

switch (_event) do {
    case "low": {
        [_speaker] call FUNC(rebase); // sets the low flag
        ["Your speaker's battery is at 10%"] call _tell;
    };
    case "empty": {
        [_speaker] call FUNC(rebase); // sets the dead flag
        [_speaker] call EFUNC(audio,halt);
        ["Your speaker ran out of battery"] call _tell;
    };
    case "full": {
        _speaker setVariable [VAR_CHARGING, "", true];
        [_speaker] call FUNC(rebase);
        ["Your speaker is fully charged"] call _tell;
    };
};
