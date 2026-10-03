#!/usr/bin/env python3
"""Convert songs in music/ to mono Ogg Vorbis in addons/audio/sounds/, then rebuild the playlist.

Usage: python3 tools/convert_music.py [input_folder]

Needs ffmpeg (decoding) and oggenc from vorbis-tools (encoding):
    brew install ffmpeg vorbis-tools
Already-converted songs are skipped. Display titles live in addons/audio/sounds/titles.json;
edit them there (English only - Arma's fonts have no Hebrew) and they are kept on later runs. Put a BPM in the filename for the LED show later, e.g. "Song [128].mp3".
"""
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOUNDS = ROOT / "addons" / "audio" / "sounds"
TITLES = SOUNDS / "titles.json"
AUDIO_EXTS = {".mp3", ".m4a", ".aac", ".flac", ".wav", ".ogg", ".opus", ".wma"}


def safe_name(stem):
    """ASCII-only file name (Arma is unreliable with non-English paths in PBOs), unique per song."""
    slug = re.sub(r"[^a-z0-9]+", "_", stem.lower()).strip("_")[:32] or "track"
    return f"{slug}_{hashlib.sha1(stem.encode()).hexdigest()[:6]}.ogg"


def find_tool(name):
    path = shutil.which(name) or (Path("/opt/homebrew/bin") / name)
    if not Path(path).exists():
        sys.exit(f"{name} not found - run: brew install ffmpeg vorbis-tools")
    return str(path)


def main():
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "music"
    if not src.is_dir():
        sys.exit(f"Put your songs in {src} (or pass a folder) and run again")
    ffmpeg, oggenc = find_tool("ffmpeg"), find_tool("oggenc")

    songs = sorted(p for p in src.iterdir() if p.suffix.lower() in AUDIO_EXTS)
    if not songs:
        sys.exit(f"No audio files in {src}")

    titles = json.loads(TITLES.read_text(encoding="utf-8")) if TITLES.exists() else {}
    for song in songs:
        out = SOUNDS / safe_name(song.stem)
        titles.setdefault(out.name, song.stem)  # keep titles you edited by hand
        if out.exists() and out.stat().st_mtime >= song.stat().st_mtime:
            print(f"skip     {song.name}")
            continue
        decode = subprocess.Popen(
            [ffmpeg, "-loglevel", "error", "-i", str(song), "-vn", "-map_metadata", "-1", "-ac", "1", "-ar", "44100", "-f", "wav", "-"],
            stdout=subprocess.PIPE,
        )
        encode = subprocess.run([oggenc, "-Q", "-q", "5", "-o", str(out), "-"], stdin=decode.stdout)
        decode.stdout.close()
        if decode.wait() != 0 or encode.returncode != 0:
            out.unlink(missing_ok=True)
            print(f"FAILED   {song.name}")
        else:
            print(f"convert  {song.name} -> {out.name}")

    TITLES.write_text(json.dumps(titles, ensure_ascii=False, indent=2), encoding="utf-8")
    subprocess.run([sys.executable, str(ROOT / "tools" / "build_playlist.py")], check=True)


if __name__ == "__main__":
    main()
