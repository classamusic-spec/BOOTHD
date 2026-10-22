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

## Consequences

- One new runtime dependency family (`audioplayers` and its platform
  packages); the APK permission audit must stay clean.
- Fonts: five SIL OFL faces added (provenance in
  `docs/ASSET_PROVENANCE.md`).
- Device questions (audio latency, loudness in a hall, whether the iPad's
  silent switch mutes the booth) are recorded for the device procedure.
