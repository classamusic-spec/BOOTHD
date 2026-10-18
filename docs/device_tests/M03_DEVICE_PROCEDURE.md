# M03 device procedure: storage, operator PIN and route isolation

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and a
physical Android tablet. Simulators and emulators do not count. Record
every result in `docs/ACCEPTANCE_EVIDENCE.md` (M03) with the device model,
OS version, app commit, build mode and date. Never write a PIN or recovery
code into the evidence.

## 0. Setup

- Flutter 3.47.7 exactly; `tool/check.sh` passes.
- Android: enable USB debugging; `flutter devices` lists the tablet.
- iPad: follow `docs/IOS_VALIDATION.md`; `flutter devices` lists the iPad.
- Start from a clean install: delete the app first (Android: also
  `adb uninstall com.example.porcelain_photo_booth`).
- Steps 1 to 6 use a release build (`flutter run --release -d <id>`);
  step 7 needs a debug build on Android (`run-as` only works there).

## 1. First-run setup (AC-0301)

1. Launch. Expect the Welcome step. Tap Begin setup, then Continue.
2. Enter `111111`: expect "That PIN is too easy to guess…" and nothing
   saved. Enter a non-obvious PIN, then a different confirmation: expect
   "Those PINs didn't match. Choose your PIN again." Then enter the PIN
   twice correctly.
3. The recovery code appears once. Write it down. Continue stays disabled
   until "I've written this code down" is on.
4. Name the booth, choose a look, Finish setup. Expect the dashboard.
5. Kill the app (app switcher) and relaunch: expect the PIN screen with the
   booth name, never the dashboard.

Record: each expectation met or not.

## 2. Unlock time on the device (ADR-0009, PBKDF2 120,000 iterations)

Screen-record (iPad: Control Centre; Android: `adb shell screenrecord`)
while entering the correct PIN five times, locking the Studio in between
(Lock Studio in the sidebar). For each, count frames from the sixth digit
appearing to the dashboard appearing. Record the five times and the
median. Over one second is a finding to report.

## 3. Rate limit and lockout (AC-0301)

1. On the PIN screen enter five wrong PINs. Expect "That PIN isn't right.
   N tries left before a short wait." counting down, then "Too many tries.
   You can try again in 0:30." with a live countdown and the pad disabled.
2. While locked, kill and relaunch the app. Expect the lockout to continue,
   not reset.
3. Optional: while locked, set the device clock back one hour (Settings),
   relaunch: expect a full lockout from now, not an unlock. Restore the
   clock.
4. After the lockout, the correct PIN unlocks and the counter resets.

## 4. Recovery code (AC-0301)

1. Lock the Studio. Tap Forgot PIN?, enter the recovery code with or
   without dashes, set a new PIN.
2. A new recovery code appears; the old one must now fail (check after the
   next lock).
3. Three wrong recovery codes: expect a one-minute lockout.

## 5. Persistence across restarts (AC-0302, AC-0303)

1. Create an event: title, date, venue; Capture: rear camera, mirror saved
   photos on, Landscape, 2 photos, 5 s countdown, whole-session retakes,
   2 retakes; Guests: Light Oak theme; Privacy: "For a set time".
   Save. Duplicate it, archive the copy, reopen the copy.
2. Force-stop the app (Android: `adb shell am force-stop
   com.example.porcelain_photo_booth`; iPad: swipe away in the app
   switcher). Relaunch, unlock, open the event: every value must match.
3. Power the tablet off and on. Repeat the check.
4. Settings: change the default camera, orientation and output; create a
   new event and confirm it starts with those defaults.

Templates: production M03 builds have no template library (M04/M05), so
the Templates tab shows the empty library and no event can be activated
yet. That is expected.

## 6. Route isolation on the device (AC-0305)

On an M03 build an event cannot pass its launch checks (camera and
renderer checks are "Not yet available" until M04 to M06, and there are no
templates), so Booth Mode cannot be started on a device yet. Device checks
of Booth Mode (system back, gestures, Home and Recents, relaunch into the
guest welcome, the hidden three-second exit) move to the first build that
can launch an event; until then they are covered by the widget tests listed
in the evidence. What can be checked now:

1. Studio locked: use the system back button or gesture on the PIN screen.
   Expect to stay on the PIN screen. If the platform closes the app
   anyway, relaunching must show the PIN screen again, never the Studio.
2. Unlocked: Lock Studio, then system back. Expect the PIN screen to stay.

## 7. No plaintext secrets, no backup (Android debug build)

1. After setup, list the app's storage:
   `adb shell run-as com.example.porcelain_photo_booth ls -R`.
2. Pull the database:
   `adb exec-out run-as com.example.porcelain_photo_booth cat files/database/porcelain_booth.sqlite > booth.sqlite`
   (if the path differs, take it from step 1). In `sqlite3 booth.sqlite`,
   `SELECT recovery_verifier, pin_failures FROM operator_access;` must show
   a `pbkdf2-sha256$...` value, never the code.
3. Search all pulled files for your PIN digits and recovery code: no hit
   is expected (a chance six-digit match inside encrypted data is possible;
   check its context).
4. Backup: `adb shell bmgr backupnow com.example.porcelain_photo_booth`.
   Expect it to be refused or the package reported as not eligible
   (`allowBackup=false`, data-extraction rules). Record the output.

iPad: the Keychain item is "this device only" and cannot be inspected
without developer tools; record only that unlock works after a restart and
after a power cycle (steps 1 and 5).

## Recording template

```text
Device: <model> | OS <version> | build <commit> <release/debug> | <date>
1 setup:        PASS/FAIL notes
2 unlock times: <t1..t5>, median <m> ms
3 lockout:      PASS/FAIL notes (restart, clock)
4 recovery:     PASS/FAIL notes
5 persistence:  PASS/FAIL notes (force-stop, power cycle, defaults)
6 isolation:    PASS/FAIL notes (Booth Mode parts: not testable in M03 builds)
7 secrets:      PASS/FAIL notes (Android only), bmgr output
```
