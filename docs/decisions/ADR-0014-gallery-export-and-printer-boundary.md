# ADR-0014: Operator gallery, export, deletion and the printer boundary

- Status: Accepted (M08, 2026-10-19). Device questions stay open
  (section 11).
- Implements: P-11 (local gallery), P-12 (export and printing boundary),
  P-13 (retention and deletion), A-04 `GalleryRepository` and
  `PrintService`, A-11 (journaled file operations), A-13 (printer
  boundary), S13 Gallery, S14 Session Detail, S16 Output Settings.
- Covers: AC-0801..AC-0807. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M08).
  Device steps: `docs/device_tests/M08_DEVICE_PROCEDURE.md`.

## Context

M07 left every guest session on the tablet: originals (with retakes), the
session's frozen plan and template revision, and its verified finished
photo. M08 gives the operator the gallery: find a session among
thousands, inspect everything recorded about it, make its finished photo
again, export files off the tablet without a network, and delete under
the event's retention rule. Printing stays unsupported until a printer is
chosen, and nothing may suggest otherwise.

## Decision

### 1. Schema version 6

- `capture_sessions.sequence`: the session's number within its event
  (1, 2, ...), unique per event and frozen with the plan (the plan
  trigger now covers it). New sessions take the event's highest number
  plus one; the 5 to 6 migration numbers existing sessions per event in
  the order they started. Numbers are what operators and export file
  names use. A number can return only if the event's newest session is
  deleted; export names also carry the date and time, so names do not
  collide.
- `session_outputs.origin`: `session` (the session's own finished photo,
  whoever triggered the render) or `rerender` (made again from the
  gallery). Existing rows become `session`.
- `export_batches` and `export_batch_items`: exports whose files left
  the tablet (what the share sheet reported, counts, file names). A
  dismissed share sheet sent nothing and is not recorded. Items go with
  their session; the batch keeps its counts.
- `pending_file_deletions`: the deletion journal (section 6).

All seeded versions v1 to v6 migrate with every value intact
(`test/drift/booth/migration_test.dart`).

### 2. The gallery index (S13, AC-0801)

`DriftGalleryRepository.sessions(eventId)` reads one light row per
session (number, status, times, counts, set completeness, newest output,
cover photo, last export) in one query with correlated subqueries on
indexed keys: 5,000 sessions in 340 ms on the host, in memory. The grid is
a `SliverGrid` built on demand, so only tiles near the screen exist, and
each tile asks for its thumbnail only when built: the paging that costs
memory (images) follows what is on screen; the light rows are needed
whole for counts, filters, "Select all" and search. Filters: All,
Finished, To finish (waiting to be finished or failed), Ended early.
Search: a session number (`42`, `#42`) or a time of day (`21:30`,
`9:30 pm`, `21:3` for ten minutes, `21:` for the hour), on the tablet's
clock.

Thumbnails (`ManagedThumbnailStore`): the source decoded at reduced size
by the platform decoder (EXIF orientation applied), encoded as a small
JPEG on a background isolate, written atomically to
`thumbnails/<kind>-<id>.jpg`, at most two made at once and each once.
Sources are immutable, so a thumbnail never goes stale; the cache can be
cleared at any time (Settings > Storage).

### 3. Session detail (S14, AC-0802)

Every camera photo by set, shot and attempt, the ones in the finished
photo marked; photo space to photo bindings; the frozen template
revision (name, revision number, page); every finished photo with its
pixel size, print size at its own resolution tag, format and quality,
size, origin and renderer version; the session's timeline, outcome and
frozen settings; and its export history. The newest finished photo is
read back against its checksum and checked (`PrintReadiness`): reads
back as saved, a complete standard file of the recorded format, the
template page's pixel size, and a print resolution tag. A file that fails
is labelled "Needs attention", never shown as ready.

### 4. Making a finished photo again (AC-0804)

`SessionRenderer` is now shared by the booth and the gallery, so both
render the same way: the frozen template revision, the unmodified
originals bound to its spaces, the plan's output profile and output
mirroring, exported atomically and read back against its checksum.
`GalleryService.render`:

- a session still waiting (`rendering`) is finished: `beginRender`,
  render, `complete`, as the booth does while idle;
- a completed, abandoned or failed session with a full set gets a new
  output (`addRerender`, origin `rerender`); the session row, its
  earlier outputs and the originals never change, and a failed or
  abandoned session keeps saying how it ended;
- an incomplete set, a guest still in the session or a missing original
  is refused, and nothing is recorded (a saved but unrecorded file is
  journaled for removal).

On the host a re-render is byte-identical to the first render
(`test/rendering/rerender_test.dart`). Device determinism (Impeller or
Skia on each tablet) is a device check.

### 5. Export (AC-0803, AC-0807)

Export goes through the platform share sheet (`share_plus` 13.3.1). It
is the only file export both platforms offer through maintained plugins:
`file_selector` 1.1.0 can open files on iPadOS and Android but cannot
save one to a folder the operator picks (iPadOS: open only; Android:
`getDirectoryPath` returns a tree URI `dart:io` cannot write). This is
the evidenced platform gap; a native "export to folder" bridge
(`UIDocumentPickerViewController` for exporting, Android
`ACTION_OPEN_DOCUMENT_TREE`) is an owner question (section 11), not
built: it could not be compiled for iPad or run on either tablet here.

`ManagedGalleryExporter`, per part of at most 200 files:

1. Checks free space for the copies plus 64 MB; if short, nothing is
   copied and the report gives the space needed and free.
2. Copies each file into `outgoing/<batch>/` under its export name
   (`<event>-<number>-<yyyymmdd>-<hhmm>.jpg`,
   `<event>-<number>-photo2-retake1.jpg`), checking the bytes read against
   the recorded length and checksum. Missing, damaged or uncopyable files
   are reported with their reason and left out; once the volume is full
   the rest are reported without trying. Sources are only read.
3. Offers the copies to the share sheet (iPadOS's Print action removed)
   and reports exactly what the platform said: the destination the
   operator chose (an iPadOS activity such as Save to Files or AirDrop,
   or the Android app component), a closed sheet, or that the platform
   cannot tell. The app says "handed to", never "saved": the platform
   reports the choice, not that the destination finished.

Parts whose files left are recorded in the export history; a closed sheet
can be offered again or skipped. The copies stay until the next export
or the next start (a destination may still be reading them). Nothing in
export needs a network; Save to Files on the tablet, a USB drive or
AirDrop work offline. Exported files open in two independent decoders
on the host (`test/rendering/external_viewer_test.dart`: ImageMagick and
Pillow, 1200 x 1800 at 300 dpi, full decode).

### 6. Deletion, retention and storage (AC-0805)

Every deletion is confirmed in a sheet. Deleting sessions, an archived
event or unassigned camera photos runs in one transaction that removes
the records (export items, outputs, photos, sessions, originals, the
event) and writes every file they owned, thumbnails included, to
`pending_file_deletions`. `ManagedStorageCleanup` then removes the files
and their journal rows; a file that cannot be removed stays journaled.
The journal runs after each deletion and at every start, so an
interrupted deletion always finishes and records never point at missing
files. Only photo, output and thumbnail paths are ever removed. There is
no "recently deleted" bin: deleted guest photos are gone (owner
question).

Retention ("delete after N days", from the session's start) is never
enforced silently: the gallery lists the event's sessions past it with
"Review and delete", and the deletion needs the explicit "Delete them
permanently" switch as well as the confirmation. Deleting an event needs
the event archived first, and the same switch when it has sessions. A
session a guest is still in is never deleted.

Settings > Storage shows the space finished photos and camera photos
use, camera photos in no session (camera tests, photos that arrived
after a session stopped waiting) with their own confirmed deletion, the
thumbnail cache, free space and files still waiting to be removed.

### 7. The printer boundary (AC-0806)

`PrintService` (capabilities, submit, status), `PrintRequest` (output,
page, format, copies), `PrintCapabilities` and `PrintJobStatus`
(`unconfigured`, `queued`, `submitted`, `physicalCompleted`, `failed`,
`operatorAttention`) are defined so a future adapter can tell a job
handed to the OS from a verified print. `UnconfiguredPrintService` is the
only adapter: capabilities say not configured, a request returns
`unconfigured` with no job id, and nothing is queued. Output Settings
reads it ("Not configured"); no screen has a print control. Android's
share sheet may list a system print app the app cannot hide; the app
neither submits nor tracks prints there.

### 8. Output presets and quality (AC-0807)

Output Settings lists the print sizes with their exact pixel sizes,
orientation and resolution (from `PagePreset`), keeps the JPEG or PNG
and quality defaults, and measures the space per finished photo from the
tablet's own files. Every finished photo's detail shows its pixel size,
print size, format and quality explicitly.

## Rejected alternatives

- **Keyset paging of session rows**: counts, "Select all" and search
  need the whole event; the light index is measured fast enough, and
  images (the real cost) are already paged by visibility.
- **Automatic retention deletion**: the spec makes retention
  operator-controlled with explicit confirmation; silent deletion of
  guest photos is not acceptable.
- **A trash bin**: keeps guest photos past the operator's decision and
  past retention; left as an owner question.
- **Exporting from managed paths without copies**: names would be
  `outputs/<uuid>.jpg` and Android copies them anyway.
- **A native export-to-folder bridge now**: see section 5.

## Consequences

- Schema version 6; 30 new goldens of gallery screens; Settings gains
  Storage.
- The booth controller delegates rendering to `SessionRenderer`; its
  behaviour is unchanged (M07 tests pass as before).
- Startup also finishes the deletion journal; a failure there never
  blocks the booth.

## Verification

Host tests: `gallery_repository_test.dart` (index at 5,000 sessions,
details, files, usage, cutoffs, atomic and journaled deletions),
`gallery_files_test.dart` (export copies and reports, space and full
volume, cleanup after interruption, thumbnails),
`rerender_test.dart` (real renderer: byte-identical re-render, nothing
else changes, refusals), `external_viewer_test.dart`,
`gallery_rules_test.dart`, `print_file_facts_test.dart`,
`gallery_export_run_test.dart`, `gallery_flow_test.dart` (2,000
sessions on screen, export, re-render, deletion, retention, archived
events, no print controls, Booth Mode isolation), the migration test,
the screen catalog and goldens. Devices: BLOCKED until run
(`docs/device_tests/M08_DEVICE_PROCEDURE.md`).

## Open questions

Owner:

- A native "Export to folder" (iPadOS document picker for exporting,
  Android folder access) with the exact destination reported, beside
  the share sheet?
- A "Recently deleted" bin (for example 7 days), or permanent deletion
  as built?
- Should retention ever delete without the operator (it does not now)?

Devices (need physical tablets):

- The share sheet's destinations and what each platform reports (iPadOS
  activity types; Android chosen component, which some apps do not
  report) with 1, 50 and 200 files, offline.
- Exported files opening in Files, Photos and Google Photos on the
  tablets and on a computer at 4 x 6 inches.
- Re-render byte-identity on each tablet, and thumbnail time and memory
  on a 2,000-session event.
