// CBA settings (Options > Addon Options > JBL Speaker). "Server" ones are forced on everyone.

[
    QGVAR(rangeSpeaker), "SLIDER",
    ["JBL Speaker range (m)", "How far a JBL Speaker can be heard. Past this distance the sound stops."],
    ["JBL Speaker", "Sound"],
    [20, 300, 75, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(rangePartybox), "SLIDER",
    ["JBL PartyBox range (m)", "How far a PartyBox can be heard. Past this distance the sound stops."],
    ["JBL Speaker", "Sound"],
    [50, 600, 200, 0],
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
    QGVAR(useExtension), "CHECKBOX",
    ["Use the sound extension", "Play speakers through jbl_speaker_x64.dll when it is installed: smoother volume, walls and echo. Off = the built-in Arma sound."],
    ["JBL Speaker", "Sound"],
    true,
    0,
    { call FUNC(resyncAll) }
] call CBA_fnc_addSetting;

[
    QGVAR(wallEffects), "LIST",
    ["Walls, echo and open doors", "Only with the sound extension. Off: no effects. Walls and echo: speakers behind walls are quieter and muffled, indoors adds echo. Plus open paths: sound finds its way through open doors and windows (a few more checks per second)."],
    ["JBL Speaker", "Sound"],
    [[0, 1, 2], ["Off", "Walls and echo", "Walls, echo and open paths"], 2],
    0
] call CBA_fnc_addSetting;

[
    QGVAR(muteAll), "CHECKBOX",
    ["Mute all speakers (only for you)", "You hear no speakers at all. Other players are not affected."],
    ["JBL Speaker", "Personal"],
    false,
    0,
    { call FUNC(resyncAll) }
] call CBA_fnc_addSetting;

[
    QGVAR(personalVolume), "LIST",
    ["My speaker volume", "Play every speaker quieter just for you. Other players are not affected."],
    ["JBL Speaker", "Personal"],
    [[0, 1, 2, 3], ["Full", "1 step quieter", "2 steps quieter", "3 steps quieter"], 0],
    0,
    { call FUNC(resyncAll) }
] call CBA_fnc_addSetting;
