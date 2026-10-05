// CBA settings (Options > Addon Options > Bluetooth Speaker). "Server" ones are forced on everyone.

[
    QGVAR(controlMode), "LIST",
    ["Who can control speakers", "Owner and admins: only the owner (and admins/Zeus) can use a locked speaker.\nAnyone: no ownership rules at all."],
    ["Bluetooth Speaker", "Permissions"],
    [[0, 1], ["Owner and admins", "Anyone"], 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(unownedMode), "LIST",
    ["Unowned speakers (Eden/Zeus placed)", "What players can do with a speaker nobody owns yet."],
    ["Bluetooth Speaker", "Permissions"],
    [[0, 1, 2], ["Claim it first", "Anyone can use it", "Admins and Zeus only"], 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(maxUseDistance), "SLIDER",
    ["Max control distance (m)", "The server ignores commands from players further away than this (admins excepted)."],
    ["Bluetooth Speaker", "Permissions"],
    [3, 50, 10, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(notifications), "LIST",
    ["Now playing messages", "How you see the song title when a speaker near you starts a song."],
    ["Bluetooth Speaker", "Personal"],
    [[0, 1, 2], ["Off", "System chat", "Hint"], 1],
    0
] call CBA_fnc_addSetting;
