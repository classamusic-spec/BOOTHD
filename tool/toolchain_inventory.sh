#!/usr/bin/env bash
# Prints the development host and toolchain inventory (AC-0002).
# Usage: tool/toolchain_inventory.sh > inventory.txt
# Every probe runs even if an earlier one fails; missing tools are reported.
set -uo pipefail
cd "$(dirname "$0")/.."

section() { printf '\n## %s\n' "$*"; }
probe() {
  if command -v "$1" >/dev/null 2>&1; then
    "$@" 2>&1
    echo "(exit $?)"
  else
    echo "NOT INSTALLED: $1"
  fi
}

section 'Host'
date -u +%Y-%m-%dT%H:%M:%SZ
uname -a
if [[ -r /etc/os-release ]]; then grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release; fi
if [[ "$(uname -s)" == "Darwin" ]]; then sw_vers; fi

section 'Flutter and Dart'
probe flutter --version
probe dart --version

section 'Java'
probe java -version

section 'Android SDK packages'
probe sdkmanager --list_installed

section 'Xcode'
if [[ "$(uname -s)" == "Darwin" ]]; then
  probe xcodebuild -version
  probe xcrun simctl list devices available
  probe pod --version
else
  echo 'BLOCKED: Xcode requires macOS; iOS build and simulator checks cannot run on this host.'
fi

section 'flutter doctor -v'
probe flutter doctor -v

section 'Devices and emulators'
probe flutter devices
probe flutter emulators

section 'Resolved dependencies (pubspec.lock)'
probe flutter pub deps --style=compact
