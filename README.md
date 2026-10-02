# JBL Speaker (Arma 3), phase 1

This is a placeable speaker that plays a playlist packed into the mod. Everyone within range hears it in sync, and players who join late pick it up at the right point in the song. It uses only scripts, so it works with BattlEye and has no dependencies (no CBA or ACE needed).

## Add your music
1. Convert your songs to **mono Ogg Vorbis**. Arma can't play mp3, and mono files sound like they come from the speaker:
   `ffmpeg -i song.mp3 -ac 1 -c:a libvorbis -q:a 5 song.ogg`
2. Put the `.ogg` files in `jbl_speaker/sounds/`. They play in alphabetical order.
3. Run `python3 tools/build_playlist.py`. This writes `jbl_speaker/playlist.hpp` with each track's length.

## Build (Windows, Arma 3 Tools → Addon Builder)
- Source directory: `jbl_speaker`
- Destination: `@JBLSpeaker/addons`
- Copy `mod.cpp` into `@JBLSpeaker/`
- Load `@JBLSpeaker` in the launcher as a local mod.

## Use
In Eden, find **JBL Speaker** under Props and place it. The scroll menu has Play, Stop, Next, Previous and Change range (25/50/100/200 m).

To turn any other object into a speaker from a mission script:
`[_obj] remoteExec ["JBL_fnc_init", 0, true];`
