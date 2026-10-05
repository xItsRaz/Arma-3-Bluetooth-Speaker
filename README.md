# Bluetooth Speakers for Arma 3

Portable and party speakers that feel real. Carry one, set it down, clip it to your backpack, strap it to a car roof, plug it into a generator, shoot it. Everyone nearby hears the music coming from the speaker, in sync, and the sound reacts to distance, walls, glass and rooms.

> **Work in progress.** This mod is still being built and stays a WIP until the roadmap below is finished. Things will change, move and break between commits.
>
> **Status: alpha.** Working and tested in singleplayer on Windows. Multiplayer and dedicated servers are designed for (server-owned state, permission checks on the server) but not tested yet. Expect rough edges. The 3D models are first-pass blockouts with placeholder colours.

Requires **[CBA_A3](https://steamcommunity.com/workshop/filedetails/?id=450814997)** and **[ACE3](https://steamcommunity.com/workshop/filedetails/?id=463939057)**.

> **Naming.** In game the two speakers are called **Bluetooth Speaker** (portable) and **Bluetooth Party Speaker**. Internal names (classes, settings, functions, addon files) use the prefix `btspk`. This mod is not affiliated with any speaker manufacturer.

## What you get

| | Portable speaker | Party speaker |
|---|---|---|
| Looks like | rugged cylindrical Bluetooth speaker (223 mm, about 1 kg) | floor-standing party speaker (about 57 cm tall, about 11 kg) |
| Who can place it | any player, from the inventory (or Eden / Zeus) | **Eden and Zeus only** |
| Pick up into inventory | yes | no |
| Carry / drag / load into vehicle cargo | carry, cargo | carry, drag, cargo |
| Mount on backpack | back, hip or under the backpack (needs a backpack) | back only (no backpack needed) |
| Mount on vehicles | roof, rear, front | roof, rear, front |
| Range | 75 m (setting) | 200 m (setting) |
| Battery | yes | no (setting) |
| Lights | - | colour light show at night |

**Playback**
- Plays a playlist of songs packed into the mod (you add your own, see below). Play, stop, next, previous, pick a song, volume 1 to 5.
- Everyone in range hears the same moment of the same song. Players who join late catch up.
- **Party Link**: link up to 8 speakers within 15 m, they play in sync and any of them controls the group.

**Rules and ownership**
- Whoever places a speaker owns it. Owners can lock it to themselves or unlock it for everyone. Eden or Zeus placed speakers start unowned (first to claim, anyone, or admins only, a server setting).
- Admins, Zeus and singleplayer can always control every speaker. The server checks every command again, so a modified client can't skip the rules.

**Battery and damage**
- The battery drains while playing, faster at higher volume, and does not drain while idle. Warnings at 10% and when empty.
- Charge from a running vehicle (loaded in cargo, mounted on it, or on the back of someone sitting in it), from a generator, or with a power bank item.
- Speakers can be damaged (plays slightly lower) and broken (stops, smokes, can no longer be used).

**Mounting**
- Mount on your body or on a vehicle. A live **Adjust position** menu moves the speaker 5 cm at a time, so you can fine-tune the fit. Mounted speakers keep playing and a vehicle-mounted one charges while the engine runs. If the vehicle is destroyed the speaker drops.
- A **Backpack speaker** self menu controls a speaker that is on your back.

**Sound extension (optional)**
- A small native DLL replaces Arma's built-in 3D sound. It gives smooth volume changes, a proper distance curve, left/right panning, walls and glass that muffle the sound, sound that bends through open doors and windows, and echo that follows the size of the room. Details below.
- Without it everything still works with Arma's built-in sound.

## Using it in game

In Eden place **Bluetooth Speaker** (Props) or **Bluetooth Party Speaker**. Look at a speaker and open the ACE interaction menu (default: Windows key):

- **Play / Stop / Next / Previous**, **Pick a song**, **Volume**
- **Party Link**: link nearby speakers, unlink one or all
- **Mount**: on my body, on a vehicle (within 6 m), move, adjust position, take off
- **Charging**: plug into a generator, use a power bank. **Check battery** is open to everyone
- **Pick up** (portable speaker only): into the inventory, or **Pick up and keep playing** to clip it to your backpack
- **Ownership**: claim, unlock for everyone, lock, give up
- **Speaker info**

Self interaction (Ctrl+Windows): **Place speaker** and **Clip speaker to backpack** from the inventory, **Backpack speaker** controls, **Mute all speakers (for me)**.

Keybinds (unbound by default): Options, Controls, Configure Addons. Play/stop, next song, volume up/down and mute act on the nearest speaker you can control within 5 m.

Settings: Options, Addon Options. Server settings are forced on everyone (permissions, ranges, battery, damage, Party Link limits), client settings are personal (mute, volume, notifications, lights, sound effects, debug readout).

## Adding music

Songs are never part of the repository (copyright). To hear something, build the mod locally with your own songs:

1. Put your songs (mp3, m4a, flac, wav and more) in the `music/` folder.
2. Run `python tools/convert_music.py`. It converts them to mono Ogg Vorbis in `addons/audio/sounds/`, translates non-English titles to English (Arma's fonts cannot show every script; see `tools/glossary.json`), and rebuilds the playlist. Songs that are already converted are skipped. Titles live in `addons/audio/sounds/titles.json` and can be edited by hand.
3. Build the mod (below). The songs are packed into the mod for Arma's own sound and also copied to a `music` folder next to the DLL for the sound extension.

## Build it yourself

### Windows

One-time setup:
- [HEMTT](https://hemtt.dev/) (download the Windows zip from its releases)
- Python 3 and ffmpeg: `winget install Python.Python.3.12 Gyan.FFmpeg`
- For the sound extension: Rust (`rustup`, GNU toolchain) and MinGW (`winget install BrechtSanders.WinLibs.POSIX.UCRT`)
- Optional, to binarize the 3D models: Arma 3 Tools (Steam). HEMTT finds it on its own.

Then run:

```
powershell -File tools\make_mod.ps1            # add -Music to convert your songs first
```

The finished mod is in `.hemttout\build\@BluetoothSpeaker` (a hidden folder): the addons, `btspk_speaker_x64.dll` and your `music` folder. Load it in the Arma 3 launcher (Mods, Add local mod) together with CBA_A3 and ACE3.

### Other systems

`hemtt check` (lint), `hemtt build` (dev build) and `hemtt release` (zip and signing) work anywhere HEMTT runs. The sound extension is Windows only and is built with `cargo build --release` in `extension/`.

### GitHub builds

Every push builds the addons in GitHub Actions and uploads them as the **BluetoothSpeaker** artifact, and builds the sound extension as **BluetoothSpeaker-extension**. These builds contain **no music**.

## The sound extension

`extension/` is a Rust library (`btspk_speaker_x64.dll`) that Arma loads with `callExtension`. It decodes the songs, mixes every speaker in 3D and plays them through your sound card. When it is installed the mod uses it automatically; check the Arma `.rpt` log for `Bluetooth Speaker: sound extension active`.

- **BattlEye:** Arma blocks extensions that BattlEye has not approved, so the game must be started **without BattlEye** to use the DLL (the launcher has a start option for this). That limits you to servers with BattlEye off. Without the DLL everything still works with Arma's built-in sound.
- **What it does:** distance falloff that reaches the speaker's range, panning from where you look, muffling through walls (about 15 dB per wall) and glass (a few dB, dull), sound that comes through an open door or window when a wall blocks the straight line, and echo with early reflections, a tail and a slap echo in big rooms.
- **Tuning:** Addon Options, Bluetooth Speaker, Sound has a loudness slider, a setting for how many effects to compute, and a **Sound debug readout** that shows what the extension decided for the nearest speaker.

## 3D models

The two models are generated by a Blender script, so they are reproducible and editable as code: `tools/blender/make_models.py`. It needs Blender 4.4 with the [Arma 3 Object Builder](https://github.com/MrClock8163/Arma3ObjectBuilder) addon (that addon's newest release supports Blender up to 4.4):

```
blender --background --python tools/blender/make_models.py
```

It writes `addons/speaker/models/*.p3d` with all LODs, named selections, memory points and mass. Colours are procedural for now, real textures are on the roadmap.

## Repository layout

```
addons/
  main/      mod-wide macros
  common/    permissions, command router, settings
  audio/     playlist, sync, sound extension bridge (walls, echo)
  speaker/   speaker objects, ACE menus, carry, cargo, mounting, damage, models
  battery/   battery, charging, power bank
  lights/    party light show
extension/   Rust sound extension
tools/       build, music conversion, model generation
```

## Roadmap

Next up:
- Tune the mount positions on the new models, then real textures and LED glow
- AI that hears and investigates playing speakers
- Spotify (via Spotify Connect, Premium account, personal use), line-in from a phone or PC, radio streams
- Playing from links, localisation, a public API for mission makers, Eden attributes

## Third-party

[CBA_A3](https://github.com/CBATeam/CBA_A3) and [ACE3](https://github.com/acemod/ACE3) (required, not included), [HEMTT](https://hemtt.dev/) (build), [arma-rs](https://github.com/BrettMayson/arma-rs), [cpal](https://github.com/RustAudio/cpal), [Symphonia](https://github.com/pdeljanov/Symphonia) and [ureq](https://github.com/algesten/ureq) (sound extension), [Arma 3 Object Builder for Blender](https://github.com/MrClock8163/Arma3ObjectBuilder) (model export).

## License

Copyright (C) 2026 Raz. This project is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later version** (GPL-2.0-or-later). It is distributed in the hope that it will be useful, but **without any warranty**. See [LICENSE](LICENSE) for the full text and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the licenses of the libraries it uses. Your own songs are yours and are not covered by this license.

## Trademarks and disclaimer

Spotify is a registered trademark of Spotify AB. The Bluetooth word mark is a registered trademark owned by Bluetooth SIG, Inc. Arma 3 is a trademark of Bohemia Interactive a.s. All other trademarks are the property of their respective owners.

This is an unofficial, fan-made project. It is not affiliated with, authorised, sponsored or endorsed by any of these companies. Product names are used only to describe what the speakers resemble or what the project plans to connect to. Spotify support is planned and **not implemented yet**; when it exists it will only work with a user's own Spotify Premium account, and using unofficial Spotify clients may go against Spotify's terms, so it is for personal use at your own risk.
