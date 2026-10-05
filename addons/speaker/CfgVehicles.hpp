class CBA_Extended_EventHandlers_base;

// ACE condition/statement strings: _target = the speaker, _player = you.
// Conditions run every frame while the menu is open, so they only read variables.
// The server checks permission again for every command.

// 2 s progress bar, then the server command (cancels if you walk away)
#define PICKUP_STATEMENT(cmd) QUOTE([ARR_6(2,[ARR_2(_target,_player)],{ [ARR_3(_this select 0 select 0,_this select 0 select 1,cmd)] call FUNC(send) },{},'Picking up speaker...',{ (_this select 0 select 1) distance (_this select 0 select 0) < 4 })] call ace_common_fnc_progressBar)

class CfgVehicles {
    class Land_FMradio_F;
    // Placeholder model until the Charge-style model exists (PLAN.md section 15)
    class jbl_speaker: Land_FMradio_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "JBL Speaker";
        model = "\z\jbl\addons\speaker\models\jbl_speaker.p3d"; // tools/blender/make_models.py
        hiddenSelections[] = {"camo", "led_battery", "led_glow", "damage"};
        jbl_rangeSetting = "jbl_audio_rangeSpeaker"; // CBA setting with the range
        jbl_range = 75;          // fallback cut-off distance in metres
        jbl_soundSuffix = "";    // normal loudness (the PartyBox will use "_party")
        jbl_extensionGain = 0.45; // loudness when played through the sound extension (0-1)

        // ACE carry (small and light: carried in front of the chest, can't be dragged) - tune in game
        ace_dragging_canCarry = 1;
        ace_dragging_carryPosition[] = {0, 0.6, 0.9};
        ace_dragging_carryDirection = 90;
        ace_dragging_canDrag = 0;
        // ACE cargo: fits in any vehicle with cargo space
        ace_cargo_size = 1;
        ace_cargo_canLoad = 1;
        // Fragile: a few bullets or one grenade breaks it (see fnc_damaged)
        armor = 2;
        destrType = "DestructNo";

        class EventHandlers {
            class CBA_Extended_EventHandlers: CBA_Extended_EventHandlers_base {};
        };

        class ACE_Actions {
            class ACE_MainActions {
                displayName = "Interactions";
                selection = "";
                distance = 3;
                condition = "true";

                class GVAR(menu) {
                    displayName = "Speaker";
                    condition = "true";
                    statement = "";
                    modifierFunction = QUOTE(_this call FUNC(modifyMenu));

                    class GVAR(play) {
                        displayName = "Play";
                        condition = "!(_target getVariable ['jbl_playing', false]) && {count getArray (configFile >> 'jbl_audio_playlist' >> 'tracks') > 0} && {[_target, _player] call jbl_common_fnc_canControl}";
                        statement = "[_target, _player, 'play'] call jbl_speaker_fnc_send";
                    };
                    class GVAR(stop) {
                        displayName = "Stop";
                        condition = "_target getVariable ['jbl_playing', false] && {[_target, _player] call jbl_common_fnc_canControl}";
                        statement = "[_target, _player, 'stop'] call jbl_speaker_fnc_send";
                    };
                    class GVAR(next) {
                        displayName = "Next song";
                        condition = "_target getVariable ['jbl_playing', false] && {[_target, _player] call jbl_common_fnc_canControl}";
                        statement = "[_target, _player, 'next'] call jbl_speaker_fnc_send";
                    };
                    class GVAR(prev) {
                        displayName = "Previous song";
                        condition = "_target getVariable ['jbl_playing', false] && {[_target, _player] call jbl_common_fnc_canControl}";
                        statement = "[_target, _player, 'prev'] call jbl_speaker_fnc_send";
                    };

                    class GVAR(playlist) {
                        displayName = "Pick a song";
                        condition = "count getArray (configFile >> 'jbl_audio_playlist' >> 'tracks') > 0 && {[_target, _player] call jbl_common_fnc_canControl}";
                        statement = "";
                        insertChildren = QUOTE(_this call FUNC(playlistChildren));
                    };

                    class GVAR(volume) {
                        displayName = "Volume";
                        condition = "[_target, _player] call jbl_common_fnc_canControl";
                        statement = "";
                        modifierFunction = QUOTE(_this call FUNC(modifyVolume));
                        class GVAR(volume1) {
                            displayName = "1 (quietest)";
                            condition = "true";
                            statement = "[_target, _player, 'volume', 1] call jbl_speaker_fnc_send";
                        };
                        class GVAR(volume2) {
                            displayName = "2";
                            condition = "true";
                            statement = "[_target, _player, 'volume', 2] call jbl_speaker_fnc_send";
                        };
                        class GVAR(volume3) {
                            displayName = "3";
                            condition = "true";
                            statement = "[_target, _player, 'volume', 3] call jbl_speaker_fnc_send";
                        };
                        class GVAR(volume4) {
                            displayName = "4 (normal)";
                            condition = "true";
                            statement = "[_target, _player, 'volume', 4] call jbl_speaker_fnc_send";
                        };
                        class GVAR(volume5) {
                            displayName = "5 (loudest)";
                            condition = "true";
                            statement = "[_target, _player, 'volume', 5] call jbl_speaker_fnc_send";
                        };
                    };

                    class GVAR(partyBoost) {
                        displayName = "PartyBoost";
                        condition = "[_target, _player] call jbl_common_fnc_canControl";
                        statement = "";
                        class GVAR(link) {
                            displayName = "Link nearby speakers";
                            condition = "isNull (_target getVariable ['jbl_linkLeader', objNull])";
                            statement = "[_target, _player, 'link'] call jbl_speaker_fnc_send";
                        };
                        class GVAR(unlinkAll) {
                            displayName = "Unlink all";
                            condition = "(_target getVariable ['jbl_linkFollowers', []]) isNotEqualTo []";
                            statement = "[_target, _player, 'unlink'] call jbl_speaker_fnc_send";
                        };
                        class GVAR(unlinkThis) {
                            displayName = "Unlink this speaker";
                            condition = "!isNull (_target getVariable ['jbl_linkLeader', objNull])";
                            statement = "[_target, _player, 'unlink'] call jbl_speaker_fnc_send";
                        };
                    };

                    class GVAR(ownership) {
                        displayName = "Ownership";
                        condition = "jbl_common_controlMode == 0";
                        statement = "";
                        class GVAR(claim) {
                            displayName = "Claim speaker";
                            condition = "(_target getVariable ['jbl_owner', '']) == '' && {jbl_common_unownedMode == 0 || {[_player] call jbl_common_fnc_isAdmin}}";
                            statement = "[_target, _player, 'claim'] call jbl_speaker_fnc_send";
                        };
                        class GVAR(unlock) {
                            displayName = "Unlock (let anyone use it)";
                            condition = "(_target getVariable ['jbl_owner', '']) != '' && {_target getVariable ['jbl_locked', true]} && {(_target getVariable ['jbl_owner', '']) == getPlayerUID _player || {[_player] call jbl_common_fnc_isAdmin}}";
                            statement = "[_target, _player, 'unlock'] call jbl_speaker_fnc_send";
                        };
                        class GVAR(lock) {
                            displayName = "Lock to owner";
                            condition = "(_target getVariable ['jbl_owner', '']) != '' && {!(_target getVariable ['jbl_locked', true])} && {(_target getVariable ['jbl_owner', '']) == getPlayerUID _player || {[_player] call jbl_common_fnc_isAdmin}}";
                            statement = "[_target, _player, 'lock'] call jbl_speaker_fnc_send";
                        };
                        class GVAR(release) {
                            displayName = "Give up ownership";
                            condition = "(_target getVariable ['jbl_owner', '']) != '' && {(_target getVariable ['jbl_owner', '']) == getPlayerUID _player || {[_player] call jbl_common_fnc_isAdmin}}";
                            statement = "[_target, _player, 'release'] call jbl_speaker_fnc_send";
                        };
                    };

                    class GVAR(battery) {
                        displayName = "Check battery";
                        condition = "true";
                        statement = "[_target] call jbl_battery_fnc_check";
                    };
                    class GVAR(charging) {
                        displayName = "Charging";
                        condition = "jbl_battery_enabled && {[_target, _player] call jbl_common_fnc_canControl}";
                        statement = "";
                        class GVAR(plug) {
                            displayName = "Plug into generator";
                            condition = "isNull (_target getVariable ['jbl_generator', objNull])";
                            statement = QUOTE([ARR_6(3,[ARR_2(_target,_player)],{ [ARR_3(_this select 0 select 0,_this select 0 select 1,'plug')] call FUNC(send) },{},'Plugging in...',{ (_this select 0 select 1) distance (_this select 0 select 0) < 4 })] call ace_common_fnc_progressBar);
                        };
                        class GVAR(unplug) {
                            displayName = "Unplug from generator";
                            condition = "!isNull (_target getVariable ['jbl_generator', objNull])";
                            statement = "[_target, _player, 'unplug'] call jbl_speaker_fnc_send";
                        };
                        class GVAR(bank) {
                            displayName = "Use power bank";
                            condition = "'jbl_powerbank_mag' in magazines _player && {(_target getVariable ['jbl_bat', [1, 0, 0]] select 0) < 1 || {_target getVariable ['jbl_charging', ''] == ''}}";
                            statement = QUOTE([ARR_6(5,[ARR_2(_target,_player)],{ (_this select 0) call jbl_battery_fnc_useBank },{},'Charging from power bank...',{ (_this select 0 select 1) distance (_this select 0 select 0) < 4 })] call ace_common_fnc_progressBar);
                        };
                    };

                    #include "MountMenuTarget.hpp"

                    class GVAR(pickup) {
                        displayName = "Pick up";
                        condition = "!(_target getVariable ['jbl_playing', false]) && {!(_target isKindOf 'jbl_partybox')} && {[_target, _player] call jbl_common_fnc_canControl} && {_player canAdd ['jbl_speaker_mag', 1]}";
                        statement = PICKUP_STATEMENT('pickup');
                    };
                    class GVAR(pickupStop) {
                        displayName = "Turn off and pick up";
                        condition = "_target getVariable ['jbl_playing', false] && {!(_target isKindOf 'jbl_partybox')} && {[_target, _player] call jbl_common_fnc_canControl} && {_player canAdd ['jbl_speaker_mag', 1]}";
                        statement = PICKUP_STATEMENT('pickup');
                    };
                    class GVAR(pickupKeep) {
                        displayName = "Pick up and keep playing";
                        condition = "_target getVariable ['jbl_playing', false] && {!(_target isKindOf 'jbl_partybox')} && {[_target, _player] call jbl_common_fnc_canControl} && {backpack _player != ''} && {isNull (_player getVariable ['jbl_clippedSpeaker', objNull])} && {isNull (_target getVariable ['jbl_clippedTo', objNull])}";
                        statement = PICKUP_STATEMENT('clip');
                    };

                    class GVAR(info) {
                        displayName = "Speaker info";
                        condition = "true";
                        statement = QUOTE(_target call FUNC(info));
                    };
                };
            };
        };
    };

    // PartyBox (PLAN.md section 4): Eden and Zeus only (no magazine, so players can't place it).
    // Carry, drag and cargo work; no Pick up, no backpack clip. Placeholder model until section 15.
    class jbl_partybox: jbl_speaker {
        scope = 2;
        scopeCurator = 2;
        displayName = "JBL PartyBox";
        model = "\z\jbl\addons\speaker\models\jbl_partybox.p3d"; // tools/blender/make_models.py
        hiddenSelections[] = {"camo", "ring_left", "ring_right", "strobe", "damage"};
        jbl_rangeSetting = "jbl_audio_rangePartybox";
        jbl_range = 200;
        jbl_soundSuffix = "_party";    // ~10 dB louder sound classes
        jbl_extensionGain = 0.7;

        // Heavy (~11 kg): carried in front with both hands, can also be dragged
        ace_dragging_canCarry = 1;
        ace_dragging_carryPosition[] = {0, 0.8, 0.6};
        ace_dragging_carryDirection = 0;
        ace_dragging_canDrag = 1;
        ace_dragging_dragPosition[] = {0, 1.2, 0};
        ace_cargo_size = 2;
        ace_cargo_canLoad = 1;
        armor = 8;
    };

    // Self-interaction: place / clip a speaker from your inventory, mute speakers just for you
    class Man;
    class CAManBase: Man {
        class ACE_SelfActions {
            class GVAR(place) {
                displayName = "Place speaker";
                condition = "'jbl_speaker_mag' in magazines _player && {isNull objectParent _player}";
                statement = "[_player, false] call jbl_speaker_fnc_place";
                exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
            };
            class GVAR(clip) {
                displayName = "Clip speaker to backpack";
                condition = "'jbl_speaker_mag' in magazines _player && {backpack _player != ''} && {isNull (_player getVariable ['jbl_clippedSpeaker', objNull])}";
                statement = "[_player, true] call jbl_speaker_fnc_place";
                exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
            };
            class GVAR(clipMenu) {
                displayName = "Backpack speaker";
                condition = "!isNull (_player getVariable ['jbl_clippedSpeaker', objNull]) && {[_player getVariable ['jbl_clippedSpeaker', objNull], _player] call jbl_common_fnc_canControl}";
                statement = "";
                modifierFunction = QUOTE(_this call FUNC(modifyMenu));
                exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};

                class GVAR(clipPlay) {
                    displayName = "Play";
                    condition = "!((_player getVariable ['jbl_clippedSpeaker', objNull]) getVariable ['jbl_playing', false]) && {count getArray (configFile >> 'jbl_audio_playlist' >> 'tracks') > 0}";
                    statement = "[_player, 'play'] call jbl_speaker_fnc_clipped";
                    exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                };
                class GVAR(clipStop) {
                    displayName = "Stop";
                    condition = "(_player getVariable ['jbl_clippedSpeaker', objNull]) getVariable ['jbl_playing', false]";
                    statement = "[_player, 'stop'] call jbl_speaker_fnc_clipped";
                    exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                };
                class GVAR(clipNext) {
                    displayName = "Next song";
                    condition = "(_player getVariable ['jbl_clippedSpeaker', objNull]) getVariable ['jbl_playing', false]";
                    statement = "[_player, 'next'] call jbl_speaker_fnc_clipped";
                    exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                };
                class GVAR(clipPrev) {
                    displayName = "Previous song";
                    condition = "(_player getVariable ['jbl_clippedSpeaker', objNull]) getVariable ['jbl_playing', false]";
                    statement = "[_player, 'prev'] call jbl_speaker_fnc_clipped";
                    exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                };
                class GVAR(clipPlaylist) {
                    displayName = "Pick a song";
                    condition = "count getArray (configFile >> 'jbl_audio_playlist' >> 'tracks') > 0";
                    statement = "";
                    insertChildren = QUOTE(_this call FUNC(playlistChildren));
                    exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                };
                class GVAR(clipVolume) {
                    displayName = "Volume";
                    condition = "true";
                    statement = "";
                    modifierFunction = QUOTE(_this call FUNC(modifyVolume));
                    exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                    class GVAR(clipVolume1) {
                        displayName = "1 (quietest)";
                        condition = "true";
                        statement = "[_player, 'volume', 1] call jbl_speaker_fnc_clipped";
                        exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                    };
                    class GVAR(clipVolume2) {
                        displayName = "2";
                        condition = "true";
                        statement = "[_player, 'volume', 2] call jbl_speaker_fnc_clipped";
                        exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                    };
                    class GVAR(clipVolume3) {
                        displayName = "3";
                        condition = "true";
                        statement = "[_player, 'volume', 3] call jbl_speaker_fnc_clipped";
                        exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                    };
                    class GVAR(clipVolume4) {
                        displayName = "4 (normal)";
                        condition = "true";
                        statement = "[_player, 'volume', 4] call jbl_speaker_fnc_clipped";
                        exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                    };
                    class GVAR(clipVolume5) {
                        displayName = "5 (loudest)";
                        condition = "true";
                        statement = "[_player, 'volume', 5] call jbl_speaker_fnc_clipped";
                        exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                    };
                };
                #include "MountMenuSelf.hpp"

                class GVAR(clipBattery) {
                    displayName = "Check battery";
                    condition = "true";
                    statement = "[_player getVariable ['jbl_clippedSpeaker', objNull]] call jbl_battery_fnc_check";
                    exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
                };
            };
            class GVAR(unclip) {
                displayName = "Unclip speaker";
                condition = "!isNull (_player getVariable ['jbl_clippedSpeaker', objNull])";
                statement = "['jbl_speaker_drop', [_player, 0.8]] call CBA_fnc_serverEvent";
                exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
            };
            class GVAR(mute) {
                displayName = "Mute all speakers (for me)";
                condition = "!jbl_audio_muteAll";
                statement = "['jbl_audio_muteAll', true] call CBA_settings_fnc_set";
                exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
            };
            class GVAR(unmute) {
                displayName = "Unmute speakers";
                condition = "jbl_audio_muteAll";
                statement = "['jbl_audio_muteAll', false] call CBA_settings_fnc_set";
                exceptions[] = {"isNotInside", "isNotSitting", "isNotSwimming"};
            };
        };
    };
};
