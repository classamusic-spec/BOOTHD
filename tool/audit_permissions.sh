#!/usr/bin/env bash
# Audits the permissions a built Android app declares after manifest merging
# (AC-1007): the camera for guests' photos, the network for optional phone
# delivery, and androidx's own signature permission for unexported
# receivers. Anything else a plugin or library adds fails the audit, so a
# new permission is a decision, not an accident.
#
# Usage: tool/audit_permissions.sh build/app/outputs/flutter-apk/app-release.apk
# Exit codes: 0 as expected, 1 unexpected or missing permissions, 2 usage or
# tool error.
set -euo pipefail

apk="${1:-}"
if [[ -z "$apk" || ! -f "$apk" ]]; then
  echo "usage: $0 <app.apk>" >&2
  exit 2
fi

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/opt/android-sdk}}"
aapt2="$(ls -1d "$sdk"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)"
if [[ -z "$aapt2" ]]; then
  echo "aapt2 not found under $sdk/build-tools" >&2
  exit 2
fi

dump="$("$aapt2" dump permissions "$apk")"
package="$(sed -n "s/^package: //p" <<<"$dump")"
actual="$(sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p" <<<"$dump" | sort -u)"
expected="$(printf '%s\n' \
  android.permission.CAMERA \
  android.permission.INTERNET \
  "$package.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" | sort -u)"

echo "$package declares:"
sed 's/^/  /' <<<"$actual"
if [[ "$actual" != "$expected" ]]; then
  echo "Unexpected permissions (+ added, - missing):" >&2
  diff <(echo "$expected") <(echo "$actual") | sed -n 's/^> /  + /p; s/^< /  - /p' >&2
  exit 1
fi
echo "Permission audit passed."
