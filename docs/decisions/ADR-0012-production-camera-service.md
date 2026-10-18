# ADR-0012: Production camera service, permissions, originals and the camera test

- Status: Accepted (M06, 2026-10-18). Makes ADR-0002's draft contract
  final and closes the M06 items of ADR-0007's refactor plan. Device
  questions stay open (section 10).
- Implements: A-04 (camera boundary), A-09 (capture lifecycle), A-11
  (journaled commits and startup recovery), S18 (Diagnostics: camera test
  and self-test), the CLAUDE.md camera invariants.
- Covers: AC-0601..AC-0609. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M06).
  Device steps: `docs/device_tests/M06_DEVICE_PROCEDURE.md`.

## Context

The M01 spike proved one still per platform in code and left five items
for M06: a permission pre-check, the capture orientation and mirroring
policy, journaled commits with startup reconciliation, original metadata
in the database, and a Diagnostics camera screen in place of the spike.
M06 must also handle the app leaving the foreground and OS interruptions
without leaking the camera or firing a late shutter, refuse duplicate
captures, and keep every original immutable and intact across restarts.
Guest multi-shot sessions are M07 and are not built here.

## Decision

### 1. The contract (`lib/domain/services/camera_service.dart`)

- `CameraService`: `status` and `statusChanges` (current status first,
  then every change), `permission`, `requestPermission`,
  `openPermissionSettings`, `availableCameras`, `initialize(request)`,
  `captureStill(origin)`, `suspend`, `resume`, `dispose`.
- Typed values: `CameraPermission` (not asked, granted, denied, denied for
  good, restricted), `CameraLifecycle`, `CameraCapabilities` (the stream
  size, zoom range, focus and exposure points, measured when the camera
  opens), `CameraRequest` (camera id, preview mirroring, saved-photo
  mirroring), `CameraStatus` (all of it as one value), `CapturedStill`
  (with device orientation, EXIF tag, sensor orientation, both mirror
  settings and the origin: diagnostics, session or legacy).
- `CameraFailure` with 13 `CAMERA_*` codes. Operator copy names the code;
  guest copy (M07) never does. Details are codes or Dart type names only:
  never a path, a description from the plugin or photo data.
- `CameraChoice.of(cameras, lens)`: the platform's first camera of the
  wanted lens (its primary one), else the other built-in lens with a
  "fell back" note. External cameras are never chosen (AC-0602).

### 2. Permissions: `permission_handler` 13.0.2 behind `CameraPermissions`

The `camera` plugin can only reveal permission by opening the camera, and
on Android it cannot tell "refused" from "refused for good" (ADR-0007). A
booth must explain why it needs the camera before the system asks, and
must send the operator to Settings when asking is no longer possible.

- **Chosen:** Baseflow's `permission_handler` (MIT, widely used, actively
  maintained), pinned in `pubspec.lock`, wrapped by
  `PermissionHandlerCameraPermissions`; nothing else imports it.
- **Rejected:** a bespoke native bridge (CLAUDE.md allows native code only
  for gaps a maintained plugin cannot fill); deriving the state from
  camera errors (cannot pre-check, cannot open Settings, ambiguous on
  Android).
- **Android semantics:** the status check reports "not allowed" for never
  asked, refused once and refused for good alike; only a request's answer
  distinguishes them, and a request after "refused for good" resolves at
  once without a prompt. So a status of "not allowed" reads as *not
  asked*, the screen offers "Allow camera", and the answer decides between
  asking again and the Settings repair.
- **iOS build requirement (important):** with Swift Package Manager (the
  Flutter 3.47 default) the plugin enables `PERMISSION_CAMERA` by finding
  `NSCameraUsageDescription` in the app's `Info.plist`, which works when
  the build starts in the project directory (`flutter build ios`,
  `flutter build ipa`, `flutter run`, `xcodebuild`). **Builds started from
  Xcode.app compile every permission out and the camera then reads as
  refused.** Archive with the Flutter CLI, or first run
  `launchctl setenv PERMISSION_HANDLER_INFO_PLIST <repo>/ios/Runner/Info.plist`
  and clear DerivedData. If a future build falls back to CocoaPods, the
  generated `Podfile` needs `PERMISSION_CAMERA=1` in its `post_install`
  `GCC_PREPROCESSOR_DEFINITIONS`. Recorded in `docs/IOS_VALIDATION.md`;
  the device procedure checks the first-run prompt.
- **No new Android permission:** the plugin declares none; the merged
  release manifest is unchanged (aapt2, evidence).
- **Flow (S18, AC-0601):** never asked: the camera test explains first and
  asks only on "Allow camera". Refused: "Allow camera" again (Android may
  still ask) and the Settings steps. Refused for good: the Settings steps
  for the platform and "Open Settings". Restricted (MDM, Screen Time): ask
  the tablet's administrator; no dead buttons. Access turned on in
  Settings while away: the camera opens when the booth is back in front.
  Launch checks and the self-test read the permission and never ask.

### 3. Lifecycle and serialisation (`ManagedCameraService`)

- One queue: `initialize`, `captureStill`, `suspend`, `resume`, `dispose`
  and permission requests run one at a time in call order, so a prompt
  never overlaps an opening camera and the camera never closes under a
  capture.
- A capture while another is in flight is refused at once
  (`CAMERA_CAPTURE_BUSY`), never queued; the screen's controller also
  ignores a second press. A capture is refused unless the camera is ready
  and the app is in front (`CAMERA_NOT_READY`, `CAMERA_APP_NOT_ACTIVE`).
- Errors the open camera reports by itself (another app took it, an
  interruption, Do Not Disturb, device policy, a fatal error; CameraX
  reports these only as English text, sorted by
  `classifyCameraErrorDescription`) close the camera and set the status;
  a capture in flight finishes first.
- `CameraSessionController` (core) follows the app: hidden or paused
  releases the camera; resumed reopens it (re-reading the permission,
  never prompting, never capturing); inactive (a system prompt, Control
  Center) changes nothing but captures are refused. Closing the screen
  releases the camera. It keeps the camera the screen wants, so access
  granted in Settings opens it on return.

### 4. Preview and mirroring

- The preview is the plugin's `CameraPreview` (it keeps the stream's
  aspect ratio) centred in a dark viewfinder (`PorcelainViewfinder`
  tokens) shaped like the stream for the screen's orientation: never
  stretched, letterboxed if shapes differ.
- Both plugin implementations mirror the front camera's preview and no
  other (`camera_avfoundation` 0.10.3+1 `DefaultCamera.swift`,
  `camera_android_camerax` 0.7.5+1 rotated-preview widgets). The driver
  flips exactly when `mirrorPreview != platformMirrorsPreview(lens)`, so
  the setting means what it says on either lens (CR-001 fix 5).
- Saved-photo mirroring is recorded with the original (`mirror_output`)
  and applied once, when rendering (M07); the stored original is always
  the camera's own bytes. The preview is never saved as a photo.

### 5. Stills and orientation

- `ResolutionPreset.max`, JPEG output, audio off (no microphone
  permission), flash off (the booth flashes the screen in M07). The
  plugin's temporary file is deleted after reading.
- Orientation is normalised once: the decoder applies the EXIF origin when
  the commit measures the image (Skia's codec generator swaps width and
  height), and the raw EXIF tag, the sensor orientation and the device
  orientation reported by the plugin at capture are stored for the record.
  `camera_avfoundation` 0.10.3+1 still sets
  `AVCaptureConnection.videoOrientation` from the device orientation
  rather than iPadOS 17+'s `RotationCoordinator`; device runs confirm it
  (section 10).

### 6. Originals: schema version 4 and a commit journal (A-11)

- `original_photos`: one row per original, immutable (an update trigger
  aborts), with checks on the id, the path (`originals/<id>.jpg`), sizes,
  checksum, enums and mirror flags. Deletion (retention) is M10.
- `pending_original_commits`: a commit's intent and full record, written
  before the file and removed in the transaction that adds the row.
- Commit: a complete JPEG (start and end markers; zero padding allowed),
  fully decoded; intent; `AtomicFileWriter` (staged, flushed, read back,
  decoded, renamed, never replacing); row plus intent removal in one
  transaction. A failed record takes the file back, so a failed save never
  surfaces later.
- Startup (`startupProvider`, before any capture): finishes commits whose
  file matches its checksum, undoes the rest, moves files that fail their
  checks to `originals/.quarantine` (never deletes), adopts the M01
  spike's originals and sidecars (origin `legacy`) and removes the spike's
  staging folder.
- Reading an original verifies its checksum; the camera test shows each
  earlier test photo as "Intact" or "Missing or changed".

### 7. Free space: a narrow platform channel

Dart has no API for free space and no dependency already in the app
provides it; adding a plugin for one number was judged worse than about
20 lines of native code. `porcelain/device_storage` has one method,
`freeBytes`: `StatFs(filesDir).availableBytes` on Android and
`volumeAvailableCapacityForImportantUsage` on iPadOS; it returns a number
only. `StorageBudget`: 40 MB per guest session, at least 1 GiB to launch.

### 8. Diagnostics (S18)

- Camera test (operator only, release builds too): permission with its
  repair, built-in lenses, live preview with its stream size, sensor
  orientation and zoom range, both mirror switches (this test only), a
  test photo saved like a guest's and read back, checked and described,
  and the earlier test photos re-checked. It replaces the M01 spike
  screen, which is removed.
- Self-test: camera permission and lenses, a timed write/read-back/remove
  of a test file, free space against the budget; each with a repair step.
  Nothing is asked for, opened or kept.
- Settings > Camera lists the tablet's cameras and links the camera test.
  Launch checks now check the camera and free space for real.

### 9. Testing without a camera

`SimulatedCameraService` (scripted permission, cameras and failures; real
small JPEGs; the contract's rules) lives in `test/support` only and is
never part of the app. The production `ManagedCameraService` is tested
over a fake driver and fake permissions with the real `OriginalStore` on a
temporary SQLite file and directory. No physical-camera criterion passes
on either.

## Consequences

- The app gains six `permission_handler` packages (MIT; recorded in
  `docs/DEPENDENCY_LICENSES.md`) and a few lines of Kotlin and Swift for
  free space.
- The iOS build path matters: archiving from Xcode.app without the
  environment variable ships a booth whose camera reads as refused.
- Schema version 4 is additive; versions 1 to 3 migrate with every value
  intact (AC-0304 test extended).
- Guest sessions (M07) reuse `CameraSessionController`, the viewfinder
  tokens and the original store unchanged.

## Verification

Host tests: `managed_camera_service_test.dart` (permissions, lenses,
mirroring maths, serialisation, interruptions, lifecycle, restart),
`original_store_test.dart` (validation, journal, crash recovery, legacy
adoption, immutability), `camera_test_screen_test.dart` (21 screen and
lifecycle cases), `device_capability_probe_test.dart`, the migration
test, the screen catalog (overflow, 200% text, tap targets, labels,
contrast, no dead controls) and goldens. Devices: BLOCKED until run
(`docs/device_tests/M06_DEVICE_PROCEDURE.md`).

## Open questions (need physical tablets)

- Preview mirroring per platform and lens as shipped (code says front
  mirrored on both).
- Still size from `ResolutionPreset.max` on the certified models; decode
  time and memory of full-size originals.
- Capture orientation and EXIF tags in each tablet orientation; iPadOS
  `videoOrientation` versus `RotationCoordinator`.
- Behaviour while the permission prompt makes the app inactive;
  interruptions (Split View, Stage Manager, multi-window, calls, another
  camera app); permission revoked in Settings while away (the OS ends the
  app; the next start reads the new state).
- Front camera position and a clear lens through the enclosure (AC-0609).
