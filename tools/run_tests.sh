#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION=${GODOT_VERSION:-4.7.2-stable}
if [ -z "${GODOT:-}" ]; then
  if command -v godot >/dev/null 2>&1; then GODOT=godot
  else
    case "$(uname -s)" in
      MINGW*|MSYS*|CYGWIN*) GODOT=".bin/Godot_v${VERSION}_win64_console.exe" ;;
      *) GODOT=".bin/Godot_v${VERSION}_linux.x86_64" ;;
    esac
  fi
fi
if [ ! -f "$GODOT" ] && ! command -v "$GODOT" >/dev/null 2>&1; then
  bash tools/setup_godot.sh
fi
"$GODOT" --headless --path . --editor --import
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gpost_run_script=res://tools/finish_tests.gd -gexit
