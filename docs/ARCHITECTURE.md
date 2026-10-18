# Porcelain Photo Booth — Engineering Architecture v3.2

## A-01: Architectural style
A pragmatic Flutter feature-oriented modular monolith. Organize by `lib/app`, `lib/core`, `lib/domain`, `lib/features`, and `lib/infrastructure` with narrow interfaces. No backend. Riverpod DI/state management; GoRouter routes; Drift/SQLite for relational data; managed files for media; app configuration and immutable domain records. Use SDK-supported null safety, concurrency patterns and platform lints. Application services orchestrate use cases, never UI widgets.

## A-02: Logical layers
**Presentation:** operator dashboard, event screens, template editor, booth journey, gallery, diagnostics, themed widget kit. **Application:** EventUseCases, TemplateEditingController, BoothSessionCoordinator, CaptureOrchestrator, OutputCoordinator, StorageRecoveryService, OperatorUnlockController. **Domain:** value objects, entities, rules, typed errors, immutable scene graph, state machine. **Infrastructure:** local Drift repositories, file/asset store, CameraService adapter, Renderer, ExportService, SecureStorage, PrintService stub, DeviceCapabilities. All dependencies flow inward; UI depends on interfaces or controllers, domain never imports Flutter widgets/plugins.

## A-03: Directory map
```
lib/
  main.dart
  app/{app.dart,router.dart,bootstrap.dart,providers.dart}
  core/{design_system,errors,logging,security,platform,utils}
  domain/{models,services,repositories,value_objects,state_machines}
  features/{onboarding,dashboard,events,template_library,template_editor,booth,gallery,settings,diagnostics}
  infrastructure/{database,file_store,camera,composition,export,printing,device}
  shared/{widgets,formatters}
test/{domain,rendering,persistence,widgets}
integration_test/
test_assets/{input_photos,transparent_pngs,expected_renders}
docs/{decisions,device_tests,implementation_logs}
```
Use suffix conventions consistently (`_screen`, `_controller`, `_repository`, `_service`, `_model`, `_test`). Generated Drift output in generated folders and generated source reviewed for migration/rebuild procedures. Keep no production event data or secrets in repository.

## A-04: Dependency interfaces
- `CameraService`: enumerate camera descriptors/capabilities; permission state; initialize(lens, quality, orientation); preview provider; captureOriginal(); suspend/resume/dispose; stream typed state and faults.
- `TemplateRepository`: create/load/revise/duplicate/archive/import/export template manifests; preserve revisions and resolve assets.
- `AssetRepository`: import, hash, verify, retrieve, reference-count or track dependencies; generate thumbnails; stage deletion.
- `CompositionRenderer`: render(documentRevision, slotBindings, renderOptions) -> preview image or exported result; independent renderer backend from UI gesture tools; testable deterministic pixel results.
- `SessionRepository`: create/checkpoint/update session states and photo references; startup recovery.
- `EventRepository`: persisted events, template selections, lifecycle, settings.
- `GalleryRepository`: event and session result projections, filtered search, batch selection, export.
- `ExportService`: validate render settings, generate output artifact, commit atomic file, return metadata/checksum.
- `PrintService`: capability discovery, enqueue request, inspect status; unconfigured adapter at v1. No physical printing.
- `DeviceService`: platform/camera/storage/power orientation and kiosk-help capability metadata.
- `OperatorAuthService`: create/change/verify PIN with rate limiting and secure storage.
- `FileTransactionService`: pending-operation journal, temp writing and atomic rename, recovery/reconciliation.

## A-05: Domain entities
`BoothProfile(id, name, theme, guestOrientation, cameraPreference, defaultOutputProfile, createdAt, updatedAt)`
`Event(id, title, startTime?, venue?, status, profileId, cameraConfig, sessionConfig, outputConfig, themeOverride?, retentionPolicy, consentText?, timestamps)`
`EventTemplate(eventId, templateRevisionId, order, defaultFlag)`
`Template(id, displayName, category, currentRevisionId, timestamps, archived)`
`TemplateRevision(id, templateId, revisionNumber, manifestPath, documentSchemaVersion, checksum, timestamp)`
`Asset(id, kind, relativePath, sha256, width?, height?, mimeType, bytes, origin, timestamps)`
`CaptureSession(id, eventId, templateRevisionId, state, plannedShotCount, chosenOutputId?, timestamps, recoveryStatus?)`
`CapturedPhoto(id, sessionId, shotIndex, attemptIndex, relativePath, width, height, orientation, cameraLens, mirrorApplied, checksum, timestamp, isSelectedForSlot)`
`RenderedOutput(id, sessionId, outputProfileId, relativePath, sha256, widthPx, heightPx, mimeType, renderVersion, timestamp, status)`
`PrintJob(id, outputId, printerAdapterId?, copies, status, timestamps, providerReceipt?)` — interface/bookkeeping only until certified adapters exist.
`OperationJournal(id, operationType, relatedId, stage, tempRelativePath?, destRelativePath?, createdAt, lastError?)`
`AppSettings` and `DeviceDiagnostics` records as needed.

Require foreign keys, unique IDs, explicit cascades, migration tests and retention rules. Deleting an event is NOT an automatic unreviewed cascade of assets/photos; use deliberate delete workflows and a staged cleanup policy.

## A-06: Template document semantics
Use a **versioned JSON manifest plus relative asset references** and an immutable template revision ID. Store page physical dimensions (width/height with unit and intended DPI), coordinate-space metadata, layers with stable IDs and ordinal z-indices, reusable asset map, optional bleed/safe area. Geometry defined in a page-normalized coordinate space (x/y/w/h relative to page width/height); negative x/y and >1 bounds allowed for decorations so editor can show off-page artwork. Rotation in degrees with documented pivot (default layer center). Explicit fit/crop/focal point, layer opacity, blend default source-over, and visibility/lock. Photo slots have `slotIndex`, clip shape, source photo crop/focal point, and optional border/frame styles. Text has font family/asset/license ID, alignment, line spacing, style; shape fill/stroke/geometry. Global z-order used for ALL layers. Background can be page property or layer with deterministic precedence; avoid storing competing backgrounds.

**Editor clip vs output clip:** Render each photo slot with its own clip mask; apply no slot clipping to unrelated PNG/image layers even if they overlap; clip at outer page bounds for final export (unless bleed profile explicitly changes page bounds). Rendered previews and final export must resolve geometry identically.

**Serialization:** `schemaVersion: 1` initially; validate type constraints, unknown layer types, files, image dimension caps, manifest size, path traversal/zip bombs during import; support no-destruction future migration. Provide portable `.porcelain-template`/`.zip` package manifest and managed assets; no dependency on absolute external paths.

**Scene graph:** immutable `DocumentScene` -> ordered `RenderableNode`s -> transform/clip/paint commands; one layout and compositing core for screen-preview and offscreen export. Text layout metrics/font rasterization require fixed font bundles and renderer consistency tests. Golden comparison can use bounded tolerances on platform-specific output, with acceptance of exact composition geometry.

## A-07: Rendering order & export
1. Resolve exact document revision; verify assets and slot bindings.
2. Decode necessary source media with orientation and mirroring policy applied **once**.
3. Compute target output dimensions using physical paper sizes and dpi (2x6 @300 = 600x1800; 4x6 @300 = 1200x1800 portrait or 1800x1200 landscape; 4x4 =1200x1200).
4. Render page background.
5. Traverse z-ordered layers, applying layer transform and opacity. For photo slot, clip captured image to slot mask; for image layers, preserve transparency without photo-slot clip.
6. Apply page boundary crop/bleed policy; encode PNG or JPEG with explicit quality/color profile plan.
7. Write to temp, validate dimensions/readability/hash, atomic rename, journal commit and DB record.
8. Generate thumbnails separately and emit finalized output event. Never set status `saved` before #7 succeeds.

Do not screenshot Widgets as export. Benchmark offscreen Flutter canvas methods and encoding on both platforms. Do not assume all GPU operations are isolate-safe; use compute/native isolates only where supported and measure memory. Limit concurrent full-size renders, image cache sizes and decode sizes. Preserve high-res originals; editor thumbnail decode may be scaled.

## A-08: Editing commands
Use `EditCommand` (apply, undo, merge/coalesce) or immutable history snapshots with memory caps for small docs. History targets document mutation, not zoom/pan. Coalesce drag/pinch sessions into one undo action. Save document transactions through repository; autosave debounced with recovery snapshot but not tied to a widget's lifecycle. Element interactions include select, transform, edit inspector, reorder, lock/hide, duplicate, copy/paste, snap, guides, asset selection. Maintain testable geometry conversions `document <-> viewport <-> output pixels`.

## A-09: Camera lifecycle / orientation
Use maintained Flutter `camera` plugin behind CameraService; endorsed Android CameraX and iOS AVFoundation-backed implementations. Verify package and OS support against pinned Flutter SDK. Camera lifecycle is owned by app; on inactive/paused/disposed, suspend/dispose safely; on resume, recheck permissions and initialize idempotently. Serialize initialize/capture/suspend. Never capture after timeouts if foreground has been lost. Capture plugin-generated full-size still, validate file and metadata, stage to managed immutable original. Preview mirroring and output mirroring separate; normalize EXIF orientation only once. Avoid defaulting to rear camera if front absent without presenting reason and preview.

Guest orientation is stored per booth/event. iPad programmatic orientation lock may require full-screen mode / disabling multitasking for a dedicated kiosk. Android 16 apps targeting API 36 on >=600dp smallest-width tablets generally have requested orientation/resizability restrictions ignored; a temporary opt-out exists for API 36. Android 17/API 37 removes that developer opt-out for large screens. The app must adapt its booth layout regardless of the operator preference, and validate behavior in actual full-screen managed deployment. Layout must adapt even when OS ignores orientation request. Explain to operator if requested orientation can't be enforced. Distinguish display orientation vs camera sensor EXIF orientation vs document output orientation.

## A-10: Booth session state machine
States `idle, preparing, templateSelection, preview, countdown, capturing, capturedIntermission, review, rendering, completed, resetting, interrupted, recoverableFailure, terminalFailure`. Transitions are typed events with invariants (e.g. no capture without ready camera, validated event and adequate storage; no completed without validated saved output). Session starts by freezing active event settings and selected template revision; saves a durable session ID. Every successful capture gets immutable photo record. Retake uses attempt index and chooses preferred binding without destroying old asset. Rendering reads the selected bindings. Automatic reset only when no in-flight write/capture. Persist checkpoints and recover startup incomplete sessions as resumable/re-renderable or explicitly abandoned, never silently discard files.

## A-11: Offline persistence & atomicity
SQLite WAL/foreign-key/migrations via Drift plus managed file directories. File writes: stage temp under same volume, write fully, optionally fsync where feasible, verify image decode/header/hash, atomically rename, then commit DB references; journal pending state allows reconciliation if app terminates between file and DB steps. Read paths only from normalized relative identifiers; avoid traversal. Maintain storage reserve threshold based on conservative capture/output estimate; display warnings. Thumbnail/cache generated independently; safe to clear. Backup package must contain DB snapshot, templates, assets and sessions necessary for restore with version, counts, checksums; verify restore in fresh test sandbox. Document OS backup limitations and media lifecycle. Batch export must handle partial failures honestly.

## A-12: Permissions, PIN, privacy
Camera permission on each platform; media import/export via sanctioned pickers; no microphone usage unless proven necessary for selected plugin configuration, and do not activate audio. PIN verifier: securely store random salt and keyed/slow hash with rate limiting; protected by device-secure storage if available. Consider brute force reset/recovery policy for booth owner. Studio routes require operator session; kiosk mode relies on OS features, not in-app PIN alone. Privacy notice/consent customizable; data retention and deletion explicit; redact camera paths and PII from logs as feasible. No analytics, telemetry or background internet in v1.

## A-13: Printer boundary
`PrintCapabilities` with supported formats/media, adapter availability, status support; `PrintRequest(outputId, profile, copies)`, `PrintJob(status: unconfigured, queued, submitted, physicalCompleted?, failed, operatorAttention)`. `ExportOnlyPrintService` returns `unconfigured` for print request, never queues a fake print job. A future system print adapter should distinguish OS dialog submission from verified physical completion. Retries when status ambiguous require operator confirmation.

## A-14: Diagnostics
Machine-readable error codes + human-friendly guest/operator messages. Key code families CAMERA_*, SESSION_*, STORAGE_*, TEMPLATE_*, RENDER_*, EXPORT_*, AUTH_*, KIOSK_*. Include device info, camera selection, battery/thermal if available, free storage, active event validation, output write self-test, template asset audit, last error and sanitized log export. No photo bytes/guest names/secret values in logs.

## A-15: Revisions and migrations
Drift schema versions/migrations with automated old->new tests. Template revisions have stable ID and immutable manifest; sessions bind revision ID and captured originals. Template import must not overwrite an existing revision silently. Maintain forward-compatibility warning for newer manifest versions. Events referencing deleted templates require explicit operator recovery.

## A-16: Deployment & external boundaries
A Mac with supported Xcode is required for iPad builds/signing; Android toolchain also required for Android builds. Choose minimum iPadOS/Android versions based on device targets, plugin support, and test matrix; current Flutter camera docs list Android SDK 24+ and iOS 13+ but the project's required SDK may be higher based on installed package versions. Do not lock target blindly. iPad dedicated orientation enforcement depends on Xcode full-screen/multitasking settings, which have app UX/distribution implications. Android device-owner kiosk provisioning requires supported management workflow; app pinning alone is insufficient for commercial lock-down.


## A-17: Cross-platform-first validation gate (v3.1 amendment)
The approved Flutter decision is final. M01 precedes all major theme/dashboard work and tests cross-platform rendering plus actual native still capture using the same Dart API boundary. See `docs/FLUTTER_PLATFORM_STRATEGY.md` for hardware gates and exact service ownership. M04 and M06 mature the spike into the production renderer and camera service. SwiftUI-only rewrite and deferred Android port are out of scope.

## v3.2 cloud exception — Phone delivery module
The offline application remains the source of truth for sessions, captures, templates and outputs. A new optional `DeliveryService` / local `DeliveryIntentRepository` and separate Supabase/Twilio backend exists solely for consented photo texting. The client never holds Twilio or server role credentials. Use device pairing, encrypted/minimized phone storage, explicit consent receipts, private full-size objects, separate provider-fetchable preview, safe queue, provider signature-validated webhooks and revocable expiring guest grants. See `docs/PHONE_DELIVERY_SPEC.md`. The phone-delivery backend does NOT replace local event/media storage; it must be safe to disable entirely.
