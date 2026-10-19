# M10 device procedure: resilience, backup and kiosk readiness

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and
a physical Android tablet. The host tests cover the logic; only the
tablets can show how the operating systems behave. Record each result in
`docs/ACCEPTANCE_EVIDENCE.md` (M10) with the device, OS version, app
commit, build mode and date. Until then the device halves of
AC-1001..AC-1008 stay BLOCKED.

**Exit gate:** on both tablets, a kill at any moment loses no completed
photo; a backup made on one tablet restores on a freshly installed app;
the kiosk method chosen keeps guests in the booth; airplane mode changes
nothing for guests.

## 0. Setup

- A profile build of the commit under test on each tablet (M07 procedure
  section 0), a computer for backups (AirDrop, Files, or USB transfer).
- An event with a 2-photo portrait template and 20 or more sessions in
  the gallery.

## 1. First run, unlock, recovery (AC-1001)

1. Delete and reinstall the app. Complete first-run setup; note the
   recovery code.
2. Lock the Studio; unlock with the PIN. Enter a wrong PIN five times:
   record the wait shown. Use "Forgot PIN" with the recovery code and set
   a new PIN.

## 2. Kiosk (AC-1002)

For each method available (Guided Access on iPad; Single App Mode if a
supervised iPad and a management service exist; app pinning on Android;
lock task if a managed Android tablet exists):

1. Open Settings > Kiosk lock before turning the method on: record that
   it shows "Guests can leave the booth app" with the "Not locked" badge.
2. Turn the method on (`docs/KIOSK_DEPLOYMENT.md` sections 1 and 2) and
   tap Check again: record the state shown (expected: "Locked to the booth
   app", "Pinned to the booth app" or "Locked by device management").
   For Single App Mode, record what is shown: whether iPadOS reports it as
   Guided Access is an open question (ADR-0016).
3. Run the launch checks: "Kiosk lock" passes with the lock on and warns
   with "How to lock" without it; it never blocks.
4. Follow `docs/KIOSK_DEPLOYMENT.md` section 4 (try to leave the booth).

Record which methods were tested and which are BLOCKED.

## 3. Launch checks (AC-1003)

1. With everything ready and the tablet locked: every check passes
   (printing is "For information").
2. Revoke the camera permission in system settings: the camera check
   blocks with the steps to fix it.
3. Fill the tablet until under 1 GB is free: the free-space check warns
   and Start Booth Mode stays available; under about 120 MB (one
   session) it blocks.
4. Rotate against the event's orientation (with the rotation lock off):
   the orientation check warns.

## 4. Kills and recovery (AC-1004)

For each moment below, kill the app (iPad: swipe up from the app
switcher; Android: swipe it away, or `adb shell am force-stop
com.example.porcelain_photo_booth`), reopen it, and record what the
gallery shows:

1. During the countdown before a photo.
2. Right after "Photo saved" (the original is committed).
3. During "Creating your photo" (the finished photo is being rendered).
4. Right after the finished screen appears.
5. During a gallery deletion of 10 sessions.
6. During "Creating backup".

Expected: no completed photo is lost; a session left mid-way shows as
ended early; an unmade finished photo is made at the next start; a
deletion finishes; no partial backup file is offered.

## 5. Low storage (AC-1005)

Fill the tablet (large video files) until the booth's free-space check
warns, then until it blocks. Run a session at each step. Expected: the
booth never says "saved" for a photo it could not keep; earlier photos
stay in the gallery; the guest is told to ask the host.

## 6. Backup and restore (AC-1006)

1. Settings > Backup: make an "Everything" backup; share it to the
   computer. Record its size and the time it took.
2. Delete the app; reinstall it. On the first screen choose "Restore from
   a backup", pick the file. Record the summary shown.
3. After the restore: set a new PIN; check that the events, templates and
   every session's photos are back (open three finished photos), and that
   texting shows "not paired".
4. Restore the same backup on the other platform (iPad to Android and
   back), if both are available.
5. Try a backup cut short (copy only half the file): the restore refuses
   it and the booth stays empty.

## 7. Logs, permissions and device backups (AC-1007)

1. During a full session with an error forced (a camera permission
   denial; a full tablet), read the device log: Console.app filtered on
   `porcelain:` for the iPad, `adb logcat -s flutter` for Android. Record
   that no path, file name, phone number, link or token appears.
2. Android: `tool/audit_permissions.sh` on the installed build's APK
   passes; Settings > Apps > Porcelain Photo Booth > Permissions lists
   the camera only. iPad: Settings > Privacy & Security lists the app
   under Camera only.
3. iPad: after a session, Settings > [your name] > iCloud > Manage
   Account Storage > Backups > this iPad: Porcelain Photo Booth is
   absent or a few kilobytes, not the size of its photos. Record the
   size shown.

## 8. Airplane mode (AC-1007 audit)

Turn on airplane mode. Run sessions, the gallery, an export (AirDrop
needs Wi-Fi and Bluetooth radios but no network) and a backup. Expected:
nothing changes, and no message mentions the network unless texting is
on.

## 9. Privacy controls (AC-1008)

Follow `docs/OPERATOR_PRIVACY_AND_DATA.md` section 4: delete one session,
then an archived event, then check the gallery and free space.
