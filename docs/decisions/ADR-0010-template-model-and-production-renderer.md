# ADR-0010: Template document model, production renderer and template store

- Status: Accepted (M04, 2026-10-18). Builds ADR-0003 for production and
  answers the M04 items in ADR-0007's refactor plan; device questions stay
  open (section 11).
- Implements: A-05 (Template, TemplateRevision, Asset), A-06, A-07, A-11,
  A-15; owner-locked ADR-008 (slot clipping only clips photos).
- Covers: AC-0401..AC-0409. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M04).

## Context

M01 proved that one `dart:ui` painter can render FIX-01 exactly on the
host. M04 turns that spike into the production pipeline: a document format
templates can be stored, moved and migrated in; a scene shared by every
preview and the print export; JPEG and PNG output; atomic saving; and a
template store that refuses unsafe or damaged input. Constraints: no new
dependencies without need, offline only, bounded memory on tablets, and no
UI screenshots as output.

## Decision

### 1. Document schema v1 (pure Dart, `lib/domain/template/`)

- A `TemplateDocument` holds a page, an asset table and layers. Page:
  width and height in inches or millimetres plus DPI (72 to 1200); pixel
  size `round(width × dpi)` must be 1 to 20,000 per side and at most 40 MP.
  Presets: 2x6 (600x1800), 4x6 (1200x1800 / 1800x1200), 4x4 (1200x1200),
  all at 300 DPI.
- Geometry is normalised to the page: a frame's x/y may lie between -10
  and 10 and its size up to 20 page widths or heights, so decorations can
  sit off the page in the editor. Rotation is in degrees, clockwise, about
  a pivot given as a fraction of the frame (default its centre).
- Layers: background (solid, linear gradient with 2 to 8 stops, or image),
  photo slot (slot index, cover or contain fit, focal point, rectangle,
  rounded rectangle, ellipse or mask clip, optional border), image (fill,
  contain or cover, crop), text (bundled or imported font, size in points,
  colour, alignment, line height, letter spacing) and shape (rectangle,
  rounded rectangle or ellipse, fill, stroke). Every layer has a stable
  id, a global z-index, a name, opacity, visibility and a lock flag.
- Order: z-index ascending, ties in document order, for all layers. At
  most one background, with the strictly lowest z-index. Slots are
  numbered 0 to n-1 without gaps, at most 8.
- Colours are `#AARRGGBB`; sizes are points (px = pt × DPI / 72).
- Validation reports every problem with a code, a JSON path and a message;
  errors block saving and rendering, warnings (layer off the page, empty
  text, invisible shape, unused asset) do not.
- JSON: strict reading (unknown fields, unknown layer types and wrong
  types are errors, so nothing is half-understood and re-saved without
  it) and canonical writing (fixed field order, sorted asset ids, two-space
  indent, trailing newline). The revision checksum is the SHA-256 of the
  canonical bytes. `TemplateMigrations` upgrades older versions step by
  step and refuses newer ones (`TEMPLATE_NEWER_VERSION`); version 1 has no
  steps yet.

### 2. Scene and one painter (`lib/domain/template/document_scene.dart`, `lib/core/composition/`)

- `compileScene` turns a valid document plus the measured slot photos into
  an immutable scene in page pixels: fills, photo, image, text and shape
  nodes with placement, rotation and pivot, source crops in unmirrored
  source pixels, and the largest scale each image is drawn at.
- Mirrored photos: the cover crop is chosen in the mirrored (displayed)
  image, then mapped back to source pixels, so a focal point means what
  the guest saw.
- `paintScene` (core, so features can preview without infrastructure) is
  the only painter. Exports paint at scale 1; previews and the editor
  workspace scale the canvas and never lay text out again. Opacity applies
  to a layer as one group. Strokes sit inside the shape edge.
- Photos fill their slot shape through an image shader, so each edge is
  anti-aliased once. The first version clipped and then drew the image
  with its own anti-aliased edge; where a slot edge fell between pixels the
  two coverages multiplied (25% instead of 50%) and left a pale seam. The
  preview parity test found it (FIX-02 slot edges, FIX-03 rotated slots).
  Masks are applied with `dstIn` over more than the slot, without
  anti-aliasing and with edge pixels extended, so they scale the photo's
  edge instead of cutting it again.
- `compileRender` and `loadRenderResources` (core) are shared by the
  renderer and the `ScenePreview` widget: same validation, photo
  measurement, decode policy and font resolution.

### 3. Renderer (`lib/infrastructure/composition/`)

- Exports render offscreen at exactly the page's pixels from the original
  encoded inputs, one at a time (a future chain), since they hold the most
  memory. Previews may run alongside.
- Decode policy: every image decodes at `min(1, drawn scale × output
  scale)`, so a 12 MP photo in a 960 px slot decodes at about 960 px wide
  (FIX-01: 0.238 and 0.317). An image that no longer decodes to the size
  the scene was compiled against stops the render (`RENDER_IMAGE_MISMATCH`).
- Failures are typed (`RENDER_INVALID_DOCUMENT`, `RENDER_MISSING_ASSET`,
  `RENDER_MISSING_PHOTO`, `RENDER_UNREADABLE_IMAGE`,
  `RENDER_IMAGE_MISMATCH`, `RENDER_RASTERIZE_FAILED`,
  `RENDER_ENCODE_FAILED`); warnings (`RENDER_FONT_FALLBACK`,
  `RENDER_TEXT_OVERFLOW`) travel with the output for the operator.
- `rendererVersion = 1` is recorded with outputs.

### 4. Output formats and colour

- PNG: encoded by the engine (which writes sRGB and sBIT chunks), then a
  `pHYs` chunk is added for the page DPI (11,811 px/m at 300 DPI). Alpha is
  kept: a transparent page stays transparent.
- JPEG: an in-house baseline encoder (`lib/infrastructure/codecs/`):
  4:4:4 (no chroma subsampling, for crisp text and edges), Annex K tables
  scaled like libjpeg, AAN DCT, standard Huffman tables, JFIF with the page
  DPI, quality 80 to 100 from the event (default 92). Runs on a background
  isolate. Host PSNR on a synthetic 320x240 test image (gradients, a
  hard-edged disc, a sine pattern and noise): q80 40.0 dB, q92 42.5 dB,
  q100 51.0 dB; 1200x1800 encodes in about 110 ms (p50) on the host.
  Chosen over a platform codec bridge: no native code, identical bytes on
  both platforms, no new dependency.
- JPEG has no alpha, so the page is flattened on purpose onto an opaque
  colour (white by default; any colour can be passed) before painting.
- Colour: everything is sRGB. PNG says so; JPEG is untagged, which print
  services read as sRGB. Embedding an ICC profile waits for a chosen
  printer (A-13).

### 5. Fonts

- Bundled families: Inter (400, 500, 600) and Cormorant Garamond (500,
  600), with their licences (M02). Template text uses them by family and
  weight.
- Imported TTF or OTF files are assets: checked by header, then registered
  with the engine once per process under `porcelain-font-<first 16 hex of
  the id>`, so a changed file can never be mistaken for the old one.
- A missing, damaged or non-font file falls back to Inter, deterministically,
  with a `RENDER_FONT_FALLBACK` warning. Each paragraph forces a strut from
  its own font and line height, so a fallback glyph never moves lines. An
  imported copy of Inter renders identically to the bundled one (max
  delta 0).

### 6. Tolerances (AC-0407)

- Golden tolerance stays as ADR-0007 set it (threshold 8, at most 0.5% of
  pixels over, mean at most 1.0, geometry samples within 3), provisional
  until devices are measured.
- Preview parity: a preview at 1/4 size is compared with the export
  box-filtered to the same size. Outside text: threshold 16, at most 0.5%
  of pixels over, mean at most 1.0 (previews decode smaller and resample
  once, so hard edges inside photos differ by up to a pixel's blend;
  measured worst 0.137% over and mean 0.51). Text is rasterised by the
  font engine at the preview's size, so it is compared by geometry: the
  same number of lines and ink bounds within 1 preview pixel per side.
  Negative controls: a preview moved by 1 pixel fails, text moved by 2
  fails.
- The `ScenePreview` widget and the renderer's preview must agree within 1
  per channel (measured 0).

### 7. Atomic files (A-11)

- `AtomicFileWriter`: stage in `staging/` (same volume), write and flush,
  read back and compare, run the caller's check (decode, size), then rename
  into place. A destination is never replaced. On any failure the staged
  file is deleted; if even that fails, `ManagedStorage.prepare()` discards
  every `*.tmp` in `staging/` at the next start, before anything writes.
  Full disk (ENOSPC, EDQUOT) is reported as such.
- `FileExportService` writes `outputs/<uuid>.<jpg|png>`, verified by
  decoding to the page size, and returns the file's id, path, SHA-256,
  size, format and render version. Recording it against a session
  (RenderedOutput) comes with sessions in M06.

### 8. Template store and schema v2

- Assets are content-addressed: the id is the lowercase hex SHA-256 of the
  bytes, stored once at `assets/<id>.<png|jpg|ttf|otf>`. `crypto` is
  allowed in the domain for this (layer rules updated).
- An asset is accepted on its bytes, never its name or a claimed type:
  PNG (IHDR checked), baseline, extended or progressive Huffman JPEG
  (lossless, hierarchical and arithmetic-coded frames are refused),
  TrueType or OpenType with the required tables (collections and web fonts
  refused). Limits are checked on the header
  before decoding: 50 MB, 12,000 px per side, 50 MP; fonts 20 MB. Images
  are then fully decoded (at a small size) by the platform decoder, which
  also gives the size with EXIF orientation applied; that displayed size
  is what documents record. Names are reduced to a plain file name.
- Revisions are immutable: the canonical manifest is written once to
  `templates/<templateId>/<revisionId>.json`, then the revision (number,
  schema version, checksum, page size, slot count) and its asset links are
  recorded in one transaction. Loading checks the checksum. Every asset a
  document lists must already be stored as described.
- Drift schema v2 adds `assets` (immutable; id, media type, path derived
  from the id, sizes, name, origin; limits and path rule as CHECKs) and
  `template_revision_assets` (revision CASCADE, asset RESTRICT). The v1 to
  v2 step creates them through generated shapes, with foreign keys off
  inside one transaction that commits only if every link holds.

### 9. Template packages (`.porcelain-template`)

- A ZIP with `template.json` (`format`, `formatVersion` 1, template name
  and category, the document) and `assets/<id>.<ext>` for exactly the
  document's assets. Written stored, in a fixed order with a fixed
  timestamp, so the same revision always gives the same bytes.
- Read by a strict reader written for this (dart:io raw inflate; no new
  dependency): at most 100 MB, 216 entries, 50 MB per entry and 200 MB in
  total; deflated entries over 64 KB may expand at most 100 times;
  inflating stops the moment output passes the declared size. Refused:
  absolute, parent, backslash, drive and control-character paths, empty
  segments, symbolic links, duplicate names in any case, local headers
  that disagree with the directory, entries sharing bytes, encryption,
  other compression methods, ZIP64, split archives, CRC or size mismatches,
  trailing data, non-UTF-8 names. Nothing is ever extracted to a path.
- Import checks everything before storing anything: manifest (strict),
  document (strict, migrated, valid), each asset present, matching its id,
  type and declared size, and decoding. Then assets are stored and a new
  template is created; an existing template or revision is never touched.
  Files macOS adds when zipping (`__MACOSX/`, `.DS_Store`) are skipped.

### 10. Launch checks

The renderer check renders every template of the event at full print size
in the event's format, with a stand-in photo in each slot, and decodes the
result (a plain page when there are no templates); nothing is saved. The
template asset check verifies each manifest's checksum and every asset's
content id and decoded size. Problems block with their code.

## Consequences

- Preview and print share one scene and one painter; what the editor shows
  is what prints, within a stated tolerance, and text never re-wraps.
- The format is strict: a document from a newer app is refused rather than
  half-read, and a template changes only by adding a revision.
- PNG decoding still holds the full image briefly before resizing (M01
  finding 5); the 50 MP limit bounds that. Camera JPEGs decode scaled.
- The pure-Dart JPEG encoder costs about 110 ms per 4x6 on the host; device
  cost is unmeasured.
- No file picker yet: import works through `TemplatePackages`; choosing a
  file and the library screen are M05.

## Verification

`test/domain/template/` (document, JSON, scene), `test/rendering/` (render
lab, goldens, preview parity, text, output formats, benchmark),
`test/infrastructure/` (JPEG encoder, export service with fault injection,
asset and template repositories, ZIP reader, packages, launch checks),
`test/drift/booth/migration_test.dart` (v1 and v2 seeds).

## Open questions (need devices)

Device render time and memory for 4x6 with 12 MP camera JPEGs; the real
iPad and Android pixel difference against the host goldens (this decides
the final tolerance); JPEG encode time on tablet CPUs; whether scaled JPEG
decoding holds on both decoders. Procedure:
`docs/device_tests/M04_DEVICE_PROCEDURE.md`.
