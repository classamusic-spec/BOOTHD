# ADR-0013: Guest sessions: state machine, durable checkpoints and guest screens

- Status: Accepted (M07, 2026-10-19). Device questions stay open
  (section 11).
- Implements: A-10 (booth session state machine), P-09 (guest session
  flow), A-11 (checkpoints and startup recovery for sessions), S20 to S27
  and S29, the CLAUDE.md camera, rendering and Booth Mode invariants.
- Covers: AC-0701..AC-0709. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M07).
  Device steps: `docs/device_tests/M07_DEVICE_PROCEDURE.md`.

## Context

M03 made Booth Mode a locked guest area with a welcome screen whose Start
did nothing yet. M04 built the print renderer and atomic export, M06 the
camera service, its lifecycle and the originals store. M07 joins them into
the guest session: welcome, optional template choice, live preview, a
countdown, one to four photos, review and retakes, the finished photo,
"saved", and a reset that leaves nothing of the guest behind. It must
survive the booth leaving the foreground, a crash mid-way and a guest who
walks off, and never take a photo late, lose an original, claim a save that
did not happen or show one guest's photos to the next.

## Decision

### 1. The flow is a value (`lib/domain/session/guest_flow.dart`)

`GuestFlow` is immutable; each step is a method that returns the next flow
or throws `InvalidGuestTransition`. It holds the stage, the templates on
offer, the session's template revision, its `SessionShots`, the current
shot, the seconds left and the problem. It does no work: effects belong to
the controller (section 4), so every rule is unit-tested without a camera.

| Stage | A-10 state(s) | Screen |
| --- | --- | --- |
| `idle` | idle | S20 welcome |
| `templateSelection` | templateSelection | S21 template choice |
| `preparing` | preparing, preview | S22 live preview, camera opening |
| `countdown` | countdown | S23 numeral on the plaque |
| `capturing` | capturing | S24 flash, "Snap!" |
| `shotSaved` | capturedIntermission | S24 "Lovely!", thumbnail |
| `review` | review | S25 |
| `rendering` | rendering | S26 |
| `completed` | completed | S27 |
| `interrupted` | interrupted | "Welcome back!" and Continue |
| `failed` | recoverableFailure, terminalFailure | S29 |

A-10's `preview` is the live picture while the camera opens; the countdown
starts as soon as the camera is ready, so it is part of `preparing`.
`resetting` is not a resting state: the reset runs in one step and refuses
to run while work is in flight (`busy`: capturing or rendering, P-09).
`GuestProblem.recoverable` separates the two failure states: camera,
capture and render problems can be retried; a full tablet or an event that
cannot run a session cannot.

### 2. The session is frozen when it starts (`SessionPlan`)

The first preparing step loads the template revision and freezes a
`SessionPlan`: event id, template revision id, the template's photo spaces
in `slotIndex` order (shot n fills the n-th), the capture settings (lens,
both mirror settings, counts, countdown, pause, retake policy and limit),
the output profile and the finish timeout. A plan whose shot count does not
match the template's photo spaces is refused (`SESSION_*` codes). The plan
is stored as versioned JSON with the session and never changes: a session
renders the same way whatever happens to the event later (A-15).

### 3. Photos, attempts, rounds and bindings (`SessionShots`)

Every saved photo is a `ShotPhoto` (shot, attempt, round, original id,
time). The photo used for a shot is its latest attempt; earlier attempts
stay recorded with their originals (AC-0703).

- Per-photo retakes (`perShot`): each shot up to the event's limit; a
  retake is the shot's next attempt in the same round.
- Whole-set retakes (`wholeSession`): the set is taken again as a new
  round, up to the limit. The guest confirms first (CR-001 fix 10). The
  database records the new round with its first photo
  (`SessionShots.record`), so a round never exists without a photo.
- `slotBindings` (photo space to original) exist only for a complete set
  and drive the render (AC-0704).

### 4. Schema version 5

`capture_sessions` (id, event, template revision, planned shots, plan JSON,
status `capturing | reviewing | rendering | completed | abandoned |
failed`, end reason, render attempts, output, times), `session_photos`
(primary key session + shot + attempt; round; slot; unique original) and
`session_outputs` (relative path `outputs/<id>.jpg|png`, checksum, size,
format, renderer version). Checks tie end times, outputs and reasons to
statuses; triggers refuse changes to a plan, a photo, an output or a
finished session. `DriftSessionRepository` re-reads a session and applies
the domain rules in one transaction before every write, so the rows always
describe a state the flow could reach. Migration 4 to 5 is additive.

### 5. The controller (`lib/core/booth/booth_session_controller.dart`)

`BoothSessionController` drives one event's sessions for as long as Booth
Mode shows them:

- **Start** checks free space first (at least three sessions' worth,
  `StorageBudget.minimumSessionFreeBytes`), then offers templates or goes
  straight to the event's default.
- **Camera**: opened when a session starts, through M06's
  `CameraSessionController`; released when the booth returns to the
  welcome, so an idle booth holds no camera. Readiness is read from the
  service's own status (the session controller's copy follows a moment
  later). Guests are never asked for camera access: the launch checks
  block Booth Mode without it, and a revoked permission is a camera
  problem for the host.
- **Countdown**: `Timer.periodic`, one step a second (monotonic time,
  never the wall clock), haptic tick if the tablet has one.
- **Foreground rule (AC-0702)**: when the app becomes inactive or hidden
  while preparing, counting down or between photos, the session pauses
  (`interrupted`). Only the guest's Continue resumes it, from a fresh
  countdown, after the camera reopens. A photo already being taken
  finishes first and is kept, then the session pauses.
- **Capture**: a photo is recorded only after the store has committed its
  original (M06) and the session row accepts it.
- **Watchdogs**: opening the camera (and recording the session) longer
  than 20 s, or one photo longer than 30 s, becomes a guest-safe problem
  with a Try again. A photo that arrives after its watchdog is kept in
  storage but not used.

### 6. Rendering and "saved" (AC-0705, AC-0707)

Keep these moves the session to `rendering` and counts the attempt (the
checkpoint). The finished photo is rendered from the unmodified originals
with the plan's output profile and the event's output mirroring, exported
atomically (M04), **read back and checked against its checksum**, and only
then is the session recorded `completed` with its output. Only then does
the guest see "Saved to the booth gallery." A render or export failure,
or a file that does not read back intact, is a render problem: the
session stays `rendering` with its photos, Try again renders again.

If the guest leaves, or the app stops, the checkpoint stays. While the
booth is idle the controller finishes sessions left `rendering`, one at a
time; at startup (`SessionRecovery`) sessions cut off while taking or
reviewing photos end as `abandoned` (`interrupted`), and a session whose
finished photo failed three times ends as `failed` (`renderFailed`) for the
operator. Nothing is deleted.

### 7. Guest-safe timeouts

| Where | After | Then |
| --- | --- | --- |
| Template choice | 60 s | the welcome |
| Review | 90 s | the photos are kept and the finished photo made, as if the guest tapped Keep |
| Paused | 60 s | the session ends (`timedOut`) and the welcome returns |
| Problem | 90 s | the session ends (`problem`; a render problem keeps its checkpoint) |
| Finished | the event's finish timeout (10 to 120 s) | the welcome |

Review's auto-keep is an owner question (section 11): the alternative is
to end the session unrendered.

### 8. Reset and privacy (AC-0709)

Next guest, a timeout or the operator's exit ends any unfinished session
(abandoned, with its reason), forgets the session's photos, finished photo
and template, clears Flutter's image cache including live images, and
releases the camera. The screen switch drops the last guest's screen at
once when the welcome returns (no cross-fade), so no photo lingers on the
idle screen. Photos are decoded at about their shown size, never full size.

### 9. Guest screens (S21 to S27, S29; CR-001, CR-002)

`BoothScreen` hosts `BoothSessionView`, which shows one screen per stage,
styled from the owner's guest-flow board: spaced-capital "Choose your
style" with drawn template cards and a gold Continue; "Get ready!" over the
live picture in a porcelain frame with the numeral on a pearl plaque and
the session's photos as marks; a soft flash and "Snap!"; tilted prints for
"How do they look?" with Retake and the retakes left under each; "Creating
your photos"; the finished photo as a tilted print with still gold confetti,
"Your photos are ready!", "Saved to the booth gallery." and Next guest;
"Welcome back!"; plain problem screens. Words live in `BoothCopy`; guests
never see a code. The operator does: once the PIN is entered on the
Booth Mode operator screen, the last problem a guest met is shown with
where to repair it, its code and its time (`lastGuestProblemProvider`,
cleared when Booth Mode ends), as the CLAUDE.md camera rules ask.

- Layouts come from the space each screen actually has (portrait or
  landscape, ADR-0004). The booth also asks the OS for the event's
  preferred orientation, a request it may ignore; the layouts never
  depend on it. The template's portrait or landscape output is separate.
- No back, settings, share, save-to-device or print control exists on any
  guest screen (AC-0706, A-13). System back does nothing; deep links are
  redirected to Booth Mode. The operator's hidden hold waits for a photo
  or finished photo being saved, ends the session, then opens the PIN.
- Reduced motion: no flash, no fades, still spinners. Guest buttons are at
  least 72 dp and show spaced capitals (`PorcelainButton.caps`) while
  screen readers get the plain label.
- Phone delivery (the board's screen 7) is M09 and absent.

### 10. Rejected alternatives

- **One controller per screen** (as M06's camera test): the session spans
  screens; a single controller makes the stage, the camera and the timers
  one consistent state.
- **Persisting every stage**: only states a restart can act on are stored
  (capturing, reviewing, rendering, finished). A countdown cannot resume
  after a restart: its guest is gone.
- **Showing the finished photo straight from the renderer's bytes**: it
  would show "saved" for a file that may not be on disk intact. The
  displayed bytes are the ones read back.

## Consequences

- Schema version 5; versions 1 to 4 migrate with every value intact.
- Originals from abandoned sessions and late photos stay in storage until
  the operator's retention and gallery tools (M08) act on them.
- Startup reads unfinished sessions once; idle finishing renders one
  session at a time, so a guest's Start is never blocked by it.
- 30 more goldens (about 13 MB) document every session step.

## Verification

Host tests: `guest_session_test.dart` (flow rules),
`session_repository_test.dart`, `session_recovery_test.dart`, the v5
migration test, `booth_session_controller_test.dart` (14 cases:
countdown, interruptions, retakes, failures, verification, timeouts,
watchdogs, full tablet, operator exit), `booth_session_flow_test.dart` (19
flows, including Start to the next guest at every tablet size),
`booth_render_test.dart` (the real renderer and file export: each photo
in its own space, the right way round), the screen catalog (overflow,
200% text, tap targets, labels, contrast, no dead controls for every
step) and goldens. Devices: BLOCKED until run
(`docs/device_tests/M07_DEVICE_PROCEDURE.md`, with the scripted
`integration_test/guest_session_test.dart`).

## Open questions

Owner:

- Review timeout: keep and finish the photos (built), or end the session
  unrendered?
- Countdown sounds and the board's countdown styles (S14 "Countdown
  Style", "Sound Effects"): not built; they need audio assets and settings.
- A per-event "cancel session" for guests (S22 "cancellation only if
  event allows"): not offered; walk-away guests are covered by timeouts.

Devices (need physical tablets):

- Full airplane-mode sessions to a saved finished photo and the next guest
  on both tablets (the exit gate), in both orientations.
- Whether each OS honours the orientation request in kiosk setups.
- Render time and memory for 12 MP originals at 1200 x 1800 on the
  certified tablets, and thermal behaviour over a long event.
- Countdown and flash timing as guests perceive them; haptics.
