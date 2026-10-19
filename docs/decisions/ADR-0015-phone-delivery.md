# ADR-0015: Optional phone delivery (MMS preview and private link)

- Status: Accepted for implementation (M09, 2026-10-19). Live sending is
  not enabled anywhere: no domain, backend project, Twilio account,
  sender registration, legal review, tablet or test phone exists yet
  (`docs/delivery/PREREQUISITES.md`). Section 10 lists what only those
  can settle.
- Implements: PD-01 to PD-10 (`docs/PHONE_DELIVERY_SPEC.md`), UX-PD1 to
  UX-PD7 (`docs/PHONE_DELIVERY_UX.md`), S30 to S36, the approved
  exception in `CLAUDE.md` ("optional authenticated delivery backend").
- Covers: AC-0901..AC-0922. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M09).
  Threat model: `docs/delivery/THREAT_MODEL.md`. Contract:
  `backend/openapi/delivery-v1.yaml`. Device and carrier steps:
  `docs/device_tests/M09_DEVICE_PROCEDURE.md`.

## Context

Guests at a staffed booth often want their photo on their phone. The
booth must stay a fully offline product: capture, the finished photo,
the gallery and export never wait for a network. Texting needs a sender
(Twilio), a registered US campaign or toll-free number, a public HTTPS
place for the provider to fetch the picture and for the guest to
download the full photo, and somewhere to keep secrets that must never
ship in an app. It also handles phone numbers, which are personal data,
and costs money per message.

## Decision

### 1. Two independent halves

- **The booth app** asks, records consent, keeps a durable local queue
  and hands each request to the service. It holds one secret: its own
  booth credential, in platform secure storage. It never holds a Twilio
  key, a storage key or the database address, and it never calls Twilio.
- **The delivery backend** (`backend/`, Postgres plus one Deno Edge
  Function on Supabase, or any equivalent host) authenticates booths,
  stores the consent receipt, validates the two uploads, sends the text
  through Twilio's Messaging Service, follows Twilio's signed status and
  inbound webhooks, serves the preview to Twilio and the download page to
  the guest, and deletes everything on schedule.
- Delivery is off by default at every level: the tenant's
  `sending_enabled`, the booth's pairing, the event's toggle. The server
  refuses to send until an administrator records the sender registration
  reference and the legal review (`readiness.ts`), and the booth offers
  texting only when the service says it is ready.

### 2. Booth identity

- An administrator issues a single-use pairing code (12 Crockford base-32
  characters, 30 minutes, stored hashed). The operator types it on the
  booth with the service's HTTPS address (S36). The booth receives a
  256-bit credential, stored hashed on the server and in platform secure
  storage on the tablet (Keychain, Android Keystore-backed storage).
- The credential is exchanged for 15-minute access tokens. Credentials
  can be rotated (the old one works ten more minutes) and revoked by the
  administrator; a revoked booth gets `CREDENTIAL_INVALID` and must be
  paired again.
- Pairing addresses must be `https` (plain `http` only for the loopback
  addresses used by tests). Upload URLs the service returns must be on
  the paired host (`UPLOAD_URL_UNTRUSTED` otherwise).

### 3. Consent and the guest's screens

- S30 appears only after the finished photo is verified and saved; texting
  is a choice beside "No thanks, finish". The photo is never held back.
- S31: a keypad for a US (+1) number, validated to E.164 with the same
  rules as the backend (ten digits; area code and exchange start 2 to 9;
  no N11 codes; no non-geographic area codes 555, 900 or 976; Canadian,
  Caribbean and US-territory area codes refused as not yet supported),
  and a separate consent box that starts unchecked. Whether a number is a
  mobile is known only to the provider (a landline fails there). "Send my photos" stays disabled until both are valid, then a
  confirmation shows the full number once. Privacy and Terms open in-app
  cards with the address to read on the guest's own phone: the booth never
  opens a browser.
- The consent text is versioned (`pd-consent-1`), its SHA-256 is stored
  with the request and sent to the server, which stores an immutable
  receipt (version, digest, time, event, session, screen S31, locale and a
  keyed digest of the number). It covers one transactional text about
  this photo; there is no list, no marketing and no second message.
- S32 never claims more than is known: "Text request sent" (provider
  accepted), "Delivery confirmed" only on a carrier delivery report,
  "Waiting for a connection" when queued offline, plain failures for
  opt-outs and unsupported numbers. Read receipts do not exist for MMS and
  nothing implies one. "Done" is always available; the booth's own finish
  timeout resets the screen (and wipes the number) whatever the guest is
  doing, and each touch restarts that timeout so nobody is cut off
  mid-number.

### 4. The booth's queue (schema version 7)

- `delivery_intents` stores each consented request before anything leaves
  the tablet: ids, the last four digits only, consent version and digest,
  link days, event limit, whether offline waiting was allowed, a per-
  request idempotency key, the local state (`queued`, `handingOver`,
  `handedOver`, `finished`), the service's mirrored status, history,
  attempts and the next retry time. The full number lives in platform
  secure storage under the request's id and is erased once the service has
  it, when the request ends, after 24 hours or when its session is
  deleted.
- `delivery_pairings` keeps the pairing and the service's last readiness
  answer (trusted for 24 hours, so the consent screen works through a
  short outage). `event_delivery_options` holds each event's settings.
  `delivery_remote_revocations` journals hosted copies to revoke when a
  session is deleted while offline.
- The queue runs only while the app is in front (`DeliveryRunner`): a pass
  at start and on resume, then one when work is due, and a readiness
  check every ten minutes while paired. iPadOS and Android do not let the
  booth send reliably from the background, so it does not pretend to.
- Retries back off with jitter and stop at the 24-hour consent window;
  then the request expires and its number is erased. Requests the event
  did not allow to wait are dropped at once when the service cannot be
  reached.

### 5. Uploads and the two storage paths

- Exactly two files per delivery: the finished composition (the gallery's
  verified output, unchanged) and a JPEG preview the booth makes from it
  (longest side at most 1024 px, quality stepped down until under the
  service's byte budget, 600 kB by default, hard cap under 5 MB). Raw
  camera originals are never uploaded.
- Each upload declares format, byte size, SHA-256 and pixel size; the
  service checks the bytes against all four (type read from the bytes, not
  the header) and refuses anything else. Upload grants are single use and
  15 minutes long.
- Finished photos go to a private bucket; previews to another private
  bucket. Twilio fetches the preview through `/m/{token}`: a separate
  60-minute GET/HEAD-only capability that is never the guest's link. The
  guest's link `/p/{token}` (128-bit random token, stored as SHA-256)
  serves a noindex page (`X-Robots-Tag`, CSP, `no-referrer`, no analytics)
  and short-lived private downloads of the full file.

### 6. Sending exactly once

- Every request carries the booth's idempotency key; a repeat returns the
  same delivery. A commit queues one dispatch job.
- The dispatcher leases jobs. It retries only after a definite
  non-submission (a 4xx from Twilio that proves nothing was queued, or a
  connection that never reached it). A timeout or 5xx after the request
  left becomes `delivery_unknown`; the reconciler looks for the message by
  its link hash in Twilio's records, and if it cannot decide, an operator
  does (S35: "Close it", or "Send again" acknowledging the guest may get
  two texts).
- Status webhooks are verified with Twilio's own `validateRequest` (the
  official library, `npm:twilio@6.2.0/lib/webhooks`), stored once by event
  identity and applied forward only (`queued` < `sent` < `delivered`;
  `failed`/`undelivered` are final), so repeats and out-of-order reports
  change nothing. "Sent" never becomes "read".
- Inbound STOP/START/HELP (and their synonyms) are verified the same way.
  STOP adds a keyed digest of the number to the suppression list, which
  every later request checks; HELP gets empty TwiML so Twilio's Messaging
  Service answers once with the operator's HELP text (no duplicate
  replies).

### 7. Limits and cost

- Per recipient 3 an hour and 6 a day; per booth and per tenant daily
  limits (150 and 200 by default); per event the smaller of the event's
  limit and the tenant's (500 by default); a monthly budget (US$20 by
  default) against an estimate of 3.2 cents a message. Pairing (10 per
  10 minutes), administrator calls and the guest page are rate limited by
  a daily-rotating keyed hash of the caller's address. Operators see the event's estimate in S34 and the
  month's in S36; the provider's invoice is the truth.

### 8. Retention

- An unsent request expires 24 hours after consent. The number's
  ciphertext is erased when the text is submitted, fails, expires or is
  canceled. Hosted files are deleted when the link expires (7 days by
  default, at most 14 unless the administrator raises it to 30) or is
  revoked, and the provider's media copy is deleted too. Job rows without
  personal data stay 90 days for support; the suppression list and
  consent receipts stay as long as the law requires (legal review).
- Deleting a session on the booth revokes its hosted copies (journaled
  while offline). Copies already delivered to a phone cannot be recalled;
  the operator screens and the privacy draft say so.

### 9. Environments

- Staging and production are separate projects with separate secrets.
  Staging sends only to administrator-approved test numbers (keyed
  digests), so device tests cannot text a stranger.

## Consequences

- The booth gains no network dependency: with texting off, unpaired,
  offline or failing, every guest still finishes with a saved photo.
- No new packages on the booth. The HTTP client is `dart:io`; secure
  storage reuses the PIN's plugin (`flutter_secure_storage`).
- Android release builds now declare `INTERNET` (until M09 only debug and
  profile builds did, for Flutter's tooling). Cleartext traffic stays off.
  iPadOS needs no entitlement for HTTPS; App Transport Security stays at
  its defaults. An unpaired booth makes no network request at all.
- The backend adds Postgres, Deno and Twilio's webhook validator, all
  pinned (`backend/deno.lock`). Its correctness is tested locally against
  a real Postgres 16, a stand-in Twilio API and in-memory storage; no
  test touches a live service.
- Operating it costs money and carries legal duties (registration,
  consent records, opt-outs, retention): `docs/delivery/OPERATIONS.md`.

## Verification

- Backend: `backend/tool/test.sh` (format, lint, type check, 67 tests on
  a real Postgres): pairing, quotas, uploads, dispatch with ambiguous
  outcomes, reconciliation, webhooks with tampered or missing signatures,
  STOP/HELP, preview and download pages, revocation, retention, a contract
  test that keeps `openapi/delivery-v1.yaml` and the routes identical.
- Booth: domain rules (E.164, consent digest, retry policy), the service
  over the real database (queue, offline, expiry, idempotency, restart),
  the HTTP client against a local server, schema v7 migration tests, the
  guest flow end to end in both orientations at every tablet size, the
  operator screens, goldens of S30 to S36.
- Booth against backend: `tool/delivery_contract.sh` runs the backend
  locally and drives the app's real HTTP client through pairing,
  readiness, a delivery with both uploads, the stand-in provider fetching
  the preview, the guest page and download, status reports and
  revocation.

## Open questions (need the real world)

1. Real MMS on certified US carriers: preview transcoding, link
   rendering, delivery reports (AC-0912, AC-0920).
2. Twilio's current per-message prices and carrier fees (PD-08).
3. The legal review of the consent wording, minors at events, and how
   long consent receipts and the opt-out list must be kept.
4. iPad and Android behaviour of secure storage and the queue across
   restarts, captive portals and long offline periods (AC-0905, AC-0906
   device rows).
5. Whether the operator's domain fronts the Supabase function directly or
   through a proxy (the default Supabase domain cannot serve HTML pages).
