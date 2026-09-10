#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$ROOT/scripts/restore-release.sh"
cd "$ROOT/.runtime/qa-superpower-v4"
npm install
if [ "${INSTALL_PLAYWRIGHT_BROWSER:-false}" = "true" ]; then
  npx playwright install chromium
fi
npm run check
