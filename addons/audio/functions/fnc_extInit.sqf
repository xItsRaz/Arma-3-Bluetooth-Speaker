#include "..\script_component.hpp"
/*
 * Author: Raz
 * Client side, at mission start. Looks for the sound extension (jbl_speaker_x64.dll in the mod
 * folder). If it is there and opens the sound card, speakers play through it. Otherwise
 * everything keeps using Arma's built-in sound.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 */

GVAR(extReady) = false;
GVAR(extVoices) = [];
GVAR(extIndex) = 0;
GVAR(extIndoor) = false;  // are you under a roof (set from the room measurement)
GVAR(extRoomTick) = 0;
GVAR(extRoomSent) = -100; // last room size sent to the extension

// "" means the extension is not installed (or was blocked, e.g. by BattlEye)
// (the array form: this extension only answers calls made as [command, [args]])
private _answer = ("jbl_speaker" callExtension ["init", []]) select 0;

if (_answer select [0, 3] == "ok:") then {
    GVAR(extReady) = true;

    // The extension keeps running when you leave a mission (e.g. back to the editor): silence it
    // at the start of every mission and whenever the mission ends or its display closes
    "jbl_speaker" callExtension ["stop_all", []];
    addMissionEventHandler ["Ended", { "jbl_speaker" callExtension ["stop_all", []]; }];
    [] spawn {
        waitUntil { !isNull findDisplay 46 };
        findDisplay 46 displayAddEventHandler ["Unload", { "jbl_speaker" callExtension ["stop_all", []]; }];
    };
    diag_log format ["JBL Speaker: sound extension active (%1)", _answer];
    addMissionEventHandler ["ExtensionCallback", { _this call FUNC(extEvent) }];
    [LINKFUNC(extTick), 0.05] call CBA_fnc_addPerFrameHandler;
} else {
    diag_log format ["JBL Speaker: sound extension not used (%1)", ["not installed or blocked", _answer] select (_answer != "")];
};
