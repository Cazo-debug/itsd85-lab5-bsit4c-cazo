$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    $gameVersion = if ($env:GODOT_VERSION) { $env:GODOT_VERSION } else { '4.7.2-stable' }
    $gameBinary = if ($env:GODOT) { $env:GODOT } elseif (Get-Command godot -ErrorAction SilentlyContinue) { 'godot' } else { ".bin/Godot_v${gameVersion}_win64_console.exe" }
    if ($gameBinary -ne 'godot' -and -not (Test-Path -LiteralPath $gameBinary)) { & "$PSScriptRoot/setup_godot.ps1" }
    & $gameBinary --headless --path . --editor --import
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    & $gameBinary --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
    if ($LASTEXITCODE -ne 0) { throw 'GUT tests failed.' }
} finally { Pop-Location }
