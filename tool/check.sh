#!/usr/bin/env bash
# Repeatable static and unit checks (AC-0003, AC-0004, AC-0005), and
# freshness of committed generated code (M03).
# Same sequence as CI; run from any directory. Stops at the first failure.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

step 'flutter pub get --enforce-lockfile'
flutter pub get --enforce-lockfile

step 'generated code is current (build_runner, drift make-migrations)'
# Drift's database code, schema dumps and migration-test schemas are
# committed; regenerating must change nothing (ADR-0009).
generated() {
  find lib test drift_schemas -type f \( -name '*.g.dart' \
    -o -path 'test/drift/*/generated/*' -o -path 'drift_schemas/*' \) \
    | sort | xargs sha256sum
}
before=$(generated)
dart run build_runner build
dart run drift_dev make-migrations
after=$(generated)
if [[ "$before" != "$after" ]]; then
  diff <(printf '%s\n' "$before") <(printf '%s\n' "$after") || true
  echo 'Generated code was stale: commit the regenerated files above.' >&2
  exit 1
fi

step 'dart format --output=none --set-exit-if-changed .'
dart format --output=none --set-exit-if-changed .

step 'flutter analyze'
flutter analyze

step 'flutter test'
flutter test

step 'dependency license report is current'
dart run tool/dependency_licenses.dart --check

printf '\nAll checks passed.\n'
