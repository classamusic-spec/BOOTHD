# Acceptance and Release Checklist — Porcelain Flutter v3.2

**Platform decision:** iPadOS AND Android must pass physical-device gates. **How to use:** Each `[ ]` is NOT YET VERIFIED. Claude Code must never self-mark PASS without evidence (test name, build log, screenshot, hardware model, timestamp where applicable). `PASS` / `FAIL` / `BLOCKED` / `N/A (with reason)` should be recorded in `docs/ACCEPTANCE_EVIDENCE.md`. A manual review by project owner is required to accept milestones. Items labeled **DEVICE** require physical tablets, not a simulator or a mock.

## M00 — Toolchain, project baseline
- [ ] AC-0001 Both platform targets generated; repository structure documented.
- [ ] AC-0002 Toolchain inventory captures Flutter/Dart/Xcode/Android SDK versions, host OS and connected devices; iPad build limitations honestly stated.
- [ ] AC-0003 `dart format --output=none --set-exit-if-changed .` and `flutter analyze` pass (or existing unrelated issues documented).
- [ ] AC-0004 `flutter test` passes starter tests; sample app launches in accessible simulators/emulators.
- [ ] AC-0005 Exact dependency lockfile and licenses recorded; CI/local script for repeatable checks exists.
- [ ] AC-0006 Architecture, data ownership, test and orientation decisions documented in ADRs.

## M01 — Cross-platform rendering + camera feasibility SPIKE
- [ ] AC-0101 Fixture 4×6 (1200×1800 pixels at 300 dpi) renders from actual image assets, not widget screenshot.
- [ ] AC-0102 Photo-slot image masks clip each photograph, while independent transparent PNG overlay crosses both slot boundaries without implicit clipping.
- [ ] AC-0103 Rotated and outside-page decoration test confirms global z-order, per-layer transforms, and separate final page crop.
- [ ] AC-0104 Rendering fixture output decodes at target dimensions on both runtime targets, with platform comparison and explicitly bounded geometry/golden tolerance.
- [ ] AC-0105 Render time, memory, alpha edges and failure behavior measured/logged; no claim of optimized production renderer yet.
- [ ] AC-0106 DEVICE/iPad: real built-in front-camera preview and still photo saved and reopened; model/OS/lens/resolution/orientation/mirror evidence captured (or BLOCKED).
- [ ] AC-0107 DEVICE/Android: same physical still-capture test/evidence on Android CameraX device (or BLOCKED).
- [ ] AC-0108 Minimal dev-only diagnostics and an ADR describe plugin limitations, platform-specific risks, current blockers, and production refactor plan for M04/M06.

## M02 — Design system and navigation
- [ ] AC-0201 Porcelain default palette and semantic tokens implemented; no raw per-feature color scattering.
- [ ] AC-0202 Reusable buttons/cards/toggles/steppers/sheets/forms with press/disabled/selected/loading/focus states.
- [ ] AC-0203 Dashboard and navigation work; all links/actions functional or clearly disabled with rationale.
- [ ] AC-0204 Studio layout tested at tablet portrait and landscape viewport sizes; no overflows.
- [ ] AC-0205 Contrast, labels, touch target and reduced motion evaluated; recorded exceptions fixed or justified.
- [ ] AC-0206 Theme data shape supports Light Oak/Darkroom without feature changes.

Owner directive 2026-10-17 (CR-001, `docs/decisions/CR-001-premium-ux-quality-bar.md`): the UI must exceed the 15-screen concept board. AC-0207–AC-0211 bind M02 and are re-run at every later milestone that adds or changes screens.
- [ ] AC-0207 Automated token-pair contrast test: guest primary text and countdown >=7:1, all other text >=4.5:1, focus rings and control boundaries >=3:1, in every implemented theme.
- [ ] AC-0208 Every implemented screen passes Flutter tap-target, labeled-tap-target and text-contrast guideline tests in portrait and landscape.
- [ ] AC-0209 Golden screenshots exist for every implemented screen in portrait and landscape at the defined tablet sizes; owner records that they exceed the concept board.
- [ ] AC-0210 No guest-visible print, save-to-gallery, share, settings, back or escape controls (automated widget tests).
- [ ] AC-0211 Fonts, icons and illustrations have recorded licences and provenance; no concept-board artwork or sample people ship.

## M03 — Offline events/security
- [ ] AC-0301 First-run operator PIN setup, verification and rate-limit tested; no plaintext PIN stored.
- [ ] AC-0302 Events can create/edit/duplicate/archive/reopen offline, persisting across app restarts.
- [ ] AC-0303 Event capture settings, template selection, theme override and orientation persist.
- [ ] AC-0304 Drift migration and referential-integrity tests pass on seeded old/new DBs.
- [ ] AC-0305 Guest route guards prevent access to Studio/gallery on back/deep route attempts.
- [ ] AC-0306 Draft/missing-template/invalid settings appropriately block or warn at preflight.

## M04 — Template document and renderer
- [ ] AC-0401 Versioned JSON documents validate and round-trip, including out-of-page layer bounds and rotation.
- [ ] AC-0402 Render order is deterministic and respects global z-order, visibility and opacity.
- [ ] AC-0403 CRITICAL: independent transparent PNG extends beyond two separate photo-slot boundaries without being slot-clipped.
- [ ] AC-0404 Photo source is clipped to its own photo slot; masking and crop are correct.
- [ ] AC-0405 Export dimensions correct: 2x6 600x1800, 4x6 1200x1800 / 1800x1200, 4x4 1200x1200 at 300dpi.
- [ ] AC-0406 PNG alpha preserved where relevant and JPEG background flattened intentionally; no alpha fringe regression.
- [ ] AC-0407 Preview and high-res export have equivalent geometry; golden/pixel tests with deterministic fixtures pass on target platforms within documented tolerance.
- [ ] AC-0408 Asset import validates MIME/header, dimensions, path safety, missing sources and unsupported schema.
- [ ] AC-0409 Export failure/low storage leaves originals and previous valid output untouched; memory bounded in repeat tests.

## M05 — Advanced layered template editor
- [ ] AC-0501 New template from blank and preset; correct canvas/page metadata.
- [ ] AC-0502 Add/edit/delete photo slots, PNG images, text, backgrounds and shapes.
- [ ] AC-0503 Select, drag, resize, rotate and exact numeric transform work in both orientations.
- [ ] AC-0504 Layers reorder, rename, lock/unlock, show/hide, duplicate and front/back operations persist.
- [ ] AC-0505 Snap-to-guides/grid/center, pan/zoom, fit-to-screen, selection handles and coordinate transforms work.
- [ ] AC-0506 Undo/redo tested for create/move/rotate/delete/reorder, with drag gesture coalescing.
- [ ] AC-0507 Autosave, explicit save and reopening restore editable geometry/assets and history-safe last saved revision.
- [ ] AC-0508 PNG from file picker copied into managed store and still works after temporary picker URI disappears.
- [ ] AC-0509 Template package export/import round trip matches original; corrupt/unknown file safely rejected.
- [ ] AC-0510 Preview matches final renderer including out-of-photo-slot artwork.

## M06 — Physical camera support
- [ ] AC-0601 Camera permissions denied/granted/permanently denied have safe UX and documented repair.
- [ ] AC-0602 Lens enumeration avoids unsupported cameras and selects known front/rear when available.
- [ ] AC-0603 DEVICE/iPad: real still capture saved at camera-supported resolution with orientation/mirror metadata correct.
- [ ] AC-0604 DEVICE/Android: same real capture acceptance on certified Android model.
- [ ] AC-0605 Preview maintains aspect ratio with no stretch and correct mirrored preview setting.
- [ ] AC-0606 Background/foreground/interrupt recovery does not leak camera or trigger delayed shutter.
- [ ] AC-0607 Capture calls are serialized; two fast taps cannot create duplicate unintended shots.
- [ ] AC-0608 Saved originals survive app restart; no preview screenshot substituted.
- [ ] AC-0609 DEVICE: front-camera position and lens clear through real enclosure.

## M07 — Guest booth flow
- [ ] AC-0701 Correct flow welcome -> optional template -> preview -> countdown -> 1–4 captures -> review/retake -> render -> saved -> reset.
- [ ] AC-0702 Countdown follows monotonic time, pauses/cancels safely on background/interrupt.
- [ ] AC-0703 Guest review/retake replaces selected binding without destroying original captures.
- [ ] AC-0704 Captured photos map to correct slots; missing/extra slots handled as specified.
- [ ] AC-0705 Rendering progress and Saved label only appear after verified durable export.
- [ ] AC-0706 Guest cannot access Studio/gallery, other guest photos or system share picker.
- [ ] AC-0707 Session state checkpoint and interrupted render recovery preserves originals.
- [ ] AC-0708 Configured portrait/landscape guest layouts work on both physical tablet families (DEVICE).
- [ ] AC-0709 After finish, booth resets without showing previous guest imagery.

## M08 — Gallery/export/print boundary
- [ ] AC-0801 Local Gallery thumbnails and event/session filters work at large sample counts.
- [ ] AC-0802 Originals, attempts, chosen slot bindings, immutable template revision and final outputs inspectable by operator.
- [ ] AC-0803 Batch export returns actual file/share results and reports individual failures accurately.
- [ ] AC-0804 Re-render from originals + stored template revision is deterministic; prior output preserved.
- [ ] AC-0805 Event/session deletion honors retention policy with explicit confirmation and recoverable cleanup.
- [ ] AC-0806 PrintService returns 'unconfigured' honestly; no fake button/physical success or required printer.
- [ ] AC-0807 Output presets/orientation/quality explicit and files re-openable in external image viewers.

## M09 — Optional MMS preview + private photo link (v3.2)
This checklist duplicates the canonical M09 detail in `docs/PHONE_DELIVERY_ACCEPTANCE.md`, to make release gating easy to audit. Real provider approvals, operator consent text, backend setup and physical phone tests must be evidenced; if not available, mark BLOCKED and keep the feature disabled.

- [ ] **AC-0901** Event/booth delivery off by default until provider readiness + operator enable; capture/render/gallery remain offline with delivery disabled.
- [ ] **AC-0902** Finished photo saved before phone prompt; `No thanks` exits without intent/upload/send.
- [ ] **AC-0903** Phone validation to E.164, initial supported US-only region, masked UI/logs; input cleared on guest reset.
- [ ] **AC-0904** Separate unchecked documented transactional MMS consent with version/time/event/source; no send without accepted receipt; no marketing enrollment.
- [ ] **AC-0905** Flutter iPad/Android guest screens support portrait/landscape, accessible keypad, offline status, and 7-day expiry disclosure.
- [ ] **AC-0906** Local durable delivery queue survives restart/offline, retries safely on active reconnect within 24h and expires while erasing phone PII; local photos unaffected.
- [ ] **AC-0907** Device pairing authorization, scoped token revocation, backend quotas and per-recipient throttles prevent unauthenticated/abusive dispatch.
- [ ] **AC-0908** Only selected final composition and preview uploaded; checksum/MIME/pixel/size validation and private object store; never raw original captures.
- [ ] **AC-0909** Preview uses limited provider-fetchable GET/HEAD URL, valid HTTPS/MIME, tested carrier-conservative byte budget under 5MB; original remains private.
- [ ] **AC-0910** Guest token cryptographic entropy >=128 bits, hashed storage, 7-day max-default expiry/revoke, non-indexed download page, private short-lived full-quality object access.
- [ ] **AC-0911** Twilio server-side only credentials; US sender campaign/verification and registered consent artifacts confirmed; no live send without approval.
- [ ] **AC-0912** Real MMS received on certified US phone with image preview + private download link; high-res file exact template output dimensions.
- [ ] **AC-0913** Provider status callbacks verified using official signature validation; `accepted/sent/delivered/failed/undelivered` mapped correctly, no false received claims.
- [ ] **AC-0914** STOP opt-out blocks later sends; HELP handling works; signed inbound events processed without duplicate replies.
- [ ] **AC-0915** Double taps and repeated callbacks do not duplicate sends; ambiguous provider timeouts become UNKNOWN/manual review; unsafe blind retries prohibited.
- [ ] **AC-0916** Rate limit, max event spend estimate, unsupported destination, insufficient storage, bad upload, expiring preview URL and provider outage all handled with safe recovery.
- [ ] **AC-0917** Expiry and operator revoke make full-quality download inaccessible; delete hosted media, attempt provider media cleanup, clearly document already-delivered carrier copies cannot be recalled.
- [ ] **AC-0918** Secure webhook regression tests reject tampered/missing signatures; secrets not shipped in app binary, error logs redact phone/token/PII.
- [ ] **AC-0919** Mobile download page works on iPhone and Android with images safe from search indexing and unapproved analytics, and honest expired-link errors.
- [ ] **AC-0920** Live tests log certified booth, carrier, real phone, sanitized Twilio SID, consent proof and actual delivery result; untested carriers/physical devices recorded BLOCKED, never assumed.
- [ ] **AC-0921** Staging/production separation, migration/rollback/deletion jobs, incident documentation, and monthly cost/retention review exist.
- [ ] **AC-0922** No guest is trapped waiting for text; after operator-chosen timeout, booth resets without exposing number or prior guest photos.

## M10 — Commercial operations, privacy/recovery
- [ ] AC-1001 First-run setup, operator unlock and safe recovery screens complete.
- [ ] AC-1002 Kiosk deployment guidance distinguishes iPad Guided Access vs supervised Single App Mode and Android screen pinning vs managed lock-task.
- [ ] AC-1003 Preflight checks camera, template, storage, write access, output and orientation; blocks only critical issues.
- [ ] AC-1004 Recovery reconciles files/DB after simulated kill between temp file/rename/record commit.
- [ ] AC-1005 Low storage handled without claiming capture success or losing existing completed originals.
- [ ] AC-1006 Backups include database/documents/assets/media per configuration; restore validated to empty app sandbox.
- [ ] AC-1007 Logs omit photo bytes, credential material and sensitive filenames where feasible; camera/network permissions audited.
- [ ] AC-1008 Privacy/retention/delete controls and event consent text implemented and operator documented.

## M11 — Certified-device validation
- [ ] AC-1101 DEVICE: iPad portrait and landscape end-to-end sessions pass, camera + final export.
- [ ] AC-1102 DEVICE: Android portrait and landscape end-to-end sessions pass.
- [ ] AC-1103 DEVICE: 100 consecutive automated/manual-interleaved sessions targeted per platform with zero lost completed originals (log actual count/results).
- [ ] AC-1104 DEVICE: multi-hour powered enclosure soak test with memory, heat, storage and crash observations recorded (actual duration required).
- [ ] AC-1105 DEVICE: permission withdrawal, restart, interrupted render, backgrounding, low-storage and recovery scenarios pass or are documented release blockers.
- [ ] AC-1106 Cross-platform template output geometry/PNG overlap tests pass against certified fixtures.
- [ ] AC-1107 Performance baselines documented (capture latency, render latency, p95 editor frame time, peak memory) on actual hardware.
- [ ] AC-1108 Accessibility, visibility in venue lighting, touch target and guest/operator route review signed off.

## M12 — Release go/no-go
- [ ] AC-1201 Release-mode signed iPad/Android builds generated or signing/distribution blockers explicitly resolved.
- [ ] AC-1202 Clean install -> PIN/setup -> event -> template -> capture -> export -> backup walkthrough demonstrated on both supported devices.
- [ ] AC-1203 Installer/operator manual, supported device/OS list, orientation/kiosk setup, known limitations and troubleshooting complete.
- [ ] AC-1204 License/provenance audit covers shipped images, fonts, code dependencies and software notices.
- [ ] AC-1205 Security/privacy review and retention disclosure checked for intended deployment; no implicit claim of universal legal compliance.
- [ ] AC-1206 Rollback/update/backup test executed with sample operator data.
- [ ] AC-1207 All critical/higher bugs resolved, all release-blocking AC entries PASS, remaining issues documented and approved.
- [ ] AC-1208 Explicit owner GO decision recorded; printer integration listed as later hardware-certified enhancement.

## Release-blocking failures irrespective of milestone
- Lost or mutated original files, unverifiable image saves, or invalid template migration.
- Photo-slot clipping wrongly crops independent PNG overlays.
- Inability to complete offline full session on either claimed certified platform/orientation.
- Guest access to previous guest gallery or operator Settings without authorization.
- False 'saved'/'printed' success statements.
- Hard crash/leak in ordinary repeated use on certified hardware.
- Missing migration/backup path or untested recovery after known critical failure.
