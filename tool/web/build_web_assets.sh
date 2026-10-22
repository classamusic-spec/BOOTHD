#!/usr/bin/env bash
# Places the browser database's two assets in web/ (ADR-0018):
#   web/sqlite3.wasm     SQLite for the browser, from the sqlite3 package's
#                        release matching the version pinned in pubspec.lock;
#                        its SHA-256 is checked.
#   web/drift_worker.js  the database worker, compiled from
#                        tool/web/drift_worker.dart with the pinned drift.
# Both are committed; run this again after upgrading drift or sqlite3.
set -euo pipefail
cd "$(dirname "$0")/../.."

SQLITE3_VERSION=3.5.2
SQLITE3_WASM_SHA256=13d3f11d05b39ba0618a7115fb41640a5d48b6300f5d3f325f554b42bd6688a4

locked=$(awk '/^  sqlite3:$/{f=1} f&&/version:/{gsub(/"/,"",$2);print $2;exit}' pubspec.lock)
if [[ "$locked" != "$SQLITE3_VERSION" ]]; then
  echo "pubspec.lock has sqlite3 $locked; update SQLITE3_VERSION and its checksum" >&2
  exit 2
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/sqlite3.wasm" \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$SQLITE3_VERSION/sqlite3.wasm"
echo "$SQLITE3_WASM_SHA256  $tmp/sqlite3.wasm" | sha256sum -c --quiet
cp "$tmp/sqlite3.wasm" web/sqlite3.wasm

dart compile js -O4 -o "$tmp/drift_worker.js" tool/web/drift_worker.dart
cp "$tmp/drift_worker.js" web/drift_worker.js
echo "web/sqlite3.wasm and web/drift_worker.js are up to date"
