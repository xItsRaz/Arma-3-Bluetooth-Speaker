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

## Build on Windows
`powershell -File tools\make_mod.ps1` builds everything into `.hemttoutuild\@JBLSpeaker` (hidden folder): the addons, the sound extension `jbl_speaker_x64.dll`, and your converted songs in `music\`. Add `-Music` to convert the songs in `music/` first. Load that folder with CBA_A3 and ACE3.

One-time setup: Python 3 and ffmpeg (`winget install Python.Python.3.12 Gyan.FFmpeg`), HEMTT (download `windows-x64.zip` from its GitHub releases), and for the extension Rust (`rustup`, GNU toolchain) plus MinGW (`winget install BrechtSanders.WinLibs.POSIX.UCRT`).

**The sound extension** gives smoother volume, quieter speakers behind walls, echo indoors and sound that finds open doors. It needs the game to run **without BattlEye** (the Arma launcher has a start option for that). Without the DLL, or with it blocked, everything still works with Arma's built-in sound. Check the `.rpt` for "JBL Speaker: sound extension active".

## Build tools
- [HEMTT](https://hemtt.dev/): `hemtt check` (lint), `hemtt build` (dev build), `hemtt release` (zip + signing).
- `include/x/cba/` holds CBA's macro headers, used by every `script_component.hpp`.

## Use in game
Needs **CBA_A3** and **ACE3**. In Eden, place **JBL Speaker** (Props). Look at it and open ACE interaction (default **Windows key**) → **Speaker**:
- **Play / Stop / Next song / Previous song**, **Pick a song**, **Volume 1–5** (4 is normal).
- **PartyBoost**: link nearby speakers so they play in sync; unlink one or all.
- **Ownership**: claim an unowned speaker (it's locked to you), unlock it for everyone, lock it again, or give it up.
- **Speaker info**: owner, lock, PartyBoost, volume and song.

Self-interaction (**Ctrl+Windows**) has **Mute all speakers (for me)**. Keybinds (unbound by default) are in **Options → Controls → Configure Addons → JBL Speaker**. Settings: **Options → Addon Options → JBL Speaker**.

Admins, Zeus and single player can always control every speaker.
