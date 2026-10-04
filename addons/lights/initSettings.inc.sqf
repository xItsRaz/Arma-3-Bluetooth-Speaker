// CBA settings (Options > Addon Options > JBL Speaker). "Server" ones are forced on everyone.

[
    QGVAR(quality), "LIST",
    ["Party lights", "Coloured lights from a playing PartyBox at night. Lights cost some performance."],
    ["JBL Speaker", "Lights"],
    [[0, 1], ["Off", "On"], 1],
    0
] call CBA_fnc_addSetting;

[
    QGVAR(maxLights), "SLIDER",
    ["Most lights at once", "Only the nearest PartyBoxes get a light."],
    ["JBL Speaker", "Lights"],
    [1, 8, 3, 0],
    0
] call CBA_fnc_addSetting;
