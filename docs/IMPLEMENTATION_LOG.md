# Implementation log

Newest milestone first. Each entry: scope, plan, changes, commands and exit
codes, platform results, spec issues raised, risks, next step.

## M01: cross-platform render and camera feasibility spike

- Date: 2026-10-18 (UTC)
- Authorised by: owner ("approved, start M01"), after the M00 report said
  that no physical iPad, Android tablet or Mac was available here, so the
  device subgates would be BLOCKED.
- Host: the same Linux cloud session as M00 (`docs/TOOLCHAIN_INVENTORY.md`).

### Plan (as executed)

1. Pure-Dart template model and scene compiler (page units and DPI,
   normalised geometry, photo slot and image layers, z-order, cover crop).
2. `dart:ui` painter and offscreen renderer (export and editor workspace).
3. Procedural fixtures through a pure-Dart PNG writer; FIX-01 pixel checks,
   z-order variant, FIX-04 halo probes, failure probes, goldens, metrics.
4. Camera: `camera` 0.12.1 behind `CameraService` via a driver seam;
   original store with staged, validated, atomic commits; EXIF reader.
5. Platform permissions: iOS usage string; strip unneeded Android
   permissions the plugin adds.
6. Dev-only render and camera spike screens behind non-release routes;
   DI providers bound in the composition root.
7. Device integration test, driver, host comparison test and procedure.
8. ADR-0007; format, analyze, tests, Android builds; evidence.

### Changes

- Domain: `lib/domain/template/` (new), `composition_renderer.dart` (new
  draft contract), `camera_service.dart` (`CapturedStill` gains id,
  checksum, byte length, EXIF and capture-time mirroring settings;
  `CapturedStillStore` added).
- Infrastructure: `composition/` (painter, renderer), `camera/` (driver
  seam, managed service), `file_store/` (original store, EXIF reader).
- App wiring: `lib/core/di/service_providers.dart`, `productionOverrides()`
  in `lib/app/providers.dart`, spike routes only when the build mode is not
  release, baseline screen links in debug and profile.
- Spike UI and fixtures: `lib/features/diagnostics/spikes/`.
- Platform: `ios/Runner/Info.plist` (`NSCameraUsageDescription`),
  `android/app/src/main/AndroidManifest.xml` (remove `RECORD_AUDIO`,
  `WRITE_EXTERNAL_STORAGE`).
- Dependencies: camera ^0.12.1, path_provider ^2.1.6, crypto ^3.0.7.
- Tests: `test/domain/document_scene_test.dart`, `test/rendering/` (5
  files), `test/infrastructure/` (3 files), `test/widgets/spike_screens_test.dart`,
  router and baseline updates; `integration_test/render_spike_test.dart`,
  `test_driver/integration_test.dart`.
- Fixtures: `test_assets/` (two Pillow-made JPEGs, two host goldens,
  provenance README).
- Docs: ADR-0007, `docs/device_tests/M01_DEVICE_PROCEDURE.md`, inventory,
  iPad guide, README, licence report.
- Migrations: none.

### Problems met and how they were handled

- Plugin manifests add `RECORD_AUDIO` and `WRITE_EXTERNAL_STORAGE`, and the
  merger implies `READ_EXTERNAL_STORAGE`; all removed with
  `tools:node="remove"` (audio is never enabled). The release APK audit
  also showed a required rear camera implied by `CAMERA`, now declared
  optional, and `ACCESS_NETWORK_STATE` from `androidx.media3`, kept and
  flagged for M10 (ADR-0007).
- The first Android build auto-installed SDK Platform 35 and CMake 3.22.1
  (plugins compile against API 35; `path_provider_android` builds JNI
  code). Recorded in the inventory; CI's runner does the same.
- Tests caught a real bug: the camera lifecycle stream, written as
  `async*`, dropped the `initializing` event emitted just after a
  listener subscribed. Rewritten with `Stream.multi`.
- The halo probe was first written so that partly transparent edge pixels
  carried the hidden colour, which would make a dark fringe legitimate.
  Fixed before any result was recorded; a separate test now proves the
  probe fails on exactly that kind of bad input.
- Reading `ProcessInfo.maxRss` after the 12 MP run confounded the drift
  measurement; drift is now measured first.

### Spec issues raised

1. ARCHITECTURE A-03 lists `test_assets/transparent_pngs/`; transparent
   fixtures are generated in code instead, so hosts and devices render
   identical inputs without bundling binaries. The directory stays absent.
2. FLUTTER_PLATFORM_STRATEGY §3 says to keep the spike in
   `lib/features/diagnostics/spikes/`. Only the demo UI and fixtures live
   there; core functions went to their target layers so M04/M06 can
   promote them (ADR-0007). Layer rules forbid features from importing
   plugins or `dart:io`, so this was the only compliant option.
3. Still pending from M00: confirmation of ADR-0004 (orientation without
   "Requires Full Screen"), the board image file, and device models.

### Risks carried forward

- AC-0104 cross-platform comparison, AC-0106 and AC-0107 are BLOCKED until
  a physical iPad (with a Mac) and an Android tablet run the procedure.
- JPEG output encoder and decode-size policy are open for M04 (ADR-0007).
- Permission pre-checks and "denied forever" on Android are open for M06.

### Next

Owner review of M01, including explicit approval to proceed to M02 with
the device subgates still BLOCKED (MASTER_PROMPT §D), or a pause to run the
device procedure first.

## M00: dual-target toolchain, repository and CI baseline

- Date: 2026-10-17/18 (UTC)
- Authorised by: owner, by supplying the v3.2 master package whose
  MASTER_PROMPT §G orders "Execute M00 only"; sequencing re-confirmed by the
  owner on 2026-10-17 (keep spec order, see CR-001).
- Host: Linux cloud session (no macOS, no KVM, no attached devices).
  Details: `docs/TOOLCHAIN_INVENTORY.md`.

### Plan (as executed)

1. Split the consolidated v3.2 master into its 16 package files; verify a
   lossless round trip.
2. Install Flutter 3.47.7 (SHA-256 verified) and the Android SDK; record
   `flutter doctor -v`, devices and emulators.
3. Generate the Flutter project for iOS and Android only; set iPad-only
   device family and app labels; keep Android defaults.
4. Minimal shell: Riverpod root scope, GoRouter with a detail-free fallback,
   one honest baseline screen with no controls.
5. Typed boundaries: orientation value objects, draft `CameraService`
   contract, layer import rules enforced by tests.
6. Tests: architecture fitness, domain, widget layout at six tablet
   viewports and 200% text, accessibility guidelines, router fallback,
   integration launch smoke test.
7. Scripts (`tool/`), CI workflow, exact Flutter pin, licence report.
8. ADR-0001..0006; owner change request CR-001 (premium UX bar).
9. Run format, analyze, tests and both platform builds; record evidence.

### Changes

- Package docs: `START_HERE.md`, `CLAUDE.md`, `prompts/*.md`, `docs/*.md`
  (verbatim split of the master; round trip verified byte for byte).
- Flutter project: `pubspec.yaml` (Flutter pinned to 3.47.7,
  flutter_riverpod ^3.4.3, go_router ^18.1.0, integration_test),
  `pubspec.lock`, `analysis_options.yaml` (strict casts, inference and raw
  types; async-safety lints), `android/`, `ios/`.
- Platform settings: `TARGETED_DEVICE_FAMILY = 2` (iPad only); Android
  label "Porcelain Photo Booth". Everything else is the Flutter 3.47.7
  template.
- App: `lib/main.dart`, `lib/app/{bootstrap,app,providers,router,route_not_found_screen}.dart`,
  `lib/core/platform/app_environment.dart`, `lib/core/routing/route_paths.dart`,
  `lib/features/dashboard/baseline_home_screen.dart`.
- Domain: `lib/domain/value_objects/orientation.dart`,
  `lib/domain/services/camera_service.dart` (draft placeholder contract).
- Tests: `test/architecture/`, `test/domain/`, `test/widgets/`, `test/app/`,
  `test/support/`, `integration_test/app_launch_test.dart`.
- Tooling: `tool/check.sh`, `tool/build_android.sh`, `tool/build_ios.sh`,
  `tool/toolchain_inventory.sh`, `tool/dependency_licenses.dart`,
  `.github/workflows/ci.yml`.
- Docs: `README.md`, `docs/TOOLCHAIN_INVENTORY.md`, `docs/IOS_VALIDATION.md`,
  `docs/DEPENDENCY_LICENSES.md`, `docs/decisions/*`, this log,
  `docs/ACCEPTANCE_EVIDENCE.md`. CR-001 amendments appended to
  `docs/ACCEPTANCE_CHECKLIST.md` (AC-0207..AC-0211),
  `docs/UX_SCREEN_SPECS.md` and `docs/DECISIONS_AND_RISKS.md`.
- Migrations: none (no database until M03).

### Commands and results

Recorded with exit codes in `docs/ACCEPTANCE_EVIDENCE.md` (M00 section).

### Problems met and how they were handled

- Maven Central answered HTTP 429 through the session's shared egress while
  Gradle built the Flutter Gradle plugin. Workaround local to this
  container: a Gradle init script that resolves Maven Central artifacts from
  Google's public mirror. No repository change; CI uses Maven Central.
- A release build failed at `javac` because `GeneratedPluginRegistrant.java`
  still listed the dev-only `integration_test` plugin. Cause: `flutter pub`
  commands run concurrently with the build regenerated the registrant in
  debug mode. Re-running the build with no concurrent Flutter commands is
  the fix; scripts run steps sequentially.
- `flutter_riverpod` 3 depends on `flutter_test` (widget-test helpers), so
  test packages sit in the runtime dependency graph. The licence report
  treats that whole graph as shipped (conservative).

### Spec issues raised (not silently resolved)

1. **iPad "Requires Full Screen" is obsolete.** `UIRequiresFullScreen` is
   deprecated from iPadOS 26 and no longer prevents resizing for iOS 27 SDK
   builds (Apple TN3192, revised 2026-10-09). ADR-0004 proposes adaptive
   layouts plus operational locking; CLAUDE.md, A-09, A-16, strategy §5 and
   UX-03 still mention the old approach. Owner confirmation requested.
2. **Milestone changelog is one version behind.**
   `docs/MILESTONE_CHANGELOG_v3_1.md` maps v3.0 to v3.1 (M09 Resilience, M10
   Certification, M11 Release), but v3.2 inserted M09 Phone Delivery, so
   Resilience is M10, Certification M11 and Release M12. A v3.1→v3.2 entry
   is missing.
3. **Missing package files.** `reference/15_screen_concept_reference.png`
   (UX-00) and `examples/template_v1.json` (MASTER_PROMPT §A) are referenced
   but not in the package. The owner shared the board in chat; it still
   needs committing as a file.
4. **Truncated link** in `docs/PHONE_DELIVERY_SPEC.md` PD-10
   (".../a2p-10dlc-campaign-registration-will-require-privacy-policy-and-").
5. **Stale minimums.** A-16 cites camera docs listing iOS 13+; the Flutter
   3.47.7 template targets iOS 15.0 and Android API 24.
6. `docs/FLUTTER_PLATFORM_STRATEGY.md` is labelled version 3.1 inside the
   3.2 package (cosmetic).
7. The concept board conflicts with the spec in 12 places (guest print and
   save buttons, guest settings and back controls, a single mirror toggle,
   and more). CR-001 lists them; the spec wins.

### Risks carried forward

- No physical iPad or Android tablet identified (D-04 #1): every DEVICE gate
  from M01 on stays BLOCKED until hardware is available.
- No Mac yet: iPadOS has never been compiled; the manual CI job or an
  owner Mac must do it (`docs/IOS_VALIDATION.md`).
- JPEG export has no built-in `dart:ui` encoder (ADR-0003); M01 measures the
  options.
- Placeholder bundle and application IDs must be replaced before signing.

### Next

Owner review of M00. On approval: M01 cross-platform render and camera
feasibility spike (AC-0101..AC-0108), with camera checks BLOCKED until a
physical iPad and Android tablet are available.
