# ADR-0007: M01 feasibility spike: findings, limits and refactor plan

- Status: Accepted (M01, 2026-10-18). Answers several open questions in
  ADR-0002 and ADR-0003; physical-device questions remain open.
- Covers: AC-0101..AC-0108. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M01).

## What was built, and where

Core functions live in their target layers, labelled spike-grade, so M04
and M06 promote them instead of rewriting them. Only the demo UI sits in
`lib/features/diagnostics/spikes/` (debug and profile builds only).

| Concern | Code |
| --- | --- |
| Page, geometry, layers, global z-order (pure Dart) | `lib/domain/template/` |
| Scene compile and cover crop (pure Dart) | `lib/domain/template/document_scene.dart` |
| Renderer contract, camera contract | `lib/domain/services/` |
| One painter for export and editor workspace | `lib/infrastructure/composition/scene_painter.dart` |
| Offscreen renderer (`dart:ui`, exact output pixels) | `lib/infrastructure/composition/dart_ui_composition_renderer.dart` |
| Camera plugin seam and managed service | `lib/infrastructure/camera/` |
| Managed immutable originals, EXIF reader | `lib/infrastructure/file_store/` |
| DI providers bound in the composition root | `lib/core/di/service_providers.dart`, `lib/app/providers.dart` |
| Fixtures, pixel checks, spike runner, dev screens | `lib/features/diagnostics/spikes/` |

## Findings verified on the host (Linux, `flutter test`)

1. **Composition semantics hold.** FIX-01 renders to exactly 1200x1800 from
   decoded PNG inputs. 16 export samples, 4 workspace samples and 3
   z-order samples pass: photos clip to their own slots (rounded corner
   included), the translucent flower crosses both slot edges unclipped, the
   marker rotates clockwise about its centre, the page edge crops export
   output while the workspace shows the overflow. Removing the slot clip or
   reversing rotation makes the checks fail (mutation-tested).
2. **No alpha halos.** FIX-04 discs scaled by 0.73 and rotated 17° leave
   white-on-white and black-on-black pages untouched (max delta within 2),
   and the probe fails when edge colours are deliberately wrong.
3. **Deterministic across hosts.** Re-rendering matches the committed
   goldens with max delta 0, here and on a GitHub-hosted runner (CI run
   39085230790), so same-version Linux hosts render identically.
4. **Cost on this host.** FIX-01 export median about 0.2 s: decode about
   55 ms, rasterise about 63 ms, PNG encode about 69 ms. With 12 MP inputs,
   about 0.4–0.5 s. No memory drift across 30 repeated renders (+1.5 to
   +2.0 MB across runs).
   Host numbers say nothing about tablets.
5. **Bounded decoding shows no consistent saving for PNG.** Decoding 12 MP
   PNGs at the drawn size raised peak memory by +30 to +58 MB across runs,
   against +47 MB at full size; PNG decodes at full size before resizing,
   and process-wide peak memory is noisy. Camera JPEGs may decode scaled
   (DCT scaling); measure on devices before choosing the M04 policy.
6. **JPEG output needs a decision.** `dart:ui` encodes PNG only. M04 must
   choose and measure a JPEG encoder (pure Dart or a small platform codec
   bridge with an ADR).
7. **The decoder applies EXIF orientation.** A 640x480 JPEG tagged
   orientation 6 decodes as 480x640, correctly rotated, and
   `ImageDescriptor` reports the oriented size. The app must therefore never
   rotate originals again: originals are stored untouched and the tag is
   recorded. Confirm on both devices.
8. **Truncated files fail to decode** (PNG and JPEG, cut at 1–95%), so
   decode-on-commit validation is effective on the host. M06 adds an
   end-of-image marker check and device confirmation.

## Camera plugin limits found in code (camera 0.12.1)

- **Permission state is only observable by opening the camera.** iOS
  reports `CameraAccessDeniedWithoutPrompt` and `CameraAccessRestricted`;
  Android CameraX reports only `CameraAccessDenied` or
  `CameraPermissionsError`, so "denied forever" is invisible there. M06
  decides whether a permission plugin or a narrow bridge is justified
  (needs an ADR).
- **The plugin manifest adds `RECORD_AUDIO` and `WRITE_EXTERNAL_STORAGE`**
  (API 28 and below), and the manifest merger then implies
  `READ_EXTERNAL_STORAGE`. All three are removed in our manifest; audio is
  disabled in the controller. Verified with `aapt2` on the release APK.
- **Camera features.** The plugin requires `android.hardware.camera.any`;
  the `CAMERA` permission would also imply a required rear camera, hiding
  the app from front-camera-only tablets, so `android.hardware.camera` is
  declared optional.
- **`ACCESS_NETWORK_STATE` remains**, contributed by
  `androidx.media3:media3-common` through the CameraX plugin. It grants no
  network access (`INTERNET` is absent from release builds). Removing a
  library's permission without a device to exercise its code paths could
  crash, so it stays until the M10 permission audit (AC-1007) tests it.
- The plugin writes captures to a temporary file; the driver deletes it
  after reading, so guest photos exist only in managed storage.
- Hardware flash is turned off; the booth will use a screen flash (M07).
- A lifecycle stream written as `async*` dropped transitions emitted right
  after subscription; the tests caught it and `Stream.multi` fixed it.
- The Android build now also installs SDK Platform 35 and CMake 3.22.1 (for
  JNI-based `path_provider_android`); AGP fetches them automatically.

## Still unknown: needs physical devices (BLOCKED)

Default preview and saved-photo mirroring per platform; still resolution
from `ResolutionPreset.max`; capture orientation versus device and
interface orientation; behaviour while a permission dialog makes the app
inactive; iPadOS 27 `AVCaptureDevice.RotationCoordinator` handling in
`camera_avfoundation`; device render timings, memory and the real
cross-platform pixel difference against the host golden. Procedure:
`docs/device_tests/M01_DEVICE_PROCEDURE.md`.

## Golden tolerance (provisional, AC-0104)

Geometry samples must match within 3 per channel on every platform. Whole
images may differ by more than 8 per channel on at most 0.5% of pixels,
with a mean absolute difference of at most 1.0. These thresholds were set
before any device measurement; tightening them after device runs is
expected, loosening them needs owner approval with evidence.

## Production refactor plan

- **M04 renderer:** versioned JSON documents with migrations; text, shape
  and background layers; asset references through `AssetRepository`
  instead of raw byte maps; atomic output commit (stage, validate, rename);
  JPEG encoder decision; one full-size render at a time; decode-size policy
  per input format; FIX-02..FIX-06; tolerance finalised from device data.
- **M06 camera:** permission pre-check decision; capture orientation and
  mirroring policy applied once at render; journaled commits and startup
  reconciliation of `originals/.staging`; metadata in Drift (M03); the
  diagnostics camera screen (S18) replaces the spike screen.
- **Spike UI:** removed once S18 and Template Preview (S11) exist; the
  fixtures and runner remain as test utilities.
