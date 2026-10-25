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

Each item keeps CR-001's rules: nothing animates with reduced motion, no
dead or pretend controls, no colour-only status, every screen still passes
the overflow, 200% text, tap-target, label and contrast checks.

1. **Narrow windows.** Below 600 dp (an Android tablet in split screen, or
   a phone opening the web test build) the Studio drops its side rail: a
   top bar holds the wordmark, Diagnostics and Lock Studio, and the other
   five sections sit in a bottom bar. Page margins tighten on phone-sized
   windows only, so panes side by side on a tablet keep theirs. Headers of
   the event editor and launch checks show their side buttons as icons on
   narrow windows, so titles keep the room.
2. **Entrances.** Studio pages bring their header and sections in once,
   each fading in and rising 16 dp a beat after the one before (about
   0.44 s in all). The widget tree stays the same throughout, every
   section is in the semantics tree and tappable from the first frame,
   and with reduced motion nothing moves.
3. **Event cards** open with a cover in the event's guest look (its
   canvas, colours and decorations) with the event's designs laid on it
   like prints, the default on top, or the start medallion when it has
   none.
4. **Launch checks** carry a seal (gilded check when nothing blocks the
   launch, a lock otherwise) and the counts of passed, warning and
   blocking checks; the check groups enter one after another.
5. **Dashboard.** The Gallery card counts the sessions actually stored (it
   said "No sessions yet" whatever the gallery held); on a narrow card the
   hero's buttons stack full width.
6. **Segmented controls** give up side padding when room is tight, then
   keep their width and scroll sideways rather than break a label inside
   a word.
7. **Guest camera.** While the camera opens, the viewfinder shows a still
   lens mark (the plaque below keeps the one moving sign of progress), and
   the plaque's messages change with a fade-through, so two messages never
   show on top of each other.

### 3. Owner feedback from testing on a phone (2026-10-25)

The owner asked how an operator leaves an event in Booth Mode and how to
check the booth's photos. Both now have an answer on screen:

1. **Leaving Booth Mode.** The way out is unchanged (hold the top-right
   corner for 3 seconds, then the PIN, then Exit Booth Mode), but the
   launch checks now say so under Start Booth Mode. Guest screens still
   show no way out.
2. **Photo reel.** After the PIN, the operator screen offers a Photo reel:
   the running event's finished photos, newest first, one at a time,
   view only. It stays behind the PIN and the operator screen's idle
   timeout, so guests never reach it. Exporting and deleting stay in the
   Studio's Gallery.
3. **Guest screens on a phone.** Below 600 dp wide in portrait, the guest
   welcome and finished screens put the print above the words, so titles
   and button labels are no longer squeezed or cut short.

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

AC-UXP-01 to AC-UXP-04 for the new-event flow and AC-UXP-05 to AC-UXP-10
for the polish, with commands and results, in
`docs/ACCEPTANCE_EVIDENCE.md` (UX-P1). Device runs on an iPad and an
Android tablet are owed, as for every Studio change.
