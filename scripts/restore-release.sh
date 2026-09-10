#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT/release"
RUNTIME_DIR="${QA_RUNTIME_DIR:-$ROOT/.runtime}"
ZIP="$RUNTIME_DIR/qa-superpower-v4-enterprise.zip"
EXPECTED_SHA="ed0b19c8313e1278ca44451ee2d2aa9ec53be38f2fbe91e307e9721fb9964d13"

mkdir -p "$RUNTIME_DIR"
rm -rf "$RUNTIME_DIR/qa-superpower-v4" "$ZIP"

parts=("$RELEASE_DIR"/qa-superpower-v4-enterprise.zip.b64.part*)
if [ "${#parts[@]}" -ne 15 ]; then
  echo "Expected 15 release chunks, found ${#parts[@]}" >&2
  exit 1
fi

cat "${parts[@]}" | base64 -d > "$ZIP"
ACTUAL_SHA="$(sha256sum "$ZIP" | awk '{print $1}')"
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
  echo "Release checksum mismatch: expected $EXPECTED_SHA, got $ACTUAL_SHA" >&2
  exit 1
fi

unzip -q "$ZIP" -d "$RUNTIME_DIR"
test -f "$RUNTIME_DIR/qa-superpower-v4/server.js"
test -f "$RUNTIME_DIR/qa-superpower-v4/index.html"
test -f "$RUNTIME_DIR/qa-superpower-v4/package.json"

echo "$RUNTIME_DIR/qa-superpower-v4"
