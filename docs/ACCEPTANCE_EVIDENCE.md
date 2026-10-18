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

## M04: production template model, renderer and template store

```text
Milestone: M04 | code commit bbdf29948686b07d6e2e4116dc31d81216e5db35 | build 0.1.0+1
Host: same Linux cloud VM as M00 to M03 (4 cores, no KVM, no macOS, no attached devices)
Flutter 3.47.7 / Dart 3.13.5; no new packages (crypto, already present, now also
  used by the domain for content ids; ZIP and JPEG code written in the project)
iPad: BLOCKED (no physical iPad, no Mac)
Android: builds PASS; no physical tablet
Owner approval requested: YES
Owner review page (private): https://claude.ai/artifact/Dh8GvRUHGmbpqUujo62GSi
```

### Commands and exit codes (2026-10-18 UTC)

Rows 1 to 6 ran on `bbdf299`; the working tree differed only in
documentation.

| # | Command | Exit | Result |
| --- | --- | --- | --- |
| 1 | `tool/check.sh` | 0 | Generated code current (build_runner and `drift_dev make-migrations` changed nothing, including the schema v2 dump and steps). Format: 0 changed. Analyze: no issues. Tests: 1,378 passed, 1 skipped (device comparison, no device results). Licence report current |
| 2 | Test breakdown (`flutter test --reporter json` at `bbdf299`) | 0 | 1,378 passed, 1 skipped: architecture 189; domain 110 (template documents 19, JSON 13, scenes 15, event rules 15, event service 9, auth service 11, PIN and code policy 10, launch checks 10, orientation 8); persistence 14; migrations 6; infrastructure 124 (ZIP reader 24, packages 24, assets 13, revisions 6, export service 10, launch-check probe 5, JPEG encoder 6, security 9, managed storage 4, camera 14, originals 6, EXIF 3); rendering 46 + 1 skip (render lab 13, preview parity 11, text 8, goldens 7, output formats 6, benchmark 1; the skip is the device comparison, which has no device results); core 12; design system 18; app flows 42 (access 16, events 10, router 16); widgets 640; widget goldens 177 |
| 3 | `tool/build_android.sh release` | 0 | `app-release.apk`, 66,236,312 bytes, SHA-256 `cd7d7b812882f75cc92f918d4ee83e84c311a010816f13cf82cc22b77784fc36`. `aapt2`: targetSdk 36; permissions unchanged from M03 (`CAMERA`, `ACCESS_NETWORK_STATE`, the AndroidX internal receiver permission); `allowBackup=false`, `fullBackupContent=false`, `dataExtractionRules` present |
| 4 | `tool/build_android.sh debug` | 0 | `app-debug.apk`, 240,182,449 bytes, SHA-256 `0c43d0cc447075694f141183112f5b5ba3863e385120a40d53e63137fbf0f0e6`; adds only `INTERNET` (Flutter debug tooling), as before |
| 5 | `tool/build_ios.sh release` | 3 | BLOCKED: Linux host |
| 6 | `flutter drive --profile … integration_test/render_lab_test.dart` (M04 procedure) | not run | BLOCKED: no device. The render lab, goldens, parity, text probes and repeat timings run on the host in row 1; the device run saves every render for `device_render_comparison_test.dart` |

### Measurements on the host (informative; tablets will differ)

Render goldens (inside row 1), threshold 8: all six match exactly (max
delta 0): `fix01_export_1200x1800` and `fix01_workspace_1440x2160` (the M01
goldens, still reproduced by the production renderer), `fix02_export_600x1800`,
`fix03_export_1800x1200`, `fix05_export_1200x1800`, `clip_export_1200x1200`.

Preview at 1/4 against the export box-filtered to the same size
(`preview_parity_test.dart`; tolerance outside text: threshold 16, at most
0.5% over, mean at most 1.0):

| Fixture | Max | Mean | Over 16 | Text (lines; ink bounds preview vs export) |
| --- | --- | --- | --- | --- |
| FIX-01 | 53 | 0.508 | 0.137% | none |
| FIX-01b | 53 | 0.505 | 0.081% | none |
| FIX-02 | 1 | 0.012 | 0.000% | title: 1 line both; 24,399..127,421 vs 24,400..127,422 |
| FIX-03 | 8 | 0.034 | 0.000% | none |
| CLIP | 36 | 0.107 | 0.121% | none |
| GRADIENT | 1 | 0.219 | 0.000% | none |
| FIX-05 | 0 | 0.000 | 0.000% | 1, 1, 4 and 3 lines both; every edge within 1 px |

Every scaled export check where the reduced export is uniform also passes
(at least half of each fixture's checks apply). The `ScenePreview` widget
matches the renderer's preview with max delta 0 (FIX-01, FIX-03, CLIP,
FIX-05). Negative controls: a preview moved by one pixel fails the
tolerance (FIX-01, FIX-03, CLIP); text moved by two pixels fails.

Render cost (`render_metrics_test.dart`, `build/m04/host_render_benchmark.json`,
4-core VM):

| Case | Runs | Total p50 / p95 (ms) | Decode p50 | Raster p50 | Encode p50 |
| --- | --- | --- | --- | --- | --- |
| FIX-01 JPEG 1200x1800 (1600x1200 PNG photos) | 20 | 316 / 342 | 91 | 110 | 108 |
| FIX-01 PNG 1200x1800 | 10 | 311 / 371 | 96 | 95 | 112 |
| FIX-01 JPEG with 12 MP JPEG originals | 20 | 372 / 413 | 123 | 122 | 123 |
| FIX-01 preview 300x450 with 12 MP originals | 10 | 67 / 86 | 53 | 6 | 8 |

The 12 MP photos decode at 0.238 and 0.317 of full size (the size their
slots draw them). Resident memory over 100 more 12 MP JPEG exports, every
ten: −0.2, 1.1, 2.4, 2.3, 4.1, 7.9, 7.8, 9.1, 10.5, 10.3 MB. A longer
probe (300 exports) levelled at 20.9 MB after 200; PNG exports and
previews showed no growth (allocator caching for the encoder isolate, not
a leak). JPEG encoder PSNR on its synthetic test image: q50 37.4, q80
40.0, q92 42.5, q100 51.0 dB.

### Acceptance items

| AC | Status | Evidence |
| --- | --- | --- |
| AC-0401 Versioned JSON validates and round-trips, including out-of-page bounds and rotation | PASS | `template_json_test.dart`: every layer type, fill, clip, fit and font round-trips to equal documents and identical canonical bytes, including off-page frames (a slot starting at x -0.05; an image from y -0.1 reaching past the right edge), rotations (-7.5° about a corner pivot, 135°) and Unicode text; unknown fields, unknown layer types, wrong types and newer or invented versions are refused with codes and paths; the frozen `test_assets/templates/v1/everything.json` still reads and re-encodes byte for byte. `template_document_test.dart`: every validation rule. Stored revisions round-trip through the store (`template_repository_test.dart`) and packages (`template_packages_test.dart`) |
| AC-0402 Deterministic render order with z-order, visibility and opacity | PASS | Render lab: FIX-01 and FIX-01b (flower above, then below both slots), CLIP hidden layer and group opacity (the line hides the fill under it). Same bytes on repeated renders, JPEG and PNG (`preview_parity_test.dart`). `template_document_test.dart`: paint order is ascending z with ties in document order, for every layer type; `document_scene_test.dart`: the scene keeps that order |
| AC-0403 CRITICAL: transparent PNG crosses two slot boundaries unclipped | PASS (host); device BLOCKED | FIX-01 checks: flower centre in the gap, translucent petals over the page and over slot A's photo, disc above slot A by z-order; still exact against the M01 golden. Device run: M04 procedure |
| AC-0404 Photo clipped to its own slot; masking and crop correct | PASS (host) | FIX-01 cover crops and rounded corner; FIX-03 focal points and rotated slots; CLIP ellipse, ring mask, contain fit with border, mirrored photo. Single anti-aliased slot edge (no seam) shown by parity on fractional edges |
| AC-0405 2x6 600x1800, 4x6 1200x1800 / 1800x1200, 4x4 1200x1200 at 300 dpi | PASS | `render_lab_test.dart` export sizes; PNG `pHYs` and JPEG JFIF both say 300 dpi (`output_formats_test.dart`); `FileExportService` verifies the saved file decodes at the page size |
| AC-0406 PNG alpha preserved; JPEG flattened intentionally; no alpha fringe | PASS | `output_formats_test.dart`: transparent page stays transparent with translucent petals at their alpha; edges keep their colour (no dark or light fringe); JPEG flattened onto white by default or any colour, and a template background wins. FIX-04 halo probes pass |
| AC-0407 Preview and export geometry equivalent; golden/pixel tests within documented tolerance | PASS on the host; target platforms BLOCKED | Measurements above; tolerance in ADR-0010 section 6. Device comparison tooling ready (`device_render_comparison_test.dart` compares all six goldens) |
| AC-0408 Asset import validates MIME/header, dimensions, path safety, missing sources, unsupported schema | PASS | `asset_repository_test.dart` (13): content not names, unknown and unsupported formats, truncated and cut-off PNGs, over-limit sizes refused before decoding, rotated JPEG recorded at display size, names reduced, reads verified. `zip_archive_test.dart` (24): traversal, absolute, backslash, drive and control-character paths, links, duplicates, disagreeing headers, overlapping entries, bombs, over-declared inflation, size and count limits, encryption, ZIP64, split archives, CRC and size damage, trailing data, non-UTF-8 names. `template_packages_test.dart` (24, FIX-06): corrupt PNG, oversized image, unknown layer type, newer document and package versions, invented version, missing asset, wrong content or type, oversized page, escaping and absolute paths, bomb, encryption, unexpected or unused files, missing or broken manifest, not a package: each refused with its own code, storing nothing; macOS extras ignored |
| AC-0409 Export failure or low storage leaves originals and previous output untouched; memory bounded in repeats | PASS (host); device memory BLOCKED | `file_export_service_test.dart` (10): full disk mid-write, silently short write, corrupted bytes, failed rename and a render failure each save nothing, leave no staged file and leave every original and earlier output byte-identical; a crash leaves a staged file that the next start discards; a file is never replaced; 30 repeated exports stay within the memory bound. Benchmark above |

### M04 exit gate

| Gate | Status |
| --- | --- |
| Renderer reproducible | PASS (host): same bytes on repeat; M01 goldens matched exactly |
| Print quality | PASS (host): exact page sizes at 300 dpi, PNG with alpha, JPEG 4:4:4 q92 default, no seams or fringes; device output BLOCKED |
| Correct alpha, order and clipping | PASS (host), AC-0402 to AC-0404, AC-0406 |
| Output dimensions and validated save | PASS (host), AC-0405, AC-0409 |

### CI (GitHub Actions)

[Run 39136784713](https://github.com/classamusic-spec/BOOTHD/actions/runs/39136784713)
(#11) on `bbdf299`, GitHub-hosted `ubuntu-24.04` runners (4 cores). Run
#10 on the first M04 commit, `7a7e609`, also passed.

| Job | Conclusion | Notes |
| --- | --- | --- |
| Format, analyze, test, licences | success | Generated code current; 1,378 passed, 1 skipped, as locally. All six render goldens match exactly on a second machine (max delta 0); preview parity and widget-preview figures identical to the host's. Benchmark on the runner: FIX-01 JPEG p50 111 ms (p95 120), PNG 125 (157), with 12 MP originals 133 (148), preview 22 (24); memory over 100 exports +7.8 MB |
| Android release smoke build | success | 66,236,312 bytes, the same size as locally; SHA-256 `e0e7e959e70f62b09ad0e3f32460bd8cca9e13109e597ac51d12b0400272a90e` differs only because each machine signs with its own debug key |
| iPadOS unsigned build | skipped | Manual dispatch only, by design |

### Security and privacy notes (M04)

- No new permissions or packages, no network use. Release permissions are
  as in M03 (row 3).
- Template files are judged by their bytes, never by names or claimed
  types; limits apply before any pixel is decoded; packages are read in
  memory under hard limits and never extracted to a path, so traversal
  and link entries cannot write anywhere.
- Assets are content-addressed and checked against their id on every
  read; manifests against their checksum on every load. A changed file
  stops a render (`RENDER_MISSING_ASSET`) instead of printing something
  else.
- Diagnostics carry codes, asset ids and entry names only; never device
  paths or file contents. No guest photos exist yet; outputs are written
  only under managed `outputs/`.

## M05: full layered Template Studio and template library

```text
Milestone: M05 | code commit fa34247 (checks also on cfadbda) | build 0.1.0+1
Host: same Linux cloud VM as M00 to M04 (4 cores, no KVM, no macOS, no attached devices)
Flutter 3.47.7 / Dart 3.13.5; new packages: file_selector 1.1.0, share_plus 13.3.x
  (and their platform packages), behind the OperatorFiles interface
iPad: BLOCKED (no physical iPad, no Mac)
Android: builds PASS; no physical tablet
Tablet layouts tested on the host at iPad 1180x820 / 820x1180, Android
  1280x800 / 800x1280 and compact 960x600 / 600x960 logical pixels
Owner approval requested: YES
```

### Commands and exit codes (2026-10-18 UTC)

| # | Command | Exit | Result |
| --- | --- | --- | --- |
| 1 | `tool/check.sh` on `cfadbda` | 0 | Generated code current (build_runner and `drift_dev make-migrations` changed nothing, including the schema v3 dump and steps). Format: 0 changed. Analyze: no issues. Tests: 1,633 passed, 1 skipped (device comparison, no device results). Licence report matches `pubspec.lock` |
| 2 | `fa34247` (UI fix and four tests after row 1): `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test --reporter json` | 0, 0, 0 | Format: 0 changed. Analyze: no issues. Tests: 1,635 passed, 1 skipped, 0 failed: architecture 218; domain 133 (editing 23); persistence 14; migrations 7; infrastructure 128 (asset store 17); rendering 67 + 1 skip (editor parity 21, preview parity 11); core 33 (starter designs 12, template library 9); design system 18; app flows 42; features 12 (editor controller); assets 2; widgets 760 (screen checks 689, Template Studio 13, library flows 9, stress 3); widget goldens 201 |
| 3 | `tool/build_android.sh release` on `fa34247` | 0 | `app-release.apk`, 71,087,057 bytes, SHA-256 `641b197762b11d8ba7e3459233c0b1313f2aa6fa3e2a4c712299898d0248aa5e`. `aapt2`: targetSdk 36; permissions unchanged from M04 (`CAMERA`, `ACCESS_NETWORK_STATE`, the AndroidX receiver permission); `allowBackup=false`, `fullBackupContent=false`, `dataExtractionRules` present; new, not exported: `ShareFileProvider` and the `SharePlusPendingIntent` receiver (`share_plus`) |
| 4 | `tool/build_android.sh debug` on `fa34247` | 0 | `app-debug.apk`, 240,723,927 bytes, SHA-256 `55ce6833bff5d4d7b77ca8274f3422b5051249d151c03fb62164adb3cf672b18`; adds only `INTERNET` (Flutter debug tooling), as before |
| 5 | `tool/build_ios.sh release` | 3 | BLOCKED: Linux host |
| 6 | M05 device procedure (`docs/device_tests/M05_DEVICE_PROCEDURE.md`) | not run | BLOCKED: no iPad, no Android tablet |

### Measurements on the host (informative; tablets will differ)

Template Studio canvas against the renderer (`editor_parity_test.dart`;
ADR-0011 section 5). The live canvas is captured with grid, print-safe
margin and selection off; only the slot numbers and the page's edge line
are masked. Canvas against the renderer's preview at the same size: max
delta 0 (classic, retro, gold, blanks) or 1 (floral, modern) at 1/2 and at
1/4. Canvas against the 300 dpi export box-filtered down, outside text
(ADR-0010 tolerance: threshold 16, at most 0.5% over, mean at most 1.0):

| Design (page) | 1/2: over 16, mean | 1/4: over 16, mean (recorded) |
| --- | --- | --- |
| Classic Strip (600x1800) | 0.000%, 0.096 | 0.173%, 0.319 |
| Floral Elegance (600x1800) | 0.377%, 0.374 | 1.374%, 0.880 |
| Modern Minimal (1200x1800) | 0.000%, 0.217 | 0.000%, 0.240 |
| Retro Film (600x1800) | 0.156%, 0.304 | 0.306%, 0.550 |
| Gold Celebration (1200x1800) | 0.002%, 0.303 | 0.025%, 0.516 |
| Blank 2x6, 4x6, 6x4, 4x4 | 0.000%, 0.000 | 0.000%, 0.000 |

Text: every text layer has the same number of lines and ink bounds within
1 pixel of the export's at 1/2. Floral Elegance's vine (it starts beyond
the left edge and crosses all three photo spaces): where it lies over the
photos 21.1% of the pixels differ by more than 16 from the page without
it, beside them 17.2% (it is drawn, not clipped). Negative control: the
vine moved by 2 canvas pixels gives max delta 209 and 1.81% over, failing.
The spray beyond the page shows faded in the margin (847 of 12,554 margin
pixels change when it is hidden); the export is exactly the page. The
same figures came from the CI runner (run #17).

M04 lab fixtures (`preview_parity_test.dart`, 1/4) after the preview
decoding change, over 16 and mean: FIX-01 0.030%, 0.546; FIX-01b 0.025%,
0.563; FIX-02 0.000%, 0.012; FIX-03 0.083%, 0.043; CLIP 0.214%, 0.150;
GRADIENT 0.000%, 0.219; FIX-05 0.000%, 0.000. All inside the tolerance;
all six export goldens still match exactly (exports are unchanged).

Stress (`template_stress_test.dart`): a 4x6 template with 30 layers (6
photo spaces, 8 texts, 7 shapes, 8 transparent PNG decorations, background)
took 150 random edits through the editor; 148 applied, 2 refused (locked
or already at the top), 35 layers at the end; the document was valid
after every edit. Undo walked back the 100 kept steps, each equal to the
recorded state, then stopped; redo walked forward to the end exactly.
Saved and reopened equal and editable. Its 300 dpi PNG export: 1200x1800,
paint 14 ms, PNG encode 345 ms, no warnings (CI runner: 7 ms, 205 ms).
The Template Studio opened it with all 29 reorderable rows plus the
background listed.

### Acceptance items

| AC | Status | Evidence |
| --- | --- | --- |
| AC-0501 New template from blank and preset; correct canvas/page metadata | PASS (host); device BLOCKED | `starter_designs_test.dart` (9): the five designs and four blank pages build valid documents with the right page (2x6 600x1800, 4x6 1200x1800 portrait and 1800x1200 landscape, 4x4 1200x1200, all 300 dpi, inches), photo counts and stored decorations. `template_library_flows_test.dart`: "Choose your style" > Retro Film > name "Film night" > Continue creates the template (600x1800, 300 dpi, four photos) and opens it in the Studio, on iPad landscape and Android portrait. The inspector's page summary reads "2 × 6 in · 600 × 1800 px at 300 dpi" |
| AC-0502 Add/edit/delete photo slots, PNG images, text, backgrounds and shapes | PASS (host) | `template_studio_test.dart`: the Text and Photo tools add layers, undo and redo, in both iPad orientations. `editor_controller_test.dart`: background colour, gradient and removal, one undo step each. `template_library_flows_test.dart`: a PNG picked from the document picker is stored and placed as an image layer. `template_stress_test.dart`: all five kinds added, then edited, duplicated and deleted 150 times. `editing_test.dart`: add, remove, duplicate, update and renumbering rules |
| AC-0503 Select, drag, resize, rotate and exact numeric transform in both orientations | PASS (host, iPad landscape and portrait layouts); device BLOCKED | `template_studio_test.dart`, each orientation: tap selects; a drag moves the layer as one undo step with snapping; the bottom-right handle resizes with the top-left corner fixed; the rotation handle turns a quarter turn to exactly 90° (15° snapping); the inspector sets X 50 px, width 480 px and rotation 12.5° exactly, three undo steps. `editing_test.dart`: resize keeps the opposite corner for every handle and rotation, minimum sizes, pivot changes keep the layer in place |
| AC-0504 Layers reorder, rename, lock/unlock, show/hide, duplicate and front/back persist | PASS (host) | `template_studio_test.dart`: in the Layers panel, Title dragged below Rule, Subtitle hidden, Rule locked; in the inspector, Photo 1 brought to the front, duplicated (the copy becomes photo 4) and the copy renamed; after Save the stored revision has every change and equals the editor's document. `editing_test.dart` and the stress run cover the operations and refusals |
| AC-0505 Snap to guides, grid and centre; pan, zoom, fit; selection handles; coordinate transforms | PASS (host) | `editing_test.dart`: snapping to page edges and centres, other layers and the grid with guides; handle positions and hit tests on rotated frames. `template_studio_test.dart`, each orientation: Zoom in (×1.25, the percentage updates), a two-finger pinch keeps the point between the fingers in place, the Pan tool drags the view even over a layer, Fit the page restores the fitted view, page and screen coordinates convert both ways, and none of it changes the document or the undo history |
| AC-0506 Undo/redo for create, move, rotate, delete, reorder, with drag coalescing | PASS | `editing_test.dart` (history, gestures, saved marker). `editor_controller_test.dart`: a 30-step drag is one step; a rotation and an opacity slider are one step each; a step that breaks the rules is skipped and the drag goes on. `template_studio_test.dart`: tools, drags, handles and inspector entries. Stress: 100 undo steps exact, then redo exact, across moves, rotations, reorders, duplicates and deletions |
| AC-0507 Autosave, explicit save and reopening restore editable geometry and assets and a history-safe last saved revision | PASS (host); force-quit on a device BLOCKED | `editor_controller_test.dart`: a draft 1.2 s after a change; none in the middle of a drag; removed when undo returns to the saved design; a refused draft says so and the next change retries; leaving keeps unsaved work at once; save stores revision 2, removes the draft, keeps history (undo goes past the save) and leaves revision 1 unchanged; a refused save keeps the work in memory and in the draft; a draft reopens editable and Discard returns to the save. `template_studio_test.dart`: Save gives "Saved as revision 2."; a draft equal to its revision is discarded unseen. Migration tests: v1 and v2 databases open as v3 with the drafts table. Stress: saved and reopened equal and editable |
| AC-0508 PNG from the file picker copied into managed storage; works after the picker's temporary file is gone | PASS (host, by construction); device BLOCKED | `PlatformOperatorFiles` checks the size, reads the bytes once and keeps no path. `template_library_flows_test.dart`: the picked PNG is stored under its content id, read back byte-identical and placed; a non-image named `.png` is refused and nothing is stored; an oversized file is refused before reading; renaming works, and removal is refused while a template uses the image. On a device the original is deleted in step 11 of the procedure |
| AC-0509 Package export/import round trip; corrupt or unknown files safely rejected | PASS | `template_library_flows_test.dart`: Export package hands the share sheet `Garden-party-r1.porcelain-template` as `application/zip`; it imports on another booth as the same document; a dismissed share sheet claims nothing; Import refuses a file that is not a package ("Nothing was imported.", nothing stored), one over 100 MB, and does nothing when cancelled. `template_library_test.dart` and M04's `template_packages_test.dart` (24) cover the real package format |
| AC-0510 Preview matches final renderer, including artwork outside photo slots | PASS (host, at 1/2: the target tablets' range); 1/4 recorded; device BLOCKED | Measurements above: the canvas is the renderer's preview pixel for pixel, inside ADR-0010's tolerance of the 300 dpi export at 1/2, with the floral vine across all three photo spaces and the spray off the page; a 2-pixel misplacement fails |

### M05 exit gate

| Gate | Status |
| --- | --- |
| On either tablet, an operator creates and reopens a fully editable floral photo template with a matching 300 dpi export | PASS on the host at tablet sizes in both orientations (flows, editor and parity tests); BLOCKED on physical tablets (procedure section 1) |

### CI (GitHub Actions)

Runs on GitHub-hosted `ubuntu-24.04` runners (4 cores). Every M05 push
passed: #13 `10776ba`, #14 `8c35aae`, #15 `9ce9d4c`, #16 `30abcb2`, #17
`cfadbda` and
[#18](https://github.com/classamusic-spec/BOOTHD/actions/runs/39165416286)
on `fa34247`.

| Job (#18) | Conclusion | Notes |
| --- | --- | --- |
| Format, analyze, test, licences | success | Generated code current; 1,635 passed, 1 skipped, as locally. The editor parity, preview parity and stress figures above were reproduced exactly on the runner in #17; its stress export took 7 ms to paint and 205 ms to encode |
| Android release smoke build | success | Built from `fa34247` |
| iPadOS unsigned build | skipped | Manual dispatch only, by design |

### Security and privacy notes (M05)

- New packages `file_selector` and `share_plus` are used only through the
  `OperatorFiles` interface in infrastructure. Release permissions are
  unchanged (`CAMERA`, `ACCESS_NETWORK_STATE`, the AndroidX receiver
  permission). New manifest components come from `share_plus` and are not
  exported: `ShareFileProvider` and the `SharePlusPendingIntent` receiver.
- Picked files are judged by their bytes (PNG or JPEG for images, the
  package reader for packages); their names are display text only. Size
  limits apply before reading. Nothing keeps a picker path or URI.
- Exported packages contain the template and its assets only; the share
  sheet receives bytes, a file name and a type. No guest photos exist yet.
- Drafts live in the booth database like revisions and are deleted with
  their template; nothing is sent anywhere.

## M06: production camera service and Diagnostics camera test

```text
Milestone: M06 | code commit 832ce8d, Android build fix a9cee67 | build 0.1.0+1
Host: same Linux cloud VM as M00 to M05 (4 cores, no KVM, no macOS, no attached devices)
Flutter 3.47.7 / Dart 3.13.5; new package: permission_handler 13.0.2 (and its five
  platform packages), behind the CameraPermissions interface; camera 0.12.1 unchanged
iPad: BLOCKED (no physical iPad, no Mac)
Android: builds PASS; no physical tablet
Camera behaviour tested on the host only: the production service over a fake driver
  with the real originals store, and the screens on a simulated camera. Neither is a
  camera: every DEVICE item below is BLOCKED.
Owner approval requested: YES
```

### Commands and exit codes (2026-10-18 UTC)

| # | Command | Exit | Result |
| --- | --- | --- | --- |
| 1 | `tool/check.sh` on the tree committed as `832ce8d` | 0 | Generated code current (build_runner and `drift_dev make-migrations` changed nothing, including the schema v4 dump, steps and test schemas). Format: 292 files, 0 changed. Analyze: no issues. Tests: 1,793 passed, 1 skipped (device comparison, no device results), 0 failed. Licence report matches `pubspec.lock` |
| 2 | `flutter test --reporter json` on the seven M06 test files | 0 | `managed_camera_service_test.dart` 32, `original_store_test.dart` 15, `camera_test_screen_test.dart` 21, `device_capability_probe_test.dart` 8, `migration_test.dart` 9, `camera_choice_test.dart` 5, `contrast_test.dart` 10; 0 failed. The screen catalog adds 80 checks for the five new screens (overflow at six sizes, 200% text, tap targets, labels, contrast in three themes, no dead controls) and 16 goldens |
| 3 | `tool/build_android.sh release` on `832ce8d` | 1 | FAIL: `permission_handler_android` 14.1.0 compiles against API 37. AGP 9.1.0 downloaded `platforms;android-37.0` (the only API 37 platform) during the build and then could not find target `android-37`; on the next run it refused an app compiled against 36. Fixed in `a9cee67` (ADR-0012 section 2) |
| 4 | `tool/build_android.sh release` on `a9cee67`, started from an SDK without `android-37.0` | 0 | The script installed the platform, then built `app-release.apk`, 71,136,157 bytes, SHA-256 `58f26cdcb9a6d808fd805c4a44af5670644746f41019280470956c505a258c8b`. `aapt2`: compileSdk 37, targetSdk 36 (unchanged); permissions unchanged from M05 (`CAMERA`, `ACCESS_NETWORK_STATE`, the AndroidX receiver permission); components unchanged: `ShareFileProvider`, `SharePlusPendingIntent`, CameraX `MetadataHolderService` and `InitializationProvider` not exported, `ProfileInstallReceiver` exported behind `DUMP`; `allowBackup=false`, `fullBackupContent=false`, `dataExtractionRules` present |
| 5 | `tool/build_android.sh debug` on `a9cee67` | 0 | `app-debug.apk`, 240,891,123 bytes, SHA-256 `4641fb186168969247a2c83a0b88623bf4b2dbe4a4157eae36df14e91a9a01d7`; adds only `INTERNET` (Flutter debug tooling), as before |
| 6 | `tool/build_ios.sh release` | 3 | BLOCKED: Linux host. The Swift free-space channel and the `permission_handler` Swift package have not been compiled yet (CI's manual iPadOS job or a Mac) |
| 7 | `flutter test integration_test/camera_capture_test.dart -d <device>` | not run | BLOCKED: no physical tablet |
| 8 | M06 device procedure (`docs/device_tests/M06_DEVICE_PROCEDURE.md`) | not run | BLOCKED: no iPad, no Android tablet, no enclosure |

### Acceptance items

| AC | Status | Evidence |
| --- | --- | --- |
| AC-0601 Camera permissions denied/granted/permanently denied have safe UX and documented repair | PASS (host); device BLOCKED | `managed_camera_service_test.dart` (32; permission group 11): never asked prompts once on opening; refused, refused for good and restricted fail with their own codes without prompting or opening; a refusal at the prompt says so; plugin permission errors map to the same states; the Settings repair is reported and its failure returns false; plugin exceptions become typed failures; `permission_handler` statuses map as ADR-0012 section 2 says. `camera_test_screen_test.dart`: the screen explains before asking and asks only on "Allow camera"; refused for good shows the Android Settings steps and opens Settings without asking; restricted shows no dead buttons; access turned on in Settings while away (or before ever being asked) opens the camera on return without a prompt or a photo. Launch checks and the self-test read the permission and never ask (`device_capability_probe_test.dart`, Diagnostics test). Repair steps: S18 copy per platform, `docs/device_tests/M06_DEVICE_PROCEDURE.md` section 1, and the iOS build rule in `docs/IOS_VALIDATION.md` |
| AC-0602 Lens enumeration avoids unsupported cameras and selects known front/rear | PASS (host); device BLOCKED | `camera_choice_test.dart`: the platform's first camera of a lens is chosen, the other built-in lens is a noted fallback, external cameras never. Probe: the event's lens missing gives `CAMERA_LENS_UNAVAILABLE`, only an external camera gives `CAMERA_NONE`. Screen: only built-in lenses are offered; a rear-only tablet says so and opens the rear camera; switching reopens the chosen one |
| AC-0603 DEVICE/iPad: real still saved at camera resolution with correct orientation/mirror metadata | BLOCKED | No iPad or Mac. Ready: `integration_test/camera_capture_test.dart` and procedure section 3 |
| AC-0604 DEVICE/Android: the same on the certified Android model | BLOCKED | No Android tablet. Ready: the same test and procedure |
| AC-0605 Preview keeps its aspect ratio with no stretch and the chosen preview mirroring | PASS (host, logic and layout); device BLOCKED | `managed_camera_service_test.dart`: the shown preview is mirrored exactly when asked on both lenses given each platform's own front-camera mirroring; the preview shape is the stream's long side over its short side in either orientation. The viewfinder takes that shape for the screen and centres the plugin's own aspect-keeping preview (letterboxed, never stretched); the camera test's goldens and screen checks in both orientations; mirroring switches change the preview and are recorded with the photo, independently |
| AC-0606 Background/foreground/interrupt recovery without a leaked camera or delayed shutter | PASS (host); device BLOCKED | Service: suspend releases the camera (no camera open afterwards), resume reopens without prompting or capturing; access revoked while away fails on resume without prompting and recovers when restored; an interruption (another app) closes the camera and says why, and a capture in flight finishes first; suspending waits for a capture; dispose leaves no camera open. Screen: background then foreground reopens with zero shutters; a press while not in front is refused and nothing fires later; closing the screen releases the camera |
| AC-0607 Capture calls serialised; two fast taps cannot make duplicate shots | PASS (host); device BLOCKED | Service: a second capture during one is refused at once (`CAMERA_CAPTURE_BUSY`), the driver fires once, and the next press works; operations run in call order. Screen: a double tap takes one photo. The device test repeats the double press on each lens |
| AC-0608 Saved originals survive app restart; no preview screenshot substituted | PASS (host); device BLOCKED | `original_store_test.dart` (15): complete-JPEG and decode checks before storing; never overwrites; full disk and failed records leave nothing; recorded originals are immutable; after closing and reopening the database and files every original lists and reads back intact; a changed or missing file fails its check; startup finishes a commit interrupted after the file, undoes one interrupted while writing, quarantines a mismatching file and adopts the M01 spike's originals. Service: a capture survives a restart; the stored bytes are the driver's. Stills come only from the camera's full-resolution capture (`ResolutionPreset.max`), never from the preview; the device test asserts each still is at least as large as the preview stream |
| AC-0609 DEVICE: front-camera position and lens clear through the enclosure | BLOCKED | No tablet or enclosure. Procedure section 8 |

### M06 exit gate

| Gate | Status |
| --- | --- |
| Real iPad and Android full-resolution still save and reopen, reliable lifecycle, no duplicate shutter | BLOCKED: no physical iPad or Android tablet. The service, store, lifecycle and screens pass on the host; the scripted device test and procedure are ready |

### CI (GitHub Actions)

Runs on GitHub-hosted `ubuntu-24.04` runners (4 cores). #20 on `832ce8d`
was cancelled by the next push before its Android job ran (that commit's
Android build fails, row 3).
[#21](https://github.com/classamusic-spec/BOOTHD/actions/runs/39172769990)
on `a9cee67`:

| Job (#21) | Conclusion | Notes |
| --- | --- | --- |
| Format, analyze, test, licences | success | `tool/check.sh` in 7 min 14 s: generated code current, format and analyze clean, all tests passed as locally (goldens compared on Linux) |
| Android release smoke build | success | From a runner SDK without API 37: the script installed `platforms;android-37.0`, AGP added CMake 3.22.1, `assembleRelease` 358 s; `app-release.apk` 71,136,157 bytes (the local size), SHA-256 `35978459c868a4eb3176557b5c7f32edfcc3d41d54c9c71ee3ac255608dbf6cf` (signed with the runner's own debug key, so the hash differs from row 4) |
| iPadOS unsigned build | skipped | Manual dispatch only, by design; not run (macOS minutes), so the Swift changes are not yet compiled |

### Security and privacy notes (M06)

- `permission_handler` is used only through `CameraPermissions` in
  infrastructure. It adds no Android permission (merged release manifest
  compared with `aapt2`). On iOS it compiles in only the permissions whose
  `Info.plist` keys exist (camera); the build rule in
  `docs/IOS_VALIDATION.md` prevents a build with the camera compiled out.
- Originals stay in the app's private support directory; the plugin's
  temporary file is deleted after reading. Records hold dimensions,
  checksum, lens, orientation, mirror settings and times: no location, no
  guest data. Nothing is sent anywhere.
- Failure details are codes or Dart type names: plugin descriptions (free
  text that may name the device) and file paths never reach the screen or
  logs. Diagnostics shows codes and repair steps only.
- Recovery never deletes an original: files that fail their checks are
  moved to `originals/.quarantine`.
- The free-space channel returns one number. Camera test and self-test
  are operator-only routes behind the PIN and absent from Booth Mode
  (`access_flow_test.dart` checks the camera test route from Booth Mode).
