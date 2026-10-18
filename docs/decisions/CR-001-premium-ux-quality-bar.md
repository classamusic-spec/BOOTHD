# CR-001: Premium UX quality bar: exceed the 15-screen concept board

- Status: **Approved by owner, 2026-10-17.** Directive: "Make the UI/UX even
  better than this reference photo; make it AAA premium quality."
- Sequencing (owner decision, same day): keep the spec order. M01 stays a
  plain feasibility spike; this bar binds M02 and every later milestone that
  touches UI (M03, M05, M07, M08, M09, M10). The M00 baseline screen is
  deliberately plain.
- Priority: P0 for M02 onward (change control D-05).
- Reference: the owner's 15-screen iPad board. UX-00 names its path,
  `reference/15_screen_concept_reference.png`, but the file is **not yet in
  the repository** (it arrived as a chat image). Owner action: commit it at
  that path.

## What "better than the board" means

The board sets the mood: warm porcelain ivory, champagne-gold tactile
controls, botanical line art, an elegant serif wordmark, calm guest pacing.
Keep all of that. "Better" means the same mood plus what the board lacks:
truthful controls, every state and both orientations designed, measurable
accessibility, deliberate motion, and artwork the product can legally ship.

## Keep from the board

- Ivory canvas, charcoal-brown text, champagne-gold primary actions.
- The large tactile pill CTA ("Start Booth") and the card-grid dashboard.
- Editor layout: left tool rail, central canvas, right inspector; layer list
  with drag handles, visibility and lock.
- Serif display type for the brand; script faces only inside templates.
- Guest pacing: welcome, template choice, live preview, big countdown
  numeral, review, finished.

## Fix: where the board conflicts with the spec (do not copy)

| # | Screen | Board shows | Spec rule | Required change |
| --- | --- | --- | --- | --- |
| 1 | Home dashboard | Start always enabled; no system status | S02 | Start disabled with a reason until an event passes preflight; show camera, storage and preflight status |
| 2 | Events list | All / Upcoming / Past / Favorites; Start on every row | P-05, S03, S05 | Filters Active / Draft / Archived; launch only through preflight |
| 3 | Event settings | One page; red Delete as a primary action | S04, P-05 | Tabs General, Templates, Capture, Guest UI, Output, Privacy; archive before delete with confirmation; archiving never deletes photos |
| 4 | Template gallery | No page size or usage | S06 | Show size/aspect (2x6, 4x6 portrait/landscape, 4x4), reference count and damaged-asset state |
| 5 | App settings | One "Mirror Front Camera Preview" toggle | P-08, A-09 | Separate preview mirroring and saved-output mirroring; resolution only from supported presets; printer shown as Not configured |
| 6 | Template editor | Unitless X/Y/W/H; no rotate handle or page guides; small handles | S07, S10 | Document units, rotate handle, page/safe-area outline, zoom %, handles with 44 pt hit areas, visible undo/redo state |
| 7 | Elements panel | Sticker store categories | P-18, D-04 #6 | No marketplace in v1; starter decorations need recorded licences |
| 8 | Guest welcome | "1 Pose · 2 Smile · 3 Print" | P-12, S27 | Never imply a physical print in v1; final copy chosen in M02 |
| 9 | Live preview, countdown | Back chevron and settings gear on guest screens | UX-04, S22 | No back, settings or escape controls for guests; operator exit is a hidden gesture plus PIN |
| 10 | Review and retake | One Retake for everything | S25 | Per-photo retake, retakes remaining, confirm before a full reset |
| 11 | Finished | "Save to Gallery" and "Print (When Configured)" buttons; no final image | S27, S30 | Show the final composition and "Saved to booth gallery" (it already is); no print button; Done/Next Guest; "Text my photos" only when M09 delivery is enabled |
| 12 | All | Sample couple, names and 2024 dates | UX-09, T-02 | No sample people or names in shipped UI; fixtures are owned and licensed |

## Exceed: the measurable bar

Thresholds are binding from M02; the owner may tune them at M02 kickoff.

1. **Contrast.** "AAA" taken literally where it matters most: guest primary
   text and the countdown numeral at least 7:1 (WCAG 2.2 AAA) in every
   theme; all other text at least 4.5:1; focus rings and control boundaries
   at least 3:1. Enforced by an automated token-pair test.
2. **Touch.** At least 44 pt everywhere (Flutter tap-target guideline tests);
   guest primary actions at least 72 pt; editor handles drawn at 24 pt or
   more with 44 pt hit areas.
3. **Every state designed** (UX-07): rest, pressed, focus, selected,
   disabled with reason, busy, success, error; empty, loading, error and
   partial lists; camera permission, initialising and interrupted.
4. **Both orientations for every screen**, chosen from the effective
   viewport (ADR-0004), with golden screenshots per screen, orientation and
   implemented theme at the certified-device sizes.
5. **Type system.** Licensed families with a written scale: a refined serif
   for display, a highly legible sans for UI with tabular figures for
   counts and coordinates, script faces only inside templates. Licences
   recorded (AC-1204).
6. **Tactile depth.** A documented elevation model (key light plus ambient),
   pressed states with visible inset and 1 dp travel at 120–180 ms (UX-01),
   no low-contrast neumorphism; Darkroom Walnut keeps the same hierarchy.
7. **Motion.** Purposeful transitions (shared-axis between Studio sections,
   container transform into the editor, a crisp countdown numeral), each
   with a reduced-motion variant; 60 fps on certified hardware and 120 Hz
   where the iPad supports it, measured in M11.
8. **Art and icons.** One icon family with a consistent stroke; original or
   licensed botanical artwork with provenance. Nothing is lifted from the
   concept board unless licensed.
9. **Microcopy.** Warm, short and truthful; never claims saved, printed,
   sent or delivered before it is true.
10. **Owner review.** Each UI milestone presents goldens side by side with
    the board; the owner records the "exceeds" sign-off in
    `docs/ACCEPTANCE_EVIDENCE.md`.

## Acceptance additions

Added to `docs/ACCEPTANCE_CHECKLIST.md` under M02 as AC-0207 to AC-0211,
re-run at every later milestone that adds or changes screens.
