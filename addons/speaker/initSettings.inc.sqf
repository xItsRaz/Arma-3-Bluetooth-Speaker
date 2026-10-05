// CBA settings (Options > Addon Options > Bluetooth Speaker). "Server" ones are forced on everyone.

[
    QGVAR(destructible), "CHECKBOX",
    ["Speakers can break", "A few bullets or one grenade break a speaker. Takes effect for speakers created after the change."],
    ["Bluetooth Speaker", "Damage"],
    true,
    1
] call CBA_fnc_addSetting;
