# Acceptance evidence

Status values: PASS, FAIL, BLOCKED (could not run; reason and owner steps
given), N/A (with reason). Owner review is required to accept a milestone.
DEVICE gates are never satisfied by CI, emulators, simulators or mocks.

## M00: toolchain, project baseline

```text
Milestone: M00 | code commit dba6ce4e26044313b486a93f867ba10b975545c2 | build 0.1.0+1
Host: Ubuntu 24.04.5 LTS (Linux 6.18.44, cloud VM, no KVM, no macOS)
Flutter 3.47.7 stable / Dart 3.13.5 / AGP 9.1.0 / Gradle 9.3.1 / Kotlin 2.4.0
Packages: flutter_riverpod 3.4.3, go_router 18.1.0 (exact set: pubspec.lock)
iPad: BLOCKED (no macOS/Xcode on host; no physical iPad)
Android: build only; no physical tablet; emulator impossible without KVM
Owner approval requested: YES (do not start M01 automatically)
```

### Commands and exit codes (2026-10-18 UTC, host above)

Rows 4–9 and 13 were re-run with the working tree clean at commit `dba6ce4`
(build caches kept) with identical results. APK SHA-256 (identical across
two builds):
debug `1a3f52fd7fc28e8397dc9bfceaafe93d173bed35669f09ddefd99f426918a67c`,
release `e0c12c229f51f6fa8b0e948c1aa59a902d297833ebb6988f65146ddf939c06f4`.

| # | Command | Exit | Result |
| --- | --- | --- | --- |
| 1 | `flutter doctor -v` | 0 | Flutter, Android toolchain (SDK 36, licences accepted), network: OK. Chrome and Linux desktop missing (not targets). Output: `docs/TOOLCHAIN_INVENTORY.md` |
| 2 | `flutter devices` | 0 | Only "Linux (desktop)", not a target. No iPad, no Android device |
| 3 | `flutter emulators` | 0 | No AVDs; cannot run without `/dev/kvm` |
| 4 | `dart format --output=none --set-exit-if-changed .` | 0 | 0 files need formatting |
| 5 | `flutter analyze` | 0 | No issues found |
| 6 | `flutter test` | 0 | 43 tests passed (architecture 23, domain 8, widgets 10, app 2) |
| 7 | `dart run tool/dependency_licenses.dart --check` | 0 | Report matches `pubspec.lock`; 0 packages need manual review |
| 8 | `tool/build_android.sh debug` | 0 | `app-debug.apk` built (163,393,409 bytes). Earlier attempts failed on HTTP 429 from Maven Central; see the implementation log |
| 9 | `tool/build_android.sh release` | 0 | `app-release.apk` built (47,270,499 bytes; arm64-v8a, armeabi-v7a, x86_64; native libraries stored uncompressed). `aapt2 dump`: targetSdk 36, label "Porcelain Photo Booth", no permissions except the AndroidX internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (no INTERNET, no CAMERA). Debug-signed smoke build, not distributable |
| 10 | `tool/build_ios.sh release` | 3 | BLOCKED by design on Linux: "iOS builds require macOS with Xcode" |
| 11 | `flutter test integration_test` | not run | BLOCKED: no device, emulator or simulator reachable |
| 12 | Mutation check: inject `import 'package:flutter/widgets.dart'` into `lib/domain/value_objects/orientation.dart`, run `flutter test test/architecture/` | 1 | The domain file's boundary test failed as intended; file restored byte-identical; suite passes again |
| 13 | `tool/check.sh` (rows 4–7 in one script, as CI runs it) | 0 | All checks passed |

### Acceptance items

| AC | Status | Evidence |
| --- | --- | --- |
| AC-0001 Both platform targets generated; repository structure documented | PASS | `android/` and `ios/` from `flutter create --platforms ios,android` (Flutter 3.47.7); layout in `README.md` and ADR-0005, enforced by `test/architecture/layer_boundaries_test.dart` (rows 5, 6) |
| AC-0002 Toolchain inventory incl. Flutter/Dart/Xcode/Android SDK, host OS, devices; iPad limits stated | PASS | `docs/TOOLCHAIN_INVENTORY.md` (rows 1–3); Xcode absent and iPad build BLOCKED stated explicitly; repeatable via `tool/toolchain_inventory.sh` |
| AC-0003 `dart format` and `flutter analyze` pass | PASS | Rows 4, 5 |
| AC-0004 `flutter test` passes; sample app launches in accessible simulators/emulators | BLOCKED | Tests PASS (row 6). Launch could not run: no emulator (no KVM) or simulator (no macOS) and no device (row 11). Owner steps: run `flutter test integration_test -d <device>` on an Android emulator or tablet and on an iPad simulator (`docs/IOS_VALIDATION.md`) |
| AC-0005 Exact lockfile and licences recorded; repeatable CI/local checks exist | PASS | `pubspec.lock` (Flutter pinned 3.47.7), `docs/DEPENDENCY_LICENSES.md` (row 7), `tool/check.sh`, `.github/workflows/ci.yml`. GitHub Actions run #1: both jobs green (see "CI" below) |
| AC-0006 Architecture, data ownership, test and orientation decisions in ADRs | PASS | `docs/decisions/ADR-0001`..`ADR-0006` |

### M00 exit gate

| Gate | Status |
| --- | --- |
| Project launches on reachable targets | BLOCKED: no reachable target on this host (see AC-0004) |
| Both platform folders exist | PASS |
| Toolchain and signing gaps documented | PASS (`docs/TOOLCHAIN_INVENTORY.md`, ADR-0001) |
| Baseline tests run | PASS (row 6) |
| Android build attempted | PASS: debug and release APKs build (rows 8, 9) |
| iPadOS build attempted | BLOCKED (Linux host); manual macOS CI job and `docs/IOS_VALIDATION.md` provided, not yet run |

### CI (GitHub Actions run #1)

[Run 39081949708](https://github.com/classamusic-spec/BOOTHD/actions/runs/39081949708)
on commit `3f90522` (push to `claude/new-session-fh2zxl`, 2026-10-18 UTC),
GitHub-hosted `ubuntu-24.04` runners:

| Job | Conclusion | Notes |
| --- | --- | --- |
| Format, analyze, test, licences (`tool/check.sh`) | success | Licence report reproduced exactly on a different machine |
| Android release smoke build (`tool/build_android.sh release`) | success | 47,270,499 bytes, same size as local. SHA-256 `1f68c7c1b808205c37373d3a5d5b2c7778e1d3b3b19cbb7ab1e9ca3ac9743170` differs from local only because each machine signs with its own debug key. Log warns that `cupertino_ui` references Cupertino icon fonts the app does not bundle (harmless; M02 picks the icon family per CR-001) |
| iPadOS unsigned build | skipped | Manual dispatch only, by design |

CI is not device evidence and does not change AC-0004's BLOCKED status.

### Security and privacy notes

- No network, camera, photo or storage permissions requested. The Android
  INTERNET permission exists only in the debug and profile manifests
  (Flutter tooling), not in release.
- No secrets, keys or personal data in the repository. Release builds use
  the Android debug key until M12.
- The unknown-route screen shows no route, error or exception text.

## M01: cross-platform render and camera feasibility spike

```text
Milestone: M01 | code commit af018c73ed07738cd749d3976c2045a59fb6a752 | build 0.1.0+1
Host: same Linux cloud VM as M00 (no KVM, no macOS, no attached devices)
Flutter 3.47.7 / Dart 3.13.5; camera 0.12.1 (camera_android_camerax 0.7.5+1,
  camera_avfoundation 0.10.3+1), path_provider 2.1.6, crypto 3.0.7
iPad: BLOCKED (no physical iPad, no Mac)
Android: builds PASS; no physical tablet (an emulator would not count either)
Owner approval requested: YES, including whether to continue to M02 with the
  device subgates BLOCKED (MASTER_PROMPT §D)
```

### Commands and exit codes (2026-10-18 UTC)

Rows 1–4 ran on a clean working tree at `af018c7`.

| # | Command | Exit | Result |
| --- | --- | --- | --- |
| 1 | `tool/check.sh` | 0 | Format: 0 files changed. Analyze: no issues. Tests: 117 passed, 1 skipped (device comparison; no device results). Licence report current: 69 runtime and 9 dev packages, 0 needing review |
| 2 | Golden comparison (inside row 1) | 0 | Export and workspace both max delta 0 against the committed host goldens |
| 3 | `tool/build_android.sh debug` | 0 | `app-debug.apk`, 203,486,560 bytes |
| 4 | `tool/build_android.sh release` | 0 | `app-release.apk`, 52,237,076 bytes, SHA-256 `02f5bd33379a870d45597189eb075e2424b86e0b29e98a40191757b40ab99897`. `aapt2`: permissions `CAMERA` and `ACCESS_NETWORK_STATE` plus the AndroidX internal one; `android.hardware.camera.any` required, `android.hardware.camera` optional |
| 5 | Mutation checks before commit (painter restored byte-identical) | 1, 1 | Removing the slot clip fails "slot B rounded corner clips its photo"; reversing rotation fails all three marker checks |
| 6 | Decoder probes before commit | 0 | JPEG with EXIF orientation 6 decodes as 480x640, correctly rotated; PNG and JPEG truncated at 1–95% fail to decode (ADR-0007) |
| 7 | `tool/build_ios.sh release` | 3 | BLOCKED: Linux host |
| 8 | `flutter drive … integration_test/render_spike_test.dart` | not run | BLOCKED: no device |
| 9 | Camera procedure, `docs/device_tests/M01_DEVICE_PROCEDURE.md` §2 | not run | BLOCKED: no device |

### Host render metrics (row 1, `build/m01/host_render_metrics.json`)

Informative only: a 4-vCPU cloud VM with Flutter's test rasteriser says
nothing about tablet performance. GPU memory is not observable from Dart.

| Scenario | Median total | Decode | Rasterise | PNG encode | Memory |
| --- | --- | --- | --- | --- | --- |
| FIX-01 1200x1800 (inputs 1600x1200, 1200x1600), 10 runs | 191 ms (183–228) | 58 ms | 63 ms | 70 ms | +1.5 MB resident after 30 more renders |
| FIX-01 with 12 MP inputs, bounded decode, 3 runs | 413 ms | 277 ms | 67 ms | 69 ms | peak +56.6 MB (+30 to +58 MB across all runs) |
| FIX-01 with 12 MP inputs, full decode, 3 runs | 371 ms | 238 ms | 63 ms | 68 ms | peak +46.7 MB |

### Acceptance items

| AC | Status | Evidence |
| --- | --- | --- |
| AC-0101 Fixture 4x6 renders at 1200x1800 from image assets, not a screenshot | PASS (host) | `test/rendering/fix01_render_test.dart`: offscreen `PictureRecorder` render from PNG-encoded inputs decoded by the platform codec; output PNG re-decodes at 1200x1800 |
| AC-0102 Slot masks clip photos; transparent overlay crosses both slot edges unclipped | PASS (host) | FIX-01 checks: rounded-corner clip, flower disc over slot A's bottom edge, in the gap and over slot B's top edge, translucent petals over photo and page; mutation check (row 5) |
| AC-0103 Rotated and off-page decoration: z-order, per-layer transforms, page crop | PASS (host) | Marker rotated 90° (both halves and empty unrotated footprint), cropped at x=1199 in export but visible beyond the page in the workspace; flower-below-slots variant hidden only inside slots |
| AC-0104 Output decodes at target size on both runtimes, platform comparison, bounded tolerance | BLOCKED | Host half done: decodes at 1200x1800; tolerance written down (geometry samples within 3 per channel; whole image at most 0.5% of pixels over 8 and mean at most 1.0, provisional; ADR-0007). iPad and Android runs impossible here. Tooling ready: `integration_test/render_spike_test.dart`, `test_driver/integration_test.dart`, `test/rendering/device_render_comparison_test.dart` |
| AC-0105 Render time, memory, alpha edges and failure behaviour measured | PASS (host) | Metrics above; FIX-04 halos within 2 per channel for both polarities, and the probe fails on deliberately bad edges; failure probes: missing asset → `missingAsset`, corrupt and truncated PNG → `assetDecodeFailed`, duplicate ids and unbound slot → `invalidDocument`. No claim of an optimised renderer. Device figures come with AC-0104 |
| AC-0106 DEVICE/iPad real front-camera preview and saved, reopened still | BLOCKED | No iPad and no Mac. Ready: `PluginCameraDriver`, `ManagedCameraService`, `OriginalStore`, camera spike screen; 23 host tests of the EXIF reader, original store and camera service with a fake driver (not device evidence). Owner steps: device procedure §2 |
| AC-0107 DEVICE/Android same capture test | BLOCKED | No Android tablet. Same code and procedure; the Android build includes CameraX (row 4) |
| AC-0108 Dev-only diagnostics and an ADR on limits, risks, blockers and refactor plan | PASS | Spike screens exist only outside release builds (`test/app/router_test.dart`: "release builds cannot reach the developer spikes"); ADR-0007 |

### M01 exit gate

| Gate | Status |
| --- | --- |
| Evidence-backed 1200x1800 overlay render | PASS (host) |
| Physical capture validated on both platforms, or explicitly BLOCKED pending hardware | BLOCKED pending an iPad (with a Mac) and an Android tablet |

### CI (GitHub Actions run #3)

[Run 39085230790](https://github.com/classamusic-spec/BOOTHD/actions/runs/39085230790)
on `af018c7`, GitHub-hosted `ubuntu-24.04` runners:

| Job | Conclusion | Notes |
| --- | --- | --- |
| Format, analyze, test, licences | success | 117 passed, 1 skipped; both goldens max delta 0 on a second machine (cross-host determinism) |
| Android release smoke build | success | about 5 min, including SDK Platform 35, CMake and JNI compilation on a fresh runner |
| iPadOS unsigned build | skipped | Manual dispatch only, by design |

### Security and privacy notes (M01)

- Release builds request `CAMERA` only for app functions. `RECORD_AUDIO`,
  `WRITE_EXTERNAL_STORAGE` and the implied `READ_EXTERNAL_STORAGE` are
  removed. `ACCESS_NETWORK_STATE` comes from `androidx.media3` and grants
  no network access (`INTERNET` is absent); flagged for M10 (AC-1007).
- iOS declares `NSCameraUsageDescription`; no microphone string, since
  audio is never enabled.
- The plugin's temporary capture file is deleted after reading; originals
  live only in app support storage with SHA-256 checksums, and metadata
  holds no guest data.
- The spike screens are unreachable in release builds.

## M02: Porcelain design system and adaptive Studio shell

```text
Milestone: M02 | code commit 9e368d5ed9ea62182030f5d4e279009201b4bc8d | build 0.1.0+1
Host: same Linux cloud VM as M00 and M01 (no KVM, no macOS, no attached devices)
Flutter 3.47.7 / Dart 3.13.5; new: material_symbols_icons 4.2960.0;
  bundled fonts Inter 4.001 and Cormorant Garamond 4.001 (SIL OFL 1.1)
iPad: BLOCKED (no physical iPad, no Mac); layouts verified at iPad sizes in the test renderer
Android: builds PASS; no physical tablet
Owner approval requested: YES, including the AC-0209 "exceeds the board" sign-off
Owner review page (private): https://claude.ai/artifact/Xr7e93RdsmfDZ8nvi2HNss
```

### Commands and exit codes (2026-10-18 UTC)

Rows 1, 3 and 4 ran on a clean working tree at `9e368d5`.

| # | Command | Exit | Result |
| --- | --- | --- | --- |
| 1 | `tool/check.sh` | 0 | Format: 113 files, 0 changed. Analyze: no issues. Tests: 559 passed, 1 skipped (M01 device comparison, no device results). Licence report current: 70 runtime and 9 dev packages, 0 needing review |
| 2 | Test breakdown (inside row 1) | 0 | architecture 97, domain 20, infrastructure 23, rendering 13 (+1 skip), design system 18, core 3, app/router 16, components 24, screens 225, guest isolation 13, spike screens 4, goldens 103 |
| 3 | `tool/build_android.sh release` | 0 | `app-release.apk`, 56,093,766 bytes, SHA-256 `d2b9a1a703b5883b5cccce89e1430afcd7e2cd4b3961483e0a636e2bb433aa03` (identical to the pre-commit build). `aapt2`: permissions unchanged from M01 (`CAMERA`, `ACCESS_NETWORK_STATE`, AndroidX internal); `android.hardware.camera` optional |
| 4 | `tool/build_android.sh debug` | 0 | `app-debug.apk`, 203,487,738 bytes, SHA-256 `1d6f2959809189557fe25e9e793585f72559bc2f6c62db2b6f3365aadaa4ce99` |
| 5 | Release APK font audit (`unzip`, fontTools 4.60.1) | 0 | Icon tree shaking: `MaterialSymbolsRounded.ttf` 15,073,408 to 139,836 bytes, 82 glyphs, `fvar`/`gvar`/`HVAR`/`avar` kept with FILL, GRAD, opsz and wght axes, so fill and weight variations work in release. Inter and Cormorant Garamond TTFs and both OFL texts bundled unmodified |
| 6 | `tool/build_ios.sh release` | 3 | BLOCKED: Linux host |
| 7 | `flutter test integration_test/app_launch_test.dart -d <device>` | not run | BLOCKED: no device. Updated to expect the Studio dashboard |
| 8 | Mutation guards (inside row 1) | 0 | A palette halfway between light and dark fails the contrast check; literal colours are caught by the token rule; a disabled control without a reason is caught by the dead-control audit |

### Acceptance items

| AC | Status | Evidence |
| --- | --- | --- |
| AC-0201 Porcelain default palette and semantic tokens; no raw per-feature colour scattering | PASS | `lib/core/design_system/` (34 colour roles, 24 type styles, metrics, motion, depth); `test/design_system/design_system_rules_test.dart`: no colour literals in `lib/features` or `lib/shared` (M01 spike fixtures excepted), with a mutation guard |
| AC-0202 Reusable buttons, cards, toggles, steppers, sheets, forms with press, disabled, selected, loading and focus states | PASS | `lib/shared/widgets/`; `test/widgets/components_test.dart` (24): pressed depth and 1 dp travel while held, disabled reason in semantics and on tap, busy ignores presses and announces progress, keyboard focus ring and Enter activation, touch sizes, switch, stepper (incl. accessibility increase), segments, field error, selected card, toast, sheet, grid, navigation. Every state per theme in the component-gallery goldens |
| AC-0203 Dashboard and navigation work; all links and actions functional or clearly disabled with rationale | PASS | `test/app/router_test.dart` (16): every section from sidebar and rail, state kept across sections, dashboard cards, guest preview open and close, settings two-pane and single-pane, rotation keeps the open section, licence page, theme preview then apply, fallback route, developer tools only in debug. `screens_test.dart` audits every screen in both orientations: each control is enabled, busy, or disabled with a stated reason |
| AC-0204 Studio layout at tablet portrait and landscape viewport sizes; no overflows | PASS (test renderer) | `test/widgets/screens_test.dart`: 14 screens at 6 tablet sizes (iPad 820x1180 and 1180x820, Android 800x1280 and 1280x800, compact 600x960 and 960x600) and at 200% text on the compact sizes, no exceptions. Physical tablets: M11 |
| AC-0205 Contrast, labels, touch targets and reduced motion evaluated; exceptions fixed or justified | PASS | Guideline tests (AC-0208); reduced motion: zero-duration presses, still busy indicator, skipped route transitions, operator override and platform setting (`components_test.dart`, `router_test.dart`). Findings fixed, none waived: 1x contrast sampling of thin 13 px labels, a label box touching an item edge, captions inside a frame shadow, 200% text overflow in list rows (implementation log) |
| AC-0206 Theme data shape supports Light Oak and Darkroom without feature changes | PASS | One `PorcelainColors` and `PorcelainTypography` shape for all profiles; applying Light Oak in Settings re-themes the running app (`router_test.dart`); every screen has goldens in all three profiles with no profile-specific feature code |
| AC-0207 Automated token-pair contrast test | PASS | `test/design_system/contrast_test.dart`: 82 pairs in each of 6 palettes (3 profiles, standard and high contrast) meet guest text 7:1, other text 4.5:1, focus and boundaries 3:1; ink on canvas 12.4–19.3:1; high contrast never lowers contrast |
| AC-0208 Every screen passes tap-target, labelled-tap-target and text-contrast guidelines in portrait and landscape | PASS | `screens_test.dart`: all four guidelines on 14 screens at iPad and Android portrait and landscape (56 runs), plus text contrast in Light Oak and Darkroom Walnut; `guest_isolation_test.dart`: the welcome in all three themes, both orientations |
| AC-0209 Golden screenshots for every screen in portrait and landscape at the defined sizes; owner records that they exceed the board | BLOCKED (owner sign-off) | Goldens PASS: 103 in `test/goldens/` (every screen at iPad and Android sizes for Porcelain Studio, iPad size for Light Oak and Darkroom Walnut, component galleries, high-contrast dashboard), compared exactly on two machines (row 1, CI). Waiting for the owner's verdict; review page above |
| AC-0210 No guest-visible print, save, share, settings, back or escape controls | PASS | `test/widgets/guest_isolation_test.dart` (13): at all 6 sizes the welcome exposes one actionable node ("Start"), no back, close, icon, menu, drawer or app-bar widgets, no forbidden words; also inside the operator preview; sample copy never mentions printing |
| AC-0211 Fonts, icons and illustrations have recorded licences and provenance; no board artwork or sample people | PASS | `docs/ASSET_PROVENANCE.md` with SHA-256 per bundled file, enforced by `test/core/app_info_and_licences_test.dart`; font licences registered on the licence page (tested); icon licence in `docs/DEPENDENCY_LICENSES.md`; botanical art original and drawn in code; generic sample copy with no names, dates or people |

### M02 exit gate

| Gate | Status |
| --- | --- |
| Shared UI renders legibly on both device layouts | PASS in the test renderer at iPad and Android tablet sizes (overflow, guideline and golden tests); on physical tablets BLOCKED until devices are available (M11 certifies) |
| No dead functional controls | PASS (dead-control audit on every screen, both orientations) |

### CI (GitHub Actions run #5)

[Run 39091137971](https://github.com/classamusic-spec/BOOTHD/actions/runs/39091137971)
on `9e368d5`, GitHub-hosted `ubuntu-24.04` runners:

| Job | Conclusion | Notes |
| --- | --- | --- |
| Format, analyze, test, licences | success | 559 passed, 1 skipped, as locally; all 103 widget goldens matched exactly on a second machine |
| Android release smoke build | success | 56,093,766 bytes, the same size as locally; SHA-256 `0cbf4feb58c31f62d2012c01daafb8eac8841e50afedef7e626fdaecaf339199` differs only because each machine signs with its own debug key. Same icon tree shaking (Rounded font 15,073,408 to 139,836 bytes). The log still warns that `CupertinoIcons` glyphs are not bundled, as in M00; the app references no Cupertino icons |
| iPadOS unsigned build | skipped | Manual dispatch only, by design |

### Security and privacy notes (M02)

- No new permissions (row 3) and no network use: fonts are bundled, never
  fetched at runtime.
- The licence page lists every package plus the two bundled font licences.
- Developer tools (spikes, component gallery) are unreachable in release
  builds (`router_test.dart`).
- The guest welcome is shown only as an operator preview; the guest area
  has exactly one control. Booth Mode isolation and the PIN come in
  M03 and M07.
- No guest data is created or stored by M02.

## M03: offline storage, event configurations and operator access

```text
Milestone: M03 | code commit 46a61708dd0133723607c0de3c0216e8c9ea229b | build 0.1.0+1
Host: same Linux cloud VM as M00 to M02 (no KVM, no macOS, no attached devices)
Flutter 3.47.7 / Dart 3.13.5; new: drift 2.35.2, drift_flutter 0.3.1, sqlite3 3.5.2
  (bundled SQLite from its build hook), flutter_secure_storage 11.2.0;
  dev: drift_dev 2.35.1, build_runner 2.16.2
iPad: BLOCKED (no physical iPad, no Mac); flows verified in the test renderer
Android: builds PASS; no physical tablet
Owner approval requested: YES
Owner review page (private): https://claude.ai/artifact/FvYeKfJTHs48WAsa4G6R5m
```

### Commands and exit codes (2026-10-18 UTC)

Rows 1 to 4 ran on a clean working tree at `46a6170`; row 7 ran on the
working tree just before that commit, with the same check script.

| # | Command | Exit | Result |
| --- | --- | --- | --- |
| 1 | `tool/check.sh` | 0 | Generated code current (build_runner and `drift_dev make-migrations` changed nothing). Format: 197 files, 0 changed. Analyze: no issues. Tests: 1,194 passed, 1 skipped (M01 device comparison, no device results). Licence report current: 87 runtime and 38 dev packages, 0 needing review |
| 2 | Test breakdown (`flutter test --reporter json` at `46a6170`) | 0 | architecture 163; domain 74 (event rules 15, event service 9, auth service 11, PIN and code policy 10, launch checks 9, M01 document 12, orientation 8); persistence 14; migrations 4; infrastructure 37 (security adapters 9, managed storage 5, M01 camera and files 23); core 12 (route guard 9); design system 18; app flows 42 (access 16, events 10, router 16); components 24; screens 593; guest isolation 19; spike screens 4; rendering 13 (+1 skip); goldens 177 |
| 3 | `tool/build_android.sh release` | 0 | `app-release.apk`, 65,335,192 bytes, SHA-256 `d58ddced48a923f5060ee37cd5d3adc6519d9c54f376639957aaa4104ea7bf6d` (byte-identical to the pre-commit build). `aapt2`: permissions unchanged from M02 (`CAMERA`, `ACCESS_NETWORK_STATE`, AndroidX internal receiver permission); `allowBackup=false`, `fullBackupContent=false`, `dataExtractionRules` present and excluding root, file, database, sharedpref and external from cloud backup and device transfer; `libsqlite3.so` bundled for arm64-v8a, armeabi-v7a and x86_64 |
| 4 | `tool/build_android.sh debug` | 0 | `app-debug.apk`, 239,874,210 bytes, SHA-256 `f820cc7a8f4a3d7bf93c11a2bbe874741246a201602224ffd1e4d7acf6403dd0`; adds only `INTERNET` (Flutter debug tooling), as in M00 to M02 |
| 5 | `tool/build_ios.sh release` | 3 | BLOCKED: Linux host |
| 6 | `flutter test integration_test/app_launch_test.dart -d <device>` | not run | BLOCKED: no device. Updated: a fresh install shows setup, later launches the PIN screen |
| 7 | Mutation guards | 1 (expected) | Generated-code check: an edited CHECK limit in the schema fails (`drift_dev`: schema v1 differs, bump the version); a hand-edited `booth_database.g.dart` fails with the checksum diff. Both restored. Inside row 1: the dead-control audit still catches a disabled control without a reason |
| 8 | Device procedure, `docs/device_tests/M03_DEVICE_PROCEDURE.md` | not run | BLOCKED: no device. Covers setup, unlock time, lockout across restart and clock change, recovery, persistence across force-stop and power cycle, back on the PIN screen, no plaintext secrets and refused backup (Android). Booth Mode cannot be launched on an M03 build (no templates, camera and renderer checks not yet available), so its device checks move to the first build that can launch an event |

### Acceptance items

| AC | Status | Evidence |
| --- | --- | --- |
| AC-0301 First-run operator PIN setup, verification and rate limit tested; no plaintext PIN stored | PASS (host); on-device secure storage BLOCKED | `operator_auth_service_test.dart` (11): slow salted verifiers only, guessable PIN refused with nothing stored, countdown then growing lockouts, lockout survives restart, serialised attempts, unreadable PIN never accepted, recovery resets and replaces the code, stricter recovery lockout, fresh proof needed for changes, weaker verifier upgraded. `security_adapters_test.dart` (9): RFC 7914 vectors, constant-time compare, verifier holds scheme and work but never the PIN, isolate, tampered verifiers fail, Keychain "this device only" and no silent Android reset. `access_flow_test.dart`: setup end to end, refusals, interrupted setup, cold start asks for the PIN, lockout countdown in the UI and after restart, recovery, unreadable PIN offers the code. `operator_secrets_test.dart` (10): PIN and code policy. Keychain and Keystore themselves need a device (M11) |
| AC-0302 Events create, edit, duplicate, archive and reopen offline and persist across restarts | PASS (host); device restart BLOCKED | `events_flow_test.dart`: an event built in the editor is stored exactly and survives a restart onto the same database file; duplicate, archive and reopen from the list; archived read-only until reopened; unsaved-changes guard. `event_service_test.dart` (9) lifecycle rules; `booth_database_test.dart`: events, settings and setup survive closing and reopening the file. No network is used anywhere in these flows |
| AC-0303 Capture settings, template selection, theme override and orientation persist | PASS (host) | Same restart test checks the stored event field by field: rear camera, saved-photo mirroring, landscape guest orientation, 2 shots, 5 s countdown, whole-session retakes and limit, allowed and default template, Light Oak theme override, delete after 30 days. `events_flow_test.dart` "settings" tests: camera, output and orientation defaults shape new events; booth name, PIN and recovery code changes persist |
| AC-0304 Drift migration and referential-integrity tests pass on seeded old/new DBs | PASS for schema v1; upgrade from an older version N/A until schema v2 exists | `migration_test.dart` (4): every version has a dump and a seed and the newest is the app's; a fresh database matches the dump exactly; a seeded v1 file opens with every value intact; a newer database is refused and left untouched. `booth_database_test.dart` (14): foreign keys on and WAL; out-of-range values, inconsistent archive fields, a second default, deleting a revision in use, editing a revision, escaping manifest paths, unknown enum names and extra settings rows are all refused by SQLite; an event and its templates save atomically; deleting an event removes only its own links. `tool/check.sh` fails on any schema change without a version bump (row 7) |
| AC-0305 Guest route guards prevent access to Studio and gallery on back and deep-route attempts | PASS (host); hardware back and OS gestures on devices BLOCKED | `access_redirect_test.dart` (9): in Booth Mode all 20 attempted locations (Studio pages, setup, unlock, developer routes, unknown and foreign-host URLs) lead to the guest welcome; locked, operator, setup and startup phases reach only their own routes. `access_flow_test.dart`: back and 14 deep links in Booth Mode, a platform route push, a restart during Booth Mode, the three-second hidden hold and PIN as the only exit, idle return to guests, the hidden corner absent from the accessibility tree, Lock Studio then back and deep link. `guest_isolation_test.dart`: in Booth Mode at all 6 tablet sizes the screen exposes one actionable node, Start, and no back, close, menu or forbidden words |
| AC-0306 Draft, missing-template and invalid settings block or warn at preflight | PASS | `preflight_test.dart` (9): draft and archived events block; no template, a missing template or a slot mismatch block; invalid stored settings block; an archived template and an orientation mismatch only warn; a failed storage probe or missing PIN blocks; capabilities this build cannot check are "Not yet available" and block, and none is reported as passed. `events_flow_test.dart`: the launch-check screen for a draft, the not-yet-available items, a warning-only orientation case, and Start Booth Mode enabled only when every check passes (with ready fakes) |

### CR-001 items re-run for the new screens (AC-0207 to AC-0211)

| AC | Status | Evidence |
| --- | --- | --- |
| AC-0207 Token-pair contrast in every theme | PASS | Palettes unchanged; `contrast_test.dart` passes in row 1 |
| AC-0208 Every screen passes tap-target, labelled-tap-target and text-contrast guidelines in portrait and landscape | PASS | `screens_test.dart` now covers 37 screens and states (every setup step, PIN and recovery, events, all six editor tabs, draft, archived and new events, launch checks, Booth Mode welcome and exit): all four guidelines at iPad and Android portrait and landscape, text contrast in Light Oak and Darkroom Walnut, overflow at 6 sizes and at 200% text, dead-control audit (593 tests) |
| AC-0209 Goldens for every screen in portrait and landscape at the defined sizes; owner verdict | Goldens PASS; owner verdict requested | 177 goldens. Every route (setup, unlock, events, editor, launch checks and the M02 screens) in Porcelain Studio at iPad and Android sizes and in Light Oak and Darkroom Walnut at iPad sizes; further steps, tabs and states in Porcelain Studio at iPad portrait and landscape; Booth Mode, which wears the event's theme, at all four sizes. Compared exactly locally and in CI. Review page above |
| AC-0210 No guest-visible print, save, share, settings, back or escape controls | PASS | `guest_isolation_test.dart` (19): the real Booth Mode screen at all 6 sizes exposes only Start; the hidden exit is outside the accessibility tree (`access_flow_test.dart`) |
| AC-0211 Licences and provenance; no board artwork or sample people | PASS | No new fonts, icons or artwork; new packages in the licence report (0 needing review); seeded test events use invented titles only in tests |

### M03 exit gate

| Gate | Status |
| --- | --- |
| Offline events persist across restart | PASS on the host (file database reopened); physical-device restart BLOCKED |
| PIN gate tested | PASS on the host; device Keychain and Keystore BLOCKED |
| Migrations and route isolation pass | PASS (schema v1 baseline; route guard, back, deep links, restart) |

### CI (GitHub Actions run #8)

[Run 39100674354](https://github.com/classamusic-spec/BOOTHD/actions/runs/39100674354)
on `46a6170`, GitHub-hosted `ubuntu-24.04` runners:

| Job | Conclusion | Notes |
| --- | --- | --- |
| Format, analyze, test, licences | success | Generated code current; 1,194 passed, 1 skipped, as locally; all 177 goldens matched exactly on a second machine |
| Android release smoke build | success | 65,335,192 bytes, the same size as locally; SHA-256 `edafec30afd42e0bd7ab61d9f78056e2a278a7f6500164598509ffcc47d9b7de` differs only because each machine signs with its own debug key. The SQLite build hook ran on a clean runner (first build needs network, as recorded in ADR-0009) |
| iPadOS unsigned build | skipped | Manual dispatch only, by design |

### Security and privacy notes (M03)

- Neither the PIN nor the recovery code is stored or logged. The PIN
  verifier (PBKDF2-HMAC-SHA256, 120,000 iterations, random 16-byte salt)
  lives in Keychain or Keystore-backed storage; the code's verifier and the
  attempt counters live in the private database. Errors carry codes, never
  secrets or paths.
- A six-digit PIN cannot be protected offline by hashing alone; the
  protection is the sandbox, secure storage, backup exclusion and the
  persisted rate limit (about 24 guesses a day once saturated). The 80-bit
  recovery code is strong offline. ADR-0009 section 4.
- Android app data is excluded from cloud backup and device transfer
  (row 3). iPadOS file backup exclusion is planned for M10 (risk).
- No new permissions, no network use at runtime. SQLite is bundled at
  build time (the sqlite3 build hook downloads it with a pinned hash).
- Booth Mode keeps guests on one screen with one control; the operator
  exit is hidden, needs a three-second hold and the PIN, and returns to
  guests after 45 s untouched.
- No guest photos or personal data exist yet; event notes and names are
  operator data kept on the device.
