#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/.runtime/qa-superpower-v4"
if [ ! -f "$APP/server.js" ]; then
  bash "$ROOT/scripts/restore-release.sh" >/dev/null
fi
cd "$APP"
exec npm start
