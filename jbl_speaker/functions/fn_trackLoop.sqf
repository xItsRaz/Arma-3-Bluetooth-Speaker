/*
    JBL_fnc_trackLoop
    Server only (spawned). Moves to the next track when the current one ends.
    Exits early if the speaker is deleted or a newer command started a new session.
*/
params ["_speaker", "_session"];

private _durations = getArray (configFile >> "JBL_Playlist" >> "durations");
private _duration = _durations select (_speaker getVariable ["jbl_track", 0]);
private _end = (_speaker getVariable ["jbl_start", 0]) + _duration;

private _stale = { isNull _speaker || {(_speaker getVariable ["jbl_session", 0]) != _session} };

waitUntil {
    sleep 0.5;
    (call _stale) || {([time, serverTime] select isMultiplayer) >= _end}
};

if (call _stale) exitWith {};
[_speaker, "next"] call JBL_fnc_command;
