class CfgMagazines {
    class CA_Magazine;
    // Rounds = charge in battery percent points. "Use power bank" moves it into a speaker.
    class btspk_powerbank_mag: CA_Magazine {
        scope = 2;
        displayName = "Power bank";
        descriptionShort = "Charges a Bluetooth Speaker.<br/>Rounds = charge left (percent points).";
        count = 100;
        mass = 15;
    };
};
