# ADR-0016: Resilience, backup and restore, logs, permissions and kiosk readiness

- Status: Accepted (M10, 2026-10-19). What only the tablets can settle is
  listed in section 11 and stays BLOCKED until they are available.
- Implements: A-11 (journaled file operations and recovery), A-12
  (security, secrets and logs), P-13 (retention and deletion), UX-04
  (first run, unlock, recovery), the kiosk, permission and backup
  requirements of `CLAUDE.md` and `docs/FLUTTER_PLATFORM_STRATEGY.md`.
  Closes the iPadOS device-backup risk ADR-0009 left for M10.
- Covers: AC-1001..AC-1008. Evidence: `docs/ACCEPTANCE_EVIDENCE.md`
  (M10). Device steps: `docs/device_tests/M10_DEVICE_PROCEDURE.md`.
  Operator guides: `docs/KIOSK_DEPLOYMENT.md`,
  `docs/OPERATOR_PRIVACY_AND_DATA.md`.

## Context

By M09 the booth captures, renders, keeps a gallery, exports and
(optionally) texts. Before a commercial pilot it must survive what venues
do to tablets: the app killed mid-write, storage running out, a tablet
lost or replaced, guests poking at the system interface, and operators
who need to know what the booth keeps and how to remove it. None of this
may need a network.

## Decision

### 1. A backup is one checked tar file

Settings > Backup makes `porcelain-backup-YYYYMMDD-HHMM.tar`, a POSIX
ustar archive under one root folder `porcelain-backup/`:

| Entry | What |
| --- | --- |
| `README.txt` | What the file is and that it holds guests' photos |
| `database.sqlite` | A `VACUUM INTO` snapshot of the booth database, scrubbed (below) |
| `files/<area>/...` | Template revisions and images; with "Everything", camera photos and finished photos |
| `manifest.json` (last) | Format version, app and schema version, contents, booth name, counts, and every entry's size and SHA-256 |

- **Scrubbed before it is archived:** the texting pairing is deleted, the
  recovery code's verifier is cleared, and "Setup only" also deletes
  sessions, photos and export history. The PIN's verifier lives in
  platform secure storage and pending phone numbers in secure storage
  only, so neither can be in a backup.
- **Checked before it is offered:** the finished file is read back from
  the start: every entry's header, size and SHA-256 against the manifest.
  Only then is it moved out of staging and handed to the share sheet. It
  is made only when the tablet has room for it (estimate plus a 256 MB
  margin).
- **Why tar, written by the app:** photos are already compressed, so a
  container that streams and never inflates suits them; a reader that
  refuses anything unusual is smaller than auditing a zip library
  against zip bombs and traversal (CLAUDE.md). The reader refuses links,
  devices and extended headers, absolute or parent paths, names outside
  the root, duplicates, bad checksums, truncation and anything over the
  limits (400,000 entries, 4 GiB per entry, 512 GiB in all). The format
  is standard: `tar -tf` lists it.

### 2. Restore only into an empty booth, swapped in before the database opens

The first screen of a booth with nothing on it offers "Restore from a
backup". A restore never mixes with a booth in use (events, sessions or
photos refuse it).

1. **Inspect:** the chosen file is copied into staging (never read from a
   temporary picker location afterwards) and checked from end to end as
   in section 1. A newer format or schema version is refused. Nothing in
   the booth has changed yet; a refused file says why.
2. **Stage:** the copy is extracted beside the live data
   (`restore/unpack-<id>`), the database is checked (`integrity_check`,
   `user_version` no newer than the app's, every recorded file present
   in the archive), then renamed to `restore/incoming` and marked
   `restore/ready.json`.
3. **Swap:** the app starts again in place (`RestartableApp` replaces the
   provider scope and waits for the database connection to close). At
   the next start, before the database opens, `PendingRestore` moves
   every file into its area, then the database, and marks the restore
   applied. Each step is a rename and can be repeated: a swap cut off
   half-way finishes at the next start; an extraction never marked ready
   is discarded.
4. **Finish:** once the database is open (and migrated, for a backup
   from an older version), setup is marked unfinished, the recovery
   state is reset, any pairing is gone and texts that were waiting are
   closed (`NOT_RESTORED`: their numbers were never in the backup). The
   first screen says what came back and asks for a new PIN and recovery
   code.

### 3. Recovery after a kill at any stage (AC-1004)

The write paths from A-11 already stage, verify and rename, and camera
photos are journaled (`pending_original_commits`). M10 closes the gaps a
kill could still leave:

- **Orphan sweep at startup only.** A file renamed into place whose
  record was never written (a finished photo, a template image, a
  template revision) is removed; a camera photo nothing refers to is
  moved to `originals/.quarantine/`, never deleted. Files the deletion
  journal still lists are left to it. The sweep runs after the journal
  and before anything can write, never after a deletion, so it cannot
  race a save in progress.
- **Backup and restore working files** have names the next start
  recognises (`BackupStaging`) and are discarded with other staged
  files; anything else in staging is left alone.
- **Tests stop a real save at a stage for good** (a file operation that
  never returns, as if the process died there) and start again on the
  same files and database. Throwing instead would run each layer's
  clean-up, which a kill does not. Matrix: camera photo, finished photo,
  template image and template revision, each killed during the staged
  write, before the rename and after the rename; a deletion killed
  before its files went; a backup and a restore killed half-way.
  Afterwards nothing is staged, records and files match one to one and
  the photos saved before the kill are untouched
  (`test/persistence/kill_recovery_test.dart`).

### 4. Low storage never claims success (AC-1005)

A session does not start below the room one session needs, and a photo
or finished photo that cannot be written is never called saved (M06,
M07). The launch checks now block only when not even one session fits
and warn below the booth's 1 GB budget or when the tablet does not say;
backups and restores check room before they start.

### 5. Launch checks block only critical problems (AC-1003)

Blocks: event not active or invalid, templates missing or unrenderable,
camera unavailable or refused, storage not writable, no room for one
session, operator PIN unreadable. Warns: low or unknown free space, the
tablet's shape against the event's orientation, no kiosk lock. Printing
is information only (export-only release). A table test pins each case.

### 6. Kiosk: read the lock, never set it (AC-1002)

The app cannot lock a tablet to itself and never says it can. A
read-only bridge (`porcelain/kiosk`, one method) reports
`ActivityManager.getLockTaskModeState` on Android (lock task or pinned)
and `UIAccessibility.isGuidedAccessEnabled` on iPadOS. Settings > Kiosk
lock shows it with the two methods of the tablet's platform (Guided
Access or supervised Single App Mode; app pinning or managed lock task),
and the launch check passes only when the tablet reports a lock,
otherwise it warns with the guide one tap away. A test checks the
native code never calls `startLockTask`, `stopLockTask`,
`setLockTaskPackages` or `requestGuidedAccessSession`. Native code is
used because Flutter has no API for either state (CLAUDE.md: evidenced
gap, narrow interface), as for free space (ADR-0012).

### 7. One sanitized way to the device log (AC-1007)

`SafeLog` is the only code that writes to the device log; an
architecture test forbids `print`, `debugPrint`, `dart:developer`,
`stdout`/`stderr` and debug dumps anywhere else. Every line is cleaned of
photo data, paths and file names, phone numbers, e-mail addresses, links
(the host is kept) and tokens; UUIDs and timestamps stay readable for
support. Uncaught framework and asynchronous errors go through it from
startup, by type and cleaned message, with stack traces in debug builds
only. Release builds draw a widget that failed to build as a plain grey
area; guests never see an error's text.

### 8. Permissions: camera, and the network for texting only (AC-1007)

The release APK's merged manifest is audited by
`tool/audit_permissions.sh` in CI: `CAMERA`, `INTERNET` and androidx's
own receiver permission, nothing else. The audit found
`ACCESS_NETWORK_STATE`, added by CameraX's video library (media3); the
booth records no video and never asks the network's state, so it is
removed. iPadOS asks for the camera only; App Transport Security stays at
its defaults and there are no background modes.

### 9. The booth's data stays out of the tablet's own backups

Android already excludes app data from cloud backup and device transfer
(ADR-0009). On iPadOS every start marks the storage root
`isExcludedFromBackup` through the existing `porcelain/device_storage`
channel, so neither iCloud nor a computer backup carries guests' photos;
a failure is logged and never stops the booth. The booth's own backup is
the way to move a booth. iPadOS may keep the app's Keychain entries after
the app is deleted; a reinstalled booth replaces them (section 2 of the
operator guide).

### 10. Privacy controls are documented for operators (AC-1008)

Consent text, retention per event and deletion were built in M03, M08 and
M09; `docs/OPERATOR_PRIVACY_AND_DATA.md` says what the booth keeps,
where, for how long, how to delete it and what a backup holds.

## Consequences

- A lost or replaced tablet can be rebuilt from one file, which holds
  guests' photos and must be stored like any personal data; the app says
  so and never puts secrets in it.
- Startup does a little more (a sweep that reads the paths of every
  record once), before anything can take a photo.
- Three narrow native calls now exist: free space, backup exclusion and
  the kiosk lock state. Each fails safe (unknown, logged, warning).
- Directory entries are not fsynced after a rename (Dart has no API for
  it). An app kill cannot lose a rename; a power loss at that instant
  might on some file systems, which only a device test can show.

## Verification

Host tests: tar reader and writer, byte-for-byte round trip into an empty
sandbox, refusals, the interrupted swap, the restart, the kill matrix and
the sweep, the launch-check table, the kiosk bridge and guide, SafeLog
and the logging rule, the permission audit, airplane mode (no connection
opened by a guest session or thirteen Studio screens), device backup
exclusion, and the operator screens with goldens. Evidence lists the
commands and results.

## Open questions (device only, BLOCKED)

1. Kill, low-storage and power-loss behaviour on the certified tablets.
2. Whether iPadOS reports supervised Single App Mode as Guided Access.
3. That `isExcludedFromBackup` keeps the booth out of an iCloud backup
   (Settings > Apple Account > iCloud > Manage Storage > Backups).
4. Backup and restore of a full event between real tablets, including
   iPad to Android and back, and the time and space they take.
