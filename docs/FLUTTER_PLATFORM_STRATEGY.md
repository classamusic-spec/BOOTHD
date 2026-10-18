# Flutter-First Cross-Platform Architecture — Decision ADR-CP-001
**Status:** APPROVED | **Version:** 3.1 | **Scope:** Commercial-ready iPadOS + Android tablets from first release

## 1. Decision and rationale
- Single Flutter/Dart application; equal iPadOS and Android parity. No SwiftUI-only or React Native implementation and no Android-later port.
- Editor and Porcelain UI are highly customized; Flutter's Canvas/CustomPainter, gesture framework and shared widget pipeline suit this. Platform-specific native interfaces remain narrow exceptions.
- Primary commercial risks are exact template output, device camera reliability and kiosk operations. Validate both render and camera *before* investing in extensive UI polish.

## 2. Ownership boundaries
| Layer | Where | Contract/ownership |
|---|---|---|
| Design tokens, guest/operator widgets, adaptive navigation | Flutter | Shared; Porcelain first, Oak/Walnut tokens thereafter |
| Template document, transformations, immutable scene graph | Pure Dart | Shared; no widget or filesystem imports in domain |
| Template editor | Flutter | Gesture handlers create domain commands; editing state is not the renderer |
| Renderer layout/painting | Shared Dart + Flutter offscreen canvas | Same layout algorithm for preview/export; high-res based on source assets |
| Sessions and event workflows | Pure Dart + Riverpod orchestration | Explicit persistent state machines and tested clocks |
| Photo permissions/capture/preview | Flutter camera plugin behind CameraService | Android CameraX, iPad AVFoundation backend; native bridge only if proven necessary |
| SQLite/metadata and file assets | Drift and managed app files | Source images immutable; recoverable temp→rename→DB commit protocol |
| Delivery | Flutter ExportService | Print-ready JPEG/PNG; future printer adapter unconfigured |
| Kiosk containment | OS deployment | Guided Access/managed iPad, Android device-owner lock task where configured |

## 3. Vertical risk spike M01 (before major UI work)
- Fixture with 2 colored striped photographs and a translucent floral PNG, rotated and scaled across both photo slots. Create 4×6 template document and produce 1200×1800 output from originals; verify PNG transparency shows OUTSIDE photo-slot bounds; verify photo mask does NOT affect overlay. Include a test layer partly outside the page to confirm editor-space overflow vs export page clip. Compare output geometry on Android/iPad; record golden tolerance, render latency, maximum memory and device details. Use simple debug UI only.
- On one real iPad and one real Android tablet, initialize built-in front camera, display un-stretched preview, take one actual still, verify path/header/dimensions, store file permanently and reopen after app restart. Record permissions, lens, sensor orientation, preview mirroring and output mirroring. Repeat with rear lens where present. Mocked/simulator results cannot satisfy physical-device evidence.
- If physical devices absent, deliver compile/tests and mark these proofs BLOCKED. Block **commercial readiness**, not architecture documentation; the owner explicitly approves work around blockers.
- Throw away demo UI, not validated core functions. Keep spike in `lib/features/diagnostics/spikes/` behind dev-only visibility until the production renderer/camera wrappers supersede it.

## 4. Typed service contracts (conceptual, not final syntax)
`CameraService`: `initialize(CameraRequest) -> CameraCapabilities`, `previewSurface`, `captureStill() -> CapturedAsset`, `suspend`, `resume`, `dispose`, structured status/errors.

`RenderService`: `render(TemplateRevision, ImageBindings, OutputProfile) -> RenderArtifact`, `renderPreview(TemplateRevision, ImageBindings, Viewport)`. Both use one immutable scene graph and geometry engine, with explicit output pixels and memory controls.

`AssetRepository`: import original image; validate, fingerprint, copy to managed store; resolve stable asset IDs; isolate temporary picker URLs.

`SessionCoordinator`: validated event snapshot, approved template revision, number of shots, retakes, timeout, render, confirmed save and reset.

`PrintService`: unconfigured in v1; no fabricated printed/submitted state. `ExportService` owns offline composition artifacts and operator-sharing.

## 5. Adaptive tablet strategy
- Operator config stores `preferredGuestOrientation ∈ {portrait, landscape}`; runtime knows `effectiveViewport` from LayoutBuilder/MediaQuery/view display metrics. Separate `templatePageOrientation` from both.
- Render portrait/landscape guest layouts adaptively to actual available bounds, regardless of requested OS lock. Preserve session state during rotations and window resizing, including camera preview aspect and countdown cancellation/recovery.
- On iPad, preferred orientation can require 'Requires Full Screen' (no Split View/Slide Over) for orientation control. Explicit operator deployment decision.
- On Android large screens, targeting API 36+ may ignore application orientation requests; API 37 removes temporary opt-out. Never depend on manifest orientation alone. Validate in actual Android device-owner/lock-task deployment if used.
- Camera rotation, captured JPEG EXIF, mirroring, crop and output page orientation are distinct transformations.

## 6. Package approval policy
| Area | Candidate | Decision |
|---|---|---|
| Core | Flutter stable + Dart | Pin validated toolchain; no guessed SDK versions |
| DI/state | Riverpod | Provider scoped by app services; test fakes |
| Routing | GoRouter | Guest/operator route guards, robust deep-links/back behavior |
| Persistence | Drift SQLite | Explicit migrations, seeded old-schema tests |
| Camera | camera + endorsed plugins | Pin compatible versions after real-device spike |
| Files | path_provider + standard file APIs | Platform sandbox; no absolute paths |
| Secrets | Platform-secure storage adapter | Salted verifier + rate limit; recovery policy |
| Integration | Flutter integration_test | Native permission UI requires manual or specialized tools |

Prefer a pragmatic modular monolith. Never split into multiple Flutter packages or build Swift/Kotlin camera drivers just for abstract purity.

## 7. Build and CI strategy
- CI quick checks: formatting, analyze, all pure Dart and widget tests, schema migration/unit tests, deterministic renderer fixtures; run Android build on supported runner.
- macOS runner required to build iPadOS/iOS app. Sign/test on physically connected iPad or appropriate distribution flow; Xcode signing prerequisites must be documented, never promised away.
- Device matrix includes iPad & Android portrait/landscape, front/rear if supported, app interruption, permission denial, 100-session target, export and backup restore. Any absent hardware test is BLOCKED.
- Output format at first: 2×6 600×1800, 4×6 1200×1800 and 1800×1200, square 1200×1200 at nominal 300 DPI; printer bleed/cut profiles wait for actual printer.

## 8. Non-goals for version 1
No physical printing, internet-hosted QR sharing, account/cloud backend, DSLR, AI filters, livestream, video, multi-kiosk remote control, hosted marketplace, web client, or generic phone UX. Android and iPad support are NOT non-goals.

## 9. Verified external reference points (recheck during development)
- Flutter camera: https://docs.flutter.dev/cookbook/plugins/picture-using-camera
- Camera plugin lifecycle: https://pub.dev/packages/camera
- Flutter orientation policy: https://api.flutter.dev/flutter/services/SystemChrome/setPreferredOrientations.html
- Android 17 screen behavior: https://developer.android.com/about/versions/17/changes/ff-restrictions-ignored
- Flutter integration tests: https://docs.flutter.dev/testing/integration-tests

## v3.2 platform expansion — network delivery kept isolated
The Flutter app handles S30–S32/S34–S36 identically on iPad/Android. Delivery shares only final output ID, consent and selected composite file with an optional secure HTTP delivery client; NO shared server for core camera/editor/render/gallery. No iOS Messages composer or Android default SMS APIs for commercial sending. Backend handles sender auth, secure upload, registered Twilio MMS, signed webhooks and guest mobile download webpage. Feature off/config gate means offline operation unaffected.
