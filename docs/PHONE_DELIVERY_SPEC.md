# PD — Guest phone delivery: MMS preview + private high-resolution download (v3.2)

**Status:** Approved addition to the commercial-release scope; OPTIONAL per event and device. **Offline capture, rendering and gallery must never depend on this feature.** The iPadOS and Android apps use one Flutter delivery client, identical UI/consent behavior, and one backend. This is a feature specification, not a claim that Twilio credentials, campaign registration, servers or delivery have been configured.

## PD-01: Scope, assumptions and boundaries
- Guest receives **one MMS containing a compressed preview and a private URL to the original-quality FINISHED COMPOSITION**. Only the finished composition is uploaded, not separate camera originals unless an owner-approved policy explicitly changes this.
- Connectivity is *usually* available by venue Wi-Fi or hotspot; offline and captive-portal conditions are expected. The entire booth is fully usable with delivery disabled or unavailable.
- Initial certified phone region: **US mobile numbers**, US MMS-enabled sender, and tested US carriers. Canadian and international support, including sender registration and country-dependent attachment limits, require separate capability certification. Support E.164 phone parsing and international prefixes structurally, without claiming geographic coverage.
- Delivery is *transactional and one-time* for the requested photos. No marketing opt-in, mailing list creation or later promotional texting. STOP/HELP routing and opt-out synchronization mandatory.
- Per-event toggle: off by default until provider is configured, registered/verified, consent disclosures reviewed, and backend integration tests pass. Event can optionally enable guest `Skip`, `Text my photos`, and queue-if-offline with honest disclosures.
- Default download availability: **7 days after successful send**, configurable by the operator subject to a defined max. Pending local delivery intents expire **24 hours** after consent, with phone-number erasure; these are proposed policy defaults, not legal guarantees. Operator must be able to shorten/revoke. No infinite retries.
- New guest screen only AFTER successfully persisted final output. Do not make delivery a condition of session completion.

## PD-02: Guest flow and microcopy
Guest final image is durably saved -> Finished preview -> optional **Text My Photos** -> phone entry with country code (+1 initially), grouped phone keypad, explicit *unchecked* consent checkbox, privacy/terms links and estimated 7-day link expiry -> tap `Send My Photos` -> submit validated local intent -> server upload/dispatch states -> confirmation -> Done/Next Guest. Guest may choose `No thanks` without penalty. No marketing checkbox in v1.

**Consent example for legal/provider review (not a pre-approved compliance template):**
> [ ] I agree to receive one photo-delivery text from [Event Operator/Brand] at the number I entered. The text includes a photo preview and a private download link. Message/data rates may apply. Reply STOP to opt out or HELP for help. Your download link expires after 7 days. [Privacy] [Terms]

**Sample MMS body for sender/campaign vetting (short, brand-identifying):**
> [Booth Brand]: Your photos from [Event Name] are ready: https://photos.example.com/p/<random-token> (available for 7 days). Reply STOP to opt out, HELP for help.

Use an operator-controlled, properly configured production domain, **never** `example.com`. Show opt-out/help disclosures consistent with approved campaign and applicable requirements. Phone number input must not be prefilled from the previous guest; number must be masked in operator views, never shown on unattended welcome. Provide `Edit number` confirmation before submission. Consent checkbox cannot be preselected and cannot be part of a mandatory global Terms checkbox. Guest must be able to skip and finish. No automatic collection of guest names required. Render privacy copy in event languages supported by the actual registered campaign.

**UI truthful statuses:**
- `Photo saved` (local image validated); `Waiting for connection — we'll try to text within 24 hours` (validly consented queued job); `Uploading`; `Submitting text`; `Text request sent` (provider accepted; **NOT** a claim of phone receipt); `Delivery confirmed` only after provider delivered callback, still not proof the guest read/downloaded it; `Could not send—your photo is saved`; `Number unsupported`/`Opted out`/`Link expired`.
- On offline submission tell guest explicitly the text may arrive later if connectivity returns within the stated window; no guaranteed delivery. If no provider is configured, hide the send CTA and show an operator-only preflight notice.
- Avoid running persistent background connectivity tasks with unsupported iPad/Android OS behavior; retry on app resume and while booth app is running. Don't claim guaranteed background sends.
- Always clear phone-entry state on session reset. Operators may inspect masked attempts, time/status and retry eligibility, never view full phone by default.

## PD-03: Trust boundaries / system diagram
```
Flutter iPad + Android (local stills, final output, consent, encrypted pending queue)
    | TLS / authenticated registered booth identity
    v
Delivery API (Supabase Edge Functions or equivalently secure backend)
    |---- AuthN/AuthZ, rate limit, policy gate, idempotency, audit
    |---- Postgres delivery records, immutable consent receipt, suppression table
    |---- Private object storage: output_full, preview_small
    |---- Transactional worker: upload validation, MMS dispatch, retries
    |---- Download page: https://photos.<domain>/p/{unguessable_grant}
    |---- Twilio webhook receiver (verify X-Twilio-Signature)
    v
Twilio Programmable Messaging, registered sender/Messaging Service
    | MMS image preview (provider-fetchable short-lived URL)
    | message body: private time-limited guest download link
    v
Guest phone -> HTTPS download landing page -> short-lived authorized access
```
**No Twilio API keys, Supabase service_role secrets, message-sending secrets or permanent privileged credentials in Flutter.** Backend secrets kept in a managed secret store. Client uses scoped, revocable provisioned device identity/keypair or equivalent short-lived device tokens, paired by operator authorization, with event/booth permissions, key rotation and server-side quota. Do not rely on a hardcoded shared API secret or public Supabase anon key as proof of an authorized booth. No unauthenticated guest-supplied send endpoints.

## PD-04: Two intentionally different URLs
**MMS preview URL:** Twilio needs to issue HTTP GET and HEAD against an externally accessible media URL with valid Content-Type. The provider cannot retrieve a file behind a standard authorization header. Produce a separate **JPEG preview**, generally target **150–400 KB**, with an absolute **hard limit below 5 MB for all message content/media**; adopt a more conservative configurable per-carrier limit, run real carrier tests. Generate a high-entropy scoped token or short-duration signed access URL served through HTTPS, accept GET/HEAD, valid Content-Type `image/jpeg`, `Content-Disposition`, content length. URL should expose ONLY preview, never the full-resolution original or private gallery; not be enumerable; avoid long caching and analytics logs. Short validity must be long enough for asynchronous provider media retrieval (initial suggested testing window 30–60 min, tune empirically). Twilio may cache or retain its own media copy; deleting our URL does not delete provider-held attachments. Deletion policy includes provider media resource cleanup when supported.

**Private guest download URL:** User-facing `https://photos.<domain>/p/{token}`, with 128+ bits of cryptographic entropy, hash-only token persistence, expiry, revocation and bounded access. Token is a bearer capability: anyone possessing the link can view it; disclose this honestly, prevent indexing/referrer leakage and avoid guessable event IDs. Validate the grant on the server, then stream the full image or issue a *very short-lived* signed object URL from a private bucket. Avoid raw permanent Supabase signed URLs in text messages; pre-issued storage signed URLs can remain usable through their validity despite changed guest grant status, and CDN caching can complicate immediate revocation. Keep signed URL TTL minimal, cache controls restrictive, and delete backing objects as part of revocation/purge. The high-quality composition is rendered at the template export resolution (e.g. 1200x1800 4×6 at 300 DPI), stored separately from the small MMS preview. Offer full-resolution JPEG/PNG download as configured.

**Retention nuance:** Twilio can retain an MMS media copy until deletion through its Media subresource; carrier/recipient copies cannot be revoked or erased by the booth operator. Hosted file expiry, deletion, and sender-provider retention must be explained in privacy documentation; do not promise complete erasure from phones or carriers.

## PD-05: Proposed backend implementation
**Choice:** Supabase Postgres + Storage (private buckets) + Edge Functions (Deno/TypeScript) for limited HTTP endpoints, with a managed queue/worker scheduler for retry-safe dispatch; Twilio Messaging API. If Supabase Edge Function runtime cannot guarantee a particular durable queue, implement DB-backed transactional claiming/lease/worker. Do not assume a function invocation continues reliably after returning a response. Use backend migrations and isolated tests. Cloud services apply ONLY to phone delivery. No user login or cloud dependency for photo sessions.

**Endpoints (names/examples; define versioned OpenAPI contract during milestone):**
- `POST /v1/booths/pair` — operator-approved, short-lived pairing flow; issue revocable scoped booth identity; protect against unauthorized signup.
- `GET /v1/delivery/capabilities` — server-validated enabled countries, region/cost policy, current sender readiness.
- `POST /v1/deliveries` — create intent with `{boothId,eventId,sessionId,outputId,phoneE164,consentReceiptVersion,consentTimestamp,consentAccepted,clientIdempotencyKey}`; server checks operator policy, freshness, quotas, event ownership, suppression.
- `POST /v1/deliveries/{id}/upload-init` — issue short-lived scoped upload grants only for `final` and `preview`; require size/type bounds, mime sniffing and object ownership.
- `POST /v1/deliveries/{id}/commit` — verify object existence, content-type/decoder/dimensions, checksums and max sizes; atomically mark dispatch-ready. Server must not send unless image and consent verified.
- `GET /v1/deliveries/{id}` — return sanitized state for owner booth with masking.
- `POST /v1/deliveries/{id}/cancel` — cancel if still possible and revoke grants; cannot unsend already dispatched texts.
- `POST /webhooks/twilio/status` — verify provider signature using official SDK and original request URL; idempotently upsert status transitions for matching MessageSid.
- `POST /webhooks/twilio/inbound` — signed webhook for STOP/HELP handling and suppression synchronization; let Twilio configured replies handle keywords where applicable.
- `GET /p/{grant}` — rate-limited private landing page, no-index/security headers; full-res download through grant-validated streaming/ephemeral signed URL.
- Admin-only `POST /v1/admin/retention/run` / on-schedule worker — revoke expired grants, delete objects, prune PII, reconcile provider media as supported, record audit summary.

**Job states:** `saved_locally -> pending_consent` (no network job until consent) -> `queued_locally -> authenticating -> uploading -> upload_verified -> dispatch_pending -> dispatching -> provider_accepted -> provider_sent -> delivered` OR `failed_retryable / failed_permanent / expired / canceled / delivery_unknown`. Separate local queue phase and server job states. Never call a callback `delivered` when the provider reports only `queued`/`sent`. A missing webhook does not imply delivery. Optionally record download page opens without invasive tracking or phone identity enrichment.

**Duplicate suppression:** Idempotency key bound to booth + session + output + recipient + deliberate submission attempt; reject multi-tap duplicates and repeated webhook deliveries. With ambiguous provider submit timeout, reconcile by provider SID/queue status before retry; if still ambiguous, mark `delivery_unknown` and require operator review rather than risking duplicate MMS. Exponential backoff + jitter only for safe transient failures; rate-limit by booth, event, phone (hashed index, securely keyed), IP where appropriate. Strict server-side daily quota and alert thresholds.

**Network queue:** SQLite/Drift queue records intent and consent evidence immediately; manage phone E.164 encrypted locally using OS-backed key material if practically supportable and document fallback limitations. Do not log the number. On restart or network recovery while app is active, upload under a renewed short-lived booth token and retry until 24-hour cap, without re-requesting consent. Expired local intents erase phone data; original final photos remain in local gallery. Don't promise background execution when the OS suspends the app. Server cleanup reconciles orphaned uploads.

## PD-06: Data entities (new local + server)
**Local `DeliveryIntent`**: id, sessionId, eventId, outputId, deliveryMode=`mms_with_link`, encryptedPhoneReference, phoneLast4, country, consentReceiptId, consentTextVersion, acceptedAtUtc, locale, sourceScreen, evidenceDigest, createdAt, expiresAt, idempotencyKey, queueState, remoteJobId, lastErrorCode, attemptCount, retryAt. Never expose full number in guest-visible next session; minimize persistence after provider accepted.

**Server:**
- `registered_booths`: id, tenant/operator ID, revocation status, credential fingerprint, quota, allowed event scope.
- `delivery_jobs`: id, boothId, eventId, sessionId, outputId, recipient ciphertext, last4, output checksum, preview key, full key, state, provider MessageSid, attempts, nextAttemptAt, expiration, failure code, idempotency key, timestamps.
- `consent_receipts`: ID, jobId, encrypted/minimized recipient or keyed digest, UTC timestamp, checkbox accepted true, textVersion, venue/event, source/version, local client receipt signature/hash, retention policy. No fake consent.
- `download_grants`: id, jobId, tokenHash, createdAt, expiresAt, revokedAt, download cap if configured.
- `suppression_entries`: keyed phone digest + sender/service scope + reason/timestamp; opt-outs must survive shorter photo retention as minimally necessary.
- `provider_events`: provider MessageSid, exact status, timestamps, sanitized failure reason, webhook-idempotency record; PII redacted.
- `deletion_audit`: deletion request, assets purged, Twilio media cleanup attempted/result, timestamp.

**Security/storage:** separate private buckets for full-size finished compositions and MMS previews; safe object keys not derived from phone numbers. RLS deny by default; only backend privileged workers access service credentials. TLS required. Publish privacy notice, retention chart, contact/revocation mechanism and Terms suitable for messaging registration. Avoid reusing images for training/marketing.

## PD-07: Registration and compliance prerequisites (US launch)
1. Obtain a business Twilio account, Messaging Service, MMS-capable US sender/number.
2. For a US 10-digit long code sender: A2P 10DLC business + campaign registration is REQUIRED; for toll-free, follow distinct toll-free verification rules. The delivery traffic type, exact in-booth consent screen, brand, privacy URL, Terms URL, sample messages, STOP/HELP handling and how a recipient requests a message should match the approved campaign. Publicly accessible privacy/terms URLs are now required for new US 10DLC campaign registrations and for new toll-free submissions (provider policies change; verify current requirements).
3. Separate transactional photo delivery consent from promotional marketing. This project sends no marketing in version 1. A checkbox is a conservative explicit-consent design choice; it is not a substitute for provider registration or jurisdiction-specific legal review.
4. STOP/HELP: configure provider's appropriate automatic handling; receive signed inbound opt-outs when available, update local suppression and do not try to send after STOP; do not issue duplicate auto-replies. Follow provider's current documentation for toll-free special behavior.
5. Carrier MMS support, forwarding and transcode behavior depend on country/carrier; initial certification is for agreed US carriers and phone models only. If MMS unsupported, **do not silently downgrade to SMS without an explicitly approved fallback policy and consent text**. Optional explicitly approved link-only SMS fallback can be introduced later and priced/tested separately.
6. No legal-compliance guarantees: obtain suitable counsel/operator review of photo-consent, texting policy, minors, privacy/deletion and regional messaging obligations prior to enabling real traffic.

## PD-08: Cost model and operational controls
Published Twilio US base outgoing MMS cost (as of Oct 2026): **$0.022/message**; extra carrier charges vary (US long-code outbound MMS examples $0.007–$0.010). Approximate starting direct rate for those carriers therefore **$0.029–$0.032** per successful outbound MMS, **excluding** registration/onboarding, rental/monthly messaging number, possible provider failed-processing charges, image storage/egress/compute, taxes, retry/duplicate and optional services. Pricing is not guaranteed; re-fetch before launch.

| Outbound sends | Twilio base MMS alone | Illustrative base + $0.007–$0.010 carrier fee |
| --- | ---: | ---: |
| 100 | $2.20 | $2.90–$3.20 |
| 500 | $11.00 | $14.50–$16.00 |
| 1,000 | $22.00 | $29.00–$32.00 |

Capacity example: 500 final outputs x 3 MB = **~1.5 GB** temporarily stored, plus 500 preview images x 0.25 MB = **~125 MB** and guest downloads/egress. Storage/egress bills depend on plan, retention and access; do not claim zero cost. Use a per-event estimated spend dashboard (estimated not billed totals), sender quota, daily cap, low-balance warning if provider API makes it available, and explicit admin enable/disable switches. No sends when budget threshold exceeded unless operator explicitly raises quota.

## PD-09: Test matrix and delivery acceptance principles
Mandatory deterministic tests with provider mock; staging send tests only to **approved test numbers** and from properly verified/registered sender. Block live release if onboarding incomplete. Assert:
- Without checked consent, no upload or message job. Skip never creates job. Changing guest clears phone input.
- Parsing invalid/unsupported country returns guest-safe correction, E.164 successful canonicalization, masked logging and encryption check.
- Shared iPad and Android Flutter UI behaves the same with a fake backend and a live registered sender.
- Local output saves even if backend unreachable; queued intent survives restart and expires after 24h deleting phone; retries on resume within TTL.
- Upload only compressed preview + finished composite, never camera originals, with hash/type/dimension integrity check.
- Preview GET and HEAD produce correct headers and 200 before expiry, 403/410 on expiry; works with actual Twilio media fetch. Output remains private from unauthenticated URL guessing.
- SMS/MMS body has brand, valid private link, and compliant required disclosures; no duplicate send on button spam, repeated callback or ambiguous timeout.
- Provider status `accepted`, `sent`, `delivered`, `undelivered`, `failed` mapped correctly; only `delivered` renders delivery confirmation.
- Tampered/missing `X-Twilio-Signature` rejected; credentials never present in APK/IPA or logs; backend scope and quotas enforced.
- STOP suppression prevents future sends, with valid HELP routing. Deletion revokes grants, removes hosted files, and cleans up provider media resource where allowed; recipient/carrier copies remain outside app control.
- URL tokens >=128bits entropy, grant expiration, revocation and access-rate limiting, no indexing and no token in analytics/referrer.
- Real MMS arrives with jpeg preview AND working private high-quality link on certified US recipient phones and carriers; preview may be transcoded by carrier. Valid within 7 days, fails after expiry; file image dimensions match export.
- Mobile hotspot/Wi-Fi outage cases, low bandwidth, resumed send, server crash, upload retry, backpressure, abusive send attempt, expired consent, provider account errors, Twilio rate limits, out-of-order callbacks.
- Staging e2e test must record actual source booth type, recipient carrier/device, message SID redacted, provider statuses and redacted screenshot; no fabricated PASS.

## PD-10: Official documentation pointers (verify against current docs at implementation)
- Twilio US rates: https://www.twilio.com/en-us/sms/pricing/us
- MMS fetch and public URL constraint: https://www.twilio.com/docs/messaging/tutorials/how-to-send-sms-messages
- MMS accepted MIME/5MB: https://www.twilio.com/docs/messaging/guides/accepted-mime-types
- Provider status callbacks: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks
- Twilio webhook signature verification: https://www.twilio.com/docs/usage/webhooks/webhooks-security
- US A2P 10DLC requirements: https://www.twilio.com/docs/messaging/compliance/a2p-10dlc
- New 2026 Privacy/Terms policy: https://www.twilio.com/en-us/changelog/a2p-10dlc-campaign-registration-will-require-privacy-policy-and-
- Twilio opt-outs: https://www.twilio.com/docs/messaging/tutorials/advanced-opt-out
- Twilio media stored copy: https://www.twilio.com/docs/messaging/api/media-resource
- Supabase private storage: https://supabase.com/docs/guides/storage/buckets/fundamentals
- Supabase signed URL caveats: https://supabase.com/docs/guides/storage/serving/downloads
