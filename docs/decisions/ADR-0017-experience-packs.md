# ADR-0017: Guest Experience Packs

- Status: Accepted for EP01 to EP03 (2026-10-22); later stages append to
  it. What only tablets can settle (audio latency and loudness, Live
  Template Camera frame rate) stays BLOCKED until devices are available.
- Implements: the owner's Experience Pack System v2.0
  (`docs/experience_packs/EXPERIENCE_PACK_PROMPT_V2.md`) through the plan
  `docs/experience_packs/EP00_INTEGRATION_PLAN.md`, owner-approved with
  decisions 4.1 to 4.8.
- Covers: AC-EP01 to AC-EP17. Evidence: `docs/ACCEPTANCE_EVIDENCE.md`
  (EP sections).

## Context

Every event shows guests the same Porcelain look, chosen by the booth's
operator appearance. Operators want themed guest experiences (kids'
parties, retro gaming, galas) without a second app, a fork of the guest
flow per theme, or any change to how photos are captured, rendered,
stored or texted.

## Decision

### 1. Three independent layers

- **Operator appearance** (Porcelain Studio, Light Oak, Darkroom Walnut):
  the Studio only. Unchanged in structure; polished in EP02 at the
  owner's request.
- **Guest experience**: a versioned Experience Pack, chosen per event.
- **Photo template**: chosen per event as before; packs only recommend.

### 2. Packs are data

An `ExperiencePack` (schema version 1, JSON) holds ids, a twelve-role
palette, copy, typography ids, preset ids (layout, countdown,
transitions, shutter, celebration), sound ids per cue, decoration ids,
variants, accessibility defaults and which settings an operator may
change. Every id comes from a fixed catalog (`ExperienceCatalog`); there
is no code, no URL and no remote asset in a pack. Eight packs ship in the
app (`bundled_packs.dart`).

### 3. Validation and fallback, never a broken screen

`ExperienceRegistry` validates every pack on load: ids, text lengths and
placeholders, opaque colours, WCAG 4.5:1 for every text pair in every
variant, both orientations, 72-point minimum targets. A failing pack is
left out. Resolving an event's configuration never throws: an unknown or
newer pack falls back to Porcelain Classic; an unknown variant, preset or
unreadable colour falls back to the pack's own; each replacement is
reported with an `EXPERIENCE_*` code for the operator.

### 4. Storage and the session snapshot

- `events.experience_json` holds the operator's
  `EventExperienceConfiguration` (pack, version, variant, overrides,
  revision); schema v8 converts each event's former theme to the pack
  with the same look.
- A guest session freezes the resolved experience inside its plan JSON,
  which a database trigger already makes immutable: editing the event
  never changes a running or finished session. A plan without one (older
  sessions) or with an unreadable one shows the fallback.

### 5. One guest flow, presented by the pack

The guest screens stay single; they read `GuestExperience` (tokens,
copy, fonts, button family, countdown, sounds). `GuestButton` has one API
and six faces; primary buttons are the accent with its readable
on-accent text, secondary ones the panel with its ink, so every face is
as readable as its pack.

### 6. Countdown

The session controller keeps the countdown's timing (monotonic timers,
cancelled on any step change, never while the booth is in the
background). `CountdownState` is read from the guest flow; the nine
presenters only draw it, each with a still form for reduced motion, and
none flashes (WCAG 2.3.1, measured in tests). Countdown graphics are
guest UI only and never reach the renderer, so exports cannot contain
them.

### 7. Sound: `audioplayers` behind a port

- `GuestSoundService` (domain port), `SilentGuestSoundService`, and
  `AudioplayersGuestSoundService` (infrastructure) using
  `audioplayers` 6.8.1 (MIT, Blue Fire), version pinned in
  `pubspec.lock`, licence in `docs/DEPENDENCY_LICENSES.md`.
- Sounds are bundled WAV assets (`assets/sounds/`), preloaded into small
  low-latency pools; playback never waits and every failure is silent.
- The audio context mixes with the venue's music and never takes audio
  focus; sound is off by default for every event.
- Sixteen original placeholders are synthesised by
  `tool/audio/generate_sounds.py`; the owner's ElevenLabs recordings
  replace them through `tool/audio/import_sounds.sh`
  (`docs/experience_packs/SOUND_SCRIPT_ELEVENLABS.md`).

Alternatives considered: `just_audio` (MIT; heavier, built for long
media), a native `SoundPool`/`AVAudioPlayer` bridge (more native code to
maintain, against CLAUDE.md's "native only for evidenced gaps"), and
haptics only (the owner asked for sound).

### 8. Shared screens wear the pack; the live template is display only (EP06)

- `GuestTheme.of(experience)` turns a pack into the Porcelain token set
  the shared guest screens already read. An unmodified Porcelain Classic,
  Vintage Light Wood or Darkroom keeps its audited palette exactly; any
  other pack (or a changed accent) is derived with contrast guards (ink
  7:1, muted and accent text 4.5:1, outlines 3:1, checked for every pack
  and variant in `guest_theme_test.dart`).
- Words come from the frozen pack (`context.guestCopy`), never from code
  per pack; buttons are `GuestButton` faces; the countdown is the pack's
  preset; decorations are drawn in code from the pack's colours, kept to
  the corners (emblems to the bottom corners, clear of titles), and an
  unknown id draws nothing.
- Full Template camera mode compiles the session's template with the
  export's own scene compiler, puts the photos already taken in their
  slots and the placeholder in the rest, and paints the layers below the
  active slot, the live picture clipped to the slot's shape, then the
  layers above it (`paintScene(include:)`, never passed by an export). A
  slot with an image mask, a load failure or a slow load shows the
  camera-focused stage instead; the countdown and capture never wait for
  it. The print is the same `TemplateRender` whatever the pack or stage
  (`guest_packs_test.dart`).
- Camera-focused is the default stage for every event: Full Template is
  an operator choice until its cost is measured on the certified tablets.
- Pack backdrops glow between the palette's surface and canvas only, the
  grounds every text colour is checked on (EP09: a darker edge colour
  left muted text at 3.2:1 on Retro Film).

### 9. Event Builder, Experience panel and an isolated preview (EP07, EP08)

- A new event is built in eight steps (details, experience, customise,
  templates, camera, texting, preview, check and launch) inside the event
  editor: the same draft, the same validation, the header's Save at any
  step; Save and check stores it and opens the launch checklist. Saved
  events keep the tabbed editor, whose Experience tab is the full panel
  (pack and variant with a live welcome and countdown, words, accent
  colour, countdown, motion, celebration, sound and volume, camera
  screen, children, Reset to pack defaults). No JSON anywhere.
- Accent colours come from a fixed, named list (`ExperienceCatalog`); a
  pack offers only those its text stays readable on, and the registry
  checks again when resolving.
- Template recommendations rank and mark; they never hide a template.
  Tags travel from a starter design (or a duplicated template) into the
  catalog's existing `tags_json` column.
- The Full Experience Preview runs `BoothSessionView` in a nested
  provider scope over in-memory stand-ins (`core/experience/
  preview_services.dart`): a sample camera drawing sample photos, a
  memory still store and session repository, and an export that renders
  with the real renderer at screen size into memory. The view's preview
  mode requests no orientation and asks no texting service; Send submits
  nothing and says so. Tests prove no row, file, camera use or delivery
  call results.
- The preview shows guest screens scaled into a device frame. The
  automated pixel-contrast check cannot judge downscaled text, so that one
  screen is exempt from it (and only from it); the same guest screens pass
  it at full size.
- Not built: an optional event logo (needs an asset import and a guest
  placement that the packs' layouts do not have yet); recorded for the
  owner.

## Consequences

- One new runtime dependency family (`audioplayers` and its platform
  packages); the APK permission audit must stay clean.
- Fonts: five SIL OFL faces added (provenance in
  `docs/ASSET_PROVENANCE.md`).
- Device questions (audio latency, loudness in a hall, whether the iPad's
  silent switch mutes the booth) are recorded for the device procedure.
