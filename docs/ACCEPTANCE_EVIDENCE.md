# Acceptance evidence

Status values: PASS, FAIL, BLOCKED (could not run; reason and owner steps
given), N/A (with reason). Owner review is required to accept a milestone.
DEVICE gates are never satisfied by CI, emulators, simulators or mocks.

## M00: toolchain, project baseline

```text
Milestone: M00 | code commit: see "Evidence commit" below | build 0.1.0+1
Host: Ubuntu 24.04.5 LTS (Linux 6.18.44, cloud VM, no KVM, no macOS)
Flutter 3.47.7 stable / Dart 3.13.5 / AGP 9.1.0 / Gradle 9.3.1 / Kotlin 2.4.0
Packages: flutter_riverpod 3.4.3, go_router 18.1.0 (exact set: pubspec.lock)
iPad: BLOCKED (no macOS/Xcode on host; no physical iPad)
Android: build only; no physical tablet; emulator impossible without KVM
Owner approval requested: YES (do not start M01 automatically)
```

### Commands and exit codes (2026-10-18 UTC, host above)

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
| AC-0005 Exact lockfile and licences recorded; repeatable CI/local checks exist | PASS | `pubspec.lock` (Flutter pinned 3.47.7), `docs/DEPENDENCY_LICENSES.md` (row 7), `tool/check.sh`, `.github/workflows/ci.yml`. First GitHub Actions run: recorded below once it completes |
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

### Security and privacy notes

- No network, camera, photo or storage permissions requested. The Android
  INTERNET permission exists only in the debug and profile manifests
  (Flutter tooling), not in release.
- No secrets, keys or personal data in the repository. Release builds use
  the Android debug key until M12.
- The unknown-route screen shows no route, error or exception text.
