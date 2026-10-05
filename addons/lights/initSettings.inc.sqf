// CBA settings (Options > Addon Options > Bluetooth Speaker). "Server" ones are forced on everyone.

[
    QGVAR(quality), "LIST",
    ["Party lights", "Coloured lights from a playing Party Speaker at night. Lights cost some performance."],
    ["Bluetooth Speaker", "Lights"],
    [[0, 1], ["Off", "On"], 1],
    0
] call CBA_fnc_addSetting;

[
    QGVAR(maxLights), "SLIDER",
    ["Most lights at once", "Only the nearest Party Speakers get a light."],
    ["Bluetooth Speaker", "Lights"],
    [1, 8, 3, 0],
    0
] call CBA_fnc_addSetting;
