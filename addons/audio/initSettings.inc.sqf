// CBA settings (Options > Addon Options > Bluetooth Speaker). "Server" ones are forced on everyone.

[
    QGVAR(rangeSpeaker), "SLIDER",
    ["Bluetooth Speaker range (m)", "How far a Bluetooth Speaker can be heard. Past this distance the sound stops."],
    ["Bluetooth Speaker", "Sound"],
    [20, 300, 75, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(rangeParty), "SLIDER",
    ["Bluetooth Party Speaker range (m)", "How far a Party Speaker can be heard. Past this distance the sound stops."],
    ["Bluetooth Speaker", "Sound"],
    [50, 600, 200, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(linkRadius), "SLIDER",
    ["Party Link link radius (m)", "Speakers within this distance join when you link."],
    ["Bluetooth Speaker", "Party Link"],
    [5, 50, 15, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(linkMax), "SLIDER",
    ["Party Link max speakers", "Most speakers in one Party Link group, including the main one."],
    ["Bluetooth Speaker", "Party Link"],
    [2, 16, 8, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(useExtension), "CHECKBOX",
    ["Use the sound extension", "Play speakers through btspk_speaker_x64.dll when it is installed: smoother volume, walls and echo. Off = the built-in Arma sound."],
    ["Bluetooth Speaker", "Sound"],
    true,
    0,
    { call FUNC(resyncAll) }
] call CBA_fnc_addSetting;

[
    QGVAR(wallEffects), "LIST",
    ["Walls, echo and open doors", "Only with the sound extension. Off: no effects. Walls and echo: speakers behind walls are quieter and muffled, indoors adds echo. Plus open paths: sound finds its way through open doors and windows (a few more checks per second)."],
    ["Bluetooth Speaker", "Sound"],
    [[0, 1, 2], ["Off", "Walls and echo", "Walls, echo and open paths"], 2],
    0
] call CBA_fnc_addSetting;

[
    QGVAR(extLoudness), "SLIDER",
    ["Speaker loudness (sound extension)", "How loud speakers are for you when played through the sound extension. Other players are not affected."],
    ["Bluetooth Speaker", "Sound"],
    [10, 100, 100, 0],
    0,
    { call FUNC(resyncAll) }
] call CBA_fnc_addSetting;

[
    QGVAR(debug), "CHECKBOX",
    ["Sound debug readout", "Shows what the sound extension is doing for the nearest speaker: walls, glass, open path, muffling, volume and echo."],
    ["Bluetooth Speaker", "Sound"],
    false,
    0
] call CBA_fnc_addSetting;

[
    QGVAR(muteAll), "CHECKBOX",
    ["Mute all speakers (only for you)", "You hear no speakers at all. Other players are not affected."],
    ["Bluetooth Speaker", "Personal"],
    false,
    0,
    { call FUNC(resyncAll) }
] call CBA_fnc_addSetting;

[
    QGVAR(personalVolume), "LIST",
    ["My speaker volume", "Play every speaker quieter just for you. Other players are not affected."],
    ["Bluetooth Speaker", "Personal"],
    [[0, 1, 2, 3], ["Full", "1 step quieter", "2 steps quieter", "3 steps quieter"], 0],
    0,
    { call FUNC(resyncAll) }
] call CBA_fnc_addSetting;
