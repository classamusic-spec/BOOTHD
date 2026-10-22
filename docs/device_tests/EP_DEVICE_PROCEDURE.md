# EP device procedure: guest Experience Packs (EP01 to EP09)

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and
a physical Android tablet. The host tests run every pack through the whole
guest journey on a simulated camera, compare every print request, and
review 74 pack goldens; only the tablets can show how the packs look,
sound and perform on real screens, speakers and cameras. Record each
result in `docs/ACCEPTANCE_EVIDENCE.md` (EP09) with the device, OS
version, app commit, build mode and date. Until then AC-EP16 stays
BLOCKED and the device halves of AC-EP05, AC-EP06, AC-EP09 and AC-EP14
stay open.

**Exit gate:** on both tablets, in portrait and landscape, every pack runs
a full session with real photos; Full Template keeps a smooth live picture;
sound plays on time without taking the venue's music; reduced motion and
muted sessions work; the Full Experience Preview saves and sends nothing.

## 0. Setup

- A profile build of the commit under test on each tablet (M07 procedure
  section 0). Venue-like light; a speaker or the tablet's own speaker.
- One event per pack (eight), each with a 2-photo portrait template from
  the starter designs (Kid Party and Retro Game Quest events use their own
  designs), texting off unless section 6 says otherwise.

## 1. Every pack on the guest screens (AC-EP05, AC-EP06)

For each pack (and both Retro Game Quest variants), in portrait and then
landscape:

1. Activate the event, open Booth Mode, take a full session (start, two
   photos, review, keep, finished).
2. Record: words, buttons, countdown and decorations match the pack;
   nothing is cut off or overlaps (titles, the review captions, the start
   button); text is readable from 1.5 m.
3. Open the finished photo in the gallery: record that it shows no
   countdown, button, decoration or ribbon (AC-EP11).

## 2. Full Template camera (AC-EP09, AC-EP10)

1. In one portrait and one landscape event, set Camera screen to Full
   template. Run a session with the front and the rear camera.
2. Record: the live picture fills its slot (mirrored as the event asks),
   artwork above the slot covers the live picture as in the print, the
   first photo shows in its slot during the second; the frame rate looks
   smooth (record Flutter DevTools frame times if available).
3. Record memory before and after five sessions (Xcode Instruments /
   Android Studio profiler): it must not keep growing.
4. Use a template with an image-masked slot: the camera-focused screen
   appears instead, and the session completes.

## 3. Sound (AC-EP14)

1. Turn sound on at 70% for two packs. With music playing from another
   app, run a session: record that the music keeps playing, the cues play
   at the start, each second, the photo and the finish, and none is late
   by more than about a tenth of a second.
2. iPad: flip the silent switch / Control Centre silence; record whether
   the booth is silenced. Android: set media volume to zero; record.
3. Replace the placeholder sounds with the owner's ElevenLabs files
   (`tool/audio/import_sounds.sh`), rebuild, and repeat step 1.

## 4. Reduced motion and accessibility (AC-EP14)

1. iPad: Settings > Accessibility > Motion > Reduce Motion on. Android:
   Remove animations on. Run a session in two packs: record still
   countdowns and no confetti movement; the session completes.
2. Turn on VoiceOver / TalkBack: record that Start, Retake, Keep and Done
   are announced in the pack's words and can be activated.
3. Set the largest text size: record that guest screens stay usable.

## 5. Event Builder, Experience tab and preview (AC-EP01, AC-EP07, AC-EP08)

1. Create an event with New event: walk all eight steps, choose Kid Party
   Arcade (record "Guests may be children" turning on), change words,
   colour, countdown, camera screen, add a recommended and an unrelated
   template, Save and check: the launch checklist opens.
2. Open the Experience tab of an existing event: switch pack, then Reset
   to pack defaults; record that templates, camera and texting settings
   did not change.
3. Preview the whole guest journey in portrait and landscape and in two
   packs, texting on: complete it, then record that the gallery has no
   new session, the device's camera indicator never lit, and the texting
   dashboard shows no new text.

## 6. Children and texting (EP04)

1. Kid Party Arcade event with texting on and paired: on the texting
   screen record the line "A parent or guardian enters the number and
   gives consent." The consent box is unchecked until tapped.

## 7. Missing assets (AC-EP13)

1. Remove a template's decoration asset outside the app (developer build
   only) or import a package with an unknown decoration: record that the
   session completes and shows no error to the guest.
