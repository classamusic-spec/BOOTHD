#!/usr/bin/env bash
# Runs the delivery backend's checks: format, lint, type check and the
# test suite against a real Postgres. Uses DELIVERY_TEST_DATABASE_URL when
# set (CI's service container); otherwise starts a throwaway local cluster
# with the PostgreSQL server binaries and removes it afterwards.
set -euo pipefail

cd "$(dirname "$0")/.."
DENO="${DENO:-deno}"
"$DENO" --version | head -1

echo "==> deno fmt --check"
"$DENO" fmt --check
echo "==> deno lint"
"$DENO" lint
echo "==> deno check"
"$DENO" check supabase/functions/delivery/index.ts test/ tool/

cleanup() { :; }
if [[ -z "${DELIVERY_TEST_DATABASE_URL:-}" ]]; then
  PG_BIN="${PG_BIN:-$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1)}"
  dir="$(mktemp -d)"
  port="${DELIVERY_TEST_PG_PORT:-54329}"
  run() { "$@"; }
  if [[ "$(id -u)" == "0" ]]; then
    chown postgres:postgres "$dir"
    run() { runuser -u postgres -- "$@"; }
  fi
  run "$PG_BIN/initdb" -D "$dir/data" -U postgres --auth=trust -E UTF8 --no-locale >/dev/null
  run "$PG_BIN/pg_ctl" -D "$dir/data" -l "$dir/log" -w \
    -o "-p $port -c listen_addresses=127.0.0.1 -k $dir -c fsync=off" start >/dev/null
  cleanup() {
    run "$PG_BIN/pg_ctl" -D "$dir/data" -m immediate stop >/dev/null 2>&1 || true
    rm -rf "$dir"
  }
  trap cleanup EXIT
  export DELIVERY_TEST_DATABASE_URL="postgres://postgres@127.0.0.1:$port/postgres"
fi

echo "==> deno test"
"$DENO" test --allow-net --allow-env --allow-read "$@" test/
