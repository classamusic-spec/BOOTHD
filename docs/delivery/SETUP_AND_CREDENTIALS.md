# Phone delivery: setup and credentials

How an administrator deploys the delivery backend (`backend/`) and connects
booths. Nothing here has been carried out for a real project yet
(`PREREQUISITES.md`): this is the procedure the first deployment follows.
Commands assume the Supabase CLI and `openssl`.

**Never put any of these secrets in the booth app, a booth's settings, a
repository, a ticket or a chat.** The app needs only a pairing code, typed
once on each booth.

## 1. Two environments

| | Staging | Production |
| --- | --- | --- |
| Supabase project | `porcelain-delivery-staging` | `porcelain-delivery` |
| Twilio | Separate Messaging Service (or subaccount) with a test sender | The registered Messaging Service |
| Domain | `photos-staging.<operator-domain>` | `photos.<operator-domain>` |
| `DELIVERY_ENVIRONMENT` | `staging` (sends only to approved test numbers) | `production` |
| Data | Test phones only | Guests |

Each has its own secrets; nothing is shared between them.

## 2. Database and storage

```sh
supabase link --project-ref <ref>
supabase db push            # applies backend/supabase/migrations/
```

The migration creates the tables with row-level security on and no
policies (so the public `anon` and `authenticated` roles reach nothing),
revokes their default grants, and creates two private buckets,
`delivery-final` and `delivery-preview`. Check in the dashboard that both
buckets are private.

## 3. Secrets

Generate and set (the function reads them from its secret store):

```sh
PHONE_KEY=$(openssl rand -base64 32 | tr '+/' '-_' | tr -d '=')   # 32 bytes, base64url
DIGEST_KEY=$(openssl rand -hex 32)
ADMIN_TOKEN=$(openssl rand -base64 32 | tr '+/' '-_' | tr -d '=') # keep in a password manager
ADMIN_SHA=$(printf %s "$ADMIN_TOKEN" | openssl dgst -sha256 -r | cut -d' ' -f1)

supabase secrets set \
  DELIVERY_ENVIRONMENT=production \
  DELIVERY_PUBLIC_BASE_URL=https://photos.<operator-domain> \
  DELIVERY_DATABASE_URL='postgres://...pooler.supabase.com:6543/postgres' \
  DELIVERY_PHONE_KEY="$PHONE_KEY" \
  DELIVERY_DIGEST_KEY="$DIGEST_KEY" \
  DELIVERY_ADMIN_TOKEN_SHA256="$ADMIN_SHA" \
  TWILIO_ACCOUNT_SID=AC... \
  TWILIO_API_KEY_SID=SK... \
  TWILIO_API_KEY_SECRET=... \
  TWILIO_AUTH_TOKEN=... \
  TWILIO_MESSAGING_SERVICE_SID=MG...
```

- `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided to Edge
  Functions by Supabase; the function uses them only for private storage.
- Use a Twilio **API key** (restricted if available) for sending; the
  account **auth token** is needed only to verify webhook signatures.
- Without all five Twilio settings the service runs with sending off
  (`PROVIDER_NOT_CONFIGURED`).
- The service refuses to start in staging or production unless the public
  URL is `https://`.

## 4. Deploy the function

```sh
supabase functions deploy delivery    # config.toml sets verify_jwt = false
```

JWT verification is off on purpose: Twilio's webhooks and guests' links
carry no Supabase token. The function authenticates every request itself
(booth access tokens, Twilio signatures, bearer grants, the administrator
token).

## 5. Domain

Guests open `https://photos.<operator-domain>/p/<token>`. Supabase's
default domain does not serve HTML pages, so put the function behind the
operator's domain: a Supabase custom domain, or a reverse proxy (for
example a CDN rule) that forwards `https://photos.<operator-domain>/*` to
`https://<ref>.supabase.co/functions/v1/delivery/*` without caching. The
function strips `/functions/v1/delivery` and `/delivery` path prefixes
itself (`DELIVERY_PATH_PREFIXES` changes the list).

Proxy and platform logs: request URLs contain bearer tokens. Turn off
URL logging where possible, otherwise restrict log access and keep log
retention short.

## 6. Scheduler

Run the worker every minute (dispatch retries, reconciliation, retention).
With Supabase's `pg_cron` and `pg_net`, keeping the administrator token in
Vault:

```sql
select vault.create_secret('<ADMIN_TOKEN>', 'delivery_admin_token');
select cron.schedule('delivery-worker', '* * * * *', $$
  select net.http_post(
    url := 'https://photos.<operator-domain>/v1/admin/worker/run',
    headers := jsonb_build_object('Authorization', 'Bearer ' ||
      (select decrypted_secret from vault.decrypted_secrets where name = 'delivery_admin_token')),
    timeout_milliseconds := 25000);
$$);
```

Booth diagnostics show when the worker and the webhooks last ran.

## 7. Twilio

1. A business account with billing; a **Messaging Service** with an
   MMS-capable US sender (10DLC long code with an approved A2P campaign, or
   a verified toll-free number).
2. Registration material: the operator's brand, the use case
   (transactional, one text per consenting guest, no marketing), the
   consent screen exported from the app (Event > Texting > Export consent
   proof), the privacy and terms URLs, and the sample message from
   `OPERATIONS.md`.
3. Messaging Service > Integration > incoming messages: webhook
   `https://photos.<operator-domain>/webhooks/twilio/inbound` (HTTP POST).
   Status callbacks are set per message by the service.
4. Opt-out management: keep STOP/START/HELP handling on (Advanced Opt-Out
   if available) and set the HELP reply to the operator's support
   contact. The service never replies itself, so there are no duplicate
   replies.
5. Do not enable fallback to SMS: the consent covers one MMS with a link.

## 8. Tenant, limits, attestations, booths

```sh
API=https://photos.<operator-domain>
AUTH="Authorization: Bearer $ADMIN_TOKEN"

# The operator's business (sending starts off)
curl -sS -X POST $API/v1/admin/tenants -H "$AUTH" -H 'content-type: application/json' -d '{
  "name": "<business>", "brandName": "<name in texts>",
  "privacyUrl": "https://<domain>/privacy", "termsUrl": "https://<domain>/terms",
  "supportContact": "<email or phone>"}'

# Limits (defaults: 200 a day, 500 an event, $20 a month estimated, 7-day links)
curl -sS -X PATCH $API/v1/admin/tenants/<tenant-id> -H "$AUTH" -H 'content-type: application/json' \
  -d '{"dailySendLimit": 200, "eventSendLimit": 300, "monthlyBudgetCents": 2000}'

# Only with evidence in hand: the approved registration and the legal review
curl -sS -X POST $API/v1/admin/tenants/<tenant-id>/attestations -H "$AUTH" -H 'content-type: application/json' \
  -d '{"registration": true, "registrationReference": "<campaign id>", "legalReview": true}'

# The operator's switch (and the emergency off: false)
curl -sS -X PATCH $API/v1/admin/tenants/<tenant-id> -H "$AUTH" -H 'content-type: application/json' \
  -d '{"sendingEnabled": true}'

# A pairing code for one booth (30 minutes, single use)
curl -sS -X POST $API/v1/admin/tenants/<tenant-id>/pairing-codes -H "$AUTH"
```

On the booth: Studio > Settings > Phone delivery > enter the service
address and the code. The booth then shows the service's readiness; each
event turns texting on in its Texting tab.

Staging: approve each test phone first
(`POST /v1/admin/tenants/<id>/test-recipients` with `phone` and `label`).

## 9. Rotation and revocation

- Booth lost or retired: `POST /v1/admin/booths/<booth-id>/revoke` (its
  credential and tokens stop at once). Re-pair a replacement.
- Booth credential: the app can rotate it (Settings > Phone delivery); the
  old one works for ten more minutes.
- Twilio API key: create a new key, set the secret, redeploy, then delete
  the old key in Twilio.
- Administrator token: generate a new one, set its hash, redeploy.
- Phone encryption key: rotate only when no delivery is waiting (pending
  numbers are encrypted with the current key and would become unreadable,
  failing as `RECIPIENT_UNREADABLE`).
- Digest key: changing it forgets every opt-out. Do not rotate without a
  migration plan.

## 10. After deploying: checks

1. `GET /healthz` answers `{"ok": true}`; `GET /robots.txt` disallows all.
2. A booth pairs; its diagnostics show the service reachable, readiness
   reasons as expected, and the worker time updating every minute.
3. Staging: one delivery to an approved test phone end to end
   (`docs/device_tests/M09_DEVICE_PROCEDURE.md`), then STOP and START from
   that phone, a revoked link, and an expired link.
4. Production stays `sendingEnabled: false` until the go/no-go in
   `PREREQUISITES.md` is met.
