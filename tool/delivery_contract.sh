#!/usr/bin/env bash
# The booth app's delivery client against the real delivery backend, on
# this machine (M09): starts Postgres (unless DELIVERY_TEST_DATABASE_URL is
# set), the backend with its stand-in for Twilio
# (backend/tool/serve_local.ts), then runs test/delivery/live_contract_test.dart
# against it. Nothing leaves this machine; no real text is sent.
set -euo pipefail

cd "$(dirname "$0")/.."
DENO="${DENO:-deno}"
dir="$(mktemp -d)"
server_pid=""
pg_started=""
run() { "$@"; }

cleanup() {
  if [[ -n "$server_pid" ]]; then kill -TERM "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true; fi
  if [[ -n "$pg_started" ]]; then run "$PG_BIN/pg_ctl" -D "$dir/data" -m immediate stop >/dev/null 2>&1 || true; fi
  rm -rf "$dir"
}
trap cleanup EXIT

if [[ -z "${DELIVERY_TEST_DATABASE_URL:-}" ]]; then
  PG_BIN="${PG_BIN:-$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1)}"
  port="${DELIVERY_TEST_PG_PORT:-54331}"
  if [[ "$(id -u)" == "0" ]]; then
    chown postgres:postgres "$dir"
    run() { runuser -u postgres -- "$@"; }
  fi
  run "$PG_BIN/initdb" -D "$dir/data" -U postgres --auth=trust -E UTF8 --no-locale >/dev/null
  run "$PG_BIN/pg_ctl" -D "$dir/data" -l "$dir/log" -w \
    -o "-p $port -c listen_addresses=127.0.0.1 -k $dir -c fsync=off" start >/dev/null
  pg_started=1
  export DELIVERY_TEST_DATABASE_URL="postgres://postgres@127.0.0.1:$port/postgres"
fi

mkfifo "$dir/out"
"$DENO" run --allow-net --allow-env --allow-read backend/tool/serve_local.ts >"$dir/out" &
server_pid=$!
read -r line <"$dir/out"
echo "backend: $(echo "$line" | sed 's/"pairingCode":"[^"]*"/"pairingCode":"(hidden)"/')"
# Keep reading so the server never blocks on a full pipe.
cat "$dir/out" >/dev/null &

DELIVERY_CONTRACT="$line" flutter test test/delivery/live_contract_test.dart --reporter expanded
