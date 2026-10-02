/*
    JBL_fnc_init
    Turns an object into a speaker. Runs on every machine (object init EH).
    To use on any other object from a mission: [_obj] remoteExec ["JBL_fnc_init", 0, true];
*/
params [["_speaker", objNull, [objNull]]];

if (isNull _speaker || {_speaker getVariable ["jbl_initDone", false]}) exitWith {};
_speaker setVariable ["jbl_initDone", true];

if (isServer) then {
    if (isNil {_speaker getVariable "jbl_range"}) then {
        _speaker setVariable ["jbl_range", 100, true];
    };
};

if (!hasInterface) exitWith {};

private _hasTracks = "count getArray (configFile >> 'JBL_Playlist' >> 'tracks') > 0";

_speaker addAction [
    "<t color='#ff7a00'>Play</t>",
    { [_this select 0, "play"] remoteExecCall ["JBL_fnc_command", 2]; },
    nil, 6, true, true, "",
    format ["!(_target getVariable ['jbl_playing', false]) && {%1}", _hasTracks], 3
];

_speaker addAction [
    "Stop",
    { [_this select 0, "stop"] remoteExecCall ["JBL_fnc_command", 2]; },
    nil, 6, true, true, "",
    "_target getVariable ['jbl_playing', false]", 3
];

_speaker addAction [
    "Next track",
    { [_this select 0, "next"] remoteExecCall ["JBL_fnc_command", 2]; },
    nil, 5, false, true, "",
    "_target getVariable ['jbl_playing', false]", 3
];

_speaker addAction [
    "Previous track",
    { [_this select 0, "prev"] remoteExecCall ["JBL_fnc_command", 2]; },
    nil, 5, false, true, "",
    "_target getVariable ['jbl_playing', false]", 3
];

_speaker addAction [
    "Change range",
    {
        params ["_target"];
        private _ranges = [25, 50, 100, 200];
        private _i = _ranges find (_target getVariable ["jbl_range", 100]);
        hintSilent format ["Speaker range: %1 m", _ranges select ((_i + 1) mod count _ranges)];
        [_target, "range"] remoteExecCall ["JBL_fnc_command", 2];
    },
    nil, 4, false, true, "", "true", 3
];

// JIP / late init: catch up with whatever is already playing
[_speaker] spawn {
    params ["_speaker"];
    sleep 1;
    [_speaker] call JBL_fnc_syncLocal;
};
