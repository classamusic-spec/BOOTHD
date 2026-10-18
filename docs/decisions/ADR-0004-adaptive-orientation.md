# ADR-0004: Adaptive orientation on iPadOS 26+/27 and Android 16/17

- Status: Accepted (M00, 2026-10-17). **Supersedes the "Requires Full
  Screen" approach** in CLAUDE.md, ARCHITECTURE A-09/A-16,
  FLUTTER_PLATFORM_STRATEGY §5 and UX_SCREEN_SPECS UX-03, pending owner
  confirmation (see "Spec impact").
- Related: ADR-004 (owner-locked: guest portrait AND landscape per booth)

## Context

The owner requires per-booth guest orientation (portrait or landscape) with
adaptive fallback. The platform facts changed since the spec was written,
and both now point the same way:

**Android** (developer.android.com, "Orientation, resizability and aspect
ratio restrictions ignored", checked 2026-10-17):
- Apps targeting API 37 (Android 17): on displays with smallest width
  >600dp, `screenOrientation`, `resizeableActivity`, `minAspectRatio`,
  `maxAspectRatio` and `setRequestedOrientation()` are ignored; apps fill the
  window. Android 17 removes the temporary opt-out that Android 16 (API 36)
  offered.
- Exceptions: games (`android:appCategory`), users who opt in through the
  device's aspect-ratio settings, and screens under sw600dp. The page does
  not mention device-owner or lock-task deployments.

**iPadOS** (Apple TN3192, revised 2026-10-09):
- `UIRequiresFullScreen` is deprecated from iPadOS 26. Apps built with the
  iOS 27 SDK that set it are still resized (discretely) on iOS/iPadOS 27.
- Apps should support all interface orientations and dynamic resizing, and
  provide a launch screen (required for App Store submission from iOS 27).
- Orientation lock is a request: a view controller can return
  `prefersInterfaceOrientationLocked`; "the system does not guarantee" it.
  Lock state is observable through `UIWindowScene.Geometry`
  `isInterfaceOrientationLocked`.
- Camera apps should use `AVCaptureDevice.RotationCoordinator` so captures
  and preview are oriented correctly regardless of interface lock.

## Decision

1. **Three types, never conflated** (`lib/domain/value_objects/orientation.dart`):
   `GuestOrientationPreference` (operator setting), `ViewportOrientation`
   (the window the OS granted) and `PageOrientation` (template output).
   Camera sensor/EXIF orientation is a fourth concept owned by ADR-0002.
2. **Layout follows the effective viewport, always.** Guest and Studio
   layouts are chosen from actual constraints (`LayoutBuilder` /
   `MediaQuery`), never from the preference or from an assumed lock. Every
   screen ships portrait and landscape layouts and survives resizing
   without losing session or editor state.
3. **No manifest or plist locks.** No `android:screenOrientation`, no
   `UIRequiresFullScreen`. All four iPad orientations stay declared.
4. **Preference is applied best-effort at runtime** (Flutter
   `SystemChrome.setPreferredOrientations` in Booth Mode, M07). When the
   effective viewport differs from the preference, Studio shows the operator
   an explicit warning; guests just get the correct adaptive layout.
5. **Physical lock is an operations concern:** enclosure, device rotation
   lock, iPad Guided Access or supervised Single App Mode, Android
   lock-task. M10 documents it; M11 measures what each platform honours.
6. **Native lock request only with evidence.** If M07/M11 hardware testing
   shows the booth needs `prefersInterfaceOrientationLocked` on iPadOS (not
   exposed by Flutter), add a narrowly scoped bridge with its own ADR.
7. **targetSdk stays 36 for now** (Flutter 3.47.7 default). We do not use the
   Android 16 opt-out property; the app must already behave as Android 17
   requires, so moving to targetSdk 37 later changes nothing functionally.

## Spec impact (owner to confirm)

The spec says iPad orientation control "may require Requires Full Screen /
disabled multitasking". That option is deprecated and, for iOS 27 SDK
builds, no longer prevents resizing. This ADR replaces it with adaptive
layouts plus operational locking. No spec file is edited until the owner
confirms.

## Verification

- Unit tests: `test/domain/orientation_test.dart`.
- Layout smoke tests at portrait and landscape tablet viewports:
  `test/widgets/baseline_home_screen_test.dart` (pattern for M02+).
- Hardware: T-05 orientation protocol on certified devices (M07, M11),
  including what Guided Access, lock-task and rotation lock actually enforce.
