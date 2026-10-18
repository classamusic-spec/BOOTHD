# ADR-0001: Flutter single codebase, toolchain pin and project identity

- Status: Accepted (M00, 2026-10-17)
- Implements: ADR-CP-001, ADR-001, ADR-002 (owner-locked)

## Context

The owner locked one Flutter/Dart application for iPadOS and Android tablets
as equal release targets. M00 must create both platform projects, choose a
validated toolchain without guessing versions, and leave signing and store
identity to the owner.

## Decision

1. **One Flutter app, two platform folders.** Generated with
   `flutter create --platforms ios,android` on Flutter 3.47.7. No web,
   desktop or extra packages.
2. **Toolchain pin.** Flutter 3.47.7 stable (Dart 3.13.5), the current stable
   release on 2026-10-17, is pinned exactly in `pubspec.yaml`
   (`environment.flutter: 3.47.7`) and in CI. A different SDK fails
   `flutter pub get` loudly. Upgrading is a deliberate change that updates
   the pin, `pubspec.lock`, CI and `docs/TOOLCHAIN_INVENTORY.md` together.
3. **Android build settings stay on Flutter 3.47.7 defaults:** compileSdk 36,
   targetSdk 36, minSdk 24, NDK 28.2.13676358, AGP 9.1.0, Kotlin 2.4.0,
   Gradle 9.3.1, Java 17 bytecode. Raising targetSdk to 37 (Android 17) is
   a later, tested change because it removes the large-screen orientation
   opt-out entirely (ADR-0004).
4. **iPadOS:** deployment target iOS 15.0 (template default),
   `TARGETED_DEVICE_FAMILY = 2` (iPad only), because phone UX is a v1
   non-goal (FLUTTER_PLATFORM_STRATEGY §8). The template's UIScene life
   cycle and launch storyboard are kept; iOS 27 requires a launch screen for
   App Store submission (Apple TN3192/TN3208).
5. **Minimum OS versions are provisional.** They follow Flutter and plugin
   minimums until the certified iPad and Android tablet are chosen (D-04 #1).
   The `camera` plugin (0.12.1) resolves against this toolchain; its own
   minimums are re-checked when it is added in M01.
6. **Identity placeholders.** Bundle ID `com.example.porcelainPhotoBooth` and
   applicationId `com.example.porcelain_photo_booth` are placeholders. Both
   stores reject `com.example`, which forces the owner's decision before
   M12 (D-04 #4). Release builds use the debug key until M12 signing.
7. **Android tablets only by distribution, not manifest.** No
   `supports-screens` or `compatible-screens` restriction now; tablet-only
   distribution is configured in the Play Console device catalog at M12.

## Consequences

- iPhone installs are impossible by construction; reverting is one build
  setting if the owner ever wants phones.
- Contributors need exactly Flutter 3.47.7 (FVM or a pinned checkout).
- iPadOS builds, simulators and signing are BLOCKED on Linux hosts; the
  macOS path is in `docs/IOS_VALIDATION.md` and a manual CI job.

## Verification

- `flutter doctor -v`, `flutter build apk` results: `docs/TOOLCHAIN_INVENTORY.md`
  and `docs/ACCEPTANCE_EVIDENCE.md` (AC-0001, AC-0002).
- iPad device family: `ios/Runner.xcodeproj/project.pbxproj`
  (`TARGETED_DEVICE_FAMILY = 2`). Not yet compiled by Xcode (BLOCKED, Linux).
