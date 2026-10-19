# Implementation log

Newest milestone first. Each entry: scope, plan, changes, commands and exit
codes, platform results, spec issues raised, risks, next step.

## M08: operator gallery, export-ready workflow and printer boundary

- Date: 2026-10-19 (UTC)
- Authorised by: the owner's instruction "approve start M08-M10" after the
  M07 report. M08 first; M09 and M10 follow with their own reports. M08
  scope only: no print submission, printer hardware, QR hosting, email or
  cloud.
- Quality bar: CR-001 for every Studio screen. The owner's boards have no
  gallery screen; it follows the Porcelain Studio screens.
- Host: the same Linux cloud session as M00 to M07. No tablet, no Mac.

### Plan (as executed)

1. Domain: printer boundary (`PrintService`, `PrintRequest`,
   `PrintCapabilities`, `PrintJobStatus`, `UnconfiguredPrintService`);
   gallery views, filters and search; retention cutoffs; export names,
   plans in parts and reports; print-file facts and the print-ready check.
2. Schema v6: session numbers, output origin, export history, deletion
   journal; migration 5 to 6 and a seeded v6 fixture.
3. Gallery repository, re-render through a `SessionRenderer` shared with
   the booth, journaled deletion and startup cleanup, thumbnails, export
   copies offered to the share sheet with per-file reports.
4. Screens: Gallery (S13), Session Detail (S14), export and deletion
   sheets, Settings > Storage, Output Settings (S16) through the print
   service, Delete for archived events.
5. Tests at large counts, failures and offline export; screen catalog and
   goldens; ADR-0014, device procedure, evidence, checks, builds, CI.

### Changes

- Domain: `services/print_service.dart`; `gallery/gallery_models.dart`,
  `gallery/gallery_search.dart`, `gallery/retention.dart`,
  `gallery/export_plan.dart`, `gallery/print_file_facts.dart`;
  `repositories/gallery_repository.dart`; `services/gallery_services.dart`
  (exporter, thumbnails, cleanup ports); `ShareReport`;
  `SessionRecord.number`, `SessionOutput.origin`,
  `SessionRepository.outputs` and `addRerender`.
- Infrastructure: schema v6 with dumps, steps, test schemas and
  `seed_v6.sql`; `database/drift_gallery_repository.dart`;
  `file_store/managed_thumbnail_store.dart`,
  `file_store/managed_storage_cleanup.dart`;
  `files/managed_gallery_exporter.dart` and
  `shareFilesWithPlatformSheet` (iPadOS Print excluded); managed areas
  `thumbnails` and `outgoing` (cleared at start);
  `AtomicFileWriter.isNoSpace`; `OriginalStore.stillOf`.
- Core: `booth/session_renderer.dart` (the booth controller now uses it);
  `gallery/gallery_service.dart`, `gallery/gallery_export_run.dart`,
  `gallery/gallery_providers.dart`; providers for the gallery services
  and the print service; startup runs the deletion journal.
- Features and shared: `gallery/gallery_screen.dart`,
  `session_tile.dart`, `gallery_thumbnail.dart`,
  `session_detail_screen.dart`, `export_sheet.dart`;
  `shared/gallery/gallery_copy.dart` and `gallery_actions.dart` (used by
  Gallery, Settings and Events); `settings/storage_settings.dart`;
  Output Settings rework; Events: Photos and Delete for archived events;
  the Privacy tab's retention note; `StudioSliverPage`; `formatClock`,
  `formatDay`, `formatSpan`, `formatBytes`; routes `?event=` and
  `/studio/gallery/:sessionId`.
- Tests: `persistence/gallery_repository_test.dart`,
  `infrastructure/gallery_files_test.dart`,
  `rendering/rerender_test.dart`, `rendering/external_viewer_test.dart`,
  `domain/gallery_rules_test.dart`, `domain/print_file_facts_test.dart`,
  `core/gallery_export_run_test.dart`, `widgets/gallery_flow_test.dart`;
  migration test v6 checks; support: `gallery_seed.dart` (bulk sessions,
  optional real files), `fake_gallery.dart` (thumbnails, exporter,
  cleanup, a print-size stand-in), the simulated originals store finds
  originals recorded in the database; twelve gallery and settings states
  in the screen catalog; 32 new goldens and the changed gallery and
  settings goldens.
- Docs: ADR-0014, `docs/device_tests/M08_DEVICE_PROCEDURE.md`, ADR index.

### Problems met and how they were handled

- The thumbnail store's de-duplication waited for itself: the callback
  that forgot an in-flight thumbnail returned the very future it was
  attached to, so every thumbnail hung. Found by the first thumbnail test;
  the callback no longer returns it.
- The first retention deletion left its warning on screen: the
  past-retention list was not refreshed with the rest of the gallery.
  Found by the flow test; it is now refreshed with everything else.
- Select mode first kept Export and Delete in the page header, which
  scrolls away with the grid: the screen catalog could not reach them
  after selecting a session further down, and neither could an operator.
  They are now in a bar pinned below the grid, with Done.
- The event cards had a fixed height and overflowed at 200% text; the
  long-press shortcut added an unlabelled tap target. The cards grow
  with the text; the shortcut is excluded from semantics (Select does
  the same).
- Cross-feature imports: Settings and Events needed the gallery's words
  and deletion sheets, which features may not import from each other;
  they moved to `shared/gallery`.
- ImageMagick reports a PNG's resolution per centimetre (PNG stores it
  per metre): 118.11 px/cm is 300 dpi. The external viewer test converts
  units rather than loosening the check.
- Layout review on the goldens: filters wrapped in portrait and the grid
  started below the fold in landscape. The filters were renamed (To
  finish, Ended early), search moved into the header and the summary was
  made a single row.

### Spec issues raised

- P-12 asks for the exact target location of an export. The maintained
  plugins can only report what the share sheet reports (the chosen
  activity or app), not a folder; a native export-to-folder bridge is an
  owner question (ADR-0014 section 11).
- AC-0805 "recoverable cleanup" is built as cleanup that recovers from
  interruption (journal finished at start); there is no trash bin
  (owner question).
- Retention is operator-confirmed, never automatic, as CLAUDE.md asks for
  operator-controlled retention.

### Risks carried forward

- No physical tablet: every device half of AC-0801..AC-0807 is BLOCKED;
  the procedure is ready.
- What each Android share target reports varies by app; some report
  nothing ("the tablet was not told where they went").
- Re-render byte-identity is shown on the host only.
- iPadOS has still not been compiled (no Mac; CI's manual job not run).

### Next

M09 (secure phone photo delivery), then M10, as the owner approved;
stop for approval after M10.

## M07: end-to-end guest booth and persistent session state machine

- Date: 2026-10-18 to 2026-10-19 (UTC)
- Authorised by: the owner's instruction "M07" after the M05/M06 report.
  M07 only: no gallery, re-render or export UI (M08), no phone delivery
  (M09), no kiosk lock (M10), no printing.
- Quality bar: CR-001 for every guest screen; CR-002: the guest session
  follows the owner's guest-flow board (portrait) and the landscape
  board's S02 to S07 and S11.
- Host: the same Linux cloud session as M00 to M06. No tablet, no Mac.

### Plan (as executed)

1. Domain: the guest flow as an immutable state machine; the session
   plan frozen at start (event, template revision, photo-space order,
   capture and output settings); photos with attempts and rounds, retake
   rules and slot bindings; a session repository interface.
2. Schema v5: sessions, their photos and finished photos, with checks and
   immutability triggers; migration 4 to 5 and a seeded v5 fixture.
3. Controller: camera, countdown, capture, review, render with a
   checkpoint, verified save, timeouts, watchdogs, reset; startup
   recovery and idle finishing of renders left behind.
4. Guest screens S21 to S27 and S29 from the boards, portrait and
   landscape, replacing the M03 placeholder Start.
5. Tests: flow rules, repository, recovery, migration, controller on the
   simulated camera, end-to-end widget flows at every tablet size, the
   real renderer and file export, the screen catalog and goldens; a
   scripted device session for the owner.
6. ADR-0013, device procedure, CR-002 status, evidence, checks, Android
   builds, CI.

### Changes

- Domain: `session/guest_flow.dart` (`GuestFlow`, `GuestStage`,
  `GuestProblem`), `session/session_plan.dart`,
  `session/session_shots.dart`; `repositories/session_repository.dart`;
  `services/finished_photos.dart`; `CapturedStillStore.find`;
  `StorageBudget.minimumSessionFreeBytes`.
- Infrastructure: schema v5 (`capture_sessions`, `session_photos`,
  `session_outputs`) with dumps, steps and test schemas;
  `database/drift_session_repository.dart`;
  `file_store/managed_finished_photos.dart`; `OriginalStore.find`.
- Core: `booth/booth_session_controller.dart`,
  `booth/session_recovery.dart` (run at startup);
  `composition/store_render_source.dart` (moved from infrastructure so
  core can render sessions); `CameraSessionController.release`;
  providers for sessions, finished photos and template summaries.
- Features: `booth/booth_screen.dart` (was `booth_welcome_screen.dart`;
  hosts `BoothSessionView`), `booth_copy.dart`, `guest_parts.dart`,
  `guest_template_choice.dart`, `guest_camera_stage.dart`,
  `guest_review.dart`, `guest_finished.dart`, `guest_notices.dart`; the
  Booth Mode operator screen shows the last problem a guest met (what,
  where to repair it, code, time) once unlocked; the operator preview's
  Start message no longer mentions M07.
- Shared and design system: `PorcelainButton.caps` (spaced capitals,
  plain label for screen readers); guest icons (retake, next guest,
  paused).
- Tests: `domain/guest_session_test.dart`,
  `persistence/session_repository_test.dart`,
  `core/booth_session_controller_test.dart`,
  `core/session_recovery_test.dart`,
  `widgets/booth_session_flow_test.dart`,
  `rendering/booth_render_test.dart`; migration test and `seed_v5.sql`;
  the access, events and isolation tests follow the rename and the real
  Start; support: `FakeExportService`, simulated camera gates and
  database recording, an event hook in the seed, `TrackedRenderer` (tests
  wait for renders in flight), thirteen guest session states in the
  screen catalog (screen checks; 30 goldens).
- Device: `integration_test/guest_session_test.dart` (one offline session
  with the production camera, stores, renderer and export).
- Docs: ADR-0013, `docs/device_tests/M07_DEVICE_PROCEDURE.md`, CR-002
  status, ADR index.

### Problems met and how they were handled

- `plan` is an SQLite keyword and broke the generated triggers: the
  column is `plan_json`.
- The first run of the real screens on the simulated camera showed "The
  camera needs a moment" at once: readiness was read from the screen
  controller's copy of the camera status, which follows the service a
  moment later. The controller reads the service's own status.
- A session started while the app was going to the background could
  still start its countdown once the camera opened: preparing now pauses
  too, and the controller checks the foreground before counting.
- The finished photo was first read back after the session was recorded
  as completed; a damaged file would still have been called saved. The
  order is now render, export, read back against the checksum, record.
- The first photo of a whole-set retake was refused by the database: a
  new round existed only in memory. The record now starts a round with
  its first photo (`SessionShots.record`).
- A camera that never opens, or a photo that never arrives, would have
  left a guest on a spinner and blocked the operator's exit: watchdogs
  turn both into problems with Try again; a late photo is kept unused.
- Widget tests: the in-memory template store had no documents for the
  seeded events (the guest saw "The booth isn't quite ready"); fake time
  fires zero-length timers only when the clock moves
  (`pump(Duration.zero)`); the lifecycle listener asserts real
  transitions (tests step through inactive and hidden).
- The 200% text checks of the new screens were passing without reaching
  them: Start sat below the fold and the tap missed with only a warning.
  The catalog now scrolls each control into view and every state asserts
  the screen it reached.
- Guest controls first read "Back to start" and "Go back", which the
  guest-isolation vocabulary rightly refuses: they read "Done" and
  "Cancel".
- Landscape review's title ran into the edge garland on Android sizes:
  the right margin clears it.
- A full `tool/check.sh` run failed one Studio golden (the template
  library) whose thumbnail had not finished rendering: tests waited a
  fixed real time for the renderer, and M07's extra tests running in
  parallel slowed it. The harness now counts renders in flight
  (`TrackedRenderer`) and waits until none are left; goldens unchanged.
- A guest retaking photos again and again would have kept every
  full-size photo in memory: the controller keeps only the photos in use
  (the others stay in storage).

### Spec issues raised

- A-10 names `preview`, `resetting`, `recoverableFailure` and
  `terminalFailure` as states; they map onto `preparing`, the reset step
  and `failed` with `recoverable` (ADR-0013 section 1).
- S22 "cancellation only if event allows": events have no such setting;
  not offered (owner question, ADR-0013 section 11).
- AC-0702 "pauses/cancels": built as a pause that only the guest's
  Continue ends, with a fresh countdown.
- The review timeout's outcome is not specified: built as keep and
  finish (owner question).

### Risks carried forward

- No physical tablet: the exit gate, AC-0708 and every device half stay
  BLOCKED; the scripted session and the procedure are ready.
- Render time and memory with 12 MP originals on the certified tablets
  are unmeasured (the host renders the strip in about half a second from
  small stand-in photos).
- Originals of abandoned sessions and late photos accumulate until M08's
  gallery and retention tools.
- iPadOS has still not been compiled (no Mac; CI's manual job not run).

### Next

Owner review of M07. On approval: M08 (operator gallery, export-ready
workflow and printer boundary).

## M06: production camera service and Diagnostics camera test

- Date: 2026-10-18 (UTC)
- Authorised by: the same owner instruction as M05 ("when complete start
  M05- M06 also polish the U/UX…"): M06 follows M05's report. No guest
  multi-shot orchestration (M07).
- Quality bar: CR-001 for the camera test, the Diagnostics self-test and
  the Settings camera rows; CR-002 where the boards apply (list rows now
  end with their value or control, as on the S14 settings board).
- Host: the same Linux cloud session as M00 to M05. No tablet, no Mac.

### Plan (as executed)

1. Contract: typed permission, lifecycle, capabilities, request, status,
   failures (13 `CAMERA_*` codes), lens choice, capture origin and
   orientation; an originals store interface with startup recovery.
2. Permissions: decide between deriving state from camera errors, a
   permission plugin and a bridge (ADR-0012: `permission_handler` behind
   `CameraPermissions`).
3. Driver and service: open/capture/close with measured capabilities,
   errors the open camera reports itself, mirroring that means what it
   says on both lenses, one queue, busy refusal, foreground rule.
4. Originals: schema v4 (`original_photos`, `pending_original_commits`),
   journaled commits, complete-JPEG check, startup reconciliation with
   adoption of the M01 spike's files.
5. Lifecycle controller for screens (suspend when hidden, reopen on
   return, no late shutter, open after access is granted in Settings).
6. Diagnostics: camera test screen (S18) replacing the spike, the
   measured self-test, Settings camera rows, real launch checks for the
   camera and free space (narrow free-space channel).
7. Tests: service over a fake driver with the real store, store crash
   recovery, migration v4, screen and lifecycle tests on a simulated
   camera, screen catalog and goldens.
8. ADR-0012, device procedure, iOS build note, licences, checks, Android
   builds, evidence.

### Changes

- Domain: `services/camera_service.dart` rewritten (final contract);
  `booth_capabilities.dart` gains `DeviceStorageInfo` and `StorageBudget`;
  `CameraPermission.problemCode`.
- Core: `camera/camera_session.dart` (`CameraSessionController`,
  `CaptureOutcome`); `diagnostics/device_self_test.dart`;
  `PorcelainViewfinder` colour tokens; providers for the still store,
  preview builder, free space and self-test.
- Infrastructure: `camera/camera_driver.dart` (plugin driver, preview
  flip, error sorting, capture orientation),
  `managed_camera_service.dart`,
  `permission_handler_camera_permissions.dart`;
  `file_store/original_store.dart` (journal, validation, recovery,
  legacy adoption); schema v4 with dumps and migration steps;
  `device/platform_device_storage.dart`; the probe checks the camera and
  free space.
- Native: `MainActivity.kt` and `AppDelegate.swift` register the
  `porcelain/device_storage` channel (free bytes only).
- Android build: `compileSdk = 37` (target unchanged),
  `android.suppressUnsupportedCompileSdk=37`, and `tool/build_android.sh`
  installs `platforms;android-37.0` on a fresh SDK.
- Features: `diagnostics/camera_test_screen.dart`, `camera_copy.dart`,
  `self_test_copy.dart`; the Diagnostics hub runs the self-test and links
  the camera test; Settings > Camera lists the tablet's cameras and links
  the test; launch-check copy for the new codes. Removed: the M01 camera
  spike screen and route.
- Shared: `PorcelainListRow` puts its trailing value or control at the
  row's end (it sat mid-row).
- Startup reconciles originals before anything can capture.
- Packages: `permission_handler` 13.0.2 (and five platform packages);
  licence report regenerated.
- Tests: `managed_camera_service_test.dart`, `original_store_test.dart`
  rewritten; `camera_test_screen_test.dart` new; probe, migration,
  preflight and contrast tests extended; `seed_v4.sql`; support:
  `SimulatedCameraService`, `SimulatedStillStore`, `FakeDeviceStorage`,
  `FixedStopwatch`, bound in the app harness; five new catalog screens.
- Docs: ADR-0012, `docs/device_tests/M06_DEVICE_PROCEDURE.md`, iOS
  camera-permission build note, ADR index.

### Problems met and how they were handled

- The camera test waited for ever in tests: it read the booth settings
  once from a stream nobody listened to, and Riverpod pauses unlistened
  providers. The screen now subscribes for as long as it is open.
- A tablet with one built-in lens crashed the lens picker (a segmented
  control needs two segments): one lens is now stated in words.
- A permission turned on in Settings before the booth ever asked did not
  open the camera on return: the screen controller keeps the camera it
  wants and opens it when access appears.
- Goldens of the self-test would have shown real elapsed milliseconds and
  the wall-clock time: the self-test takes an injectable stopwatch and the
  screen uses the app clock.
- Hidden apps draw no frames, so a test that looked for the "Paused"
  message while backgrounded could not see it; tests ask the service.
- Portrait put a viewfinder taller than the screen above the permission
  repair: the viewfinder is capped to leave the controls in reach and the
  repair card comes first. At 200% text on a compact tablet the capped
  viewfinder's message then overflowed (found by the screen checks): the
  message scrolls inside the viewfinder when it cannot fit.
- The launch-check flow test expected the camera and free-space rows to
  read "Not yet available"; they are real checks now, and the test reads
  their passing copy (the domain test keeps the not-yet rule).
- `permission_handler` on iOS compiles permissions in from `Info.plist`
  only for builds started in the project directory; a build from
  Xcode.app would ship a booth whose camera reads as refused. Recorded in
  ADR-0012 and `docs/IOS_VALIDATION.md` with the fix.
- The design rule's exemption for the spike folder is gone with the
  spike.
- The Android build failed: `permission_handler_android` 14 compiles
  against API 37, whose only platform package is `android-37.0`; AGP
  9.1.0 downloaded it mid-build and then failed that build, and on the
  next run refused an app compiled against 36. The app now compiles
  against 37 (target stays 36) and the build script installs the platform
  first; a release build from an SDK without it passes (ADR-0012).

### Spec issues raised

- None new. ADR-0007's open device questions move to ADR-0012 section 10
  and the device procedure.

## M05: full layered Template Studio and template library

- Date: 2026-10-18 (UTC)
- Authorised by: owner ("when complete start M05- M06 also polish the U/UX
  try to make it identical to the reference images", with two reference
  boards, now `reference/`). Read as: M05, its report, then M06 and its
  report; board polish under CR-002 within CR-001's rules. The M04
  report's questions are still unanswered; their defaults are kept.
- Quality bar: CR-001 for every new or changed screen; CR-002 (the
  boards) for the welcome screen, template cards, "Choose your style",
  the Template Studio and event setup.
- Host: the same Linux cloud session as M00 to M04.

### Plan (as executed)

1. CR-002: record the boards, map each board screen to its milestone,
   list board elements that conflict with CR-001 (sample people, extra
   guest controls) and keep CR-001.
2. Pure-Dart editing: document edits, layer copies, undo history with
   coalesced gestures and a saved marker, rotated-frame geometry (resize
   keeps the opposite corner, rotation snaps, pivot changes keep the
   layer still), snapping to page, layers and grid.
3. Drift schema v3: editor drafts; asset names editable, content still
   immutable; migration tests from v1 and v2.
4. Template library service: starter designs from the boards (five
   designs, four blank pages) with decorations drawn in code, duplicate,
   rename, archive, drafts, save, image import, packages; `OperatorFiles`
   (document picker, share sheet) behind a domain interface.
5. Template Studio: canvas drawn by the print painter with direct
   manipulation, tool rail or shelf, inspector with exact numbers, layers
   panel, asset browser, autosave and recovery, keyboard shortcuts, both
   orientations; template preview; library screen with rendered cards.
6. Board polish: guest welcome (wordmark, title, pearl Start button,
   sample print, step guide, florals) and event setup (S14 tabs and
   "Choose guest experience").
7. Tests: editing, controller, parity with the export (AC-0510), stress
   with 30 layers, library and import flows, screen checks and goldens.
8. ADR-0011, docs, checks, Android builds, evidence.

### Changes

- Domain: `editing/` (`document_edits.dart`, `edit_history.dart`,
  `editor_geometry.dart`, `layer_copy.dart`, `snapping.dart`);
  `services/operator_files.dart`; `template_store.dart` gains drafts,
  asset listing, rename, removal when unused, `loadLatest`;
  `asset_formats.dart` gains `pngHasTransparency`.
- Core: `templates/` (`starter_designs.dart`, `bundled_decorations.dart`,
  `template_library.dart`, `template_thumbnails.dart`,
  `slot_placeholder.dart`, `document_colors.dart`);
  `design_system/floral_art.dart` (the blossom painter shared by
  decorations and screens) and Template Studio icons;
  `composition/scene_loader.dart` (`decodeScaleFor`: previews decode at
  twice the shown size); providers and routes for the editor and preview.
- Infrastructure: schema v3 (`template_drafts`, narrowed asset trigger,
  `drift_schemas/booth/drift_schema_v3.json`, migration steps),
  `DriftTemplateDraftRepository`, asset rename, removal and listing,
  `PlatformOperatorFiles` (`file_selector`, `share_plus`).
- Features: `template_studio/` (editor screen, controller, canvas,
  viewport, inspector, layers, asset browser, preview); `template_library/`
  (library screen, "Choose your style", actions); event editor tabs and
  experience cards; booth welcome with the event's print; dashboard and
  component gallery without the schematic thumbnails.
- Shared: guest welcome, layout and Start button rebuilt for the boards;
  `floral_spray.dart`; `rendered_thumbnail.dart` (replaces
  `template_thumbnail.dart`); `template_messages.dart`;
  `showPorcelainNameSheet`.
- Assets: eight decorations in `assets/decorations/`, generated by
  `tool/art/decorations.dart` (a test keeps them current), with
  provenance rows.
- Packages: `file_selector` 1.1.0 and `share_plus` 13.3.x (and their
  platform packages); licence report regenerated.
- Tests: see the evidence (M05). Support: `MemoryTemplateStore` with
  failure injection, `FakeOperatorFiles`, starter library seeds.
- Docs: ADR-0011, CR-002, `docs/device_tests/M05_DEVICE_PROCEDURE.md`,
  provenance and licences.

### Problems met and how they were handled

- The canvas did not look like the print at small sizes: it drew
  print-size images at a quarter (aliasing, up to 4% of pixels off the
  renderer's own preview). Images now decode at the size they show, and
  previews at twice that because the codec's one-step shrink drops thin
  lines (ADR-0011 section 5, with before and after figures).
- Widget tests hung: a future cached across tests resumes in the zone
  that created it, and the renderer's export queue is a future, so one
  made under the fake clock blocks real-time exports. Caches hold
  results; tests make the renderer in real time.
- A spinner kept `pumpAndSettle` busy while images loaded under the fake
  clock: the loading badge is static.
- Text flashed in a stand-in font: fonts resolve before images decode.
- Renaming an image hit the "assets are immutable" trigger: v3 limits it
  to the content columns.
- Rename sheets disposed their controller while closing (found by the
  new flow tests): the sheet now owns it.
- Canvas gestures started where they cleared the touch slop, so a dragged
  layer lagged the finger and a quarter turn on the rotation handle could
  miss it (found by the new handle tests): gestures now start from each
  finger's touch-down point.
- On a 600 dp portrait screen the Layers and Inspector buttons were
  scrolled off the tool shelf, and the screen checks there had run
  without the Layers sheet open (a tap warning in CI): the two panel
  buttons are pinned at the shelf's end and the catalog asserts the panel
  opened. Long tool names shrink to stay whole.
- At 200% text a narrowed guest title overflowed because intrinsic
  measuring under-reported it: guest layouts no longer measure
  intrinsically.
- The raw-colour rule matched a class called `TemplateColors`: renamed
  `DocumentPalette`, colours kept in core.
- Accessibility checks: 44 dp controls raised to 48 dp, tool labels to
  full-contrast ink, a pivot button that looked disabled stays enabled.

### Spec issues raised

- PRODUCT_SPEC shows off-page artwork in the editor "if enabled"; there is
  no switch yet: it is always shown, faded. Owner decision (ADR-0011).
- Documents have no bleed; exports clip at the trim. Needed before
  printing (M11 or later).
- The boards show seven guest experiences; the app has three theme
  profiles plus "same as the booth". Kept until the owner decides
  (CR-002). Board screens for M07 and M09 are deferred to them.
- AC-0508's "temporary picker URI disappears" cannot happen on the host:
  the picker's bytes are copied at once and its file is never opened
  again; deleting the original on a device is step 11 of the procedure.

### Risks carried forward

- Device behaviour is unmeasured: frame times while dragging 20+ layers,
  decode bursts after zooming, memory on 3 to 4 GB tablets, the share
  sheet's popover on iPad and the pickers' type filters.
- Preview decodes may hold up to four times the pixels of an exact
  decode (bounded by full size): budget M07's guest-photo thumbnails.
- At a quarter size the densest artwork (Floral Elegance) still differs
  from the box-filtered print beyond ADR-0010's tolerance (1.37% over);
  only reachable by zooming out below the fitted size on a density-1
  screen.
- iPad builds and every device step stay BLOCKED here (no Mac, no
  tablets).

### Next

M06 (owner-assigned in the same request): production CameraService,
permissions, lifecycle, originals and the Diagnostics camera screen.

## M04: production template model, renderer and template store

- Date: 2026-10-18 (UTC)
- Authorised by: owner ("approved, start M04"). The M03 report's questions
  (recovery protocol, three-second exit hold, goldens in Git or LFS, the
  reading that "approved, start M03" approved M02, ADR-0004, the concept
  board image, device models and a Mac) are still unanswered; their
  defaults are kept and they are asked again in the report.
- Quality bar: CR-001 for every changed screen (Diagnostics, launch
  checks, Templates).
- Host: the same Linux cloud session as M00 to M03.

### Plan (as executed)

1. Pure-Dart document model v1: page in physical units and DPI with
   presets, normalised geometry with a documented pivot, five layer types,
   global z-order, opacity, visibility, clips and masks, content-addressed
   asset table; validation with codes and paths; strict JSON reading,
   canonical writing, checksums and a migration framework.
2. Scene compiled in page pixels, and the M01 painter promoted to
   `core/composition` so previews, the editor workspace and exports share
   it; text with bundled and imported fonts and a deterministic fallback.
3. Renderer: exact-size offscreen exports from originals with bounded
   decoding, PNG with print resolution and alpha, an in-house baseline JPEG
   encoder on an isolate with intentional flattening, typed failures and
   warnings, one export at a time.
4. Atomic export: stage, flush, read back, decode, rename, never replace;
   fault injection; startup discard of interrupted writes.
5. Drift schema v2 (assets, revision asset links), v1 to v2 migration with
   seeded fixtures; content-addressed asset store with header, limit and
   decode checks; template repository with immutable checksummed
   manifests.
6. Strict ZIP reader and writer (no new dependency) and the
   `.porcelain-template` package; import creates a new template and stores
   nothing unless everything checks out.
7. Real launch checks for the renderer and template assets.
8. Render lab (replacing the render spike), fixtures FIX-01 to FIX-06 plus
   clip, gradient and halo cases, goldens, preview parity with a documented
   tolerance, determinism, host benchmarks, device test and procedure.
9. ADR-0010, docs, checks, Android builds, evidence.

### Changes

- Domain (`lib/domain/template/`): `geometry.dart`, `page_spec.dart`,
  `template_assets.dart`, `template_layers.dart`, `document_issues.dart`,
  `template_document.dart`, `template_json.dart`,
  `template_migrations.dart`, `asset_formats.dart` (header sniffing),
  `document_scene.dart` (rewritten). Services: `composition_renderer.dart`
  (rewritten: `TemplateRender`, `RenderSource`, artifacts, failures,
  warnings, stats), `export_service.dart`. Repositories:
  `template_store.dart` (asset and template repositories, packages,
  `TEMPLATE_*` errors). `crypto` allowed in the domain for content ids.
- Core (`lib/core/composition/`): `scene_painter.dart` (moved from
  infrastructure and extended), `scene_images.dart`, `scene_loader.dart`,
  `scene_preparation.dart`, `template_fonts.dart`; DI providers for the
  asset and template repositories, packages and the export service.
- Infrastructure: `codecs/` (CRC-32, PNG print metadata, JPEG encoder),
  `composition/dart_ui_composition_renderer.dart` (rewritten),
  `file_store/atomic_file_writer.dart`, `file_store/file_export_service.dart`,
  `managed_storage.dart` (startup discard, writer), `templates/` (asset
  and template repositories, ZIP, packages, store render source),
  `database/` (schema v2, generated steps, shared summary mapping),
  `device/device_capability_probe.dart` (real renderer and asset checks).
- Features: `diagnostics/render_lab/` (moved from `spikes/render/`:
  fixtures, runner, checks, preview parity, screen), Diagnostics row
  "Render lab", launch-check copy for the new results, Templates
  placeholders now name M05.
- Shared: `widgets/scene_preview.dart`.
- Tests: `test/domain/template/` (document, JSON, scene),
  `test/rendering/` (render lab, goldens, preview parity, text, output
  formats, benchmark, device comparison), `test/infrastructure/` (JPEG
  encoder, export service, launch checks, `templates/` asset and template
  repositories, ZIP, packages), migration test and `seed_v2.sql`, updated
  router, spike-screen, events-flow and launch-check tests; fixtures
  `test_assets/templates/v1/everything.json` and four new render goldens;
  Diagnostics and launch-check widget goldens regenerated (text changes).
- Device: `integration_test/render_lab_test.dart` (was
  `render_spike_test.dart`), driver saving under `build/device_renders/`.
- Docs: ADR-0010; ADR-0003 and ADR-0007 status notes; ADR index; README;
  `test_assets/README.md`; `docs/device_tests/M04_DEVICE_PROCEDURE.md`;
  M01 procedure points to it.
- Migrations: schema version 2 adds `assets` and
  `template_revision_assets`; tested from seeded v1 and v2 databases.

### Problems met and how they were handled

- Preview parity found a pale seam: where a slot edge fell between pixels,
  the slot clip and the image's own anti-aliased edge each covered the
  pixel (25% instead of 50%). It showed in quarter-size previews and would
  have shown in exports of templates whose slots are not on whole pixels.
  Photos now fill their slot shape through an image shader (one edge);
  masks scale that edge without cutting it again. All goldens, which have
  whole-pixel slots, still match exactly.
- Text cannot be compared pixel for pixel between a quarter-size preview
  and a reduced export (glyphs are rasterised at each size), so text is
  compared by geometry; the documented tolerance applies to everything
  else (ADR-0010 section 6).
- JPEG exports raised resident memory by about 21 MB over the first 200
  renders and then stayed flat; PNG exports and previews showed no growth.
  That is the allocator keeping memory for the encoder isolate, not a
  leak; the benchmark records the curve and asserts a bound.
- The engine already writes `sRGB` and `sBIT` into PNGs; the metadata step
  only adds `pHYs`, and the test now parses chunks instead of assuming
  offsets.
- The JSON reader at first reported missing fields twice; absent keys now
  return defaults and are reported once.
- The design-system rule caught literal colours in a render fixture;
  fixtures use their named colours.
- The longer "Render lab" subtitle wrapped on Android portrait; shortened.
- Building FIX-01 (pure-Dart PNG encoding) in every test made the package
  tests take 69 s; built once per file, 5 s.
- `drift_dev make-migrations` regenerated `schema_v1.dart` with data
  classes now that two versions exist; expected, and checked by
  `tool/check.sh`.

### Spec issues raised

1. A-06 lists a font "license ID" for text. Schema v1 names a bundled
   family (licences in `docs/ASSET_PROVENANCE.md`) or an imported font
   asset, with no licence field. Proposal: M05's import screen records the
   operator's licence note against the asset (a database column, no
   document change).
2. A-06 allows an optional bleed or safe area. Not in schema v1: release 1
   is export-only and no paper profile is chosen; adding it later is a
   schema step. Exports clip to the page.
3. A-06 allows the background as a page property or a layer; v1 uses a
   layer only (at most one, lowest), which avoids competing backgrounds.
4. Only source-over blending; no blend modes in v1.
5. JPEG output is untagged sRGB; ICC embedding waits for a chosen printer
   (A-13).
6. "Asset copying" works through the template store and packages; there
   is no file picker until the library screen (M05), so a device cannot
   import a template yet.
7. AC-0407 asks for parity "on target platforms": the host passes; iPad
   and Android runs are BLOCKED without devices.
8. RenderedOutput rows need sessions (M06); M04 saves and verifies the
   file and returns its facts.

### Risks carried forward

- Device behaviour is unmeasured: render time and memory with 12 MP
  camera JPEGs, JPEG encode time on tablet CPUs, text rasterisation and
  the real pixel difference against the host goldens (which decides the
  final tolerance).
- A PNG decodes at full size before resizing; the 50 MP limit bounds that
  at about 200 MB, which may be too much for some tablets. Revisit after
  device runs.
- Imported fonts stay registered for the life of the process (the engine
  cannot unload them); bounded by the number of distinct font files.
- A crash between writing a file and recording it leaves an unrecorded
  manifest or asset: harmless, never read, but it takes space until the
  M10 clean-up.
- Goldens: 177 widget images (30 MB) plus 6 render goldens; Git LFS is
  still the owner's call.

### Next

Owner review of M04, then M05 (template library and layered editor) when
approved.

## M03: offline storage, event configurations and operator access

- Date: 2026-10-18 (UTC)
- Authorised by: owner ("approved, start M03"). The M02 report asked for
  approval of M02 including the AC-0209 "exceeds the board" verdict and the
  palette changes in ADR-0008; this reply is recorded as granting both
  (ADR-0008 status). The owner can overrule that reading.
- Quality bar: CR-001 for every new screen.
- Host: the same Linux cloud session as M00 to M02.

### Plan (as executed)

1. Pure-Dart domain: booth profile, events (capture, guest, output,
   retention and template selection), stable random IDs, clock, calendar
   date, event rules with blocking and warning issues, event lifecycle
   service, launch-check (preflight) model, operator PIN policy, recovery
   codes, attempt policy and the operator auth service.
2. Storage: Drift SQL-first schema v1 with CHECK constraints, explicit
   foreign-key actions, an immutable-revision trigger and one default per
   event; WAL and full sync; schema dump, generated migration schemas and a
   seeded v1 fixture; refusal of newer or unsupported databases; managed
   file areas with a write probe.
3. Security adapters: PBKDF2-HMAC-SHA256 hasher on an isolate (RFC 7914
   vectors), PIN verifier in Keychain or Keystore-backed storage, recovery
   verifier and attempt counters in the database.
4. Access: startup, setup, locked, operator and Booth Mode phases; one pure
   redirect function guarding every navigation; first-run setup; PIN and
   recovery screens; Studio lock; Booth Mode welcome with a hidden
   three-second exit to a PIN pad.
5. Events UI: list with filters and search, six-tab editor with unsaved
   changes guard, duplicate, archive, reopen, activate, return to drafts;
   launch checks with truthful "Not yet available" items; Settings defaults
   for new events, booth name, PIN change, new recovery code.
6. Tests: domain, persistence, migration, security vectors, route guard,
   end-to-end access and events flows, every new screen in the screen
   audits, goldens for every new screen and state.
7. ADR-0009, Android backup exclusion, generated-code check in
   `tool/check.sh`, licence report; format, analyze, tests, Android builds;
   evidence.

### Changes

- Domain (`lib/domain/`): models `booth_event.dart`, `booth_profile.dart`,
  `event_rules.dart`, `template_revision_summary.dart`; repositories (event,
  booth settings, template catalogue, operator access, storage errors);
  services `event_service.dart`, `preflight.dart`, `booth_capabilities.dart`,
  `managed_storage.dart`, `operator_auth_service.dart`,
  `operator_secrets.dart`; value objects `appearance.dart` (moved from core
  so the domain can store it), `calendar_date.dart`, `clock.dart`,
  `entity_id.dart`.
- Infrastructure: `database/` (schema, database, converters, connection
  setup, constraint mapping, four Drift repositories), `security/` (PBKDF2,
  hasher, secure verifier store), `file_store/managed_storage.dart`,
  `device/device_capability_probe.dart`.
- Core: `access/access_controller.dart`, `routing/access_redirect.dart`,
  `booth/booth_providers.dart`; DI bindings for every new service
  (`di/service_providers.dart`), including `recoveryCodeGeneratorProvider`;
  appearance now persists through the booth settings repository.
- App: startup and startup-problem screens, routes for setup, unlock,
  Booth Mode, event editor and launch checks; production bindings.
- Features: `onboarding/setup_screen.dart`, `operator_access/unlock_screen.dart`,
  `booth/` (welcome, operator exit, hidden corner, event theme),
  `events/` (list, editor and six tabs, actions, copy, launch checks),
  dashboard and settings now data-aware, Studio shell Lock button and live
  booth status.
- Shared: `widgets/pin_pad.dart`, `widgets/theme_profile_card.dart`,
  `operator_access/` (PIN creation, unlock, recovery, layout, copy,
  countdown), `formatters/`, `guest/event_welcome_copy.dart`; the toast is
  now a root-overlay entry; stepper, segmented control and text field gained
  reasons, counters and multi-line support.
- Android: `allowBackup="false"`, `fullBackupContent="false"` and
  `res/xml/data_extraction_rules.xml` (no cloud backup or device
  transfer).
- Build: `build.yaml` (drift_dev), `analysis_options.yaml` excludes the
  generated migration schemas, dependencies drift, drift_flutter, sqlite3,
  flutter_secure_storage, collection, meta, drift_dev, build_runner;
  `tool/check.sh` checks generated code.
- Tests: `test/domain/` (5 new files), `test/persistence/`,
  `test/drift/booth/` (migration test, seed, generated schemas),
  `test/infrastructure/` (managed storage, security adapters),
  `test/core/access_redirect_test.dart`, `test/app/access_flow_test.dart`,
  `test/app/events_flow_test.dart`; support (`fakes.dart`,
  `test_database.dart`, `seed.dart`, `screen_catalog.dart`, harness);
  screen audits, guest isolation and goldens extended (177 images).
- Docs: ADR-0009, ADR-0008 status, ADR index, README, licence report.
- Migrations: schema version 1 is the first; there is no earlier database
  to migrate.

### Problems met and how they were handled

- build_runner 2.17.0 is retracted and 2.17.1 needs `build` 5, which
  drift_dev 2.35.1 does not support; build_runner stays at 2.16.2.
- Drift inferred integer affinity for the `PorcelainThemeProfile` enum (its
  name contains "INT") and stored it by index; it is mapped by name.
- Drift runs `onUpgrade` for downgrades too; the newer-database guard
  checks the direction itself.
- Riverpod 3 pauses providers without listeners, so awaiting a stream
  provider's future from a callback never completed (the new-event editor
  waited forever); one-off reads go through repositories.
- Drift's stream timers outlived widget tests; tests use a connection that
  closes streams synchronously and never await a stream's first value under
  fake time.
- A deep link requested during startup was lost; the waiting location now
  carries it (`/starting?from=`) and the next phase judges it.
- Contrast tests sampled colours mid-way through a cold-start theme fade;
  the theme animates only after startup (also nicer on device).
- The SnackBar toast inside the Studio's Scaffold covered a sheet's Done
  button; replaced by a root-overlay toast that lets taps through, with a
  timer rather than an animation for its hold so tests settle.
- Golden review: PIN screens were cut off in landscape (side-by-side PIN
  layout); setup's Back sat below the fold and later met the corner
  ornament on wide or compact screens (Back and progress moved into the
  card); the strip template's slot label spilled out of its thumbnail and
  landscape pages would have overflowed (pages fitted to a fixed box, count
  beneath); Booth Mode's operator PIN screen and toasts used the bright
  Studio theme during a dark-themed event (the whole Booth Mode now wears
  the event theme).
- Recovery codes are random, so a screenshot of one changed every run; the
  generator is injectable and seeded in tests.

### Spec issues raised

1. AC-0304 says "seeded old/new DBs". Schema version 1 is the first, so no
   old version exists yet: M03 tests that a seeded v1 file opens intact and
   matches a fresh schema, that newer files are refused untouched, and that
   the harness requires a dump and seed for every version. The first real
   upgrade test comes with schema version 2.
2. Templates: the prompt asks for "default/allowed template revision"
   settings, but the template library arrives in M04/M05, so a production
   build has no templates and no event can be activated yet. Tests seed
   templates directly.
3. Retention: the per-event policy (keep until deleted, or delete after 1
   to 365 days) is stored and validated; deleting photos on schedule is
   M10.
4. Recovery protocol: a one-time 16-character code shown at setup; without
   PIN or code the only way back is clearing the app's data. Owner to
   confirm this is acceptable for venues.
5. Still pending from M00 to M02: confirmation of ADR-0004, the concept
   board image at `reference/15_screen_concept_reference.png`, and the
   device models (and whether a Mac is available).

### Risks carried forward

- On iPadOS the app's files are included in iCloud and computer backups
  until M10 excludes them (ADR-0009 section 9).
- Device behaviour is unproven: Keychain and Keystore storage, PBKDF2
  timing on tablet CPUs, persistence across a real process restart,
  orientation facts from real windows. All BLOCKED without hardware.
- No OS kiosk lock yet (M10): a guest could leave the app with system
  gestures; launch checks warn about it.
- Goldens now take about 30 MB (177 images). Git LFS or a smaller matrix
  is the owner's call.

### Next

Owner review of M03, then M04 (production document model and shared
composition engine) when approved.

## M02: Porcelain design system and adaptive Studio shell

- Date: 2026-10-18 (UTC)
- Authorised by: owner ("approved, start M02"), which also approved
  continuing with the M01 device subgates BLOCKED (MASTER_PROMPT §D).
- Quality bar: CR-001 (exceed the concept board; AC-0207..AC-0211).
- Host: the same Linux cloud session as M00 and M01.

### Plan (as executed)

1. Licensed type and icons with recorded provenance: Cormorant Garamond
   and Inter (SIL OFL 1.1), Material Symbols Rounded (Apache 2.0).
2. Semantic tokens as a `ThemeExtension`: three profiles (Porcelain
   Studio, Light Oak, Darkroom Walnut), each with a high-contrast variant;
   palettes tuned against CR-001 and checked by an automated pair test.
3. Component kit with every interaction state: tactile surface painter,
   shared `Pressable` behaviour, buttons, icon buttons, cards, switches,
   stepper, segmented control, text field, sheet, toast, navigation,
   responsive grid, template thumbnail, empty and loading states, status
   badges and tiles, wordmark, device-frame miniature, original botanical
   line art.
4. Adaptive Studio shell: stateful shell route with six sections; sidebar
   or compact rail chosen from the window width; Dashboard, Events,
   Templates, Gallery, Settings (master-detail, live Appearance) and
   Diagnostics (developer tools in non-release builds only).
5. Guest layout skeleton (portrait and landscape chosen from constraints)
   with the welcome screen and an operator preview route.
6. Tests: contrast pairs, design-system rules, components, every screen at
   six tablet sizes and 200% text, accessibility guidelines in both
   orientations and all themes, a dead-control audit, guest isolation,
   navigation, licences and provenance; goldens for every screen.
7. ADR-0008; format, analyze, tests, Android builds; evidence.

### Changes

- Design system: `lib/core/design_system/` (tokens, palettes, typography,
  metrics, motion, depth, theme extension and `ThemeData`, page
  transitions, appearance state, icon names, licence registration).
- Components: `lib/shared/widgets/` (24 files); guest skeleton:
  `lib/shared/guest/`.
- Screens: `lib/features/studio_shell/`, `dashboard/dashboard_screen.dart`
  (replaces the baseline screen), `events/`, `template_library/`,
  `gallery/`, `settings/` (6 files), `diagnostics/diagnostics_screen.dart`,
  `diagnostics/component_gallery_screen.dart`, `booth/guest_preview_screen.dart`.
- App: `app.dart` (theme from appearance, platform contrast and motion),
  `router.dart` (shell routes, guest preview, developer routes),
  `bootstrap.dart` (font licences), restyled `route_not_found_screen.dart`;
  `core/routing/route_paths.dart`, `core/platform/app_info.dart`.
- Assets: `assets/fonts/` (5 TTFs, 2 licence texts); `pubspec.yaml` fonts
  and assets; dependency `material_symbols_icons` ^4.2960.0.
- Architecture rule: `core` may import `material_symbols_icons`
  (`test/architecture/layer_rules.dart`, ADR-0008).
- Tests: `test/design_system/` (2 files), `test/core/`,
  `test/widgets/{components,screens,guest_isolation}_test.dart`,
  `test/app/router_test.dart` (rewritten), `test/goldens/` (103 images),
  `test/flutter_test_config.dart` (loads the real fonts),
  `test/support/app_harness.dart`, `dart_test.yaml` (golden tag);
  `integration_test/app_launch_test.dart` now expects the dashboard.
  Removed: `baseline_home_screen.dart` and its test.
- Docs: ADR-0008, `docs/ASSET_PROVENANCE.md`, licence report, README.
- Migrations: none.

### Problems met and how they were handled

- A token field named `type` silently overrode `ThemeExtension.type`, the
  key Flutter uses to look extensions up; renamed to `text` before any
  screen depended on it.
- Flutter's text-contrast guideline samples a 1x render around each label.
  It failed thin 13 px muted labels (3.1–3.4:1 measured against 5.6–6.1:1
  tokens), a sidebar label whose sampled box touched the item's edge, and
  captions sitting inside a device frame's shadow. Fixed in the design
  (14 px minimum, full-ink navigation labels, padding, smaller shadow);
  the guideline and thresholds are unchanged.
- At 200% text, list rows with a status badge overflowed on the smallest
  portrait tablet; trailing widgets may now shrink and wrap.
- First review renders showed corner sprigs crossing the guest title,
  steps wrapping awkwardly and a lone fourth format card; fixed (smaller
  corner art, shorter step copy and a vertical step list in landscape, a
  balanced grid option).
- Golden size: 103 images at 1x take about 16 MB, mostly smooth gradients
  that PNG compresses poorly. Kept, and noted in ADR-0008 (Git LFS is an
  option for the owner).

### Spec issues raised

1. UX-01 palette values were adjusted where they fail CR-001 (secondary
   text, white-on-gold primary, gold icons); table in ADR-0008. Owner to
   confirm.
2. UX-04 lists "Settings/Diagnostics" as one area; M02's prompt lists them
   separately, so Diagnostics is its own section.
3. S02 asks for a "last active event summary"; no events exist until M03,
   so the dashboard shows the empty state and readiness tiles instead.
4. Still pending from M00/M01: confirmation of ADR-0004, the concept-board
   image at `reference/15_screen_concept_reference.png`, and the device
   models (and whether a Mac is available).

### Risks carried forward

- Appearance choices reset on restart until booth storage (M03).
- Golden comparison is exact and Linux-only; on-device legibility under
  venue lighting and frame rate are M11 checks.
- AC-0209 needs the owner's "exceeds the board" sign-off.

### Next

Owner review of M02 (goldens and the live build), then M03 when approved.

## M01: cross-platform render and camera feasibility spike

- Date: 2026-10-18 (UTC)
- Authorised by: owner ("approved, start M01"), after the M00 report said
  that no physical iPad, Android tablet or Mac was available here, so the
  device subgates would be BLOCKED.
- Host: the same Linux cloud session as M00 (`docs/TOOLCHAIN_INVENTORY.md`).

### Plan (as executed)

1. Pure-Dart template model and scene compiler (page units and DPI,
   normalised geometry, photo slot and image layers, z-order, cover crop).
2. `dart:ui` painter and offscreen renderer (export and editor workspace).
3. Procedural fixtures through a pure-Dart PNG writer; FIX-01 pixel checks,
   z-order variant, FIX-04 halo probes, failure probes, goldens, metrics.
4. Camera: `camera` 0.12.1 behind `CameraService` via a driver seam;
   original store with staged, validated, atomic commits; EXIF reader.
5. Platform permissions: iOS usage string; strip unneeded Android
   permissions the plugin adds.
6. Dev-only render and camera spike screens behind non-release routes;
   DI providers bound in the composition root.
7. Device integration test, driver, host comparison test and procedure.
8. ADR-0007; format, analyze, tests, Android builds; evidence.

### Changes

- Domain: `lib/domain/template/` (new), `composition_renderer.dart` (new
  draft contract), `camera_service.dart` (`CapturedStill` gains id,
  checksum, byte length, EXIF and capture-time mirroring settings;
  `CapturedStillStore` added).
- Infrastructure: `composition/` (painter, renderer), `camera/` (driver
  seam, managed service), `file_store/` (original store, EXIF reader).
- App wiring: `lib/core/di/service_providers.dart`, `productionOverrides()`
  in `lib/app/providers.dart`, spike routes only when the build mode is not
  release, baseline screen links in debug and profile.
- Spike UI and fixtures: `lib/features/diagnostics/spikes/`.
- Platform: `ios/Runner/Info.plist` (`NSCameraUsageDescription`),
  `android/app/src/main/AndroidManifest.xml` (remove `RECORD_AUDIO`,
  `WRITE_EXTERNAL_STORAGE`).
- Dependencies: camera ^0.12.1, path_provider ^2.1.6, crypto ^3.0.7.
- Tests: `test/domain/document_scene_test.dart`, `test/rendering/` (5
  files), `test/infrastructure/` (3 files), `test/widgets/spike_screens_test.dart`,
  router and baseline updates; `integration_test/render_spike_test.dart`,
  `test_driver/integration_test.dart`.
- Fixtures: `test_assets/` (two Pillow-made JPEGs, two host goldens,
  provenance README).
- Docs: ADR-0007, `docs/device_tests/M01_DEVICE_PROCEDURE.md`, inventory,
  iPad guide, README, licence report.
- Migrations: none.

### Problems met and how they were handled

- Plugin manifests add `RECORD_AUDIO` and `WRITE_EXTERNAL_STORAGE`, and the
  merger implies `READ_EXTERNAL_STORAGE`; all removed with
  `tools:node="remove"` (audio is never enabled). The release APK audit
  also showed a required rear camera implied by `CAMERA`, now declared
  optional, and `ACCESS_NETWORK_STATE` from `androidx.media3`, kept and
  flagged for M10 (ADR-0007).
- The first Android build auto-installed SDK Platform 35 and CMake 3.22.1
  (plugins compile against API 35; `path_provider_android` builds JNI
  code). Recorded in the inventory; CI's runner does the same.
- Tests caught a real bug: the camera lifecycle stream, written as
  `async*`, dropped the `initializing` event emitted just after a
  listener subscribed. Rewritten with `Stream.multi`.
- The halo probe was first written so that partly transparent edge pixels
  carried the hidden colour, which would make a dark fringe legitimate.
  Fixed before any result was recorded; a separate test now proves the
  probe fails on exactly that kind of bad input.
- Reading `ProcessInfo.maxRss` after the 12 MP run confounded the drift
  measurement; drift is now measured first.

### Spec issues raised

1. ARCHITECTURE A-03 lists `test_assets/transparent_pngs/`; transparent
   fixtures are generated in code instead, so hosts and devices render
   identical inputs without bundling binaries. The directory stays absent.
2. FLUTTER_PLATFORM_STRATEGY §3 says to keep the spike in
   `lib/features/diagnostics/spikes/`. Only the demo UI and fixtures live
   there; core functions went to their target layers so M04/M06 can
   promote them (ADR-0007). Layer rules forbid features from importing
   plugins or `dart:io`, so this was the only compliant option.
3. Still pending from M00: confirmation of ADR-0004 (orientation without
   "Requires Full Screen"), the board image file, and device models.

### Risks carried forward

- AC-0104 cross-platform comparison, AC-0106 and AC-0107 are BLOCKED until
  a physical iPad (with a Mac) and an Android tablet run the procedure.
- JPEG output encoder and decode-size policy are open for M04 (ADR-0007).
- Permission pre-checks and "denied forever" on Android are open for M06.

### Next

Owner review of M01, including explicit approval to proceed to M02 with
the device subgates still BLOCKED (MASTER_PROMPT §D), or a pause to run the
device procedure first.

## M00: dual-target toolchain, repository and CI baseline

- Date: 2026-10-17/18 (UTC)
- Authorised by: owner, by supplying the v3.2 master package whose
  MASTER_PROMPT §G orders "Execute M00 only"; sequencing re-confirmed by the
  owner on 2026-10-17 (keep spec order, see CR-001).
- Host: Linux cloud session (no macOS, no KVM, no attached devices).
  Details: `docs/TOOLCHAIN_INVENTORY.md`.

### Plan (as executed)

1. Split the consolidated v3.2 master into its 16 package files; verify a
   lossless round trip.
2. Install Flutter 3.47.7 (SHA-256 verified) and the Android SDK; record
   `flutter doctor -v`, devices and emulators.
3. Generate the Flutter project for iOS and Android only; set iPad-only
   device family and app labels; keep Android defaults.
4. Minimal shell: Riverpod root scope, GoRouter with a detail-free fallback,
   one honest baseline screen with no controls.
5. Typed boundaries: orientation value objects, draft `CameraService`
   contract, layer import rules enforced by tests.
6. Tests: architecture fitness, domain, widget layout at six tablet
   viewports and 200% text, accessibility guidelines, router fallback,
   integration launch smoke test.
7. Scripts (`tool/`), CI workflow, exact Flutter pin, licence report.
8. ADR-0001..0006; owner change request CR-001 (premium UX bar).
9. Run format, analyze, tests and both platform builds; record evidence.

### Changes

- Package docs: `START_HERE.md`, `CLAUDE.md`, `prompts/*.md`, `docs/*.md`
  (verbatim split of the master; round trip verified byte for byte).
- Flutter project: `pubspec.yaml` (Flutter pinned to 3.47.7,
  flutter_riverpod ^3.4.3, go_router ^18.1.0, integration_test),
  `pubspec.lock`, `analysis_options.yaml` (strict casts, inference and raw
  types; async-safety lints), `android/`, `ios/`.
- Platform settings: `TARGETED_DEVICE_FAMILY = 2` (iPad only); Android
  label "Porcelain Photo Booth". Everything else is the Flutter 3.47.7
  template.
- App: `lib/main.dart`, `lib/app/{bootstrap,app,providers,router,route_not_found_screen}.dart`,
  `lib/core/platform/app_environment.dart`, `lib/core/routing/route_paths.dart`,
  `lib/features/dashboard/baseline_home_screen.dart`.
- Domain: `lib/domain/value_objects/orientation.dart`,
  `lib/domain/services/camera_service.dart` (draft placeholder contract).
- Tests: `test/architecture/`, `test/domain/`, `test/widgets/`, `test/app/`,
  `test/support/`, `integration_test/app_launch_test.dart`.
- Tooling: `tool/check.sh`, `tool/build_android.sh`, `tool/build_ios.sh`,
  `tool/toolchain_inventory.sh`, `tool/dependency_licenses.dart`,
  `.github/workflows/ci.yml`.
- Docs: `README.md`, `docs/TOOLCHAIN_INVENTORY.md`, `docs/IOS_VALIDATION.md`,
  `docs/DEPENDENCY_LICENSES.md`, `docs/decisions/*`, this log,
  `docs/ACCEPTANCE_EVIDENCE.md`. CR-001 amendments appended to
  `docs/ACCEPTANCE_CHECKLIST.md` (AC-0207..AC-0211),
  `docs/UX_SCREEN_SPECS.md` and `docs/DECISIONS_AND_RISKS.md`.
- Migrations: none (no database until M03).

### Commands and results

Recorded with exit codes in `docs/ACCEPTANCE_EVIDENCE.md` (M00 section).

### Problems met and how they were handled

- Maven Central answered HTTP 429 through the session's shared egress while
  Gradle built the Flutter Gradle plugin. Workaround local to this
  container: a Gradle init script that resolves Maven Central artifacts from
  Google's public mirror. No repository change; CI uses Maven Central.
- A release build failed at `javac` because `GeneratedPluginRegistrant.java`
  still listed the dev-only `integration_test` plugin. Cause: `flutter pub`
  commands run concurrently with the build regenerated the registrant in
  debug mode. Re-running the build with no concurrent Flutter commands is
  the fix; scripts run steps sequentially.
- `flutter_riverpod` 3 depends on `flutter_test` (widget-test helpers), so
  test packages sit in the runtime dependency graph. The licence report
  treats that whole graph as shipped (conservative).

### Spec issues raised (not silently resolved)

1. **iPad "Requires Full Screen" is obsolete.** `UIRequiresFullScreen` is
   deprecated from iPadOS 26 and no longer prevents resizing for iOS 27 SDK
   builds (Apple TN3192, revised 2026-10-09). ADR-0004 proposes adaptive
   layouts plus operational locking; CLAUDE.md, A-09, A-16, strategy §5 and
   UX-03 still mention the old approach. Owner confirmation requested.
2. **Milestone changelog is one version behind.**
   `docs/MILESTONE_CHANGELOG_v3_1.md` maps v3.0 to v3.1 (M09 Resilience, M10
   Certification, M11 Release), but v3.2 inserted M09 Phone Delivery, so
   Resilience is M10, Certification M11 and Release M12. A v3.1→v3.2 entry
   is missing.
3. **Missing package files.** `reference/15_screen_concept_reference.png`
   (UX-00) and `examples/template_v1.json` (MASTER_PROMPT §A) are referenced
   but not in the package. The owner shared the board in chat; it still
   needs committing as a file.
4. **Truncated link** in `docs/PHONE_DELIVERY_SPEC.md` PD-10
   (".../a2p-10dlc-campaign-registration-will-require-privacy-policy-and-").
5. **Stale minimums.** A-16 cites camera docs listing iOS 13+; the Flutter
   3.47.7 template targets iOS 15.0 and Android API 24.
6. `docs/FLUTTER_PLATFORM_STRATEGY.md` is labelled version 3.1 inside the
   3.2 package (cosmetic).
7. The concept board conflicts with the spec in 12 places (guest print and
   save buttons, guest settings and back controls, a single mirror toggle,
   and more). CR-001 lists them; the spec wins.

### Risks carried forward

- No physical iPad or Android tablet identified (D-04 #1): every DEVICE gate
  from M01 on stays BLOCKED until hardware is available.
- No Mac yet: iPadOS has never been compiled; the manual CI job or an
  owner Mac must do it (`docs/IOS_VALIDATION.md`).
- JPEG export has no built-in `dart:ui` encoder (ADR-0003); M01 measures the
  options.
- Placeholder bundle and application IDs must be replaced before signing.

### Next

Owner review of M00. On approval: M01 cross-platform render and camera
feasibility spike (AC-0101..AC-0108), with camera checks BLOCKED until a
physical iPad and Android tablet are available.
