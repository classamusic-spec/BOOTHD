# PD UX — Flutter screens, states and operator settings

The reference 15-screen board remains visual inspiration, not a complete implementation. Add these **responsive design screens** in Porcelain Studio style to the existing UX screen list. Both iPadOS and Android support guest portrait or landscape; same guest business logic, device-effective layout chosen using actual window constraints. All guest screens must be accessible under bright venue lighting.

## UX-PD1 Guest Delivery Choice (after durable `Finished`)
- Finished photo preview, header `Your photos are ready`, primary tactile `Text My Photos`, secondary `No thanks — Finish`.
- If messaging feature disabled, show the existing Finished screen without texting. If offline and offline queue enabled, show `Can text later when connected` explanation. If provider unconfigured, hide CTA; show operator preflight warning, never send via unconfigured mock.
- Guest should not be forced to share number, consent to marketing, or create an account.

## UX-PD2 Phone Number & Consent
- Country selector (initial US-only certification; avoid offering unsupported destinations), E.164-aware phone keypad, large editable field, inline validation/error, link to privacy/terms hosted on functioning operator-controlled domain, descriptive consent checkbox **unchecked by default**.
- Re-display event/operator sending identity and 7-day link expiry, message/data rates, STOP/HELP information; link-specific consent only, not tied to photos consent or ToS acceptance.
- Primary `Send My Photos` disabled until valid supported number + consent; secondary `No thanks`. Prevent rapid double tap and stale session association.
- Preview image is visually separate from phone input, especially in portrait. Accessible phone editing, focus, contrast, hardware keyboards and touch targets >=44 logical pixels.
- Privacy: mask phone in confirmation summary, never retain unmasked input on screen after success/exit; no phone autofill from prior session.

## UX-PD3 Sending/Queued/Result
- Confirm precise result: `Saved locally`, `Queued until connected`, `Uploading`, `Sending`, `Text request accepted`, `Delivered` only if actual carrier status, or `Not sent — photo is still saved`.
- Use a brief nonblocking state with Back/Edit until provider submission; don't trap guest waiting for delivery receipt. `Finish` resets guest-visible sensitive state even when server job remains pending. In offline queue case warn that app needs to reconnect within 24 hours and delivery is not guaranteed.
- Error types: unsupported carrier, unavailable provider, rate limit, invalid number, device offline, expired local queue, revoked consent, server failure. No raw HTTP/status codes shown to guests.

## UX-PD4 Mobile Private Download Page (web; the booth application is still Flutter)
- Fast, responsive mobile web page: Porcelain-branded header, full-composition preview, `Download Full Quality`, availability deadline, privacy notice and support contact.
- No website login required for bearer-link recipients; token itself grants time-limited access. Do not claim link can be fully private from forwarding/screenshotting. No third-party ad pixels, social trackers, indexing, referrer leaks or public event enumeration.
- `Expired`, `Revoked`, `Temporarily unavailable` and `Deleted` screens show support text without disclosing identity or other sessions.

## UX-PD5 Operator Event Delivery Settings
- `Enable phone delivery` defaults off until backend preflight passes, `Delivery mode: MMS preview + private link` locked, consent text/version preview, 7-day configurable link expiry, 24-hour max queued window, sender/region status, network requirement notice, estimated spend/event send limit, daily max and operator emergency disable.
- Region selector initial US only; unsupported numbers cannot be sent. Offline queue configurable, with explicit delayed-message wording. Add a proof/screenshot export of consent flow for sender registration.

## UX-PD6 Operator Delivery Center
- Gallery/Session Detail includes status pill: `Queued locally`, `Uploading`, `Submitted`, `Sent`, `Delivered`, `Failed`, `Expired`, `Unknown` (no raw full phone; last four only), and timestamps.
- Operator controls: retry **only if safe**, cancel queued, revoke active download grant, delete hosted image, export redacted diagnostics and count sends. Status history includes measured/timestamped provider reports, with no 'read' claim from MMS.
- Booth diagnostics: network reachability to backend, sender registration readiness, upload permission test using fixture, server quota, callback health and storage expiry cleanup. Do not send a real text from a self-test without operator action and an authorized test number.

## UX-PD7 Portrait/landscape interaction contract
- Portrait: centered photo preview above tall tactile number input and consent row; keyboard does not obscure CTA.
- Landscape: photo preview pane left, number/consent pane right; keyboard-aware scrolling; on rotation preserve number and unchecked/checked choice within same active session only.
- Content is driven by actual viewport, not assumption orientation-lock works. Reset must wipe input on both layouts. Pin-protected operator exit remains protected.

## Screen identifiers
Add: S30 Delivery Choice, S31 Phone/Consent, S32 Upload/Queue/Result, S33 Mobile Download Webpage, S34 Operator Delivery Settings, S35 Operator Delivery Center, S36 Delivery Diagnostics. Existing S27 Finished and S04 Event Editor route to these where enabled. S33 is a separate responsive web page hosted by delivery backend, **not** a web rewrite of the Flutter booth.
