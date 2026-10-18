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

# The app compiles against Android API 37 (ADR-0012). The Android Gradle
# plugin can download that platform during a build, but then fails that
# build, so a fresh SDK gets it first.
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
sdkmanager="$sdk/cmdline-tools/latest/bin/sdkmanager"
if [[ -n "$sdk" && -x "$sdkmanager" && ! -d "$sdk/platforms/android-37.0" ]]; then
  "$sdkmanager" --install 'platforms;android-37.0' >/dev/null
fi

flutter pub get --enforce-lockfile
flutter build apk "--$mode"

apk="build/app/outputs/flutter-apk/app-$mode.apk"
echo "APK: $apk ($(wc -c <"$apk") bytes)"
sha256sum "$apk"
