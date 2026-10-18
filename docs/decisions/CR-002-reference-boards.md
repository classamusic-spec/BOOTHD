# CR-002: Match the owner's reference boards

- Status: **Requested by owner, 2026-10-18**, with M05 and M06: "polish the
  UI/UX; try to make it identical to the reference images."
- Boards: `reference/guest_flow_board_2026-10-18.webp` (portrait guest
  flow) and `reference/screen_reference_board_2026-10-18.webp` (landscape
  guest flow, phone delivery, operator settings).
- Relation to CR-001: CR-001 asked to exceed the earlier concept board, not
  copy it. These boards are the owner's chosen look, so screens now follow
  them as closely as possible: layout, type, gold-and-pearl controls, cream
  florals, wording. CR-001's fixes still apply where a board conflicts with
  the spec (table below).

## Where each board screen is built

| Board screen | Milestone | Notes |
| --- | --- | --- |
| Welcome / Start (portrait 1, landscape S01) | Now (polish of the M03 screen) | Wordmark, "Let's make some memories", pearl Start button with a gold rim, icon step row, cream florals, a strip of the event's template |
| Choose your style / look (2, S02) | Card style and preset names now (M05 library); guest screen in M07 | Classic Strip, Floral Elegance, Modern Minimal, Retro Film, Gold Celebration presets. "Black & White" needs a photo filter the template format does not have yet |
| Get ready, countdown, flash, next shot (3–5, S03–S06) | M07 | Guest session flow |
| Review: How do they look? / Love it? (6, S07) | M07 | Per-photo retake rules from S25 still apply |
| Text my photos, phone and consent, sending, sent (7, S08–S11) | M09 | Optional phone delivery; off until set up |
| Sample text message, download page (S12, S13) | M09 backend | Not part of the tablet app |
| Finish: Your photos are ready (8) | M07 (without delivery), M09 (with it) | Never claims a print |
| Operator settings: Event Setup (S14) | Section layout now; experiences and countdown styles see below | |

## Board elements that conflict with the spec (CR-001 rules kept)

| Board shows | Rule | What the app does |
| --- | --- | --- |
| Photos of real-looking people in strips and previews | UX-09, CR-001 #12 | The event's own template is shown with neutral photo placeholders; no sample people ship |
| Back chevron and close X on guest screens | UX-04, CR-001 #9 | Decided with the guest flow in M07: a guest may step back inside a session only where the event allows it; never out of Booth Mode |
| Bottom row "Photo booth · Pose · Smile · Enjoy" on Welcome | Guest screens have one control (AC-0210) | Shown as a non-interactive step guide with the same icons |
| Seven guest experiences (Porcelain Classic, Light Wood, Storybook Garden, Kid Party Arcade, Retro Game Quest, Disco Nights, Midnight Gala) | UX-02: three theme profiles | The three existing themes are shown as experience cards; the four new experiences need an owner decision (new artwork, sounds and motion for each) |
| Countdown styles, sound effects, celebration animation | Belong with the countdown (M07) | Added with the guest flow, not as settings that do nothing now |

## Verification

Goldens of the changed screens in both orientations next to the boards; the
owner's verdict on likeness is requested in the milestone report.
