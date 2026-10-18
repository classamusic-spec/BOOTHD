# M09 — Claude Code implementation prompt: MMS photo preview + private high-quality download

**Execute M09 ONLY.** Read `CLAUDE.md`, master prompt and ALL of `docs/PHONE_DELIVERY_SPEC.md`, `docs/PHONE_DELIVERY_UX.md`, and `docs/PHONE_DELIVERY_ACCEPTANCE.md`, plus existing events, gallery, security, release and test docs. Do not start unless M00–M08 acceptance and release-critical image/session durability foundations have been reviewed.

## Objective
Add a genuine optional photo texting service for both iPadOS and Android Flutter clients while retaining all offline booth capabilities. Each explicitly consenting guest receives ONE MMS with a small JPEG preview plus a private time-limited high-quality download URL, subject to US-region provider coverage and verified sender registration. Default feature OFF until configured. NEVER put Twilio/Supabase privileged credentials inside the apps.

## Plan & architecture phase
1. Inspect repo/deployed resources and list prerequisites: domain, backend provider account, Twilio paid sender/registration, Supabase project, DNS/HTTPS, privacy/terms URLs, physical iPad/Android and receiving mobile phones. Report BLOCKED prerequisites instead of faking them.
2. Create reviewed ADR and threat model: consent/PII, media URL provider fetching, link forwarding, provider copy retention, suppression, out-of-order callbacks, ambiguous submit, device key theft, resource caps. Define regional support and all service contracts.
3. Write versioned OpenAPI/schema contract, DB/Drift migrations, server Postgres policies and indexes. Separate local durable DeliveryIntent and server DeliveryJob/ConsentReceipt/Grant/Suppression/Event.
4. Build backend authorization and device pairing, provisioned per-booth scoped identities, protected admin operations, conservative quotas, signed upload grants, storage validation, durable dispatch worker, Twilio integration and signature-validated webhooks. Test that the backend never sends without verified consent and final committed media.
5. Create two storage paths: private full-res final image; separately optimized short-lived MMS preview with externally GET/HEAD accessible unguessable scoped link. Ensure provider fetch URL remains valid long enough, uses correct headers, and is not the guest download URL. Web guest download page enforces hashed revocable grant and private ephemeral download access.
6. Flutter shared `DeliveryService` with mock/test implementation, Drift queue, E.164 validation, explicit consent receipt, retry/reconciliation/expiry and secure phone storage. Wire guest S30–S32 and Studio S34–S36, both orientations and truthful states.
7. Verify branding, sender/campaign approvals, STOP/HELP, SMS/MMS recipient coverage and retention policy in operator-provided production/staging accounts; never invent approvals. Validate privacy/Terms with operator/legal review before enabling sends.
8. Run Dart/widget/DB/backend unit tests, staging integration, security and expiry tests, approved-device delivery/carrier tests. Record exactly which were run with PASS/FAIL/BLOCKED entries AC-0901–AC-0922.
9. Deliver operational cost calculator, credentials/setup docs, sample message, consent-screen screenshot export, event sends cap, incident response/rollback, redacted diagnostic examples.
10. STOP and wait for owner acceptance. Do not start M10/M11/M12 automatically.

## Critical boundaries
- Continue to save/finish sessions even when offline or Twilio is down.
- The preview fetch URL is different from the guest download grant.
- A Twilio `sent`/`accepted` status does NOT mean delivered/read.
- Retries are safe only before confirmed provider submission; uncertain submission requires reconciliation/manual review.
- US sender A2P 10DLC (or applicable toll-free) registration and opt-in proof are required before live sending. No unsolicited sends or marketing lists.
- Carrier delivery is not guaranteed; MMS may be transcoded. Do not claim every phone/country is supported.
- If actual backend setup, Twilio registration, physical phones or networks are unavailable, implement/test mocks while marking live gates BLOCKED; do not advertise deployed/working service.

**Exit gate:** One explicitly consenting guest can use either certified tablet, receive preview MMS plus valid full-quality link, while non-consenting/offline/failed sessions remain safe, accessible and truthful. All AC-09 items recorded; owner approves next milestone.
