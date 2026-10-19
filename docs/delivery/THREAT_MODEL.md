# Phone delivery: threat model (M09)

Scope: the optional phone-delivery feature (PD-01 to PD-10), from the
guest's consent on the booth to the private download page, with its
backend (`backend/`) and the Twilio sender. The offline booth (capture,
rendering, gallery, export) is out of scope: it never depends on this
feature. Decisions: `docs/decisions/ADR-0015-phone-delivery.md`.

Method: assets, actors and trust boundaries, then threats per boundary
(STRIDE-style), each with its mitigation, where it is tested and what
remains. "Tested" names the test that exercises it; "device" or "live"
marks what only a tablet, a real sender or a real phone can show.

## 1. Assets

| Asset | Where it lives | Sensitivity |
| --- | --- | --- |
| Guest phone number | Booth: platform secure storage (per pending delivery, erased when done); backend: AES-256-GCM ciphertext (erased after sending, failure, expiry or purge), a keyed HMAC digest, the last four digits | Personal data |
| Consent receipt | Backend `consent_receipts` (immutable): text version and SHA-256 of the exact text, time, event, session, screen, locale, keyed digest | Evidence |
| Finished photo (full quality) | Booth gallery; backend private bucket `delivery-final` until link expiry or revocation | Personal data (likeness) |
| MMS preview | Backend private bucket `delivery-preview`; Twilio's media copy; carriers; phones | Personal data |
| Download link token | Only in the text message (stored as SHA-256) | Bearer capability |
| Preview fetch token | Only in the provider request (stored as SHA-256), 60 minutes | Bearer capability |
| Booth credential | Booth platform secure storage; backend stores SHA-256 | Authenticates a booth |
| Booth access token | Booth memory, 15 minutes; backend stores SHA-256 | Short-lived |
| Pairing code | Shown once to the administrator; SHA-256, 30 minutes, single use | One-time |
| Administrator token | Held by the administrator outside every booth; backend holds its SHA-256 | Full control |
| Twilio API key and auth token | Backend secret store only | Can send texts and spend money |
| Phone encryption key, digest key, database URL, storage service key | Backend secret store only | Decrypts or reaches everything |
| Opt-out list | Backend `suppression_entries` (keyed digests) | Must outlive photos |

## 2. Actors

- **Guest**: enters a number and consents; may be a minor (owner/legal
  question); may mistype or use someone else's number.
- **Next guest / bystander** at the booth: must never see a previous
  guest's number or photo.
- **Operator**: runs events in the Studio behind the PIN; sees masked
  numbers only; can cancel, revoke, resolve.
- **Administrator**: runs the backend, issues pairing codes, records the
  sender registration and legal review, sets limits.
- **Twilio**: sends; fetches the preview; reports statuses; relays
  STOP/HELP.
- **Recipient of a forwarded link**, link-preview crawlers, search engines.
- **Attacker**: on the venue network, holding a stolen tablet, guessing
  links, forging webhooks, abusing the API to send spam or run up cost.

## 3. Trust boundaries

1. Guest ↔ booth app (kiosk UI).
2. Booth app ↔ delivery API (internet, TLS, booth access token).
3. Delivery API ↔ Postgres and private storage (service credentials).
4. Delivery API ↔ Twilio REST API (API key, TLS).
5. Twilio ↔ delivery API (signed webhooks; unauthenticated preview fetch
   by token).
6. Anyone with the link ↔ download page.

## 4. Threats and mitigations

| # | Threat | Mitigation | Tested | Remains |
| --- | --- | --- | --- | --- |
| T1 | Unsolicited text: a send without the guest's consent | Consent checkbox unchecked by default, separate from everything else; the booth sends only with an accepted receipt; the server refuses a delivery without `accepted: true` and stores the receipt in the same transaction; no marketing, one transactional text | `intake_test` (no consent, no delivery); app tests (unchecked default, Send disabled) | Whether the consent wording satisfies the law and the campaign: legal review (BLOCKED) |
| T2 | Sending to a number the guest does not control (typo, someone else's number) | Large number display with confirm-or-edit before sending; one text per photo and number; recipient throttles (3 per hour, 6 per day); STOP honoured | `intake_test` (limits, duplicate); app tests | A deliberate wrong number still gets one text (inherent; documented) |
| T3 | Spam or cost abuse through the API | No anonymous send path; booth identity from a single-use administrator code; 15-minute tokens; per-booth, per-event, per-tenant daily limits and a monthly spend ceiling (estimates); per-recipient throttles; revocation; rate-limited pairing | `pairing_test`, `intake_test` | Real cost depends on Twilio's bill (estimates only) |
| T4 | Stolen tablet used to send | Studio and settings behind the PIN; the credential in platform secure storage (Keychain / Keystore); revoke the booth on the server, which stops its credential and tokens at once; limits cap damage | `pairing_test` (revocation) | A stolen unlocked tablet in Booth Mode can still send within limits until revoked |
| T5 | Provider or database credentials extracted from the app | None are in the app: the app holds only its own booth credential; Twilio keys, service keys and encryption keys exist only in the backend secret store | App build scan for key patterns (evidence); `security_test` (no secrets in capabilities) | — |
| T6 | Forged provider webhooks (fake delivered, fake STOP) | Twilio's official `validateRequest` against the exact public URL; account SID must match; unsigned or tampered requests rejected before parsing further | `webhooks_test` | Correct public URL configuration at deployment (setup guide) |
| T7 | Out-of-order or repeated status callbacks | One row per message and status; forward-only state rank; final states never change; reports received before the job knows its message id are replayed later | `unit_test`, `webhooks_test` | — |
| T8 | Duplicate texts from retries | Idempotency key per deliberate submission; the same photo to the same number within an hour refused; retries only after definite non-submission (refused connection, 429, auth); an ambiguous outcome (timeout, 5xx, lost lease) becomes `delivery_unknown`, reconciled by finding the message by its link hash; operator review after 30 minutes; resend only with explicit duplicate-risk acknowledgement | `dispatch_test` | Twilio offers no idempotency key for messages; reconciliation depends on its message list |
| T9 | False "delivered" claims | Only Twilio's `delivered` report shows "Delivery confirmed"; accepted and sent are shown as such; no read claims | `unit_test`, `webhooks_test`, app tests | Carrier delivery reports are not proof the guest saw the photo (stated in UI copy) |
| T10 | Download link guessed or enumerated | 256-bit random tokens; only SHA-256 stored; constant 404 for unknown tokens; no event or session ids in URLs; rate limiting per network | `unit_test` (entropy), `links_test` | — |
| T11 | Link forwarded or leaked | Expiry (7 days default, operator-shortenable), revocation by the operator, access cap per link, page says plainly that anyone with the link can see the photos; `no-referrer`, no third-party resources, `noindex` | `links_test` | Forwarding cannot be prevented; phones and carriers keep their copies |
| T12 | Preview URL abused to fetch the full photo or kept public | Separate token and path for the preview (60 minutes), serving only the small preview; the finished photo only through the download grant | `links_test`, `dispatch_test` | Twilio keeps its own media copy until deleted (deleted at purge where allowed) |
| T13 | Token leakage into logs | Logs carry codes and ids only, with a redaction pass for anything shaped like a number or token; the app never logs numbers | `security_test`, `unit_test`; the app makes no logging calls at all (M10 adds a check that keeps it so) | Platform request logs (Supabase, CDN) may record URL paths: restrict access and retention (setup guide) |
| T14 | Uploading something other than the finished photo (camera originals, other files) | Exactly two upload grants per delivery (`final`, `preview`); single use, 15 minutes; type read from bytes; size, SHA-256, pixel size and completeness checked; keys derived from the delivery id | `dispatch_test` (uploads) | Server checks are structural; the booth decodes every file before upload |
| T15 | Phone numbers exposed at rest | Booth: secure storage only, erased after hand-off, failure or 24-hour expiry; backend: AES-256-GCM, erased after sending or expiry; keyed digest for throttles and STOP; row-level security on with no policies; public roles revoked | `security_test`, `retention_test`; app tests | Keyed digests of 10-digit numbers can be brute-forced by whoever holds the digest key (kept in the secret store) |
| T16 | Previous guest's number or photo shown to the next guest | Phone entry lives only in the guest screen's memory; cleared on Finish, timeout and reset; never prefilled; masked after submission; Booth Mode isolation as before | App widget tests | — |
| T17 | Guest trapped waiting for a text | The guest can always finish; results are shown briefly and do not wait for delivery; the booth's finish timeout resets everything | App flow tests | — |
| T18 | Offline booth loses or leaks queued deliveries | Durable local queue; retries only while the app is active, on resume and periodically; 24-hour window from consent, then the number is erased; photos are unaffected | App queue tests | No background sending when the OS suspends the app (documented) |
| T19 | Messaging when the operator has not finished registration | Server readiness requires: provider configured, registration attested (with reference), legal review attested, operator switch on; the app hides texting unless the server says ready | `pairing_test`; app tests | Attestations are only as good as the administrator's evidence |
| T20 | Runaway cost or provider outage | Limits and spend ceiling; emergency switch (server and booth); queue window; provider errors leave photos saved | `intake_test`, `dispatch_test` | — |
| T21 | Deletion requests | Operator revoke deletes hosted files and attempts provider media deletion; retention purges after link expiry; deleting a session on the booth revokes its hosted copy when online | `links_test`, `retention_test`; app tests | Carrier and phone copies cannot be recalled (stated in privacy notice) |
| T22 | Staging sends to real guests | Staging accepts only administrator-approved test numbers; separate projects and credentials per environment | `intake_test` (staging) | — |

## 5. Residual risks for the owner

- Consent wording, minors, retention periods and regional law: legal
  review required before any live send (PD-07.6).
- Sender registration (A2P 10DLC or toll-free verification), opt-in
  proof and sample messages must match what the app shows: BLOCKED until
  the owner's Twilio account and registration exist.
- Forwarded links and copies on phones and carriers cannot be recalled.
- Platform request logs may hold URL paths with bearer tokens: restrict
  access and keep retention short in the hosting configuration.
