# Windows: (optionally convert music) + hemtt build + sound extension, then assemble a ready-to-load
# @BluetoothSpeaker folder in .hemttout\build\ (addons, btspk_speaker_x64.dll, music\).
# Usage: powershell -File tools\make_mod.ps1 [-Music] [-NoExtension]
param([switch]$Music, [switch]$NoExtension)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ";$env:USERPROFILE\.cargo\bin"

$hemtt = (Get-Command hemtt -ErrorAction SilentlyContinue).Source
if (-not $hemtt) { $hemtt = "$env:LOCALAPPDATA\hemtt\hemtt.exe" }

if ($Music) { python tools\convert_music.py; if ($LASTEXITCODE) { throw 'convert_music failed' } }

& $hemtt build
if ($LASTEXITCODE) { throw 'hemtt build failed' }

# The sound extension (Rust). Skipped when Rust isn't installed: the mod then uses Arma's built-in sound.
$dll = $null
if (-not $NoExtension -and (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Push-Location (Join-Path $root 'extension')
    cargo build --release
    $failed = $LASTEXITCODE
    Pop-Location
    if ($failed) { throw 'cargo build failed' }
    $dll = Join-Path $root 'extension\target\release\btspk_speaker_x64.dll'
}

$out = Join-Path $root '.hemttout\build'
$mod = Join-Path $out '@BluetoothSpeaker'
if (Test-Path $mod) { Remove-Item $mod -Recurse -Force }
New-Item -ItemType Directory $mod | Out-Null
Get-ChildItem $out -Force | Where-Object Name -ne '@BluetoothSpeaker' | Copy-Item -Destination $mod -Recurse

if ($dll -and (Test-Path $dll)) { Copy-Item $dll $mod }

# The extension plays the songs from <mod>\music (it can't read inside a PBO)
$songs = Get-ChildItem (Join-Path $root 'addons\audio\sounds') -Filter *.ogg -ErrorAction SilentlyContinue
if ($songs) {
    New-Item -ItemType Directory (Join-Path $mod 'music') | Out-Null
    $songs | Copy-Item -Destination (Join-Path $mod 'music')
}

Write-Host "Ready to load: $mod"
if (-not $dll) { Write-Host "(no sound extension in this build: Arma's built-in sound will be used)" }
