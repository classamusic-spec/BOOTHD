# M01 device procedure: render and camera feasibility

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and a
physical Android tablet. Simulators and emulators do not count for
AC-0106/AC-0107. Record every result in `docs/ACCEPTANCE_EVIDENCE.md` (M01)
with the device model, OS version, app commit, build mode and date.

## 0. Setup

- Flutter 3.47.7 exactly; `tool/check.sh` passes.
- Android: enable USB debugging; `flutter devices` lists the tablet.
- iPad: follow `docs/IOS_VALIDATION.md` (Xcode, signing team, bundle ID,
  Developer Mode); `flutter devices` lists the iPad.
- Write down: model (Settings > About), OS version, front and rear camera
  positions on the device, enclosure if any.

## 1. Render spike (AC-0104, AC-0105), each device

1. `flutter drive --profile -d <device-id> --driver=test_driver/integration_test.dart --target=integration_test/render_spike_test.dart`
   - Expect "All tests passed". Results land in `build/m01_device/<platform>-<time>/`.
2. `flutter test test/rendering/device_render_comparison_test.dart`
   - Prints the pixel difference against the host golden; record it.
3. From `report.json`, record the sorted render totals (p50 is the middle
   value, p95 the second highest of ten) and `maxResidentBytes`.
4. GPU memory is not visible to Dart: capture it with Xcode Instruments
   (Allocations, Metal) or the Android Studio memory profiler while
   step 1 runs, and record peak values.
5. Optional visual check: `flutter run --profile`, then Home > Render
   spike > Run; all lines should read PASS.

## 2. Camera spike (AC-0106 iPad, AC-0107 Android), each device

Launch with `flutter run --profile -d <device-id>` (or debug), then Home >
Camera spike.

1. **First permission.** Tap Open camera. The OS prompt appears; choose
   Allow. Record that it appeared and the state shows `ready`.
2. **Front camera preview.** Is it stretched? (A round object must look
   round.) Raise your right hand: if it appears on the right side of the
   screen, the platform preview is mirrored by default. Record both.
3. **Capture.** Hold up a page with printed text and tap Capture still.
   Record the displayed line: decoded size, EXIF orientation, sensor
   degrees, bytes, SHA-256 prefix. In the thumbnail, is the text readable
   (saved photo not mirrored) or reversed? Record.
4. **Orientation.** Rotate the tablet to the other orientation and capture
   again. Record both sizes and EXIF values, and whether the thumbnail is
   upright.
5. **Rear camera** (if present): close, choose `back`, open, capture,
   record as above.
6. **Restart.** Kill the app from the app switcher, relaunch, open Camera
   spike. "Stored originals" must list every capture (each re-verified by
   checksum). Record the count.
7. **Interruption.** With the preview open, go to the home screen for 10
   seconds and return. The camera reopens (state `ready`), no photo was
   taken while away, and a new capture works. Record.
8. **Denial.** Reset the permission (iPad: delete and reinstall the app;
   Android: Settings > Apps > Porcelain Photo Booth > Permissions >
   Camera > Don't allow), tap Open camera, deny. Record the message shown
   and the reported permission (iPad: try again and record whether it
   becomes `permanentlyDenied`). Grant it in Settings and confirm Open
   camera works again.
9. Optional file check. Android: `adb shell run-as com.example.porcelain_photo_booth ls -l files/originals`
   (Flutter's support directory may differ; record the path you find).
   iPad: Xcode > Devices > download the app container and inspect
   `Library/Application Support/originals`. Compare a file's SHA-256 with
   the value shown on screen.

## Evidence template (one per device)

```text
AC-0106 or AC-0107 | date | tester
Device: <model>, <OS version>, app commit <sha>, <debug|profile>
Permission prompt: appeared yes/no; state after allow: ...
Front preview: stretched yes/no; mirrored by default yes/no
Capture 1 (portrait): <w>x<h>, EXIF <n>, sensor <deg>, <bytes>, sha <prefix>; text readable yes/no
Capture 2 (landscape): ...
Rear camera: ...
Restart: originals listed <n>/<n>
Interruption: reopened yes/no; stray capture yes/no
Denial: message ...; permission state ...; recovery ok yes/no
Render spike: PASS/FAIL; diff <max, mean, % over 8>; p50 <ms>, p95 <ms>; max RSS <MB>; GPU peak <MB>
Result: PASS / FAIL / BLOCKED (reason)
```
