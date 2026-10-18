#!/usr/bin/env bash
# Unsigned iPadOS build. Usage: tool/build_ios.sh [debug|profile|release]
#
# Requires macOS with Xcode (docs/IOS_VALIDATION.md). On any other host it
# reports BLOCKED and exits 3 rather than pretending iOS was checked.
set -euo pipefail
cd "$(dirname "$0")/.."

mode="${1:-release}"
case "$mode" in
  debug | profile | release) ;;
  *)
    echo "usage: $0 [debug|profile|release]" >&2
    exit 64
    ;;
esac

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "BLOCKED: iOS builds require macOS with Xcode; this host is $(uname -s)." >&2
  exit 3
fi

xcodebuild -version
flutter pub get --enforce-lockfile
flutter build ios "--$mode" --no-codesign
