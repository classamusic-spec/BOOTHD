#!/usr/bin/env bash
# Repeatable static and unit checks (AC-0003, AC-0004, AC-0005).
# Same sequence as CI; run from any directory. Stops at the first failure.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

step 'flutter pub get --enforce-lockfile'
flutter pub get --enforce-lockfile

step 'dart format --output=none --set-exit-if-changed .'
dart format --output=none --set-exit-if-changed .

step 'flutter analyze'
flutter analyze

step 'flutter test'
flutter test

step 'dependency license report is current'
dart run tool/dependency_licenses.dart --check

printf '\nAll checks passed.\n'
