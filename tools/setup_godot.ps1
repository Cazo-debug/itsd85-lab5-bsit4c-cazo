$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    if (Get-Command godot -ErrorAction SilentlyContinue) { return }
    $gameVersion = if ($env:GODOT_VERSION) { $env:GODOT_VERSION } else { '4.7.2-stable' }
    $gameBinary = ".bin/Godot_v${gameVersion}_win64_console.exe"
    if (-not (Test-Path -LiteralPath $gameBinary)) {
        New-Item -ItemType Directory -Force .bin | Out-Null
        Invoke-WebRequest "https://github.com/godotengine/godot-builds/releases/download/$gameVersion/Godot_v${gameVersion}_win64.exe.zip" -OutFile .bin/godot.zip
        Expand-Archive .bin/godot.zip -DestinationPath .bin -Force
    }
    Write-Output (Resolve-Path -LiteralPath $gameBinary)
} finally { Pop-Location }
