#!/usr/bin/env bash
# Scans a built app (APK, AAB or IPA) for secrets that must never ship in
# the booth app (CLAUDE.md: "Only backend can call Twilio; Flutter must not
# include messaging keys"; AC-0911, AC-0918): messaging provider ids and
# keys, Supabase service keys, private keys and backend secret names.
#
# Usage: tool/scan_binary_secrets.sh build/app/outputs/flutter-apk/app-release.apk
# Exit codes: 0 nothing found, 1 something found, 2 usage or unpacking error.
set -euo pipefail

archive="${1:-}"
if [[ -z "$archive" || ! -f "$archive" ]]; then
  echo "usage: $0 <app.apk|app.aab|app.ipa>" >&2
  exit 2
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
if ! unzip -q "$archive" -d "$work/unpacked"; then
  echo "could not unpack $archive" >&2
  exit 2
fi

# Every printable run of 6+ characters in every file (code, native
# libraries, resources, assets).
find "$work/unpacked" -type f -print0 |
  xargs -0 strings -a -n 6 >"$work/strings.txt"

declare -a names=(
  'Twilio account SID'
  'Twilio API key SID'
  'Twilio API host'
  'Supabase secret key'
  'Supabase service role'
  'JSON web token'
  'Private key block'
  'Backend secret name'
)
declare -a patterns=(
  'AC[0-9a-f]{32}'
  'SK[0-9a-f]{32}'
  'api\.twilio\.com'
  'sb_secret_[A-Za-z0-9_-]{10,}'
  'service_role'
  'eyJhbGciOi[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'DELIVERY_(PHONE_KEY|DIGEST_KEY|DATABASE_URL|ADMIN_TOKEN)|TWILIO_(AUTH_TOKEN|API_SECRET)|SUPABASE_SERVICE_ROLE_KEY'
)

found=0
for i in "${!patterns[@]}"; do
  count="$(grep -cE -- "${patterns[$i]}" "$work/strings.txt" || true)"
  if [[ "$count" != "0" ]]; then
    found=1
    echo "FOUND ${names[$i]}: $count string(s) match /${patterns[$i]}/"
  else
    echo "none  ${names[$i]}"
  fi
done

files="$(find "$work/unpacked" -type f | wc -l)"
total="$(wc -l <"$work/strings.txt")"
echo "scanned $files files, $total strings in $(basename "$archive")"
exit "$found"
