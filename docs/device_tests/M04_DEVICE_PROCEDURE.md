# M04 device procedure: production renderer

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and a
physical Android tablet. Simulators and emulators do not count. Record every
result in `docs/ACCEPTANCE_EVIDENCE.md` (M04) with the device model, OS
version, app commit, build mode and date. This replaces section 1 of the M01
procedure; the camera part of M01 is unchanged.

## 0. Setup

- Flutter 3.47.7 exactly; `tool/check.sh` passes on the commit under test.
- Android: USB debugging on; `flutter devices` lists the tablet.
- iPad: follow `docs/IOS_VALIDATION.md` (Xcode, signing team, bundle ID,
  Developer Mode); `flutter devices` lists the iPad.
- Close other apps. Note the battery level and whether the device is
  charging (thermal state affects timings).

## 1. Render lab (AC-0402..AC-0407, AC-0409), each device

1. Run, in profile mode:

   ```sh
   flutter drive --profile -d <device-id> \
     --driver=test_driver/integration_test.dart \
     --target=integration_test/render_lab_test.dart
   ```

   Expect "All tests passed". The driver saves every export under its
   golden's file name, plus `report.json`, in
   `build/device_renders/<platform>-<time>/`.
2. Compare with the host goldens:

   ```sh
   flutter test test/rendering/device_render_comparison_test.dart
   ```

   It prints, for each of the six goldens (FIX-01 export and workspace,
   FIX-02, FIX-03, FIX-05, CLIP), the maximum and mean difference and the
   share of pixels over the threshold. Record all six lines per device. A
   failure here is a finding, not something to tune away: keep the run's
   folder and report it.
3. From `report.json` record: `passed`, every `summary` line marked FAIL
   (there should be none), the ten sorted render totals
   (`repeatTotalMsSorted`: p50 is the fifth or sixth value, p95 the
   tenth), and `maxResidentBytes`.
4. The summary also lists the FIX-05 text probes and the preview parity
   lines for each fixture; record them. Text parity is where platforms are
   most likely to differ.
5. GPU and native memory are not visible to Dart: record peak values from
   Xcode Instruments (Allocations and Metal) or the Android Studio memory
   profiler while step 1 runs.
6. Optional visual check: `flutter run --profile`, then Studio >
   Diagnostics > Render lab > Run the fixture suite. Every line reads PASS;
   look at the thumbnails for anything odd (seams at photo edges, fringes
   around the flower, text in the wrong font).

## 2. Repeated exports and memory (AC-0409), each device

Run `flutter drive` from step 1 three times in a row without restarting the
device. Record `maxResidentBytes` from each run; it should not climb run
over run by more than a few MB.

## 3. Launch checks in the app (each device)

Templates cannot be imported on a device until the library screen (M05),
so the app's own renderer check runs on its test page:

1. Install a profile or release build, finish setup, create an event
   (Events > New event) and save it as a draft.
2. Open its launch checks (event > Launch checks). "Renderer" must read
   Passed: "A test page rendered at full print size as JPEG; nothing was
   saved." "Template images and fonts" reads "No templates to check yet."
3. Change the event's output to PNG, save, and check again: the renderer
   line now says PNG. Record both texts and how long "Check again" takes.

## Evidence template (one per device)

```text
M04 render lab | date | tester
Device: <model>, <OS version>, app commit <sha>, profile
Render lab: passed yes/no; FAIL lines: none / <list>
Goldens vs host (max / mean / % over 8):
  fix01_export ..., fix01_workspace ..., fix02 ..., fix03 ..., fix05 ..., clip ...
Text probes: left/centre/right/lines PASS/FAIL (ink bounds)
Preview parity (per fixture): ...
FIX-01 JPEG export totals (ms, sorted): [...]; p50 ..., p95 ...
maxResidentBytes: run 1 ..., run 2 ..., run 3 ...
Peak GPU/native memory (Instruments or profiler): ...
Launch checks: renderer JPEG text ..., PNG text ..., time ...
Battery/charging/thermal: ...
```
