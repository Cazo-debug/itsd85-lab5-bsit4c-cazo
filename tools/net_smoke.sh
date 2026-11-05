#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if command -v python >/dev/null 2>&1; then
  python tools/net_smoke.py "$@"
else
  python3 tools/net_smoke.py "$@"
fi
