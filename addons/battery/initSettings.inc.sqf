// CBA settings (Options > Addon Options > JBL Speaker). "Server" ones are forced on everyone.

[
    QGVAR(enabled), "CHECKBOX",
    ["Battery", "Speakers drain while playing and need charging. Off = infinite battery."],
    ["JBL Speaker", "Battery"],
    true,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(partyboxBattery), "CHECKBOX",
    ["PartyBox uses a battery", "Off = the PartyBox runs on mains power and never drains."],
    ["JBL Speaker", "Battery"],
    false,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(life), "SLIDER",
    ["Play time at max volume (min)", "Full to empty at volume 5. Volume 1 lasts about 2.5 times longer."],
    ["JBL Speaker", "Battery"],
    [10, 600, 120, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(chargeTime), "SLIDER",
    ["Charge time (min)", "Empty to full from a vehicle or generator."],
    ["JBL Speaker", "Battery"],
    [5, 240, 30, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(chargeInVehicles), "CHECKBOX",
    ["Charge in vehicles", "A speaker loaded in cargo (or on the backpack of someone in a vehicle) charges while the engine runs."],
    ["JBL Speaker", "Battery"],
    true,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(generatorClasses), "EDITBOX",
    ["Generator classes", "Object classes that count as generators, separated by commas."],
    ["JBL Speaker", "Battery"],
    "Land_Generator_F, Land_PortableGenerator_01_F, Land_PortableGenerator_01_black_F, Land_PortableGenerator_01_sand_F",
    1
] call CBA_fnc_addSetting;
