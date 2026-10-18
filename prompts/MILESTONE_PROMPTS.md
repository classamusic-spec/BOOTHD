# Claude Code — M00–M12 Gated Milestone Prompts (Flutter/iPadOS + Android)

**Usage:** Explicitly authorize ONE milestone at a time. Read all canonical docs and current `CLAUDE.md`. Always report actual platform evidence, acceptance IDs and blockers. Do not skip M01's cross-platform feasibility spike. A physically absent iPad/Android never counts as PASS.


## M00 — Dual-target toolchain, repository and CI baseline
**Paste into Claude Code:**

> Execute **M00 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Inspect existing repo/Git. Inventory Flutter/Dart, host OS, Xcode/macOS, Android SDK, simulators, attached physical tablets, plugin compatibility and signing situation; run `flutter doctor -v`. Create/repair Flutter project targeting iPadOS/iOS and Android in same repository, set a minimal null-safe app, layered pragmatic folder layout, DI/routing/test harness, `pubspec.lock`, formatting/analyze/test scripts, placeholder contracts (not pretend features), CI job for Android/static tests and documented macOS/iOS validation path. Choose supported deployment targets only with actual devices and plugins in mind. Record both platform build attempts or explicit BLOCKED limits. Write ADRs for Flutter decision, camera wrapper, scene graph and orientation. Stop; do not start editor or M01 technical spike. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Project launches on reachable targets; both platform folders exist, toolchain/signing gaps documented, baseline tests run.


## M01 — Dual-platform high-risk feasibility spike
**Paste into Claude Code:**

> Execute **M01 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Build TWO narrowly scoped, honest experiments ahead of UI polish. **Render spike:** create 4x6 1200x1800 document using fixture photos, 2 distinct photo slots and transparent decorative PNG crossing both boundaries. Implement minimum shared normalized geometry, z-order and per-slot clipping; confirm overlay pixels OUTSIDE each slot, final page crop and 1200x1800 export. Repeat with rotated layer and transparency edge. Compare output on both platforms and report pixel tolerance, time/memory. **Camera spike:** display real built-in camera preview via `camera` wrapper and capture a true still to managed storage on one real iPad and Android tablet; validate decode, dimensions, lens, permissions, orientation and mirror state, reopen file after restart. No permission? Document retry/configuration. Record exact device model/OS/build and PASS/FAIL/BLOCKED separately for each platform. A simulator/mock cannot pass real capture. Minimal dev-only diagnostics UI, no full app. Do not polish Studio screens. Preserve validated code for later production renderer and CameraService. Ask approval if physical devices missing. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Evidence-backed 1200x1800 overlay render; physical capture validated on both platforms OR explicitly BLOCKED pending hardware.


## M02 — Porcelain design system and adaptive Studio shell
**Paste into Claude Code:**

> Execute **M02 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Implement Porcelain semantic tokens, raised/inset/pressed/selected/loading/error/focus states and accessible contrast. Reusable buttons, cards, inputs, toggles, selectors, sheets, toasts, navigation rail, responsive grid, simple template thumbnails. Scaffold Light Oak and Darkroom token profiles. Implement functional Studio navigation for Dashboard, Events, Templates, Gallery, Settings, Diagnostics with clear empty states; any actions awaiting later milestones must be clearly disabled. Studio portrait/landscape and guest layout skeleton must adapt to actual viewport size. Add widget/golden, semantics, reduced-motion tests and status. Keep spike accessible only in diagnostics/dev builds. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Actual shared UI renders legibly on both device layouts with no dead functional controls.


## M03 — Offline storage, event configurations and operator access
**Paste into Claude Code:**

> Execute **M03 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Create Drift tables/migrations for booth profile, events, event templates, settings, and stable entity IDs; managed files setup. Implement event create/edit/duplicate/archive, exact camera/lens/mirror orientation preferences, 1–4 shots, countdown/retake, default/allowed template revision, retention and output profile settings. First-run setup and operator PIN with secure verifier and rate limit; guards between guest/operator routes. Create preflight structure with truthful NOT YET READY checks. Tests for restart persistence, migrations, relation integrity, PIN, guest access and event validation. Do not invent camera or render complete statuses. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Offline events persist across restart; PIN gate tested; migrations and route isolation pass.


## M04 — Production document model and shared composition engine
**Paste into Claude Code:**

> Execute **M04 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Promote M01 renderer spike to production. Define versioned immutable template revisions, normalized page geometry, transforms with documented pivot, layer types (background, photo slot, image PNG, text, shape), image bindings/crop, asset refs, global z-order, opacity, mask and page clipping. Implement asset copying/verification and safe archive import. Build shared scene graph for preview/offscreen full-res output, support 2x6/4x6/square presets, JPEG/PNG, alpha and rotation, font handling and fallback. Add comprehensive geometry/golden/preview parity tests on Android/iPad fixtures, corrupted/missing input handling and memory/latency benchmarks. Independent overlay PNG must cross photo-slot boundaries unharmed. No UI screenshots as print. No editor gestures yet. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Renderer reproducible, print-quality, correct alpha/order/clipping, output dimensions and validated save.


## M05 — Full layered Template Studio and template library
**Paste into Claude Code:**

> Execute **M05 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Build the complete interactive editor on top of M04: library create/duplicate/archive/import/export, blank and preset templates, canvas pan/zoom/fit, select/move/scale/resize/rotate handles, layer panel reorder/hide/lock/rename/duplicate, inspector exact X/Y/W/H/rotation/opacity, grid/guides/snapping, undo/redo with coalesced gestures, autosave and recovery, asset import, photo placeholders, text and shapes. Both studio orientations must work on physical/tablet-sized layouts. Template save/reopen must restore editability. Stress 20+ layers; verify visual preview vs output and PNG layering. Remove UI shells replaced by real screens. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** On either tablet, operator creates and reopens a fully editable floral/photo template with matching 300 DPI export.


## M06 — Production Flutter CameraService and diagnostics
**Paste into Claude Code:**

> Execute **M06 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Promote M01 camera spike to robust CameraService with typed capabilities/status/errors, real permission paths, front/rear selection, aspect-correct preview, independent preview/output mirroring, orientation normalization once, native camera wrapper only for justified missing capabilities. Serialize init/takePicture/dispose, handle foreground/background and OS interruptions, save validated immutable original files with durable metadata. Add Diagnostics Camera screen and mock service for testing; real device verification both platforms including cold start/relaunch and rear lens when available. No guest multi-shot orchestration yet. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Real iPad and Android full-resolution still save/reopen, reliable lifecycle and no duplicate shutter; absent device remains BLOCKED.


## M07 — End-to-end guest booth and persistent session state machine
**Paste into Claude Code:**

> Execute **M07 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Implement operator-protected transition into Booth Mode and guest Welcome→optional Template Choice→Live Preview→monotonic Countdown→1–4 Captures→Review/Retake→Render→Verified Saved→Reset. Freeze exact event and template revision per session, bind photos to slots, maintain immutable retake attempts and durable checkpoints. Guest-safe timeouts and fault states, no previous guest images, recoverable render retries and cancellation after backgrounding. Build portrait/landscape adaptive guest layouts based on effective viewport and operator preference, not unguaranteed OS lock. Provide tests using mock camera and live end-to-end sessions on real iPad/Android. No print controls without actual printer. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Both devices complete airplane-mode photo→composition→local saved output→new guest with no operator intervention.


## M08 — Operator gallery, export-ready workflow and printer boundary
**Paste into Claude Code:**

> Execute **M08 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Build local event/session gallery, thumbnail paging/search, session originals/retakes/template revision detail, non-destructive re-render, individual/batch export with true platform file/share result handling, storage management, delete/retention confirmations, output profiles and print-ready asset validation. Define `PrintService`, `PrintRequest`, `PrintCapabilities`, `PrintJobStatus` and honest Unconfigured adapter. Printer UI omitted or explicitly Not Configured; no print submission, hardware adapters, QR hosting, email or cloud. Test failures and no-network export. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Operator can inspect, re-render, and export all assets offline; printing is explicitly unsupported pending hardware.


## M09 — Secure phone photo delivery (optional online subsystem)
**Paste into Claude Code:**

> Execute **M09 ONLY**. Read all approved `docs/PHONE_DELIVERY_*.md` files and execute the comprehensive work order in `prompts/M09_PHONE_DELIVERY.md`. Build Flutter phone/consent UI for both tablets, secure per-booth backend pairing, private full-res photo storage, separately provider-fetchable small MMS preview, one-time transactional MMS + guest bearer link, durable network queue, backend jobs and verified Twilio callbacks/STOP suppression, guest landing/download, quota/cleanup and commercial evidence. Support Wi-Fi/hotspot failure without blocking local photo capture. Obtain actual registered MMS sender and privacy/legal approval before live send; if unavailable, mark live checks BLOCKED, NOT PASS. Record AC-0901–AC-0922 results and STOP.

**Exit gate:** Actual consented photo MMS with preview + full-resolution download link tested on certified devices/US recipient carriers or live prerequisite gaps documented BLOCKED; no impact on offline booth operations.


## M10 — Commercial resilience, security, backup and kiosk readiness
**Paste into Claude Code:**

> Execute **M10 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Harden temp→verify→atomic rename→DB journal and recovery on restart; inject faults at all stages. Implement restoreable backup package with version/checksum/asset references, validate restore into clean sandbox; privacy/consent, retention/delete, PIN recovery, diagnostics/log sanitization, preflight PASS/WARN/BLOCK checks. Guided Access vs managed Single App Mode documentation for iPad; Android screen pinning vs device-owner lock-task prerequisites; app must not claim it can force OS kiosk mode. Audit permissions and airplane-mode operation. Confirm guest isolation after crashes and reset. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Fault-injected recovery, restore, preflight and privacy tests pass; documented kiosk deployment processes.


## M11 — iPad + Android hardware certification and endurance
**Paste into Claude Code:**

> Execute **M11 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Run reproducible portrait and landscape real sessions on at least one supported physical iPad and one supported Android tablet, front/rear if present, in enclosure under continuous approved power. Target 100 completed sessions per platform with 1/3/4-shot and retake mix, multi-hour soak, interruptions, low storage, missing assets, cold start, camera denial/regrant and app restart. Record duration/count/results/device/OS/app hash, render p50/p95, peak memory and battery/thermal observations; adjust measurable performance targets. Test Android large-screen OS orientation behavior, iPad full-screen tradeoffs, and non-stretched camera preview across rotations. No model counted certified without full evidence. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Both target physical devices tested and supported, no lost completed originals; unresolved physical gaps remain release blockers.


## M12 — Signed packages, documentation and GO/NO-GO review
**Paste into Claude Code:**

> Execute **M12 ONLY** for Porcelain Photo Booth as defined in `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`. Prepare release-mode signing/build/install on supported hardware, private key storage guidance, reproducible versions/checksums, permissions/privacy text, operator manual, first-run setup/kiosk/orientation guide, supported device list, repair/backup/restore, risk review, dependency and media font licenses, release/rollback plan. Re-run clean-install user journey on certified iPad AND Android. Compile complete acceptance evidence showing PASS/FAIL/BLOCKED per AC ID; release owner decides GO/NO-GO. Printer adapter remains future milestone after selecting actual printer hardware. Do not declare released if device security, backup or soak gates fail. Read the matching `docs/ACCEPTANCE_CHECKLIST.md` IDs. Before editing, inspect code and propose a short plan; after editing run feasible formatting, analysis, tests and both-platform builds, updating `docs/IMPLEMENTATION_LOG.md` and `docs/ACCEPTANCE_EVIDENCE.md`. Provide precise PASS/FAIL/BLOCKED evidence and STOP for approval.

**Exit gate:** Signed installable iPad and Android release candidates, complete operator documentation and owner-approved GO.


## Mandatory milestone evidence format
```
Milestone: Mxx | git SHA | build version | host OS / Flutter & plugin versions
Work implemented / key code files:
Tests: [command] -> [exit] -> [test count/result]
iPad: [physical model, OS, lens, portrait/landscape, actual camera/export test OR BLOCKED]
Android: [physical model, OS, lens, portrait/landscape, actual camera/export test OR BLOCKED]
AC-xxxx: PASS/FAIL/BLOCKED + evidence path
Performance/defects/security: ...
Owner approval requested: YES (DO NOT automatically start next milestone)
```
