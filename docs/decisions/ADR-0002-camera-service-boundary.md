# ADR-0002: CameraService boundary over the `camera` plugin

- Status: Accepted; contract is a DRAFT until the M01 spike validates it
- Related: ARCHITECTURE A-04, A-09; CLAUDE.md camera invariants; ADR-0004

## Context

Camera behaviour differs by device (risk register: High). The owner's
architecture requires the maintained Flutter `camera` plugin (CameraX on
Android, AVFoundation on iPadOS) behind an app-owned `CameraService`, never
called from guest UI, with native bridges only for proven gaps.

## Decision

1. `lib/domain/services/camera_service.dart` holds a **draft, pure-Dart
   contract**: lifecycle stream, permission, camera list, initialize,
   captureStill, suspend, resume, dispose; typed `CameraFailure` codes
   (`CAMERA_*` family). Nothing implements or reads it in M00.
2. The **infrastructure adapter** (`lib/infrastructure/camera/`, M01) is the
   only code allowed to import the plugin; `test/architecture` enforces it.
3. The adapter owns: app-lifecycle suspend/resume, serialising
   initialize/capture/dispose, refusing capture while the app is inactive,
   mapping plugin errors to `CameraFailure`, and returning a still only after
   it is decoded, validated and atomically committed as an immutable
   original with a relative path.
4. **Four orientation/mirror concepts stay separate:** sensor/EXIF
   orientation, interface orientation, preview mirroring, saved-output
   mirroring. EXIF normalisation happens once, in one place.
5. **The preview stays out of the domain.** A preview is a widget; the
   domain contract exposes no Flutter types. M01 decides how presentation
   obtains the preview surface from the adapter (likely an
   infrastructure-provided widget builder behind a provider).

## Plugin compatibility (checked 2026-10-17, not yet added)

`flutter pub add camera --dry-run` against Flutter 3.47.7 resolves
`camera 0.12.1` with `camera_android_camerax 0.7.5+1` and
`camera_avfoundation 0.10.3+1`; `camera_avfoundation 0.11.0+4` was
published that day but is not selected by `camera 0.12.1`'s constraints.
The dependency is added in M01 with the lockfile, not before.

## Open questions for the M01 spike

- Permission state before first initialise: the plugin reports denial
  through initialise errors; decide between deriving state from those errors
  and adding a permission plugin, with evidence.
- Front-camera saved-output mirroring per platform, and whether output
  mirroring is applied at capture or at render (A-05 records
  `mirrorApplied`; A-07 says apply once).
- Still resolution presets on the certified tablets, and decode memory for
  full-size originals.
- iPadOS 27 recommends `AVCaptureDevice.RotationCoordinator` for correct
  capture orientation regardless of interface orientation lock (TN3192);
  confirm what `camera_avfoundation` does and whether a bridge is needed.
- Relaunch behaviour after camera permission is revoked while backgrounded.

## Verification

Physical still capture on a real iPad and a real Android tablet (AC-0106,
AC-0107). Simulators and mocks cannot satisfy these gates.
