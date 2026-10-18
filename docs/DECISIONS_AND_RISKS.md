# Decisions, assumptions, risks, and changes

## D-01: Approved decisions (LOCKED)
| ID | Decision | Rationale |
|---|---|---|
| ADR-001 | Flutter/Dart single shared tablet application | Cross-platform UI/engine, shared code and event workflow |
| ADR-002 | iPadOS + Android | Commercial multi-hardware deployments |
| ADR-003 | Built-in tablet cameras in v1 | Simplify physical setup and camera support |
| ADR-004 | Guest portrait AND landscape configurable per booth | Supports diverse enclosures; test platform constraints |
| ADR-005 | Porcelain Studio default; other theme profiles supported | Distinct premium visual identity |
| ADR-006 | Offline-first, no backend/login | Events work without network |
| ADR-007 | FULL advanced layered template editor in v1 | Core product differentiator |
| ADR-008 | Photo-slot clipping separate from PNG overlay layer clipping | Enables custom decorations outside slots |
| ADR-009 | High-resolution export first; printer later | Printer model undecided; reliable deliverable |
| ADR-010 | Commercial readiness required | Reliability, data recovery, privacy, certified hardware |
| ADR-011 | Staged gated Claude Code implementation | Testable milestones, avoid one-shot code explosion |

## D-02: Proposed engineering choices (review at M00)
Riverpod DI, GoRouter navigation, Drift SQLite, managed filesystem, official Flutter `camera`, composition scene graph + CustomPainter/offscreen render, secure operator PIN storage, immutable originals, revisioned templates, feature-oriented modular monolith. Exact plugin versions, target OS versions, package licensing and test hardware chosen after environment audit.

## D-03: Risks / mitigation / stop criteria
| Risk | Severity | Mitigation | Stop criterion |
|---|---|---|---|
| Camera API behavior differs by model | High | Abstract camera; physical device matrix | Camera can't reliably capture on target device |
| iPad/Android requested orientation not enforced | High | Test iPad full-screen and Android 16+/17 adaptive behavior; adapt UI; warn | Intended enclosure orientation unusable |
| Preview and export differ | High | Shared scene graph + renderer goldens | Misaligned photo crop/PNG on export |
| PNG transparency lost/clipped | Critical | Alpha fixture over multiple slots; pixel tests | Overlap requirement fails |
| Incomplete writes / data loss | Critical | File journal, verification, recovery testing | Successful originals lost after interruption |
| Flutter export memory pressure | High | Measure decoding/offscreen path, bounded cache, native extension only if needed | Repeated exports leak/kill app |
| Fonts inconsistent cross-platform | Medium | Bundle licensed fonts, deterministic text tests | Text changes placement beyond tolerance |
| Guest kiosk escape | High | In-app lock + documented OS managed mode | Guest reaches operator or prior session |
| PIN secret exposure | High | Secure storage and hash/backoff; security review | PIN plaintext or trivial bypass |
| Unknown printer compatibility | Medium | Stub adapter, only certified hardware later | App falsely promises printing |
| App permissions overbroad | Medium | Manifest review, platform picker | Unnecessary restricted access requested |
| Scope explosion | High | Gate milestones; permit ONLY approved M09 texting cloud service; defer other cloud features/AI/print/GIF | Core app incomplete while extras proliferate |
| Unlicensed assets/fonts | Medium | Asset provenance/license file | Can't distribute shipped assets |

## D-04: Explicit pending physical/product inputs
1. Actual iPad model and OS version; actual Android tablet model and Android version. Needed for certified-device list and performance thresholds.
2. Deployment environment: Mac+Xcode, attached hardware and Android SDK. Needed for real iPad builds.
3. Primary kiosk enclosure and available orientations, camera location; verify obstruction and external LED lighting.
4. Commercial app distribution model: store listing vs supervised managed business installation; affects signing/management/manuals.
5. Printer choice (post-v1): brand/model, wired/network, paper profile/cut semantics.
6. Operator brand name/icon licensing, assets and custom fonts. Starter art requires documented license.
7. Desired guest consent/retention defaults based on deployment jurisdiction and event contract; legal review outside engineering scope.

## D-05: Change control
New requests receive proposed P0/P1/P2 priority, effect on schema/screens/testing, risk and acceptance changes. Do not silently promote printer or additional cloud features into first release; only the specifically approved M09 texting backend is allowed. For schema/renderer changes, include migrations and fixture updates. Track ADR in `docs/decisions`.


## ADR-CP-001 — Flutter iPadOS and Android simultaneously (approved 2026-10-17)
User explicitly selected one Flutter/Dart application supporting iPadOS and Android tablets **from the start**. SwiftUI-only and React Native alternatives were evaluated and rejected for this application. Change control requires explicit owner authorization. Milestone M01 cross-platform camera/render spike precedes styling, to eliminate early framework/platform feasibility uncertainty. See `docs/FLUTTER_PLATFORM_STRATEGY.md`.

## ADR-PD-01 (v3.2) — One optional online feature for consented phone delivery
Approved: Flutter for both tablets remains final. Printer remains export-only. Separate Supabase/Twilio optional delivery subsystem: finished photo remains local while a consented copy and a compressed preview can be securely uploaded for MMS with revocable 7-day high-quality download URL. Keep first certified destination US and sender behind registration/verification; no marketing. Delivery off until backend registration and live testing. Major risks: Twilio preview must be provider-fetchable, stored provider MMS media persists, bearer links may be forwarded, async provider responses make retries dangerous, approval requirements/costs change. See PHONE_DELIVERY_SPEC and gate M09.

## D-06: M09 phone-delivery unique risk register
| Risk | Level | Mitigation | Blocking condition |
| --- | --- | --- | --- |
| Unsanctioned texts/spam | Critical | Explicit consent record, registered sender, per-device caps, STOP block | No verified opt-in or sender approval |
| Provider media preview exposed too long | High | Small scoped random fetch link with short TTL, HEAD/GET, never publish final original | Persistent public full-size photo URL |
| Full-resolution guest link forwarded | Medium | High-entropy bearer grant, documented forwarding behavior, expiry/revoke, noindex | Guessable URL or no operator revoke |
| Duplicate MMS due to retry | High | Idempotency+provider submission reconciliation, UNKNOWN review | Blind retry on unknown provider status |
| Lost network and local PII persists | High | 24-hour queued-intent expiry, protected minimized phone, resume-only retry, cleanup | PII retained indefinitely or false delivered claim |
| Provider MMS media retained after our deletion | High | Media-subresource cleanup and honest privacy notice; cannot recall carrier/recipient copy | Claim of complete erasure from third-party phones |
| Unexpected messaging charges | Medium | Per-event/daily caps, current pricing review, no automatic unlimited sends | No spending controls |

## CR-001 (approved 2026-10-17) — Premium UX quality bar
Owner directive: the UI/UX must exceed the 15-screen concept board at "AAA premium" quality. Spec order unchanged: M01 stays a plain feasibility spike; the bar binds M02 and every later UI milestone. Measurable gates AC-0207–AC-0211 (contrast incl. WCAG AAA 7:1 for guest-critical text, tap targets, both-orientation goldens with owner sign-off, no guest print/save/escape controls, licensed type and art). See `docs/decisions/CR-001-premium-ux-quality-bar.md`.
