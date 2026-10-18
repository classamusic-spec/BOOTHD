#!/usr/bin/env bash
# Android APK smoke build. Usage: tool/build_android.sh [debug|profile|release]
#
# Release builds are signed with the debug key until release signing is set
# up in M12 (ADR-0001); they are smoke builds, not distributable artifacts.
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

flutter pub get --enforce-lockfile
flutter build apk "--$mode"

apk="build/app/outputs/flutter-apk/app-$mode.apk"
echo "APK: $apk ($(wc -c <"$apk") bytes)"
sha256sum "$apk"
