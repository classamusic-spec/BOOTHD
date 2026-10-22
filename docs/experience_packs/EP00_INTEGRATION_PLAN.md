# EP00: Experience Pack System v2.0, integration plan

- Date: 2026-10-22. Scope: EP00 only (inspect and plan). No code changed.
- Source: the owner's "Experience Pack System v2.0" master prompt (P0, first
  commercial release).
- Repository state inspected: `0b501eb` (M00 to M10 complete, CI #36
  green). Checked: `CLAUDE.md`, ARCHITECTURE A-06/A-10/A-11/A-14,
  ADR-0004, ADR-0008, ADR-0010, ADR-0013, ADR-0016, and the code listed in
  section 2.
- Status: **waiting for owner decisions (section 4) and approval before
  EP01.**

## 1. Summary

Most of what the add-on needs already exists and is shared: one guest
state machine, one camera service, one scene graph and renderer, one
delivery and consent flow, one storage and recovery layer. The add-on adds
a **presentation layer** on top of these, not a second guest app:

- a versioned, declarative `ExperiencePack` registry of eight bundled
  packs (data plus predefined Dart components, no executable content);
- an `EventExperienceConfiguration` stored with each event and a
  **snapshot frozen into each guest session** when it starts;
- a guest presentation context (`GuestExperience`) that every existing
  guest screen reads for tokens, copy, its button family, countdown,
  decorations, sounds and celebration;
- a countdown presentation layer over the controller's existing
  authoritative, monotonic countdown;
- **Live Template Camera** mode, which needs a narrow extension of the
  shared scene painter (paint layers below and above the active slot);
- an Experience Builder and Full Experience Preview for operators;
- template recommendation metadata and 14 original starter templates.

Seven decisions need the owner before EP01 (section 4). The most
important: the app already has **three** operator appearances, not two
(4.1), there is no audio playback library yet (4.3), and new fonts and
sounds need a provenance route (4.4, 4.5).

## 2. What exists and is reused

| Need | Already in the app | Where |
| --- | --- | --- |
| Guest state machine (Welcome → Template choice → Get ready → Countdown → Capture → Between shots → Review → Rendering → Finished → Delivery) | `GuestFlow`, stages `idle … completed`, paused and problem states; tested end to end | `lib/domain/session/guest_flow.dart`, `lib/core/booth/booth_session_controller.dart`, ADR-0013 |
| Authoritative countdown, independent of animation | Controller timers, cancelled on any stage change, pause or app exit; no capture unless the booth is in front | `booth_session_controller.dart` (`_enter`, `_cancelTimers`, lifecycle handling) |
| Session snapshot | A session freezes its plan (template revision, shot count, settings) when it starts | `lib/domain/session/session_plan.dart`, `capture_sessions` |
| Guest screens, both orientations, every size | Welcome, template choice, camera stage, review, finished, texting (S21 to S32) with adaptive portrait and landscape layouts | `lib/features/booth/*`, `lib/shared/guest/*` |
| Event-level guest look | `GuestSettings.themeOverride` (one of the three theme profiles) and welcome title and message | `lib/domain/models/booth_event.dart`, `BoothEventTheme`, Event > Experience tab |
| Operator appearances | `PorcelainThemeProfile`: Porcelain Studio, Light Oak, **Darkroom Walnut**, each with high contrast | `lib/core/design_system/theme_profiles.dart` |
| Tactile controls | `PorcelainButton` (raised, pressed, disabled, busy, focus, disabled reason), `TactileSurface`, guest start button | `lib/shared/widgets/*`, `lib/shared/guest/guest_start_button.dart` |
| Reduced motion, contrast, labels, 72-point guest targets | Appearance settings; screen catalog checks layout, 200% text, contrast in three themes, tap targets, labels and dead controls for every screen | `test/widgets/screens_test.dart`, `test/support/screen_catalog.dart` |
| Scene graph, renderer, slot clipping, z-order | One painter for preview, editor and export; photos clipped to their own slot only; parity tests | `lib/core/composition/scene_painter.dart`, ADR-0010 |
| Layered editable templates, bundled decorations | Template document v1, starter designs, generated transparent decorations with provenance, Template Studio | `lib/domain/template/*`, `lib/core/templates/starter_designs.dart`, `tool/art/`, `docs/ASSET_PROVENANCE.md` |
| Delivery and consent | One consent flow and queue for every event; offline-safe | ADR-0015, `lib/features/booth/guest_delivery.dart` |
| Simulated camera and preview | `SimulatedCameraService` (tests), operator guest-welcome preview (`/preview/guest-welcome`) | `test/support/simulated_camera.dart`, `guest_preview_screen.dart` |
| Haptics | Countdown ticks and PIN pad | `booth_session_controller.dart` `_haptic` |

## 3. Gaps the add-on fills

1. **No pack model or registry.** Guest look is limited to one of three
   palettes; copy is two fields; countdown, buttons, decorations and
   sounds are fixed.
2. **No sound playback.** The project has no audio package (only
   `HapticFeedback`).
3. **The camera stage shows the live picture alone**, with saved shots as
   thumbnails. The selected template is not drawn around the live slot.
4. **Template metadata** has one free `category` (40 chars) on the
   template row; no tags, recommended experiences or capture count.
5. **No guided event creation.** Events are made then edited in a tabbed
   editor (Event, Experience, Templates, Camera, Output, Privacy,
   Texting).
6. **Preview** covers the welcome screen only; no simulated full
   journey.
7. **Fonts**: Inter and Cormorant Garamond only; no display faces for
   pixel, party or Art Deco styles.

## 4. Decisions needed before EP01

Each has a recommendation; nothing is built until the owner answers.

### 4.1 Operator appearances: two named, three exist

The prompt approves "Clean Porcelain" and "Vintage Light Wood" and forbids
redesigning them. The app also ships **Darkroom Walnut** (dark retro),
used as an operator appearance and as an event guest theme.
**Recommendation:** keep all three operator appearances exactly as they
are ("Clean Porcelain" = Porcelain Studio, "Vintage Light Wood" = Light
Oak). Removing Darkroom Walnut would change approved, shipped behaviour;
the add-on does not touch operator appearance at all.

### 4.2 What happens to existing events' guest theme

`GuestSettings.themeOverride` becomes the pack choice. **Recommendation**
(schema v8 migration, lossless, tested):

| Stored today | Becomes |
| --- | --- |
| none (same as the booth) | `porcelain-classic`, or `vintage-oak` when the booth appearance is Light Oak, so nothing a guest sees changes |
| Porcelain Studio | `porcelain-classic` |
| Light Oak | `vintage-oak` |
| Darkroom Walnut | `porcelain-classic` variant "Darkroom" (keeps today's exact palette) |

### 4.3 Sound playback needs one new dependency

Flutter cannot play bundled audio on its own. Options: `audioplayers`
(MIT, maintained by Blue Fire), `just_audio` (MIT), or a narrow native
bridge (Android `SoundPool`, iOS `AVAudioPlayer`). **Recommendation:**
`audioplayers` behind a `GuestSoundService` port, its version pinned and
licence recorded in EP03 (ADR, dependency licence report). Sounds are
short, preloaded, fire-and-forget; a failure is silent and never touches
a transition. Alternative if no new dependency is wanted: haptics only in
the first release.

### 4.4 Original sounds

**Recommendation:** generate every sound in-repo from a script
(synthesised tones and noise envelopes, like the generated decorations
under `tool/art/`), so provenance is "authored here" with no third-party
licence. Each WAV is small (under 50 kB) and listed in
`docs/ASSET_PROVENANCE.md`.

### 4.5 Display fonts

Pixel-style, party and Art Deco headings need faces the app does not
have. **Recommendation:** bundle a few SIL Open Font License faces after
checking each licence file (candidates: Pixelify Sans or Silkscreen for
Retro Game Quest, Fredoka for Kid Party Arcade, Poiret One or Limelight
for Midnight Gala), recorded like Inter. Pixel text never goes below
24 logical points on guest screens, and body copy stays in Inter.
Alternative: original bitmap numerals drawn in-repo for countdowns only.

### 4.6 Guided creation versus the tabbed editor

**Recommendation:** a new 8-step **Event Builder** for *new* events
(the prompt's steps 1 to 8) that writes the same `BoothEvent`. Editing an
existing event keeps the tabbed editor, whose Experience tab becomes the
full customisation panel (pack, variant, copy, colours, countdown,
sound, motion, celebration, camera layout, reset to defaults). One model,
two entry points; no JSON editing anywhere.

### 4.7 Children and texting consent

Consent stays exactly as approved (ADR-0015). **Recommendation:** an
event switch "Guests may be children" (on by default for Kid Party
Arcade) adds one line to the texting screens, "A parent or guardian
enters the number and gives consent", and the consent text version
changes accordingly. The legal review already BLOCKED for texting covers
this wording. No flow, storage or sending change.

### 4.8 Where the EP series sits in the milestone order

**Recommendation:** run EP01 to EP09 now, between M10 and M11, as one
add-on series that extends M02 (design system), M03 (event setup), M05
(templates), M07 (guest flow) and M09 (delivery copy) in place. M11
(hardware certification) then certifies the packs on the tablets too.

## 5. Architecture

### 5.1 Three independent layers (unchanged boundaries)

| Layer | Owner | Changed by the add-on |
| --- | --- | --- |
| Operator appearance | Booth profile (`PorcelainThemeProfile`) | No |
| Guest experience | Event `experience` configuration, frozen per session | New |
| Photo template | Template library, chosen per event or by the guest | Metadata only (tags, recommendations) |

The final photo is always rendered from the template document alone.
Experience decorations, countdowns and guest messages live in the guest
UI layer and **cannot reach the export**, because the renderer never
receives them (a test proves the bytes are identical across all eight
packs, section 7).

### 5.2 Domain (pure Dart, `lib/domain/experience/`)

- `ExperiencePack`: `schemaVersion`, `packId`, `packVersion`,
  `displayName`, `description`, `themeFamily`, `variants`
  (`PackVariant`: id, name, overrides), `tokens` (`GuestTokens`: palette
  roles, radii, depth), `typography` (font refs), `layoutPresetIds`,
  `buttonStyle` (`GuestButtonStyle` enum: porcelain, wood, toyArcade,
  retroGame, gala, neonParty), `copyDefaults` (`GuestCopy`: welcome,
  start, get ready, between shots, review, keep, retake, finish,
  delivery prompt), `countdownPresetId`, `transitionPresetIds`,
  `shutterEffectPresetId`, `soundPresetIds`, `celebrationPresetId`,
  `decorations` (asset refs per screen region), `orientations`,
  `accessibilityDefaults`, `recommendedTemplateTags`,
  `customizable` (set of `ExperienceSetting`).
- `ExperiencePackRegistry`: the eight bundled packs; looks up by id and
  version; `resolve(config)` returns a `ResolvedExperience` or a typed
  `ExperienceProblem` (unknown pack, unknown version, unknown preset,
  missing asset, unsupported orientation) with a safe fallback to
  Porcelain Classic. Pure and exhaustively tested.
- `EventExperienceConfiguration`: pack id and version, variant, colour
  overrides (only roles the pack marks customisable, contrast-checked),
  welcome, get-ready and finish text, countdown preset override, sound on
  and volume, animation intensity (off, gentle, full), celebration on,
  camera stage mode (`fullTemplate`, `cameraFocused`), recommended
  template ids, `revision`. Validated by `EventRules` like other settings.
- `CountdownPreset`: id, lead-in text, per-number presentation, final
  word, sound cue ids, reduced-motion form. **Timing is never in the
  preset**: seconds come from the event (`countdownSeconds`, 2 to 10) and
  ticks from the controller.
- Packs are Dart `const` data plus a JSON manifest per pack under
  `assets/experiences/<packId>/manifest.json`, validated at startup and
  in a test. Only listed bundled assets and predefined components are
  allowed; manifests cannot name code, URLs or files outside their
  folder.

### 5.3 Persistence (schema v8, one migration)

- `event_experiences` (event id, configuration JSON with its own
  `schemaVersion`, revision), filled from `themeOverride` by the
  migration in 4.2; `themeOverride` kept read-only for one version, then
  dropped in a later migration.
- `capture_sessions.experience_snapshot` (JSON): the resolved
  configuration (pack id, version, variant and every override) frozen at
  session start, so editing the event never changes a running session
  and the gallery can show what the guest saw.
- `templates.tags` (JSON: category, occasion, style tags, recommended
  experience ids, age notes, default capture count, optional variant).
  Bundled starter templates carry them; imported packages may.
- Migration, dump, steps and seed as for v2 to v7; backups carry the new
  tables automatically (manifest `schemaVersion` 8).

### 5.4 Presentation (`lib/core/experience/`, `lib/shared/guest/`)

- `GuestExperience` (inherited widget, from the session snapshot, or
  from the event before a session starts) provides tokens, copy,
  `GuestButton` (one semantic API: label, icon, onPressed, busy,
  disabled reason, selected; six presentations), countdown presenter,
  decoration layer, celebration overlay and sound cues.
- Existing guest screens are refactored once to read from it. **No
  screen is duplicated per pack**; packs differ by data and by the six
  button presenters, countdown presenters and decoration layers.
- `GuestButton` keeps every state the current `PorcelainButton` has
  (raised, pressed with displacement, disabled with reason, loading,
  selected, focus ring) and the guest minimum of 72 points, larger where
  the layout allows; depth always comes with a border and label, never a
  shadow alone.
- Decorations draw in a separate `RepaintBoundary` from the camera and
  from controls; images are decoded once at display size and cached;
  animated decorations are capped (at most a handful of moving objects,
  none while capturing) and stop entirely with reduced motion.
- Sounds: `GuestSoundService` port, preloaded per pack, played without
  awaiting, muted by the event, the booth's reduced-stimulation setting
  or a failed load.

### 5.5 Countdown engine

The controller already owns the countdown (monotonic timers, cancelled on
any stage change, pause, app exit or operator exit, no capture while not
in front). EP03 makes this explicit and testable: a `CountdownState`
(remaining, total, started at) published by the controller; presenters
only render it. A dropped frame or a presenter exception cannot move the
capture; a test forces presenter failures and checks capture times.
Nine bundled presets (Porcelain Press, Vintage Mechanical Flip, Film
Leader, Disco Pulse, Storybook Magic, Party Pop, Arcade Start, Handheld
Boot, Gala Elegant), each with a reduced-motion and a silent form. No
flashing: the brightest change per second is bounded and checked in
tests (WCAG 2.3.1, no more than three flashes a second).

### 5.6 Live Template Camera

- **Full Template mode:** the stage paints the selected template at the
  stage's size with the shared painter in two passes: layers below the
  active photo slot, then the live camera clipped to that slot's shape
  (rectangle, rounded or ellipse), then layers above it, so transparent
  foreground art overlaps the live picture by z-order exactly as in the
  export. Earlier slots show their saved originals through the same
  crop and focal settings; later slots show placeholders. This needs a
  layer-range option on `ScenePainter` (no change to how anything is
  painted; parity tests guard it).
- **Camera-Focused mode:** today's large live picture with the template
  as a small guide.
- Mask-shaped slots in Full Template mode fall back to Camera-Focused for
  that shot (a live mask needs a shader pass whose cost is unproven on
  tablets; revisited in EP09 with device numbers).
- Preview mirroring and the slot's crop follow ADR-0012; the saved
  original never changes.

### 5.7 Event Builder and Full Experience Preview

- Builder steps 1 to 8 as in the prompt. Switching packs keeps every
  other event and template setting; Reset to Pack Defaults resets only
  experience fields.
- Preview runs the real guest screens with a `SimulatedCameraService`,
  sample photos, an in-memory session repository and a no-op delivery
  service, inside a separate provider scope; a "Preview" ribbon is always
  visible; nothing is written to the booth database or sent. Tests prove
  isolation (no rows, no files, no delivery calls).

### 5.8 Starter templates

14 original templates (Kid Party Arcade 6, Retro Game Quest 8) built as
ordinary editable template documents with generated decorations (stars,
balloons, confetti, pixel hearts, HUD bars, coins, badges), produced by
`tool/art/` scripts like today's florals, with provenance entries. No
logos, characters, handheld silhouettes, game fonts or screens are copied;
the console and cabinet shapes are generic rounded forms.

## 6. Files affected (expected)

- New: `lib/domain/experience/*`, `lib/core/experience/*`,
  `lib/shared/guest/guest_button.dart` and presenters,
  `lib/shared/guest/countdown/*`, `lib/shared/guest/decor/*`,
  `lib/features/events/builder/*`, `lib/features/booth/experience_preview/*`,
  `lib/infrastructure/audio/*`, `assets/experiences/**`, `assets/fonts/*`
  (if 4.5 approved), `tool/art/*` generators, tests and goldens.
- Changed: `booth_event.dart` (experience configuration),
  `event_rules.dart`, `booth_schema.drift` (v8) and generated files,
  session repository (snapshot), `booth_session_controller.dart` (publish
  `CountdownState`, snapshot at start; no timing change), every guest
  screen in `lib/features/booth/` and `lib/shared/guest/` (read the
  experience), `scene_painter.dart` (layer range), event editor
  Experience tab, template repository and library (tags), delivery copy
  (4.7), screen catalog and goldens.
- Unchanged: camera service, originals, renderer output, export, gallery,
  delivery service and backend, storage and recovery, operator theme.

## 7. Milestones and acceptance

Each stage: format, analyze, tests, Android builds, evidence with
PASS/FAIL/BLOCKED, then stop for approval.

| Stage | Delivers | Proven by |
| --- | --- | --- |
| EP01 | Pack schema, eight pack manifests (data only), registry, validation, fallback, `EventExperienceConfiguration`, schema v8 migration and session snapshot | Manifest validation (every pack, every bad case), migration test from v7 with every `themeOverride`, snapshot unchanged by later event edits, backup round trip on v8 |
| EP02 | `GuestButton` with six presenters, guest tokens per pack, `GuestExperience` context | Widget tests for every state per presenter, 72-point targets, focus and semantics, contrast per pack (computed), goldens of the button sheet |
| EP03 | `CountdownState`, nine presets, sound port and generated sounds, reduced-motion and silent forms | Capture times unchanged with presenters failing or frames dropped; cancellation on pause, exit and stage change; no capture after cancel; flash-rate check; muted and failed-sound runs |
| EP04 | Kid Party Arcade: decorations, copy, Party Pop, celebration, 6 templates, children consent line | Guest journey tests both orientations, goldens, template validation, consent text test |
| EP05 | Retro Game Quest with Handheld Retro and Arcade Cabinet, Arcade Start and Handheld Boot, 8 templates | Same as EP04 per variant; originality review checklist in provenance |
| EP06 | All eight packs on the shared guest screens; Live Template Camera (both modes) | Each guest screen per pack and orientation; live overlay z-order and clipping parity with export; exports byte-identical across packs |
| EP07 | Event Builder, Experience tab customisation, reset to defaults, persistence | Builder flow tests, switching packs keeps other settings, reset, config revision |
| EP08 | Full Experience Preview, template recommendations | Isolation tests (no rows, files or sends), recommendations never block other templates |
| EP09 | Goldens for eight packs in both orientations, accessibility and regression sweep, device procedure | Screen catalog for all packs; device performance and audio **BLOCKED** until tablets (M11) |

Mapping of the prompt's 17 acceptance criteria: 1 EP07; 2 EP02 (operator
goldens unchanged); 3 EP04; 4 EP05; 5 and 6 EP06; 7 EP07; 8 EP08; 9 and 10
EP06; 11 EP06 (byte-identical exports); 12 EP04 and EP06 (delivery
untouched); 13 EP01 and EP06 (fallbacks); 14 EP03; 15 every stage; 16
BLOCKED until tablets (M11); 17 EP04, EP05 and the provenance review.

## 8. Risks

- **Device performance of Full Template mode** (live texture under and
  over painted layers) is unknown until tablets exist; Camera-Focused mode
  is the fallback and the default for the first device run.
- **Scope:** eight packs and 14 templates are a large art workload;
  generated, original art keeps provenance clean but needs the owner's
  visual review per pack (CR-001, CR-002).
- **New dependency** (audio) and **new fonts** need approval and licence
  checks (4.3, 4.5).
- **Consent wording for children** awaits the legal review already
  BLOCKED for texting.
- The Swift side of earlier work is still uncompiled (no Mac); nothing in
  this plan adds native code beyond the audio package.
