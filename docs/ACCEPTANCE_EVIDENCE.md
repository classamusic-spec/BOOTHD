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
