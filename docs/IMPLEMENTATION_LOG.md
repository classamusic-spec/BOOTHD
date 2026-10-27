# Implementation log

Newest milestone first. Each entry: scope, plan, changes, commands and exit
codes, platform results, spec issues raised, risks, next step.

## Local reliability fixes: startup, browser storage and portable checks

- Date: 2026-10-22 (America/New_York).
- Authorised by: owner request to debug the code and make fixes and improvements.
- Scope: maintenance of the existing app; no new milestone or product feature,
  dependencies, schema migration, messaging configuration or deployment.

### Changes and reasons

- The composition root now owns platform initialization. A visible loading
  screen and sanitized, retryable error screen replace a blank page when
  IndexedDB is unavailable. Production services are constructed only after
  storage opens. The entrypoint again obeys the existing layer rule.
- BlobFileSystem serializes mutations through their index update. The original
  code lost overlapping appends (only `-two` remained from three writes) and
  allowed a directory to be renamed inside itself, orphaning its tree. New
  regression tests cover these cases, failed-operation recovery, pending
  write/rename ordering, entity types and returned-byte isolation.
- IndexedDB renames read and write within one read-write transaction, with
  writes queued from active request callbacks. Missing sources abort the whole
  move. Synchronous setup errors return the awaited failure instead of leaving
  an unobserved abort future. Three real-Chrome tests cover another connection's
  concurrent write, multi-file swaps and rollback/recovery.
- Browser tests have their own setup: the native font-manifest loader is not
  valid in Flutter's browser test server. CI now runs these tests and a web build.
- Smoke tests assert setup, privacy, reload, cross-origin isolation and blocked
  storage/retry using isolated browser contexts, rather than only taking delayed
  screenshots. No operator browser data is changed by these tests.
- Two UI golden sheets now follow the established Linux-only golden policy.
  FIX-05 has a separate reviewed macOS text reference; Linux references and all
  tolerances remain unchanged. The template-store round trip compares exactly
  to the source rendered on the same host; whole-image references remain in
  the dedicated renderer tests. Text geometry and mutation checks still run.
- Refreshed the stale licence report: file, path and web are direct dependencies
  already present in pubspec.yaml and pubspec.lock.

### Validation

See the local reliability section in `docs/ACCEPTANCE_EVIDENCE.md` for commands
and outcomes. The full suite passed (3,021 passed, 419 skipped), as did the
three Chrome storage tests and startup/recovery smoke. Both web and iPad simulator
builds compile. Local screenshots and
logs are under `build/local-verification/`. No tracked generated database or
migration files changed. Physical iPad/Android certification remains untested.


## UX-P1 follow-up: leaving Booth Mode, the photo reel, guest screens on phones

- Date: 2026-10-25 (UTC)
- Authorised by: the owner, testing the web build on a phone: "create a
  way so a user can check the booth reel and/or how does the main user
  exit the event". Recorded in CR-003 section 3.

### Changes

- `lib/features/events/preflight_screen.dart`: under Start Booth Mode,
  how to leave Booth Mode (hold the top-right corner 3 s, then the PIN).
- `lib/features/booth/booth_photo_reel.dart`, `booth_operator_screen.dart`:
  after the PIN, a Photo reel of the event's finished photos (view only),
  inside the operator screen and its idle timeout.
- `GalleryThumbnail` and `PrintFrame` move to `lib/shared/gallery/` so the
  booth can show thumbnails without importing the gallery feature.
- `PortraitGuestLayout` and the finished screen stack the print above
  the words below 600 dp.
- Tests: `booth_session_flow_test.dart` (reel before and after a guest),
  `events_flow_test.dart` (the exit instructions),
  `narrow_studio_test.dart` (guest screens at 390 x 844: no overflow, no
  label cut short); 10 launch-check goldens regenerated and reviewed.

### Checked in a browser

Scripted Chromium at 390 x 844 with touch: setup, a new event, Start
Booth Mode, a finger held 3.5 s on the top-right corner, the PIN, the
Photo reel, Done, Exit Booth Mode: every step passed, no page errors.

## UX-P1: premium polish and a three-step new event (CR-003)

- Date: 2026-10-25 (UTC)
- Authorised by: the owner's directive "ADD AAA Premium polish to the
  UI/UX across all screens, Simplify the event creation mode", recorded
  as CR-003: an owner-directed track like EP and W, outside M00 to M12.
  It changes no locked product decision. Work stops here for the owner's
  review.

### Plan (as executed)

1. Survey every Studio and guest screen at the tablet sizes and in a
   phone-sized window of the web test build.
2. Replace the eight-step Event Builder with a three-step flow; keep the
   editor, and let its photos per session follow the designs.
3. Polish: narrow-window Studio, page entrances, event covers, the launch
   checks' seal and tally, the dashboard's gallery count, segmented
   controls, the guest camera while it opens.
4. Tests, goldens and documents; the full checks; push; redeploy the web
   test build.

### Changes

- New event (S04-Q): `lib/features/events/create/quick_event_screen.dart`
  and `quick_event_designs.dart`; the route `/studio/events/new` opens it.
  The builder is removed from `event_editor_screen.dart`; the editor's
  issue summary offers "Use N photos" for a mismatch, and adding or
  removing designs makes the photos per session follow them when they
  agree (`EventRules.sharedSlotCount`, `templates_tab.dart`).
  `ExperienceCard` moves to `lib/features/events/editor/experience_card.dart`;
  `TemplateRecommendations.scoreTags` scores ready-made designs.
- Studio shell: `PorcelainBottomNavigation`, `WordmarkLayout.bar`, a
  selected state for `PorcelainIconButton`; `StudioShell` switches below
  600 dp.
- `lib/shared/widgets/porcelain_entrance.dart` (`PorcelainEntrance`,
  `EntranceItem`, `EntranceSliver`) used by `StudioPage`,
  `StudioSliverPage` and the launch checks; `PorcelainMotion.stagger`.
- `lib/features/events/event_cover.dart` on every event card.
- Launch checks: seal, tally, narrow header; event editor narrow header.
- Dashboard: the Gallery card reads `galleryEventsProvider`; narrow hero
  buttons stack.
- `PorcelainSegmentedControl` measures its labels: padding gives way,
  then the track scrolls.
- Guest camera: still lens mark while opening; fade-through plaque.
- Tests: `quick_event_test.dart`, `quick_event_designs_test.dart`,
  `narrow_studio_test.dart`, `polish_test.dart`;
  `event_builder_test.dart` becomes `experience_tab_test.dart` (the
  builder's tests go with it); `events_flow_test.dart` creates events
  through the new flow. The screen catalog gains the three steps and can
  show any screen at any window size; the harness can record created
  templates in the test database. Goldens: 8 builder goldens removed, 6
  new-event goldens added, 47 changed (covers, launch checks, segmented
  controls, entrance-related pixel noise), every change reviewed.
- Documents: CR-003, S04-Q and notes on S02, S03, S05 and the shell in
  `UX_SCREEN_SPECS.md`, evidence AC-UXP-01 to AC-UXP-10.

### Problems met and how they were handled

- The pixel-contrast guideline samples a text's whole paint bounds, so a
  line half hidden under the first draft's fixed action bar measured
  1.18:1 (the bar against the card) at Android landscape. The screen was
  not exempted: nothing scrolls under a bar any more. The step's actions
  sit in a side pane on wide windows and follow the content on narrow
  ones.
- Creating from a ready-made design failed in a widget test: the harness
  kept templates in memory while the database enforces the event's
  template foreign key. The harness now records created templates in the
  test database when a test asks (`recordCreatedTemplates`).
- The phone margin first applied to narrow panes on a tablet (the
  settings list), moving its header out of line with the detail pane; it
  now depends on the window's width.
- Segmented controls first scrolled as soon as their comfortable width
  did not fit, clipping the gallery's filter on an iPad in portrait;
  their padding now gives way first.
- CI had been red since W1-W2 on one architecture rule: `main.dart`
  imported Flutter to prepare the browser's storage. That setup moved
  into `app/bootstrap.dart`, which now prepares the platform before it
  builds the composition root's overrides; `main.dart` imports the app
  layer only.

### Risks carried forward

- Device runs on an iPad and an Android tablet are owed for the new flow
  and the polish (BLOCKED here: no devices).
- The phone-sized layout serves split screen and the web demonstration;
  phones are not a release target.
- A failure between Create's two writes leaves an unused template in the
  library (CR-003, Consequences).

### Next

- The owner's review of CR-003; the remaining web items; M11 when the
  owner says so.

## EP09: accessibility sweep, pack goldens, device procedure, series close

- Date: 2026-10-22 (UTC)
- Authorised by: the owner's EP00 reply ("build ep01 - ep09"). This stage
  closes the Experience Pack series; work stops here for the owner's
  review before M11.

### Changes

- `test/widgets/guest_packs_accessibility_test.dart`: every pack and the
  second Retro Game Quest variant, at iPad portrait and Android
  landscape, on the welcome, review and finished screens, against the
  tap-target, label and text-contrast guidelines; and a whole session in
  every pack with reduced motion on (still countdown, nothing animating).
- Fixed on the way: Retro Film's muted text fell to 3.2:1 near the screen
  edges because pack backdrops faded into the pack's dark rail colour.
  Pack backdrops now glow between surface and canvas, the two grounds
  every text colour is checked on (`guest_theme_test.dart`); the 74 pack
  goldens were regenerated and reviewed.
- `docs/device_tests/EP_DEVICE_PROCEDURE.md`: the tablet procedure for
  every pack, Full Template, sound, reduced motion, the builder, the
  preview, children and missing assets.
- ADR-0017 sections 8 and 9, the acceptance summary for AC-EP01..AC-EP17
  in `docs/ACCEPTANCE_EVIDENCE.md`.

### Open for the owner

- Device runs (AC-EP16) on an iPad and an Android tablet.
- The ElevenLabs sound files (placeholders ship until then).
- Originality review sign-off (AC-EP17) and the optional event logo.

## EP07 and EP08: Event Builder, Experience panel, Full Experience Preview, recommendations

- Date: 2026-10-22 (UTC)
- Authorised by: the owner's EP00 reply (item 6, "Do what you
  recommend": the 8-step builder with the Experience tab as the
  customisation panel; "build ep01 - ep09").

### Changes

- Event Builder (`event_editor_screen.dart`, `EventBuilderStep`): new
  events walk eight steps; steps can be visited in any order; Save and
  check stores the event and opens its launch checks. Saved events open
  in the editor at the matching section.
- Experience panel (`editor/guest_tab.dart`): eight pack cards (each in
  its own colours and decorations) and a variant control; a live welcome
  and countdown preview; welcome, get-ready and finished words (the
  pack's words as hints); accent colour swatches readable for the pack;
  the nine countdowns by name; animation off, gentle or full; celebration;
  sound and volume; camera-focused or full template; guests may be
  children; Reset to pack defaults (keeps pack and variant); the finished
  screen's time. Switching pack keeps the event's words, templates,
  camera and other settings.
- Template recommendations (`template_recommendations.dart`): templates
  made for the pack and variant, then the pack, then sharing a tag, come
  first with a "Suits <pack>" badge; every template stays addable. Tags
  are stored with templates created from starter designs or duplicated;
  the five original designs are tagged too.
- Full Experience Preview (`experience_preview_screen.dart`,
  `preview_services.dart`, route `/studio/events/experience-preview`): the
  whole journey on the real guest screens with a sample camera, portrait
  or landscape, any pack, Restart and Close, and a ribbon on every screen;
  nothing is stored, sent or captured. Opened from the Experience tab and
  the builder's Preview step.
- Fixes on the way: the builder's step header measured as low contrast
  because full-width text rows sit over the textured canvas; the header
  now hugs its words. The preview's ribbon wraps at 200% text.

### Not built

- Optional event logo (prompt section 11): needs an asset import and a
  place in the packs' layouts; recorded in ADR-0017 for the owner.

## EP06: every pack on the shared guest screens, and the Live Template camera

- Date: 2026-10-22 (UTC)
- Authorised by: the owner's EP00 reply ("build ep01 - ep09").

### Changes

- `GuestTheme` (`lib/core/experience/guest_theme.dart`): a pack becomes
  the Porcelain token set the shared guest screens read; the three
  original looks keep their audited palettes exactly; derived palettes
  are held to the guest text contrasts. `GuestExperienceScope` gives Booth
  Mode, the dashboard preview and the event editor's preview the event's
  pack.
- Words: every guest screen reads the frozen pack's words
  (`context.guestCopy`): welcome, get ready, review, keep, retake,
  finished, saved, next guest, choose and texting. Event customisations
  still win (the welcome title, a custom Start label).
- Buttons: the guest screens use `GuestButton` faces (review, finished,
  notices, template choice, texting); presses sound the pack's press cue
  when sound is on; a disabled button says why when tapped, as before.
  The Porcelain family keeps its round Start button, which now wraps a
  long word ("Once upon a photo") instead of shrinking it.
- Countdown: the camera's plaque shows the pack's preset
  (`GuestCountdown`); the Porcelain Press numeral is larger, Gala
  Elegant's hairline numeral larger and fully visible after a quarter of
  each second.
- Decorations (`lib/shared/guest/guest_decorations.dart`): fourteen
  code-drawn decorations from the pack's colours, at the corners, never
  hit-tested or read out; the retro emblems sit at the bottom corners,
  clear of titles; unknown ids draw nothing.
- Live Template camera (`lib/core/experience/live_template.dart`): Full
  Template mode shows the session's template around the live picture,
  compiled by the export's own scene compiler, photos already taken in
  their slots (`SessionShots.takenBindings`), artwork above the active
  slot drawn over the live picture. `paintScene` gains an `include`
  filter used only here. Image-masked slots and load failures fall back
  to the camera-focused stage; nothing waits for it. The camera frame now
  keeps the picture's shape inside its rim, so a template page shows no
  gap.
- Default camera stage is camera-focused (v8 seed and constants updated).
- Review screen: each photo's cell measures its controls (a pack's button
  face can be deeper), so the "retakes left" line is never cut off or
  covered; the line clears the button's shadow.

### Fixed on the way

- Full Template failed on every shot before the last: it asked for the
  complete slot bindings, which throw until every shot is taken. Found by
  the new journey test; `takenBindings` gives the photos taken so far.

### Tests

- `test/widgets/guest_packs_test.dart`: all eight packs and every variant
  run the whole journey on the simulated camera in portrait and
  landscape; each export request is identical; Full Template shows the
  live stage for both photos and prints the same.
- `test/experience/live_template_test.dart`, `guest_theme_test.dart`.
- `test/goldens/guest_packs_golden_test.dart`: nine looks x welcome,
  countdown, review, finished x two orientations, plus Full Template
  (74 half-resolution goldens, reviewed).

## EP04 and EP05: Kid Party Arcade, Retro Game Quest and 14 starter designs

- Date: 2026-10-22 (UTC)
- Authorised by: the owner's EP00 reply ("build ep01 - ep09"; item 7 for
  the children setting). Both stages are delivered together because they
  share the art library, the template fonts and the starter-design
  changes.

### Changes

- Art (`lib/core/design_system/party_art.dart`, original, code-drawn,
  fixed seeds): balloons, confetti, stars and bunting; pixel hearts,
  coins and sparkles, a stepped pixel border and a lit marquee. Rendered
  to ten new template decorations by `tool/art/decorations.dart`, offered
  in the editor (`bundled_decorations.dart`), provenance and hashes
  recorded.
- Template fonts: Courier Prime, Fredoka, Pixelify Sans, Poiret One and
  Monoton join Inter and Cormorant Garamond as template families (the
  variable faces at their default weight, so the renderer needs no
  change); the editor offers them in two rows.
- Starter designs: six Kid Party Arcade (Balloon Bash, Confetti Strip,
  Superstar, Bunting Party, Sticker Grid, Birthday Square) and eight
  Retro Game Quest (Player One Strip, Bonus Round, Scoreboard, Level Up,
  Marquee, High Score Strip, Co-op Mode, Game On), covering every print
  format, each an ordinary editable document with recommendation tags
  (`StarterDesign.tags`, used in EP08). Confetti deliberately crosses
  photo edges (decorations are never clipped by slots).
- Children (decision 4.7): an event switch "Guests may be children" in the
  guest tab, turned on when Kid Party Arcade is chosen
  (`ExperienceRegistry.childrenPackIds`); the texting screen then shows "A
  parent or guardian enters the number and gives consent." The consent
  checkbox, its text and the delivery flow are unchanged.
- `docs/experience_packs/ORIGINALITY_REVIEW.md`.

### Not yet

The packs' own guest screens (decorations, buttons, countdown, copy on
the live booth) arrive with EP06, which applies every pack to the shared
screens; the guest-journey tests per pack and orientation are part of it.

## EP03: countdown presets, guest sounds and the ElevenLabs sound sheet

- Date: 2026-10-22 (UTC)
- Authorised by: the owner's EP00 reply, items 3 and 4 (audio dependency
  approved; "Give me the script (I can give you a Eleven Labs SFX once you
  are ready").

### Changes

- `CountdownState` (domain): read from the guest flow, which the session
  controller already moves on monotonic timers; no timing changed.
- Nine countdown presets (`lib/shared/guest/guest_countdown.dart`):
  Porcelain Press, Vintage Flip, Film Leader, Disco Pulse, Storybook
  Magic, Party Pop, Arcade Start, Handheld Boot and Gala Elegant. Each
  draws the state only, has a still form (reduced motion or the pack's
  animation off) and at most one gentle swell a second.
- Sound: `GuestSoundService` port, `SilentGuestSoundService` (default and
  tests) and `AudioplayersGuestSoundService` (`audioplayers` 6.8.1, MIT,
  pinned): small low-latency pools from bundled assets, an audio context
  that mixes with venue music without taking focus, every failure silent.
- `GuestCuePlayer` and `GuestCueScope`: Booth Mode sounds the session
  start, each countdown second (the last one "go"), the shutter and the
  finish (celebration or plain success), plus guest button presses, from
  the session's frozen experience at the event's volume. Booth Mode also
  provides the `GuestExperience` from here on (the screens use it in
  EP06).
- Packs: sound is opt-in for every pack (three packs had it on by
  default; changed so no event makes noise unasked), and each pack's
  sound map now follows the sound sheet (short taps for presses and
  ticks, chimes for start and success).
- Sixteen original placeholder sounds (`tool/audio/generate_sounds.py`,
  committed in EP02) and `tool/audio/import_sounds.sh` for the owner's
  ElevenLabs files; the brief is
  `docs/experience_packs/SOUND_SCRIPT_ELEVENLABS.md`.
- ADR-0017 (Experience Packs, including the audio decision).

### Not changed

The session controller, its timers, captures and haptics are untouched;
countdown graphics are guest widgets only and never reach the renderer.
The guest camera screen still shows the M07 numeral; it switches to the
pack's preset in EP06.

## EP02: guest buttons, guest tokens, guest fonts and operator polish

- Date: 2026-10-22 (UTC)
- Authorised by: the owner's EP00 reply, items 1, 2 and 5 ("HYPER POLISH
  UP the OPERATOR LOOKS", "Polish up darkroom UI/UX", "add open license
  fonts"). The prompt's AC-EP02 ("both operator UI appearances remain
  unchanged") is overridden by this explicit instruction; the polish keeps
  every layout, control and word structure and changes materials only.

### Changes

- Guest presentation (`lib/core/experience/guest_experience.dart`):
  `GuestTokens` (colours, fonts, button family and touch minimum from a
  frozen `ResolvedExperience`), `GuestFonts` (font ids to families; the
  variable Fredoka and Pixelify Sans get their weight axis; display-only
  faces never set running text) and the `GuestExperience` inherited
  widget, which falls back to Porcelain Classic and turns animation off
  whenever reduced motion is asked for.
- `GuestButton` (`lib/shared/guest/guest_button.dart`) with six faces
  (`guest_button_faces.dart`): porcelain (glazed pill, gilded edge, rim
  light), wood (honey plank, grain, bevel, brass pins), toy arcade (candy
  top on a thick base that sinks when pressed), retro game (stepped pixel
  corners, heavy outline, hard shadow the face covers when pressed), gala
  (crisp rectangle, double gilt rule, spaced capitals) and neon party
  (glass pill in a glowing tube that brightens on press). One API: label,
  icon, emphasis, size (72, 88 or 112 points, never below the pack's
  minimum), busy, disabled with a reason, selected (with a check mark),
  keyboard focus ring. Primary uses the pack's accent and on-accent,
  secondary its panel and ink, so contrast never depends on the family.
- Fonts: Courier Prime, Monoton, Fredoka, Poiret One and Pixelify Sans
  (SIL OFL 1.1, google/fonts commit `45e3d52`), registered in
  `pubspec.yaml`, licences on the app's licence page, provenance and
  hashes in `docs/ASSET_PROVENANCE.md`.
- Operator polish, all three appearances (`StudioMaterial`): Porcelain
  Studio gets a soft light pool and a glaze band on the canvas; Light Oak
  a linen weave on the canvas and oak grain with knots on the sidebar;
  Darkroom Walnut a warm safelight glow, a vignette and fine paper grain
  on the canvas and walnut grain on the sidebar. Painted once per size
  behind the Studio shell, the sidebar, the event editor, the launch
  checks and session detail; never hit-tested or read out; deterministic.
- Darkroom polish: a warm brass rim light on raised surfaces (was 8 %
  white, nearly invisible) and slightly firmer card edges; both are
  decorative tokens (no text pair changes; the contrast test passes).
- Dashboard honesty: the Camera tile reports the tablet's real camera
  permission and lens (it said "Camera tests arrive with the camera
  service (M06)"), and the Storage tile the real free space and about how
  many sessions fit. Stale milestone text removed from the event editor.

### Not changed

Guest screens still use the M07 components; they switch to `GuestButton`
and the pack tokens in EP06. No camera, rendering, delivery or storage
behaviour changed.

## EP01: Experience Pack model, registry, event experience and schema v8

- Date: 2026-10-22 (UTC)
- Authorised by: the owner's reply to EP00 ("approve EP01 with your
  recommendations ... 8. build ep01 - ep09"), which accepts decisions 4.1
  to 4.8 of `docs/experience_packs/EP00_INTEGRATION_PLAN.md`. EP01 to EP09
  run in sequence before M11; each stage is reported, then work stops
  after EP09.
- Host: the same Linux cloud session. No tablet, no Mac.

### Plan (as executed)

1. Domain model with no Flutter imports (`lib/domain/experience/`): the
   catalog of preset, sound, decoration and font ids; the versioned
   `ExperiencePack` document and its JSON form; `EventExperienceConfiguration`
   (what the operator chose); the eight bundled packs as data; the
   registry that validates packs and resolves a configuration into a
   `ResolvedExperience` with every fallback reported.
2. Persistence: schema v8 replaces `events.theme_override` with
   `events.experience_json` and adds `templates.tags_json`; the migration
   keeps every guest's look (decision 4.2).
3. Sessions freeze the resolved experience inside their immutable plan.
4. Until the guest screens read packs (EP06), screens keep showing the
   matching original appearance; the guest tab picks a pack and variant.

### Changes

- New: `domain/experience/experience_catalog.dart`, `experience_pack.dart`,
  `experience_configuration.dart`, `bundled_packs.dart`,
  `experience_registry.dart`; `domain/template/template_tags.dart`.
- `BoothEvent.experience` replaces `GuestSettings.themeOverride`; new
  drafts take the booth's look (`ExperienceRegistry.forAppearance`); the
  event service moves the experience revision on with every change to it.
- Schema v8 (`booth_schema.drift`, `booth_database.dart` step `from7To8`,
  `drift_schema_v8.json`, generated steps and test schema, `seed_v8.sql`):
  an override keeps its look (Light Oak to Vintage Light Wood, Darkroom
  Walnut to Porcelain Classic "Darkroom", Porcelain Studio to Porcelain
  Classic), no override takes the booth's look the same way. The JSON
  written is spelled out in the step so it never depends on later codecs;
  a test checks it still reads back as `forAppearance` gives.
- `SessionPlan.experience`: resolved at session start and stored in the
  plan JSON, which a trigger already makes immutable, so editing an event
  never changes a running or finished session. A plan from before
  experiences, or with an unreadable snapshot, opens with none; the
  session keeps its photos.
- Interim presentation: `ExperienceRegistry.legacyAppearance` maps a
  configuration back to the original appearance for Booth Mode, the
  dashboard preview and the guest tab preview; packs with no original
  appearance show the booth's until EP06. The guest tab lists every pack
  and variant (ten cards).

### Deviations from the EP00 plan

- The plan proposed keeping `theme_override` read-only for one version
  and adding `capture_sessions.experience_snapshot`. The migration is
  lossless and total, so the old column is dropped in the same rebuild;
  the snapshot lives in the already-immutable plan JSON instead of a new
  column (no new trigger, same guarantee).
- Porcelain Classic's "none" mapping follows the booth for all three
  appearances (the plan's table named only Light Oak), which is what "so
  nothing a guest sees changes" requires for a Darkroom booth.

## M10: commercial resilience, security, backup and kiosk readiness

- Date: 2026-10-19 (UTC)
- Authorised by: the owner's instruction "approve start M08-M10". M10
  scope only; after it, work stops for the owner's approval.
- Quality bar: CR-001 for the new operator screens (Settings > Backup,
  Settings > Kiosk lock, restoring from the first screen).
- Host: the same Linux cloud session as M00 to M09. No tablet, no Mac.

### Plan (as executed)

1. Backup and restore (AC-1006): a checked tar of the scrubbed database
   and chosen files; restore only into an empty booth, checked from end to
   end, swapped in before the database opens by starting the app again.
2. Kiosk and launch checks (AC-1002, AC-1003): a read-only bridge for the
   OS lock state, an in-app guide per platform, the deployment guide; the
   launch checks block only critical problems.
3. Recovery (AC-1004, AC-1005): a startup-only orphan sweep, backup
   working files discarded at start, and kill-at-each-stage tests; low
   storage reviewed end to end.
4. Logs, permissions, device backups, airplane mode (AC-1007): SafeLog and
   uncaught-error reporting, an architecture rule, the APK permission
   audit, iPadOS backup exclusion, network-free operation tests.
5. Guest isolation after crashes; privacy and retention documented for
   operators (AC-1008); ADR-0016, device procedure, evidence.

### Changes

- Backup: `infrastructure/backup/` (`tar_archive.dart`,
  `file_backup_service.dart`, `pending_restore.dart`,
  `backup_staging.dart`); `domain/backup/backup_manifest.dart`,
  `domain/services/backup_service.dart`; `core/backup/backup_providers.dart`;
  `shared/backup/backup_copy.dart`; `features/settings/backup_settings.dart`;
  `features/onboarding/restore_backup_panel.dart` and the first screen's
  restore entry and "Backup restored" step; `app/restartable_app.dart`
  (the app starts again in place); `ManagedArea.restore`; the operator
  file picker streams large files (`pickStream`) and shares files by path
  (`shareFile`).
- Kiosk: `domain/services/kiosk_lock.dart`,
  `infrastructure/device/platform_kiosk_lock.dart`, the `porcelain/kiosk`
  channel (Kotlin, Swift), `core/kiosk/kiosk_providers.dart`,
  `shared/kiosk/kiosk_copy.dart` and `kiosk_guide.dart`, Settings > Kiosk
  lock, the launch checks' "How to lock" sheet; the probe reads the lock.
- Launch checks: free space blocks only below one session
  (`STORAGE_FULL`), warns when low or unknown; kiosk passes only when the
  tablet reports a lock.
- Recovery: `StorageCleanup.sweepOrphans` (startup only; camera photos
  quarantined, never deleted); `BackupStaging.discard` in `prepare()`; a
  restore that could not finish its swap has its own startup message
  (`RESTORE_INCOMPLETE`).
- Low storage: a tablet that fills during a session sends the guest to
  the host (`STORAGE_FULL`) instead of offering a retry; the photos
  already taken stay saved.
- Logs: `core/diagnostics/safe_log.dart`, `error_reporting.dart`
  (installed by `bootstrap`).
- Permissions and device backups: `ACCESS_NETWORK_STATE` removed from the
  merged Android manifest; `tool/audit_permissions.sh` (CI); iPadOS
  storage root excluded from iCloud and computer backups at every start
  (`porcelain/device_storage` `excludeFromBackup`).
- Tests: tar, backup round trip and refusals, restart, backup and kiosk
  screens, preflight table, kiosk bridge and guide, SafeLog, error
  reporting, logging rule, permission audit, airplane mode, device backup
  exclusion, kill recovery matrix and sweep (disabling the sweep or the
  backup clean-up makes seven of them fail), crash isolation, a disk that
  fills mid-session, the restore-incomplete start; eight new catalog
  screens with goldens; existing goldens of the settings list and first
  screen updated.
- Docs: ADR-0016, `docs/KIOSK_DEPLOYMENT.md`,
  `docs/OPERATOR_PRIVACY_AND_DATA.md`,
  `docs/device_tests/M10_DEVICE_PROCEDURE.md`, this entry, evidence.

### Problems met and how they were handled

- The restore widget test waited for a spinner that the harness's counted
  restart never stopped: it now checks the restoring state and the restart
  request, and `RestartableApp` has its own test that starts a real scope
  again and waits for the database to close.
- Pushing a Settings route over the launch checks broke the navigator's
  page keys; the kiosk guide moved to `shared/` and opens in a sheet.
- `managed_storage_test` still listed eight areas after `restore` was
  added; CI #34 caught it (1 of 2,881 tests) and the test was corrected.
- The APK audit found `ACCESS_NETWORK_STATE` from CameraX's video library;
  removed, with the audit kept in CI.
- Throwing at a stage runs each layer's clean-up, which a kill does not,
  so the kill tests stop a file operation for good instead.
- ADR-0009 left the iPadOS backup exclusion to M10; done here. The
  privacy guide no longer claims deleting the app removes Keychain entries
  on iPadOS.

### Risks carried forward

- Every device behaviour is unverified: kill and power-loss recovery on
  real file systems, the kiosk bridge (and whether Single App Mode reads
  as Guided Access), the iCloud exclusion, backups of real events between
  tablets, low storage. All BLOCKED (M10 device procedure).
- No directory fsync after renames (no Dart API): an app kill cannot lose
  a rename; a power loss at that instant might on some file systems.
- The booth does not keep the screen awake in Booth Mode; operators set
  Auto-Lock to Never (kiosk guide). A wake lock is a candidate for M11.
- The Swift side (kiosk state, backup exclusion) has not been compiled:
  no macOS host. CI's iPadOS job is skipped without a macOS runner.

### Next

STOP for the owner's approval of M08 to M10. M11 (hardware certification
and endurance) needs the physical iPad and Android tablet.

## M09: optional phone delivery (MMS preview and private link)

- Date: 2026-10-19 (UTC)
- Authorised by: the owner's instruction "approve start M08-M10". M09
  scope only: the optional texting feature, off by default, implemented
  and tested with stand-ins; every live gate (domain, backend project,
  Twilio account and registration, legal review, tablets, phones) is
  BLOCKED and recorded as such. Nothing is deployed and the feature is
  not advertised as working.
- Quality bar: CR-001 for S30 to S36; the guest screens follow the
  owner's booth boards (Porcelain Studio guest theme).
- Host: the same Linux cloud session as M00 to M08. No tablet, no Mac, no
  phone, no Twilio account.

### Plan (as executed)

1. Inventory of prerequisites (`docs/delivery/PREREQUISITES.md`): all
   live items BLOCKED. Threat model, ADR-0015, OpenAPI contract.
2. Backend (`backend/`): Postgres schema v1 (tenants, booths, pairing
   codes, tokens, jobs, consent receipts, upload and access grants,
   suppression, provider events, audit, rate counters); pairing and
   tokens; intake with quotas; uploads validated against their
   declarations; a leased dispatcher that retries only after a definite
   non-submission, with reconciliation and operator review for unknown
   outcomes; Twilio webhooks verified with the official validator;
   STOP/START/HELP; the preview fetch and the guest page; retention; the
   admin API; staging limited to approved test numbers.
3. Booth: domain (E.164 parsing shared with the backend's cases, consent
   text and digest, settings, intents, retry policy); schema v7 queue;
   secure storage for the credential and pending numbers; the HTTP client;
   `DeliveryService` and `DeliveryRunner`.
4. Screens: S30 to S32 in Booth Mode (both orientations, every size),
   S34 Event > Texting, S35 a session's Texts, S36 Settings > Phone
   delivery.
5. Tests: backend (Deno, real Postgres), booth unit, database, client,
   service, widget flows, operator screens, the app-to-backend contract
   run; the screen catalog and goldens; docs (setup, operations, privacy
   draft, device procedure); checks, builds, a secrets scan of the APK.

### Changes

- Backend: `backend/` (migration, Edge Function and shared modules,
  OpenAPI, tests, tools, README); CI job "Delivery backend".
- Domain: `delivery/phone_number.dart`, `consent.dart`,
  `delivery_settings.dart`, `delivery_intent.dart`,
  `delivery_policy.dart`; `services/delivery_api.dart` (port, models,
  `deliveryAddressAcceptable`); `repositories/delivery_repository.dart`;
  `BoothEvent.delivery`.
- Infrastructure: schema v7 (`event_delivery_options`,
  `delivery_pairings`, `delivery_intents`, `delivery_remote_revocations`)
  with dump, steps, test schemas and `seed_v7.sql`;
  `database/drift_delivery_repository.dart`; the gallery's deletion now
  journals remote revocations; `delivery/secure_delivery_secrets.dart`,
  `delivery/jpeg_preview_maker.dart`, `delivery/http_delivery_api.dart`.
- Core: `delivery/delivery_service.dart`, `delivery_runner.dart`,
  `delivery_providers.dart`, `diagnostic_image.dart`; providers and
  bindings; the runner starts after startup; `BoothSessionController.touch`
  keeps the finished screen alive while the guest types.
- Features and shared: `booth/guest_delivery.dart`, `delivery_copy.dart`,
  the finished screen's texting buttons, `booth_screen.dart`'s finished
  step; `events/editor/delivery_tab.dart`;
  `gallery/session_deliveries.dart`; `settings/delivery_settings.dart`;
  `shared/delivery/delivery_labels.dart`; delivery icons.
- Tests: `domain/delivery_rules_test.dart`,
  `delivery/delivery_service_test.dart`,
  `infrastructure/http_delivery_api_test.dart`,
  `delivery/live_contract_test.dart` (tag `contract`, run by
  `tool/delivery_contract.sh`), `widgets/guest_delivery_flow_test.dart`,
  `widgets/delivery_operator_test.dart`; migration test v7 checks;
  support: `fake_delivery.dart` (service stand-in, memory secure storage,
  preview stand-in, `seedPairing`, `seededIntent`); fourteen texting
  screens in the catalog with their goldens.
- Platform: the Android release manifest declares `INTERNET` (only
  debug and profile builds had it, for Flutter's tooling); cleartext stays
  off; nothing on iPadOS changes.
- Tools: `tool/delivery_contract.sh` (the app's client against the local
  backend), `tool/scan_binary_secrets.sh` (an APK, AAB or IPA searched for
  provider ids and keys, service keys, private keys and backend secret
  names; checked against a planted sample).
- Docs: ADR-0015 and index, `docs/delivery/` (README, PREREQUISITES,
  SETUP_AND_CREDENTIALS, OPERATIONS, PRIVACY_AND_RETENTION_DRAFT,
  THREAT_MODEL), `docs/device_tests/M09_DEVICE_PROCEDURE.md`.

### Problems met and how they were handled

- A Drift column typed `ENUMNAME(DeliveryIntentState)` got integer
  affinity because the type name contains "INT", so its CHECK rejected
  every name. The column is `TEXT` mapped by a converter.
- Generated table classes clashed with domain names (`DeliveryIntent`);
  the tables were renamed.
- Two queue passes could overlap when a guest submitted during a
  scheduled pass; `processDue` now runs one loop that repeats while asked
  to.
- Flutter's test binding answers every real HTTP request with 400; the
  client tests run a real local server with the binding's HTTP override
  lifted.
- The booth's own check that a service address is https lived only in the
  HTTP client, so a stand-in service accepted `http://`. The check moved
  to the domain and runs before pairing.
- The guest's info card had a "Close" button, a word the guest-isolation
  check forbids (it reads as leaving the booth). It says "OK".
- The session page's empty Texts section still took a section's spacing,
  moving every session golden; the section is now left out when empty.
- The Android release manifest had no `INTERNET` permission (debug and
  profile builds add it for Flutter's tooling, which hid the gap): a
  release build could never have reached the service. Found while writing
  the evidence; declared in the main manifest.
- A service that no longer holds a delivery made the booth call it
  "Expired", which claims more than is known. The last report now stands,
  with a note; schema v7's finished-state check admits that case.
- The confirmation card faded in from opacity 0, which hides its
  semantics for the first frame, while the entry behind it stayed
  readable to screen readers. The card is in the accessibility tree from
  the first frame and the entry is hidden behind it.
- Dead-control checks found the keypad's Clear and Delete keys and the
  link-life stepper at its limit disabled without a reason; each now says
  why.
- The number screen's corner blossoms sat behind the title in portrait
  (CR-001); dense guest screens now keep two small corner sprays only.
- CI #32 failed one backend test: the log redaction's phone pattern
  matched a digit run inside that run's random UUID. Ids must stay
  readable for support, so the pattern may no longer start or end inside
  an identifier and UUIDs are set aside before redaction; the test checks
  2,000 random UUIDs as well.
- Backend: Twilio's error is in `error.cause` for refused connections;
  the expiry comparison lost milliseconds through `String(Date)`; the
  phone redaction left a bracket behind. Each found by a test and fixed.

### Spec issues raised

- PD-03 asks the booth to send while offline queues drain; neither
  iPadOS nor Android lets an app send reliably in the background, so the
  queue runs only while the app is in front, and guests are told the text
  may not arrive.
- "US mobile only": whether a number is a mobile is known only to the
  provider; the booth checks NANP shape and US area codes, and a landline
  fails at the provider with an honest message.
- The consent wording, retention periods and minors need the legal
  review (PRIVACY_AND_RETENTION_DRAFT section 7).

### Risks carried forward

- No live sender, phone, carrier or tablet: every live row of
  AC-0901..AC-0922 is BLOCKED; the device procedure is ready.
- Prices (PD-08) are the spec's October 2026 figures; re-check before
  launch.
- MMS transcoding and carrier filtering are unknown until real sends.
- iPadOS has still not been compiled (no Mac; CI's manual job not run).

### Next

M10 (resilience, security, backup and kiosk readiness), as the owner
approved; stop for approval after M10.

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

## 2026-10-24 — Occasion stickers and templates

Owner request: expand stickers and templates across party occasions, including weddings, birthdays, anniversaries, Easter and Christmas.

- Added 24 original transparent watercolor PNGs, 20 occasion collections and 48 editable portrait/strip presets. Includes four children's birthday themes and engagement, bridal shower, hen/stag, graduation, Halloween, New Year, Valentine, Thanksgiving, retirement, housewarming, christening, Diwali, Eid, Hanukkah and summer parties. Existing collections stay available.
- Shared occasion metadata drives asset registration and template construction. Chooser filters now derive from the catalog; both browsers search occasion aliases. Templates have native editable titles, captions, names/date, borders, mats and photo slots.
- Recorded exact image_gen prompts, immutable source PNG hashes and provenance. Built-in image_gen was used with transparency enabled; one transient network failure succeeded on retry. Added 44.0 MiB of bundled artwork; no runtime service, dependency or schema change.
- Visual verification caught overflowing titles in two existing baby-shower portraits. Reduced the long baby-title size while retaining the existing rendering assertions. Explicit golden regeneration now works on macOS; ordinary pixel comparison remains Linux-only.
- Validation on macOS: 228 selected tests passed (assets, all starter designs, editor/library, packages/repositories, recommendations and review-sheet rendering); 22 affected screen snapshots regenerated successfully at the existing iPad/Android viewport sizes. Formatting and static analysis passed. No physical-device certification was performed for this artwork update.
- Review: `build/local-verification/occasion-catalog/occasion-overview.png`, individual full-resolution prints in that folder, and `build/local-verification/atelier-catalog/sticker-overview.png`.

- PASS — `flutter build web --no-pub` (exit 0); all 24 new bundled PNGs match their recorded SHA-256 hashes in `build/web/assets/`. Build log: `build/local-verification/occasion-web-build.log`.

## 2026-10-26 — App flow audit and clean sticker placement

- Pulled the default branch (`claude/new-session-fh2zxl`, `8563d1c`); it was already merged into the working branch. Reviewed access/setup, Studio, three-step event creation, launch checks, guest capture/review/reset, operator reel, gallery/export and template editing.
- The artwork picker now preserves sticker intent. Stickers start at 24% of the shorter page side, within the print-safe margin, preferring clear space. Their full source image uses contain fitting so resizing cannot stretch or crop it. General-image behavior is preserved.
- Separated occasion header title/artwork boxes and aligned uniform sticker sizes/positions to print pixels. All 48 companions render without warnings; existing parity tolerances and negative controls remain unchanged.
- Validation: 691 focused app/domain/renderer tests; 80 chooser/library/editor screen checks including 200% text and accessibility; 30 final placement/library/screenshot tests; four production-font editor screenshots; static analysis and formatting. Web build compiled. The broad full-suite attempt encountered host timeouts and is not counted as a full-suite pass.
- Detailed audit, source paths, evidence and scope limits: `docs/APP_FLOW_AUDIT_2026-10-26.md`. Pre-existing uncommitted startup/storage/onboarding work was preserved.
