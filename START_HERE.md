# PORCELAIN PHOTO BOOTH — FLUTTER CROSS-PLATFORM BUILD PACKAGE

**Version 3.2 | Approved platform: iPadOS + Android tablets using Flutter/Dart from the first development milestone**

## Decision: FINAL
This project is a single **Flutter/Dart** application with **iPadOS and Android as equal release targets**. Do **not** propose or implement an iPad-only SwiftUI rewrite, a React Native rewrite, a web photo booth, or a staged Android port unless the owner explicitly reverses this decision. Small native Swift and Kotlin bridges are permitted only after a concrete platform capability gap is demonstrated.

Other locked requirements:
- Built-in front/rear tablet cameras, selected by booth configuration; camera access without network.
- Porcelain Studio as the fully implemented first theme; extensible Light Oak and Darkroom Walnut token sets.
- Advanced WYSIWYG layered template editor **included in release 1**. Transparent PNG decorations may cross photo-slot boundaries and overlap slots; only photo content is clipped to its slot.
- Portrait and landscape guest presentation **configured per booth**, with adaptive fallback if OS rotation preferences are ignored. Studio adapts in both orientations.
- Offline event management, persistent session originals, full-resolution JPEG/PNG renders and operator gallery.
- **Export-ready first**; printer adapter API exists but there is no fabricated printing or unsupported hardware driver.
- **OPTIONAL PHONE DELIVERY IN V1**: guest-opted-in MMS JPEG preview plus revocable private full-quality download URL, backed by secure internet service; NO network requirement for camera, events, editor, export or gallery; disabled until provider registration/configuration validated.
- **Commercial-ready** means validated offline real sessions on a certified iPad AND a certified Android tablet, secure kiosk guidance, repair/recovery, backup/restore, signed release candidates and documented test evidence.

## Read order for Claude Code
1. `CLAUDE.md` — permanent engineering guardrails.
2. `prompts/MASTER_PROMPT.md` — how the entire execution program works.
3. `docs/FLUTTER_PLATFORM_STRATEGY.md` — architecture boundaries, early risk gate and platform policy.
4. `docs/PRODUCT_SPEC.md` — complete operator/guest features.
   - Supplement: `docs/PHONE_DELIVERY_SPEC.md`, `docs/PHONE_DELIVERY_UX.md` and `docs/PHONE_DELIVERY_ACCEPTANCE.md` — consented MMS + private link requirements.
5. `docs/ARCHITECTURE.md` — domain models, file integrity, rendering and camera contracts.
6. `docs/UX_SCREEN_SPECS.md` — component tokens and screen flows.
7. `docs/TEST_AND_DEVICE_PLAN.md` — fixtures/device certification.
8. `docs/ACCEPTANCE_CHECKLIST.md` — current milestone's exit gate.
9. `prompts/MILESTONE_PROMPTS.md` and `prompts/M09_PHONE_DELIVERY.md` — execute **M00 only**, then explicit approval per milestone.

## Final milestone order
| ID | Outcome | Key gate |
| --- | --- | --- |
| M00 | Dual-target project/toolchain baseline | iPad/Android targets generated; build capability recorded |
| M01 | Cross-platform technical spike | True-size PNG-overlay render + real-device still capture feasibility |
| M02 | Porcelain design system + responsive navigation | Shared tactile UI and operator shell |
| M03 | Offline data, events and operator authorization | Persistence + permissions/security |
| M04 | Production template scene graph/export renderer | Deterministic geometry and print-ready images |
| M05 | Full layered Template Studio | Editable, save/reopen, import/export |
| M06 | Hardened camera service | Permissions, capture, interruption handling |
| M07 | Guest session engine | Real offline capture→render→save→reset |
| M08 | Gallery, export and printer boundary | Export with accurate job/result states |
| M09 | Consented MMS + private full-quality photo link | Secure backend, UI, verified provider and real phone acceptance |
| M10 | Reliability, backup, privacy and kiosk | Fault recovery and protected operation |
| M11 | Both-platform certification and soak | Portrait/landscape physical device evidence |
| M12 | Signed build + commercial release gate | Documentation, clean install, owner go/no-go |

## How to begin
Copy the contents into the repository root. In Claude Code, paste `prompts/MASTER_PROMPT.md` and explicitly authorize **M00 only**. Then execute M01 as soon as M00 is reviewed. The M01 spike should be minimal but genuine, using fixed synthetic fixtures; refine it into production modules in M04/M06. No extensive dashboard styling before the M01 risk gate.

## Verification requirements
- iPad builds and signing require macOS/Xcode. On Windows/Linux, label iPad build checks BLOCKED and do not claim cross-platform release support proved.
- A physical iPad and Android tablet are required for real still-capture and full event certification. Simulator mock captures do not count.
- Check build/toolchain and the current Flutter/plugin docs at execution time; do not hard-code package versions from this plan.
- Official references: https://docs.flutter.dev/cookbook/plugins/picture-using-camera , https://pub.dev/packages/camera , https://api.flutter.dev/flutter/services/SystemChrome/setPreferredOrientations.html , https://developer.android.com/about/versions/17/changes/ff-restrictions-ignored , https://docs.flutter.dev/testing/integration-tests .

**This package is an engineering handoff, not a completed application. No hardware testing is claimed.**

**Important addition:** `prompts/M09_PHONE_DELIVERY.md` is the detailed work order for texting. Treat M09 as an independent online subsystem, and keep M00–M08 offline-first. The source of truth for live messaging is `docs/PHONE_DELIVERY_SPEC.md`. Sender registration, a domain, backend project and physical recipient tests are operator-provided prerequisites; absence means BLOCKED, never a mock PASS.
