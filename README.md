# JBL Speaker (Arma 3)

Bluetooth-style speakers for Arma 3. Requires **CBA_A3** (ACE3 from Session 3 on). See [PLAN.md](PLAN.md) for the full design and roadmap.

**Current state (Session 1):** a placeable speaker that plays a playlist packed into the mod. Everyone in range hears it in sync, and players who join late catch up. It's controlled from the scroll menu for now; ACE comes in Session 3.

## Get a build
Every push to GitHub builds the mod automatically:
1. Open the repo on GitHub → **Actions** → the latest **Build** run.
2. Download the **JBLSpeaker** artifact.
3. Unzip it into a folder named `@JBLSpeaker`.
4. In the Arma 3 launcher: **Mods → ⋯ → Add local mod**, pick `@JBLSpeaker`, and also load **CBA_A3**.

GitHub builds have **no music**, because songs are never pushed. To hear something, build locally with your songs (below).

## Add your music (local build)
One-time setup on the Mac: `brew install openssl@3 ffmpeg vorbis-tools` (HEMTT is in `~/.local/bin/hemtt`).

1. Put your songs (mp3, m4a, flac, wav...) in the `music/` folder. Nothing in it is ever pushed.
2. Run `python3 tools/convert_music.py`. It converts them to mono Ogg Vorbis in `addons/audio/sounds/` and rebuilds the playlist. Songs already converted are skipped.
3. Run `~/.local/bin/hemtt release`. The finished mod is zipped at `releases/jbl-latest.zip` (it contains an `@jbl` folder).
4. Copy the zip to the Windows PC, unzip it, and load `@jbl` as a local mod together with CBA_A3.

## Build tools
- [HEMTT](https://hemtt.dev/): `hemtt check` (lint), `hemtt build` (dev build), `hemtt release` (zip + signing).
- `include/x/cba/` holds CBA's macro headers, used by every `script_component.hpp`.

## Use in game
In Eden, place **JBL Speaker** (Props). Until the ACE menu arrives (Session 3), everything is in the scroll menu:
- **Play / Stop / Next / Previous**: shown only to players allowed to control the speaker.
- **PartyBoost**: link nearby speakers so they play in sync; unlink one or all.
- **Claim speaker**: an unowned speaker becomes yours and is locked to you. **Unlock** lets anyone use it; **Lock** takes it back; **Give up ownership** makes it unowned.
- **Speaker info**: owner, lock, PartyBoost status and song.

Admins, Zeus and single player can always control every speaker. Settings: **Options → Addon Options → JBL Speaker**.
