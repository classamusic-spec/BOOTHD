# M08 device procedure: gallery, export, re-render and deletion

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and
a physical Android tablet. Simulators, emulators and the host test suite
do not count for any step here. Record every result in
`docs/ACCEPTANCE_EVIDENCE.md` (M08) with the device model, OS version,
app commit, build mode, orientation and date. Until this is done the
device halves of AC-0801..AC-0807 stay BLOCKED.

**Exit gate:** on both tablets, offline, the operator inspects,
re-renders and exports every kind of asset; printing is shown as not
configured and nothing offers it.

## 0. Setup

- Flutter 3.47.7 exactly; `tool/check.sh` passes on the commit under
  test. Install a profile build as for M07
  (`docs/device_tests/M07_DEVICE_PROCEDURE.md` section 0).
- Run at least 12 real guest sessions on the portrait event (M07
  procedure section 2), including: one with a retake, one where the
  guest walks away at review (operator exit), one left after the first
  photo, and, if it can be provoked, one whose finished photo failed.
- Turn on **airplane mode** (Wi-Fi, mobile data and Bluetooth off) for
  every step except AirDrop, which needs Bluetooth and Wi-Fi radios but
  no network.
- A computer to receive files (USB drive, AirDrop, or USB file transfer
  for Android).

## 1. Gallery at scale (AC-0801)

1. Studio > Gallery. The latest event is chosen; its card shows the
   session count and finished count; the summary shows its dates and the
   space it uses.
2. Scroll the grid from top to bottom and back, quickly. Record any
   stutter, blank tiles that stay blank, and memory in the platform tool
   (Xcode Instruments Allocations / Android Studio Profiler).
3. Filters: To finish and Ended early show the right sessions with the
   right counts. Search `#3`, then a time such as `21:3`.
4. Record the number of sessions tested. Gallery behaviour at 2,000 and
   5,000 sessions is covered on the host only; a device run at that scale
   needs an event that large (M11 endurance).

## 2. Session detail (AC-0802)

For a session with a retake, record that the detail shows: every camera
photo with the retake and the earlier attempt both kept, "In the
finished photo" on the photos used, Photo space bindings matching what
the finished photo shows, the template name and revision, 1200 × 1800 px,
4 × 6 in at 300 dpi, JPEG quality, "Print-ready" with four passed checks.

## 3. Re-render (AC-0804)

1. On a finished session tap **Make again**. A second version appears;
   "identical to the newest" shows when the bytes match. Record whether
   they match on this tablet (byte-identity can differ between GPUs).
2. Export both versions (section 4) and compare them on the computer
   (`sha256sum`, or `magick compare -metric AE`).
3. On a session that ended early with every photo taken: **Make finished
   photo**. Its outcome still says how it ended.
4. Confirm the first version's file is unchanged (its checksum in the
   export history matches).

## 4. Export (AC-0803, AC-0807)

1. Select 3 sessions including one without a finished photo; **Export** >
   Finished photos > **Choose destination**.
2. iPad: Save to Files > On My iPad; then again to a USB drive; then
   AirDrop to a Mac. Android: Files by Google (or the OEM file manager),
   then Quick Share / Nearby Share. Record, for each: what the report
   says ("Handed to …"), the failure line for the session without a
   finished photo, and that the files arrived with their names.
3. Close the share sheet without choosing: the report says nothing was
   sent; **Share again** works.
4. Repeat with "Finished and camera photos" for one session: retakes
   arrive as `-photo2-retake1.jpg`.
5. 200+ files: select all on an event with more than 200 sessions; the
   export goes in parts; record the time per part.
6. Open the exported finished photos on the tablet (Files, Photos /
   Google Photos) and on the computer (Preview / Photos / an image
   viewer): they open, show 1200 × 1800 px and 300 dpi (4 × 6 in).
7. Low space: fill the tablet until less than the export needs; the
   report states the space needed and free and nothing is copied.

## 5. Deletion and retention (AC-0805)

1. Delete one session: the confirmation appears; Keep leaves it; Delete
   removes it from the grid; Settings > Storage shows the space returned.
2. Interrupt a large deletion: select 50 sessions, Delete, and force-quit
   the app within a second. Reopen: the sessions are gone and Storage
   shows no files waiting (the journal finished at start).
3. Retention: set an event to "30 days" with sessions older than that
   (change the tablet's date forward 31 days with the app closed). The
   gallery offers "Review and delete"; Delete stays disabled until
   "Delete them permanently" is on. Restore the date afterwards.
4. Archive an event and delete it from Events (Delete, switch,
   Delete). Its sessions are gone from the gallery.

## 6. Printing (AC-0806)

1. Settings > Output and printing: Printer reads "Not configured" with
   the explanation; there is no print control.
2. Gallery and session detail: no print control anywhere. iPad share
   sheet: no Print action. Android share sheet: record whether a system
   print app is listed (the app cannot hide it and does not track it).

## 7. Booth Mode isolation

Start Booth Mode; with a keyboard or `adb shell am start` deep links, try
`/studio/gallery` and a session URL: Booth Mode stays on the welcome
screen.
