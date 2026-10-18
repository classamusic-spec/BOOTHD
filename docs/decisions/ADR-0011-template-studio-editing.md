# ADR-0011: Template Studio editing, drafts, library and display-scale decoding

- Status: Accepted (M05, 2026-10-18). Builds on ADR-0010; amends its
  preview decoding (section 5 below). Device questions stay open
  (section 9).
- Implements: A-08 (editing, undo and autosave), S06 to S12 (library,
  editor, asset browser, layers, inspector, preview, packages), CR-002
  (starter designs from the owner's boards).
- Covers: AC-0501..AC-0510. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M05).

## Context

M04 delivered the document model, the one scene painter and the template
store. M05 needs an editor that operators use on a tablet in either
orientation: direct manipulation with exact numbers, layers, undo, drafts
that survive a crash or a closed app, a library with import and export,
and a canvas that shows exactly what prints, including artwork that
crosses photo spaces or runs off the page. Constraints: offline, bounded
memory with 20 or more layers, no new UI packages in features, plugins
only behind domain interfaces.

## Decision

### 1. Editing is pure Dart (`lib/domain/template/editing/`)

- `DocumentEdits`: add, remove, duplicate (copies placed just above,
  slot copies take the next numbers), update or replace one layer, move in
  the paint order, bring forward or back, translate a set of layers,
  renumber slots (by swapping). Each returns a normalised document; the
  caller validates. `NewLayers` makes photo spaces, text, shapes and
  images with sensible frames; `copyLayer` copies any layer type.
- `EditHistory`: immutable document snapshots, at most 100 undo steps.
  A gesture (drag, pinch, rotation, slider, a typing session in a number
  field) is one step however many updates it has. It remembers the saved
  document, so "unsaved changes" is exact after undo, redo and save, and
  undo continues past a save.
- `LayerGeometry`: rotated frames in page pixels; resize from any handle
  keeps the opposite corner fixed in place whatever the rotation; rotation
  snaps to 15 degrees; changing the pivot keeps the layer where it is.
  `snapping.dart` snaps edges and centres to the page, other layers and
  the grid (an eighth of an inch) within 8 screen pixels and reports the
  guides to draw.

### 2. The controller owns the working state (`features/template_studio`)

- `TemplateEditorController`: document and history, selection, view
  options, the compiled scene and its decoded images, drafts and saving.
  It belongs to the screen, not the layout, so rotating the tablet keeps
  selection, history and zoom (UX-03).
- Every committed edit is validated (`document.errors`); a failing edit
  throws `InvalidEdit` and changes nothing; a failing gesture step is
  skipped and the gesture goes on.
- Autosave (A-08): a draft is written 1.2 s after the last change, never
  in the middle of a gesture, when the app leaves the foreground and when
  the editor closes. Undoing back to the saved document removes the
  draft. A refused write shows "draft couldn't be kept" and the work stays
  in memory. Save stores a new immutable revision and removes the draft;
  a refused save keeps everything. Reopening offers the draft (a draft
  equal to its revision is discarded unseen); "Discard" returns to the
  revision.

### 3. Drafts in the database (schema v3)

- `template_drafts`: one row per template (template, base revision,
  canonical document JSON up to 1 MB, time), deleted with the template or
  its base revision. Drafts count as using their assets, so an image in
  unsaved work cannot be removed.
- Asset rows may now change only their shown name (S08 rename): the
  immutability trigger covers the content columns only. Migration v2 to v3
  replaces the trigger and adds the table; v1 and v2 databases open as v3
  in the migration tests.

### 4. The canvas is the print painter

- The page is drawn by `paintScene`, the export's own painter, at the
  view's scale, over the paper colour. Artwork beyond the page shows
  through a 65% overlay of the workspace colour (PRODUCT_SPEC: visible in
  the editor, not exported); the export clips at the page edge.
- Editor aids are painted in screen space over it: grid, print-safe
  margin (an eighth of an inch), slot numbers, selection outlines, eight
  resize handles and a rotation handle (48 dp hit areas), snap guides.
- Gestures start from each finger's touch-down point, not from where they
  cleared the touch slop: a dragged layer stays under the finger, a handle
  is grabbed where it was touched, a pinch keeps the point between the
  fingers in place. One finger moves the selection or pans empty space
  (always pans with the Pan tool); two fingers zoom and pan.
- Photo spaces show the generated placeholder (`slot_placeholder.dart`:
  a soft card with a camera mark, no people), as do thumbnails and
  previews.

### 5. Images decode at the size they show (amends ADR-0010)

- Finding (AC-0510 test): the canvas first decoded artwork at print size
  and drew it at the view's scale. At a quarter, bicubic filtering of a 4x
  larger image aliases thin strokes; the canvas differed from the
  renderer's own preview by up to 4% of pixels.
- Decision: the canvas reports its zoom times the screen's pixel density
  to the controller, which decodes each image with `decodeScaleFor`, the
  same rule the renderer uses for previews. The first decode happens at
  once; after the view or the layers have been still for 250 ms every
  image is decoded again at exactly its new size. One decode per image at
  a time; an unreadable image shows a hatched tile and is listed as
  missing in the inspector.
- Second finding: the engine's codec shrinks in one bilinear step from
  2x2 samples, so beyond a 2x reduction it drops thin lines and edges that
  the print keeps. Decision: outputs smaller than the print (previews,
  thumbnails, the canvas) decode at twice the size they show, never above
  full size, and the painter does the last reduction. Exports (scale 1)
  are unchanged; every export golden is identical.
- Measured on the host (`editor_parity_test.dart`): the canvas is the
  renderer's preview pixel for pixel (max delta 0 or 1) at 1/2 and 1/4,
  for all nine starting points (five designs, four blank pages). Against
  the 300 dpi export box-filtered down, outside text (ADR-0010 tolerance:
  threshold 16, at most 0.5% over, mean at most 1.0), share of pixels over
  16 and mean, decoding at the shown size (before) and at twice it
  (after):

  | Design | 1/2 before | 1/2 after | 1/4 before | 1/4 after |
  | --- | --- | --- | --- | --- |
  | Classic Strip | 0.343%, 0.262 | 0.000%, 0.096 | 1.083%, 0.519 | 0.173%, 0.319 |
  | Floral Elegance | 1.144%, 0.692 | 0.377%, 0.374 | 3.024%, 1.364 | 1.374%, 0.880 |
  | Modern Minimal | 0.000%, 0.194 | 0.000%, 0.217 | 0.204%, 0.316 | 0.000%, 0.240 |
  | Retro Film | 0.327%, 0.515 | 0.156%, 0.304 | 4.525%, 1.932 | 0.306%, 0.550 |
  | Gold Celebration | 0.013%, 0.407 | 0.002%, 0.303 | 1.875%, 1.145 | 0.025%, 0.516 |

  Blank pages: 0 everywhere. Target tablets show a fitted page at 0.5 to
  1 screen pixel per print pixel (iPad at density 2, Android tablets at
  1.5 to 2.25), so 1/2 is held to the tolerance. At 1/4 (only when zoomed
  out below the fitted size on a density-1 screen) Floral Elegance's
  dense petals still exceed it; those figures are recorded, not held.
- The M04 lab fixtures still pass AC-0407 at 1/4. Before and after, over
  16 and mean: FIX-01 0.137%/0.508 to 0.030%/0.546; FIX-01b 0.081%/0.505
  to 0.025%/0.563; FIX-02 unchanged (0.000%/0.012); FIX-03 0.000%/0.034
  to 0.083%/0.043; CLIP 0.121%/0.107 to 0.214%/0.150; GRADIENT and FIX-05
  unchanged. Thin artwork gains; rotated and masked photo edges lose a
  little, inside the tolerance. The tolerance itself is unchanged.
- Cost: a preview image may hold up to four times the pixels of an exact
  decode, never more than its full size. M07 must budget guest-photo
  thumbnails with this in mind (a risk carried forward in the
  implementation log).

### 6. Library, files and packages

- `TemplateLibrary` (core): create from a starter design or a blank page,
  duplicate ("… copy"), rename, archive and restore, open (revision plus
  draft), save, drafts, image import (refused unless PNG or JPEG by
  content), decorations stored on first use, package export
  (`<name>-r<n>.porcelain-template`, `application/zip`) and import.
- `OperatorFiles` (domain interface; `PlatformOperatorFiles` over
  `file_selector` 1.x and `share_plus` 13.x in infrastructure): the
  document picker returns the file's bytes at once, after a size check
  against the limit, so nothing depends on the picker's temporary file
  (AC-0508); the share sheet gets the bytes, a file name, a MIME type and
  an anchor rectangle (required on iPad). Pickers filter loosely by
  extension, MIME type and UTType; the stores decide by content.
- Rename sheets own their text controllers (`showPorcelainNameSheet`):
  the first version disposed the controller while the sheet was still
  closing, found by the new flow tests.

### 7. Thumbnails and previews

- Library cards, the event editor's template list, the guest welcome's
  sample print and the template preview are rendered by the renderer with
  placeholders in the photo spaces, cached per revision (thumbnails at
  most 540 px on the long side; the welcome print at most 1,400). Starter
  design cards render from the bundled files before anything is stored.
- The template preview (S11) shows the renderer's preview at screen size
  or the full 300 dpi render, with the render's warnings.

### 8. Tests

- Widget tests use `MemoryTemplateStore` (in-memory futures that settle
  under the fake clock, validation like the real stores, failure
  injection for full disks); the file-backed stores have their own tests.
  Engine work (decoding, rendering) only completes in real time:
  `settleRendering` and `runAsync`. Futures cached across tests resume in
  their creation zone, so caches hold results, not futures; the renderer
  must be constructed in real time for exports in widget tests (its export
  queue is a future).
- New: editor parity (AC-0510, section 5), controller autosave, drafts,
  save failures and undo steps, a 30-layer stress run, library and import
  flows, image rename and removal.

## Consequences

- One painter for canvas, thumbnails, previews and print; the editor
  cannot drift from the output without the parity test failing.
- Canvas memory follows what is on screen, not print size; zooming in
  re-decodes after a pause (a brief soft image while it does).
- Preview fidelity improved for thin artwork; slightly lower for some
  rotated photo edges (inside tolerance).
- Packages and imported images never reference picker paths.

## Verification

`tool/check.sh` (generated code, format, analyze, all tests, licences);
`editor_parity_test.dart`, `preview_parity_test.dart`,
`editor_controller_test.dart`, `template_stress_test.dart`,
`template_library_flows_test.dart`, `template_studio_test.dart`,
`template_library_test.dart`, `starter_designs_test.dart`, migration
tests v1 to v3, screen checks and goldens for every new screen.

## Open questions

1. Device performance with 20+ layers (frame times while dragging, decode
   bursts after zooming) and memory on 3 to 4 GB tablets: needs the M05
   device procedure.
2. Whether operators want an "off-page artwork" toggle (PRODUCT_SPEC says
   "if enabled"); it is always shown, faded, today.
3. Bleed: documents have none yet; the export clips at the trim.
