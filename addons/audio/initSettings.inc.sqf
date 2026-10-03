// CBA settings (Options > Addon Options > JBL Speaker). "Server" ones are forced on everyone.

[
    QGVAR(rangeSpeaker), "SLIDER",
    ["JBL Speaker range (m)", "How far a JBL Speaker can be heard. Past this distance the sound stops."],
    ["JBL Speaker", "Sound"],
    [20, 300, 75, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(linkRadius), "SLIDER",
    ["PartyBoost link radius (m)", "Speakers within this distance join when you link."],
    ["JBL Speaker", "PartyBoost"],
    [5, 50, 15, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(linkMax), "SLIDER",
    ["PartyBoost max speakers", "Most speakers in one PartyBoost group, including the main one."],
    ["JBL Speaker", "PartyBoost"],
    [2, 16, 8, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(muteAll), "CHECKBOX",
    ["Mute all speakers (only for you)", "You hear no speakers at all. Other players are not affected."],
    ["JBL Speaker", "Personal"],
    false,
    0,
    {
        // Apply right away to every speaker in the mission
        if (!hasInterface || {isNil QFUNC(syncLocal)}) exitWith {};
        { [_x] call FUNC(syncLocal); } forEach allMissionObjects "jbl_speaker";
    }
] call CBA_fnc_addSetting;
