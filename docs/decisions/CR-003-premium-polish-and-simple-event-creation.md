# CR-003: Premium polish and a simpler way to create events

- Status: **Requested by owner, 2026-10-25.** Directive: "ADD AAA Premium
  polish to the UI/UX across all screens, Simplify the event creation
  mode."
- Track: UX-P1, an owner-directed track like EP and W, outside the M00 to
  M12 sequence. It changes no locked product decision: CR-001's quality bar
  and its fixes still bind every screen touched here.

## Context

Creating an event took the eight-step Event Builder (EP07): details,
experience, customisation, templates, camera, texting, preview, then save
and check. A new booth with an empty template library could not finish it
without leaving for Templates first, every new event started at three
photos per session whatever its design needed (a blocking mismatch to fix
by hand), and after saving, the event still had to be activated in the
editor before the launch checks. On a phone-sized window the Studio kept
its side rail, leaving about 175 dp for content.

## Decision

### 1. New events in three steps (S04-Q)

`/studio/events/new` opens the new-event flow instead of the builder:

1. **Occasion**: the event's name (required), date and venue (optional),
   and an optional occasion (wedding, birthday, kids party, gala, garden
   party, retro night, game night, rustic) that picks the guest look made
   for it. Nothing about the occasion is stored.
2. **Look**: the guest experience pack, and the photo design: the library's
   own templates first, then the ready-made designs (the starter designs
   of S06, without blank pages), each best suited to the chosen look first
   (EP08 recommendations, never a restriction). A live preview shows the
   guest welcome in that look and the design as it prints.
3. **Ready**: a summary of everything the event will be, with the booth
   defaults it starts from, and two actions:
   - **Create and check the booth** saves the event, makes it active and
     opens its launch checks. Booth Mode still starts only from the launch
     checks (CR-001 fix 2, S05).
   - **Save as draft** saves it and opens it in the editor.

A ready-made design joins the library when the event is created, as
revision 1 of a new template named after the design; a ready-made design
the library already holds under its own name is not offered twice. The
event's photos per session are the design's photo slots, so a new event
never starts with a mismatch.

The editor (S04 tabs) is unchanged for existing events, with two
simplifications: adding or removing a design makes the photos per session
follow the designs when they all agree, and a remaining mismatch can be
fixed in one tap ("Use 3 photos"). The eight-step builder is removed.

### 2. Polish across the screens

Recorded with their verification in `docs/ACCEPTANCE_EVIDENCE.md` (UX-P1);
see the implementation log for the full list.

## Consequences

- S04 (UX_SCREEN_SPECS) gains S04-Q, the new-event flow. The editor's
  sections and their validation are unchanged.
- Failure between the two writes of Create (the template is stored, the
  event is not) leaves an unused template in the library and the flow on
  screen with a plain message; nothing claims success before it is stored.
- Tests and goldens for the builder's steps are replaced by those of the
  three steps (`test/widgets/quick_event_test.dart`,
  `test/features/quick_event_designs_test.dart`).

## Verification

AC-UXP-01 to AC-UXP-04 for the new-event flow; further UX-P1 criteria are
listed in `docs/ACCEPTANCE_EVIDENCE.md`.
