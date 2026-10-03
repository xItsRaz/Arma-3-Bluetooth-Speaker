class CfgMagazines {
    class CA_Magazine;
    // Inventory form of the JBL Speaker. Rounds = battery % + 1, so an empty battery is still 1 round.
    class jbl_speaker_mag: CA_Magazine {
        scope = 2;
        displayName = "JBL Speaker";
        descriptionShort = "Portable Bluetooth speaker.<br/>Rounds = battery % + 1.";
        count = 101;
        mass = 22;
    };
};
