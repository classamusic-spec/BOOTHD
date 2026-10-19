# M07 device procedure: guest sessions in Booth Mode

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and
a physical Android tablet. Simulators, emulators and the test suite's
simulated camera do not count for any step here. Record every result in
`docs/ACCEPTANCE_EVIDENCE.md` (M07) with the device model, OS version, app
commit, build mode, orientation, event settings and date. Until this is
done the M07 exit gate and AC-0708 stay BLOCKED and the device halves of
AC-0701..AC-0707 and AC-0709 stay unverified.

**Exit gate:** on both tablets, in airplane mode, photo → composition →
local saved output → next guest, with no operator action.

## 0. Setup

- Flutter 3.47.7 exactly; `tool/check.sh` passes on the commit under test.
- Install as for M06 (`docs/device_tests/M06_DEVICE_PROCEDURE.md`
  section 0), including the iPad camera-permission build rule in
  `docs/IOS_VALIDATION.md`. Use a profile build:
  `flutter run --profile -d <device-id>`.
- Allow the camera once in Diagnostics > Camera test.
- Template Studio: create a template from **Floral Elegance** and one
  from **Classic Strip** (three photos each).
- Events: a portrait event with the Floral Elegance template, three
  photos, front camera, preview mirrored, saved photos not mirrored,
  3-second countdown, 3-second pause, one retake per photo; a second event
  in landscape with both templates and "Guests choose a template" on.
- Turn on **airplane mode** (Wi-Fi and mobile data off; Bluetooth too).
  USB debugging keeps working.
- Have ready: three coloured cards (red, green, blue), a stopwatch.

## 1. Scripted session (both tablets)

With the camera allowed and airplane mode on:

```sh
flutter test integration_test/guest_session_test.dart -d <device-id>
```

It runs one whole session with the production camera, stores, renderer
and export in a temporary area and prints `M07 session: …` (photos,
capture time, finished photo size and render time, originals' sizes).
Record the line. A failure prints the problem code.

## 2. Exit gate: ten guests in a row (AC-0701, AC-0705, AC-0709)

For each tablet, with the portrait event in Booth Mode (launch checks,
Start Booth Mode), the tablet held upright:

1. Tap **Start**. "Get ready!" and "Photo 1 of 3" appear over the live
   picture within two seconds; the picture is mirrored like a mirror and
   not stretched.
2. The numeral counts 3, 2, 1, one step a second (stopwatch), with a
   haptic tick where the tablet has one; then a soft flash and "Snap!".
3. "Lovely!" and the photo's thumbnail appear only after the photo is
   saved; the next countdown starts after the pause.
4. After the third photo, "How do they look?" shows the three photos the
   way they will be used (not mirrored: text on a card reads correctly).
5. Tap **Keep these**: "Creating your photos", then "Your photos are
   ready!" with the finished photo and "Saved to the booth gallery."
   Record the time from Keep these to the finished screen.
6. Tap **Next guest** (or leave it: it resets after the event's finish
   timeout). The welcome shows nothing of the last guest.

Repeat until ten sessions are done, without opening the operator screen.
Then check the files:

- Android: `adb shell run-as com.example.porcelain_photo_booth ls -l
  files/outputs files/originals` (ten outputs; 30 originals).
- iPad: Xcode > Window > Devices and Simulators > the app > Download
  Container; look in `AppData/Library/Application Support/outputs`.

Pull one output (Android: `adb exec-out run-as
com.example.porcelain_photo_booth cat files/outputs/<file> > out.jpg`) and
check: page size in pixels (600 x 1800 for the strip), each photo in its
own space, nothing mirrored, sharp at full size.

Repeat 1 to 6 with the tablet in landscape and the landscape event; the
guest chooses a template (S21) and that design is the one saved.

## 3. Retakes (AC-0703)

1. On the review, tap **Retake** under photo 2: only photo 2 is taken
   again ("Retaking photo 2"); the review then reads "No retakes left"
   under it and "1 retake left" under the others.
2. Count the originals before and after: one more, none deleted.
3. Set the event's retakes to "Whole session" and run a session: **Retake
   all** asks first; **Cancel** keeps the photos; **Retake all** takes the
   whole set again.

## 4. Photos in the right spaces (AC-0704)

Run a session holding the red card for photo 1, green for photo 2 and blue
for photo 3. In the saved output, red, green and blue fill the first,
second and third photo spaces of the template, in its order.

## 5. Interruptions (AC-0702)

During a countdown, each of these, then return to the booth:

1. Home (swipe up / Home button). On return: "Welcome back!", no photo
   was taken while away (originals count unchanged), Continue starts a
   fresh 3-2-1.
2. Control Center (iPad) or the notification shade (Android).
3. Lock the screen with the power button, then unlock.
4. iPad: Slide Over or Split View with another app; Android: split
   screen. The guest screens adapt to the narrower window.
5. Press Home right as "Snap!" shows: the photo finishes and is kept, then
   the booth pauses.

Nothing ever fires a photo after the booth is back without the guest
tapping Continue.

## 6. A finished photo left unmade (AC-0707)

1. Tap **Keep these** and, while "Creating your photos" shows, force-close
   the app (app switcher, or `adb shell am force-stop
   com.example.porcelain_photo_booth`).
2. Open the app: it returns to the Booth Mode welcome (not an error).
3. Within a few seconds a new file appears in `outputs`, and the session
   reads `completed` (Android: `adb exec-out run-as
   com.example.porcelain_photo_booth cat
   files/database/porcelain_booth.sqlite > booth.sqlite`, then
   `sqlite3 booth.sqlite "select status, render_attempts, end_reason from
   capture_sessions order by started_at desc limit 3"`).
4. Force-close during the photos instead: on reopening, that session reads
   `abandoned` (`interrupted`) and its originals are still there.

## 7. Guests stay in Booth Mode (AC-0706)

On every guest screen try: Android back (button or gesture), long presses,
two- and three-finger gestures, an attached keyboard's Escape and
Cmd/Ctrl shortcuts. None reaches the Studio, the gallery, a share sheet,
another guest's photos or a system file dialog. (Leaving the app itself
is what the OS kiosk lock prevents: Guided Access or lock task, M10.)
Press and hold the top-right corner for three seconds during a session:
the session ends and the PIN screen opens.

## 8. Layouts on both tablet families (AC-0708)

For each tablet, with the portrait event and then the landscape event:

1. Hold the tablet the preferred way, then turn it: record whether the
   OS keeps the preferred orientation (it may not: ADR-0004).
2. Whatever the orientation, every guest screen (welcome, template
   choice, get ready, snap, lovely, review, creating, finished, welcome
   back, a problem) lays itself out for the window it has: nothing cut
   off, buttons reachable, text readable at arm's length.
3. Take a screenshot of each screen in each orientation for the evidence.

## 9. Problems and timeouts

1. Android: in Settings, turn camera access off for the app while it is
   in Booth Mode (the OS restarts the app). Start: "The camera needs a
   moment" with Try again and Start over; no code on screen.
2. Leave the review alone: after 90 seconds the photos are kept and the
   finished photo is made. Leave the finished screen: it resets after the
   event's finish timeout. Leave "Welcome back!": after 60 seconds the
   welcome returns. Leave the template choice: after 60 seconds the
   welcome returns.

## 10. Reduced motion

iPad: Settings > Accessibility > Motion > Reduce Motion. Android:
Settings > Accessibility > Remove animations. No flash, no fades; the
countdown still counts.

## Results template

```text
Device:            (model, OS version, build)
App commit:        (git rev-parse --short HEAD)
Airplane mode:     on / off
Scripted session:  (printed line)
Ten-guest run:     pass / fail (sessions completed, outputs, originals)
Render time:       (Keep these to finished, seconds; min / max)
Retakes:           pass / fail
Slot colours:      pass / fail
Interruptions:     1 2 3 4 5 (pass / fail each)
Recovery:          unmade render finished on reopen: yes / no
Isolation:         pass / fail
Orientation:       preferred kept: yes / no; layouts pass / fail
Problems/timeouts: pass / fail
Reduced motion:    pass / fail
Notes:
```
