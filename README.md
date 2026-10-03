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
1. Convert songs to **mono Ogg Vorbis**: `ffmpeg -i song.mp3 -ac 1 -c:a libvorbis -q:a 5 song.ogg`
2. Put the `.ogg` files in `addons/audio/sounds/`. They play in alphabetical order.
3. Run `python3 tools/build_playlist.py`.
4. Run `hemtt release`. The mod is in `.hemttout/release/`.

## Build tools
- [HEMTT](https://hemtt.dev/): `hemtt check` (lint), `hemtt build` (dev build), `hemtt release` (zip + signing).
- `include/x/cba/` holds CBA's macro headers, used by every `script_component.hpp`.

## Use in game
In Eden, place **JBL Speaker** (Props). The scroll menu has Play, Stop, Next track, Previous track and Change range.
