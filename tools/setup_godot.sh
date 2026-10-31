#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if command -v godot >/dev/null 2>&1; then exit 0; fi
VERSION=${GODOT_VERSION:-4.7.2-stable}
mkdir -p .bin
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/setup_godot.ps1
    exit $? ;;
  Linux*) TARGET=linux.x86_64 ;;
  *) echo 'Use Godot standard build on Windows or Linux x86_64.' >&2; exit 1 ;;
esac
FILE="Godot_v${VERSION}_${TARGET}"
if [ ! -x ".bin/$FILE" ]; then
  curl -fL "https://github.com/godotengine/godot-builds/releases/download/${VERSION}/${FILE}.zip" -o .bin/godot.zip
  unzip -o .bin/godot.zip -d .bin
  chmod +x ".bin/$FILE"
fi
