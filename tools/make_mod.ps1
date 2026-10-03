# Windows: (optionally convert music) + hemtt build, then assemble a ready-to-load @JBLSpeaker folder
# in .hemttout\build\. Usage: powershell -File tools\make_mod.ps1 [-Music]
param([switch]$Music)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')

$hemtt = (Get-Command hemtt -ErrorAction SilentlyContinue).Source
if (-not $hemtt) { $hemtt = "$env:LOCALAPPDATA\hemtt\hemtt.exe" }

if ($Music) { python tools\convert_music.py; if ($LASTEXITCODE) { throw 'convert_music failed' } }

& $hemtt build
if ($LASTEXITCODE) { throw 'hemtt build failed' }

$out = Join-Path $root '.hemttout\build'
$mod = Join-Path $out '@JBLSpeaker'
if (Test-Path $mod) { Remove-Item $mod -Recurse -Force }
New-Item -ItemType Directory $mod | Out-Null
Get-ChildItem $out -Force | Where-Object Name -ne '@JBLSpeaker' | Copy-Item -Destination $mod -Recurse
Write-Host "Ready to load: $mod"
