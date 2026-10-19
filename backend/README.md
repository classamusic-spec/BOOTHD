# Phone-delivery backend (M09)

The optional service that texts a consenting guest one MMS: a small
preview of their finished photo and a private, expiring link to the full
quality file. The booth app works completely without it. Decision record:
`docs/decisions/ADR-0015-phone-delivery.md`; threat model:
`docs/delivery/THREAT_MODEL.md`; contract: `openapi/delivery-v1.yaml`.

**Status: built and tested locally against a real Postgres, a stand-in for
Twilio's API and in-memory storage. Not deployed. No sender is registered
and no real text has been sent.** Live sending stays off until every
prerequisite in `docs/delivery/PREREQUISITES.md` is met.

## Layout

| Path | What |
| --- | --- |
| `supabase/migrations/` | Postgres schema v1: jobs, consent receipts, grants, suppression, provider events, audit; row-level security on, no policies |
| `supabase/functions/delivery/index.ts` | The Edge Function entry (Deno) |
| `supabase/functions/_shared/` | All logic: auth and pairing, intake and quotas, uploads, dispatcher with leases and reconciliation, webhooks, preview fetch, download page, retention, admin |
| `supabase/config.toml` | Function settings (`verify_jwt = false`: the service authenticates every request itself) |
| `openapi/delivery-v1.yaml` | API contract v1 (a test keeps it in step with the routes) |
| `test/` | Deno tests: unit, and integration against a fresh database per test |
| `tool/test.sh` | Format, lint, type check and tests (starts a throwaway Postgres when none is given) |
| `tool/serve_local.ts` | A local instance for the app's contract test (fake provider, memory storage) |
| `tool/make_fixtures.py` | Draws the synthetic test images |

## Running the checks

Needs Deno 2.9.6 and PostgreSQL 16 server binaries (or a database URL):

```sh
backend/tool/test.sh
# or against an existing server:
DELIVERY_TEST_DATABASE_URL=postgres://postgres@127.0.0.1:5432/postgres backend/tool/test.sh
```

CI runs the same script with a Postgres service container (job "Delivery
backend").

## Dependencies

Pinned in `deno.lock`:

- `npm:postgres@3.4.9` (Unlicense): the Postgres client.
- `npm:twilio@6.2.0` (MIT): only `lib/webhooks/webhooks.js`, Twilio's
  official signature validation. Sending uses Twilio's documented REST API
  over `fetch`, so no SDK HTTP stack is loaded.
- `jsr:@std/assert@1.0.13`, `jsr:@std/yaml@1.0.9` (MIT): tests only.

## Deploying

See `docs/delivery/SETUP_AND_CREDENTIALS.md`. In short: a Supabase project
per environment (staging, production), the migration applied, the function
deployed with its secrets, a custom HTTPS domain, a scheduled call to
`/v1/admin/worker/run` every minute, and Twilio's Messaging Service
pointing its status and inbound webhooks at this service. Sending is
enabled per tenant only after the administrator records the sender
registration and the legal review.
