# ADR-0003: Shared scene graph and offscreen export renderer

- Status: Accepted as direction; proved in M01, built for production in M04.
  ADR-0010 records the production design (the painter now lives in
  `lib/core/composition/` so previews can use it without infrastructure).
- Related: ARCHITECTURE A-06, A-07; ADR-008 (owner-locked clipping rule)

## Context

The product's core promise is that the editor preview and the 300 DPI export
agree exactly, and that decorative PNGs cross photo-slot boundaries while
only photographs are clipped to their slots. Screenshots of widgets are
banned as output.

## Decision

1. **Pure-Dart document → immutable scene.** A versioned template document
   (page size in physical units plus DPI, normalised geometry, stable layer
   IDs, global z-order) compiles to an immutable `DocumentScene` of ordered
   renderable nodes with explicit transforms and clip semantics. No Flutter
   imports in this layer (`lib/domain`), enforced by `test/architecture`.
2. **One painter for preview and export.** A Flutter painter
   (`lib/infrastructure/composition/`) walks the scene onto a `dart:ui`
   `Canvas`. Preview paints it into a viewport; export paints it with a
   `PictureRecorder` at exact output pixels (4x6 at 300 DPI = 1200x1800).
3. **Clipping rule (ADR-008):** each photo slot clips only its own photograph;
   image, text and shape layers are never clipped by slot masks; the export
   canvas is page-sized, so the page boundary crops overflow, while the
   editor viewport may show off-page artwork.
4. **Geometry is tested exactly; pixels within a stated tolerance.** Golden
   tests sample known coordinates (inside slot, outside slot under the
   overlay, outside page). Whole-image comparison allows a bounded
   per-channel tolerance that M01 measures across platforms; it is never
   loosened just to pass.

## Known risks the M01 spike must measure

- **JPEG encoding.** `dart:ui` encodes PNG but not JPEG. JPEG output needs a
  Dart encoder (slow at 1200x1800) or a small platform codec bridge. Measure
  both before choosing (A-07 step 6).
- **Decode memory.** A 12 MP original is about 48 MB as RGBA. Decode at the
  size the slot needs (codec target size) with bounded caches; measure peak
  memory per render.
- **Threading.** Rasterising `dart:ui` pictures is not freely isolate-safe;
  keep rendering on the UI isolate unless measurement justifies otherwise.
- **Fonts.** Template text needs bundled, licensed fonts for cross-platform
  determinism (FIX-05).

## Verification

AC-0101..AC-0105 (M01) and AC-0401..AC-0409 (M04).
