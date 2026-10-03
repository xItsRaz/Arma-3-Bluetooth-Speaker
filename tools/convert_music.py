#!/usr/bin/env python3
"""Convert songs in music/ to mono Ogg Vorbis in addons/audio/sounds/, then rebuild the playlist.

Usage: python3 tools/convert_music.py [input_folder]

Needs ffmpeg (decoding). Encoding uses oggenc from vorbis-tools when found, otherwise ffmpeg's libvorbis:
    brew install ffmpeg vorbis-tools        (Mac)
    winget install Gyan.FFmpeg              (Windows)
Already-converted songs are skipped. Display titles live in addons/audio/sounds/titles.json;
edit them there (English only - Arma's fonts have no Hebrew) and they are kept on later runs.
Non-English titles are translated automatically (see to_english): tools/glossary.json first, then a rough
letter-by-letter romanization. Producer credits like "(Prod. By X)" are dropped from the display title. Put a BPM in the filename for the LED show later, e.g. "Song [128].mp3".
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


GLOSSARY = ROOT / "tools" / "glossary.json"
NON_ASCII = re.compile(r"[^\x00-\x7f]")
HEBREW_RUN = re.compile(r"[֐-׿]+")
CREDITS = re.compile(r"\s*[\(\[][^\)\]]*\b(?:prod|music)\b[^\)\]]*[\)\]]|\s+prod\.?\s*by\b[^\(\[]*", re.IGNORECASE)
LETTERS = {  # rough romanization: no vowel marks in song titles, so vowels are guessed
    "א": "a", "ע": "a", "ו": "o", "י": "i", "ב": "b", "ג": "g", "ד": "d", "ה": "h", "ז": "z", "ח": "ch", "ט": "t",
    "כ": "k", "ך": "ch", "ל": "l", "מ": "m", "ם": "m", "נ": "n", "ן": "n", "ס": "s", "פ": "p", "ף": "f", "צ": "ts",
    "ץ": "ts", "ק": "k", "ר": "r", "ש": "sh", "ת": "t",
}
VOWELS = set("aoi")


def romanize(word):
    out = ""
    for ch in word:
        part = LETTERS.get(ch, "")
        if part and out and out[-1] not in VOWELS and part[0] not in VOWELS:
            out += "a"  # consonant + consonant: guess a vowel between them
        out += part
    return out.capitalize()


def to_english(title, glossary):
    """Arma's fonts have no Hebrew: glossary words first, then rough romanization of whatever is left."""
    text = " ".join(CREDITS.sub("", title).split())
    for word in sorted((k for k in glossary if not k.startswith("_")), key=len, reverse=True):
        text = text.replace(word, glossary[word])
    text = HEBREW_RUN.sub(lambda m: romanize(m.group()), text)
    text = re.sub(r"\s*&\s*", " & ", text)
    text = re.sub(r"(?<=\S)\(", " (", text)  # the credit removal can swallow the space before "("
    words = text.split()
    if len(words) > 4 and [w.lower() for w in words[-2:]] == [w.lower() for w in words[:2]]:
        words = words[:-2]  # "Eyal Golan ... Eyal Golan": drop the repeated artist
    return " ".join(words).strip(" -")


def safe_name(stem):
    """ASCII-only file name (Arma is unreliable with non-English paths in PBOs), unique per song."""
    slug = re.sub(r"[^a-z0-9]+", "_", stem.lower()).strip("_")[:32] or "track"
    return f"{slug}_{hashlib.sha1(stem.encode()).hexdigest()[:6]}.ogg"


def find_tool(name, required=True):
    path = shutil.which(name) or (Path("/opt/homebrew/bin") / name)
    if not Path(path).exists():
        if required:
            sys.exit(f"{name} not found - Mac: brew install ffmpeg vorbis-tools, Windows: winget install Gyan.FFmpeg")
        return None
    return str(path)


def main():
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "music"
    if not src.is_dir():
        sys.exit(f"Put your songs in {src} (or pass a folder) and run again")
    ffmpeg, oggenc = find_tool("ffmpeg"), find_tool("oggenc", required=False)

    songs = sorted(p for p in src.iterdir() if p.suffix.lower() in AUDIO_EXTS)
    if not songs:
        sys.exit(f"No audio files in {src}")

    titles = json.loads(TITLES.read_text(encoding="utf-8")) if TITLES.exists() else {}
    glossary = json.loads(GLOSSARY.read_text(encoding="utf-8")) if GLOSSARY.exists() else {}
    for song in songs:
        out = SOUNDS / safe_name(song.stem)
        titles.setdefault(out.name, song.stem)
        if out.exists() and out.stat().st_mtime >= song.stat().st_mtime:
            print(f"skip     {song.name}")
            continue
        if not oggenc:  # no oggenc (Windows): ffmpeg encodes straight to mono Ogg Vorbis
            ok = subprocess.run([ffmpeg, "-loglevel", "error", "-y", "-i", str(song), "-vn", "-map_metadata", "-1", "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", str(out)]).returncode == 0
            if not ok:
                out.unlink(missing_ok=True)
            print(f"convert  {song.name} -> {out.name}" if ok else f"FAILED   {song.name}")
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

    # Translate every title that still has non-English text (also songs no longer in music/).
    # Titles you edited by hand are English already, so they are never touched.
    for name, title in titles.items():
        if NON_ASCII.search(title):
            titles[name] = to_english(title, glossary)
            print(f"title    {title}  =>  {titles[name]}")
    TITLES.write_text(json.dumps(titles, ensure_ascii=False, indent=2), encoding="utf-8")
    subprocess.run([sys.executable, str(ROOT / "tools" / "build_playlist.py")], check=True)


if __name__ == "__main__":
    main()
