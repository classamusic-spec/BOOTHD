# M06 device procedure: camera service, permissions and the camera test

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and
a physical Android tablet, front and rear cameras where the tablet has
them. Simulators, emulators and the test suite's simulated camera do not
count for any step here. Record every result in
`docs/ACCEPTANCE_EVIDENCE.md` (M06) with the device model, OS version, app
commit, build mode, orientation, lens and date. Until this is done,
AC-0603, AC-0604 and AC-0609 stay BLOCKED and the device halves of
AC-0601, AC-0602 and AC-0605..AC-0608 stay unverified.

## 0. Setup

- Flutter 3.47.7 exactly; `tool/check.sh` passes on the commit under test.
- Android: USB debugging on; `flutter devices` lists the tablet.
- iPad: follow `docs/IOS_VALIDATION.md`, including **Camera permission
  builds**: install with `flutter run` (or an archive made with
  `flutter build ipa`), never a build started from Xcode.app without
  `PERMISSION_HANDLER_INFO_PLIST`.
- Delete the app first (a fresh install never asked for the camera), then
  install a profile build: `flutter run --profile -d <device-id>`. Finish
  setup and unlock the Studio.
- Have ready: a sheet of paper with the word **BOOTH** in large letters, a
  round object (a plate or a coin) and a second app that uses the camera
  (the system Camera app, FaceTime or a video-call app).

## 1. Permission and repair (AC-0601)

1. Diagnostics > Camera test. The badge reads "Not asked yet", the card
   "The booth needs the camera" and the viewfinder "No camera access yet".
   No system prompt has appeared yet. Run the self-test from Diagnostics
   first: Camera reports "Not asked yet…", still with no prompt.
2. Tap **Allow camera**: the system prompt appears (on iPad, if it does
   not, the build compiled the permission out: stop and fix the build).
   Choose **Don't Allow**.
   - Android: the card reads "Camera access was refused" with "Allow
     camera" (asks again) and the Settings steps. Tap Allow camera, refuse
     again: the card becomes "Camera access is off for this app" with
     **Open Settings** and no Allow button.
   - iPad: the card reads "Camera access is off for this app" with the
     Settings steps and **Open Settings**.
3. Tap **Open Settings**: the system Settings opens on this app. Turn the
   camera on, return to the booth: within two seconds the preview is live
   without restarting the app (iPadOS may restart the app instead; record
   which, then reopen the camera test).
4. Turn the camera off again in Settings while the booth is in the
   background. Return: record whether the OS restarted the app (expected
   on both platforms) and that the camera test shows the off state with
   its repair, not a crash or a blank viewfinder.
5. iPad only: Screen Time > Content & Privacy Restrictions > Allowed Apps:
   turn Camera off. The camera test reads "The camera is blocked on this
   tablet" with no buttons. Turn it back on.
6. Event > Launch checks with the camera refused: the Camera row blocks
   with the matching repair; no prompt appears.

## 2. Cameras (AC-0602)

1. With access allowed: the Camera card offers **Front camera** and
   **Rear camera** (or says "This tablet has only a front camera.").
2. Switch lenses both ways: the preview changes within two seconds; the
   badges show the stream size and sensor angle of each lens.
3. Optional: plug in a USB camera (Android, iPad with USB-C). It is never
   offered and never chosen. Settings > Camera > "Cameras on this tablet"
   reads "Front and rear" (or the lens the tablet has).

Record per lens: stream size, sensor angle, zoom range shown.

## 3. Real stills (AC-0603 iPad, AC-0604 Android)

First the scripted check, once in each orientation, with camera access
already allowed (step 1, or on Android
`adb shell pm grant com.example.porcelain_photo_booth android.permission.CAMERA`):

```sh
flutter test integration_test/camera_capture_test.dart -d <device-id>
```

It uses the production camera service on every built-in lens in a
temporary area (the booth's own photos are untouched): two presses at
once save one photo, each still is over a megapixel and at least as large
as the preview stream, reads back intact, and is still listed and intact
after the store and database are reopened. Record the exit code and the
`M06 front:` / `M06 back:` lines it prints (size, bytes, EXIF, held,
sensor, stream, zoom, milliseconds from press to saved).

Then by hand, for each lens, in landscape and then portrait:

1. Hold the BOOTH paper facing the camera, with "Mirror the live preview"
   on and "Mirror saved photos" off. Tap **Take test photo** once.
2. "Test photo saved" and "Checked" appear within two seconds; the
   thumbnail shows BOOTH reading correctly (not mirrored) and upright.
3. Record the Size (expect the camera's full still size, for example
   4032 × 3024 on recent iPads; never the screen size), File size, Held
   and EXIF values.
4. Copy the file off the tablet and check it on a computer:
   - Android: `adb exec-out run-as com.example.porcelain_photo_booth cat
     files/originals/<id>.jpg > still.jpg` (the id is the newest file in
     `adb shell run-as com.example.porcelain_photo_booth ls -t files/originals`).
   - iPad: Xcode > Window > Devices and Simulators > the app > Download
     Container; the file is in `Library/Application Support/originals/`.
   - `exiftool still.jpg` (or `identify -verbose`): width, height and
     Orientation match the app's Size and EXIF; the photo shown upright by
     a viewer reads BOOTH correctly.
5. Turn "Mirror saved photos" on and take another: the app's thumbnail
   reads BOOTH mirrored, Prints reads "Mirrored", and the file on disk is
   still the camera's own, unmirrored image (mirroring is applied when
   rendering, M07).

## 4. Preview shape and mirroring (AC-0605)

1. Put the round object in view: it looks round, not oval, in both
   orientations and on both lenses. The viewfinder has the stream's shape
   (letterboxed rather than stretched if the screen differs).
2. Front camera, "Mirror the live preview" on: raise your right hand; it
   appears on the right of the screen, as in a mirror. Off: it appears on
   the left. Repeat on the rear camera: on mirrors, off does not.
3. Rotate the tablet with the preview live: it follows without stretching
   and recovers within two seconds.

## 5. Background, interruptions and no late shutter (AC-0606)

With the preview live:

1. Home (or swipe up), wait ten seconds, return: the preview is live again
   within two seconds; no new photo appears under Earlier test photos.
   While the booth is in the background the system camera indicator
   (iPad green dot / Android privacy chip) must be off: the camera was
   released.
2. Lock the screen, unlock: the same.
3. Pull down Control Center (iPad) or the notification shade (Android):
   the app is only inactive; the preview may pause; nothing is captured.
4. Open the other camera app (Split View, Stage Manager or multi-window
   where available, otherwise the app switcher), use its camera, return:
   the camera test shows "Another app is using the camera" or "The camera
   was interrupted" with **Try again**, which brings the preview back.
5. Tap **Take test photo** and immediately press Home: either one photo
   was saved before leaving, or none; on return no photo is taken by
   itself.
6. Repeat steps 1 and 4 twenty times. Android:
   `adb shell dumpsys media.camera | grep -A3 "Active Camera Clients"`
   shows no client for the booth while it is in the background. Record
   any failure to recover.

## 6. One photo per press (AC-0607)

1. Double-tap and then triple-tap **Take test photo** as fast as possible:
   each burst adds exactly one photo to Earlier test photos; while saving
   the button reads "Saving…".

## 7. Originals survive restarts (AC-0608)

1. Take three test photos. Force-quit the app (app switcher). Cold start,
   unlock, Diagnostics > Camera test: Earlier test photos lists them, each
   "Intact", newest first.
2. Restart the tablet and check again.
3. Install the next build over this one (do not delete): they are still
   listed and intact.
4. Compare each Size with the screen's pixel size: they differ (the still
   is the camera's, never a screenshot of the preview).

## 8. Enclosure (AC-0609)

With the tablet mounted in the booth enclosure, in the orientation the
event uses:

1. The front camera sits behind the enclosure's opening; the camera test
   preview shows no enclosure edge, shadow or reflection at any corner.
2. Take a test photo; inspect its corners at full size on a computer: no
   vignetting from the enclosure.
3. With the enclosure's lighting on, the BOOTH paper is evenly lit and
   sharp.

## 9. Timing and memory (informative)

1. Cold start to the Diagnostics camera test showing "Live": record
   seconds.
2. Take ten test photos in a row; record the time from press to "Test
   photo saved" for each, and peak memory (Xcode Instruments > Allocations
   / Android Studio Profiler > Memory).

Record: pass or fail for each step with device, OS, lens and orientation,
the copied still files' `exiftool` output, screenshots of steps 1.2, 1.3,
3.2 and 4.2, and anything that took over two seconds.
