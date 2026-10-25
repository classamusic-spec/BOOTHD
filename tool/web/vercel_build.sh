#!/usr/bin/env bash
# Builds the web test build on Vercel (ADR-0018). Vercel has no Flutter, so
# the install step fetches the pinned SDK and the build step runs
#   flutter build web --release --no-web-resources-cdn
# into build/web, which vercel.json serves with its headers.
#   bash tool/web/vercel_build.sh install|build
# Uses an installed Flutter when it is already the pinned version.
set -euo pipefail
cd "$(dirname "$0")/../.."

FLUTTER_VERSION=3.47.7
SDK="${FLUTTER_SDK_DIR:-$PWD/.vercel-flutter}"

flutter_bin() {
  if command -v flutter >/dev/null 2>&1 &&
    flutter --version 2>/dev/null | head -1 | grep -q "Flutter $FLUTTER_VERSION "; then
    command -v flutter
  else
    echo "$SDK/bin/flutter"
  fi
}

case "${1:-}" in
  install)
    if [[ "$(flutter_bin)" == "$SDK/bin/flutter" && ! -x "$SDK/bin/flutter" ]]; then
      # The SDK's first run unpacks the Dart SDK with unzip.
      command -v unzip >/dev/null 2>&1 || dnf install -y unzip >/dev/null
      git clone --depth 1 --branch "$FLUTTER_VERSION" \
        https://github.com/flutter/flutter.git "$SDK"
    fi
    FLUTTER="$(flutter_bin)"
    "$FLUTTER" config --no-analytics >/dev/null
    "$FLUTTER" --version
    "$FLUTTER" pub get --enforce-lockfile
    ;;
  build)
    FLUTTER="$(flutter_bin)"
    "$FLUTTER" build web --release --no-web-resources-cdn
    # The database's two browser assets must be in the output.
    test -s build/web/sqlite3.wasm
    test -s build/web/drift_worker.js
    ;;
  *)
    echo "usage: $0 install|build" >&2
    exit 2
    ;;
esac
