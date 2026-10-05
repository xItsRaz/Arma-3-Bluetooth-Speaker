class CfgMagazines {
    class CA_Magazine;
    // Inventory form of the Bluetooth Speaker. Rounds = battery % + 1, so an empty battery is still 1 round.
    class btspk_speaker_mag: CA_Magazine {
        scope = 2;
        displayName = "Bluetooth Speaker";
        descriptionShort = "Portable Bluetooth speaker.<br/>Rounds = battery % + 1.";
        count = 101;
        mass = 22;
    };
};
