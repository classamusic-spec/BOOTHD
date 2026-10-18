/// M01 render fixtures: documents, encoded inputs and pixel expectations
/// (T-02 FIX-01 and FIX-04). Geometry used below, in 1200x1800 page pixels:
///
/// * slot A (0): 120,108 960x720; photo A 1600x1200 vertical stripes,
///   cover scale 0.6, no crop.
/// * slot B (1): 120,972 960x720, 40 px corner radius; photo B 1200x1600
///   horizontal stripes, cover scale 0.8, crop rows 350..1250.
/// * flower: 300,600 600x600 (centre 600,900, disc radius 90): crosses the
///   bottom edge of slot A, the gap and the top edge of slot B.
/// * marker: 970,810 360x180 turned 90° clockwise about 1150,900, so it
///   covers x 1060..1240 and overflows the right page edge.
library;

import 'dart:typed_data';

import '../../../../domain/template/geometry.dart';
import '../../../../domain/template/page_spec.dart';
import '../../../../domain/template/template_document.dart';
import 'fixture_images.dart';
import 'png_encoder.dart';
import 'render_checks.dart';

abstract final class FixtureColours {
  static const ivory = Rgb(245, 240, 233);
  static const red = Rgb(200, 40, 40);
  static const white = Rgb(250, 250, 250);
  static const blue = Rgb(40, 70, 200);
  static const yellow = Rgb(240, 200, 40);
  static const gold = Rgb(232, 180, 60);
  static const pink = Rgb(236, 120, 150);
  static const markerLeft = Rgb(220, 30, 30);
  static const markerRight = Rgb(30, 30, 220);
  static const workspace = Rgb(0x8A, 0x8A, 0x8A);
  static const pageOutline = Rgb(0xE0, 0x21, 0x8A);
  static const black = Rgb(0, 0, 0);
  static const pureWhite = Rgb(255, 255, 255);
}

abstract final class FixtureAssets {
  static const photoA = 'photo-a';
  static const photoB = 'photo-b';
  static const flower = 'flower';
  static const marker = 'marker';
  static const haloWhite = 'halo-white';
  static const haloBlack = 'halo-black';
}

/// Petal opacity as stored in the PNG (8-bit).
const _petalAlpha = 191 / 255;

const fix01SlotAssets = {0: FixtureAssets.photoA, 1: FixtureAssets.photoB};

/// FIX-01. With [flowerBelowSlots], the flower paints under both photo slots
/// (global z-order check); otherwise above them.
TemplateDocument fix01({bool flowerBelowSlots = false}) => TemplateDocument(
  id: flowerBelowSlots ? 'fix01-flower-below' : 'fix01',
  page: PageSpec.fourBySixPortrait,
  backgroundArgb: FixtureColours.ivory.argb,
  layers: [
    const PhotoSlotLayer(
      id: 'slot-a',
      zIndex: 10,
      slotIndex: 0,
      frame: NormalizedRect(x: 0.1, y: 0.06, width: 0.8, height: 0.4),
    ),
    const PhotoSlotLayer(
      id: 'slot-b',
      zIndex: 11,
      slotIndex: 1,
      frame: NormalizedRect(x: 0.1, y: 0.54, width: 0.8, height: 0.4),
      cornerRadius: 40 / 1200,
    ),
    ImageLayer(
      id: 'flower',
      zIndex: flowerBelowSlots ? 5 : 20,
      assetId: FixtureAssets.flower,
      frame: const NormalizedRect(
        x: 300 / 1200,
        y: 600 / 1800,
        width: 600 / 1200,
        height: 600 / 1800,
      ),
    ),
    const ImageLayer(
      id: 'marker',
      zIndex: 30,
      assetId: FixtureAssets.marker,
      frame: NormalizedRect(
        x: 970 / 1200,
        y: 810 / 1800,
        width: 360 / 1200,
        height: 180 / 1800,
      ),
      rotationDegrees: 90,
    ),
  ],
);

/// Encoded FIX-01 inputs. [photoA] and [photoB] set the photo sizes (stripes
/// scale with them); larger sizes stand in for full-resolution originals.
Map<String, Uint8List> fix01Assets({
  PixelSize photoA = const PixelSize(1600, 1200),
  PixelSize photoB = const PixelSize(1200, 1600),
}) => {
  FixtureAssets.photoA: _png(
    stripes(
      width: photoA.width,
      height: photoA.height,
      stripePx: (100 * photoA.width / 1600).round(),
      vertical: true,
      even: FixtureColours.red,
      odd: FixtureColours.white,
    ),
  ),
  FixtureAssets.photoB: _png(
    stripes(
      width: photoB.width,
      height: photoB.height,
      stripePx: (100 * photoB.height / 1600).round(),
      vertical: false,
      even: FixtureColours.blue,
      odd: FixtureColours.yellow,
    ),
  ),
  FixtureAssets.flower: _png(flower(size: 800)),
  FixtureAssets.marker: _png(marker(width: 400, height: 200)),
};

Uint8List _png(RgbaImage image) =>
    encodePngRgba(width: image.width, height: image.height, rgba: image.pixels);

/// Export checks for FIX-01 with the flower above the slots (AC-0101..0103).
List<PixelCheck> fix01ExportChecks() => [
  const PixelCheck('slot A photo, stripe 0', 150, 300, FixtureColours.red),
  const PixelCheck('slot A photo, stripe 1', 210, 300, FixtureColours.white),
  const PixelCheck(
    'slot B photo, cover-cropped stripe 11',
    200,
    1600,
    FixtureColours.yellow,
  ),
  const PixelCheck(
    'slot B photo inside the rounded corner',
    150,
    1000,
    FixtureColours.yellow,
  ),
  const PixelCheck(
    'slot B rounded corner clips its photo',
    122,
    974,
    FixtureColours.ivory,
  ),
  const PixelCheck(
    'gap between slots shows the page',
    200,
    900,
    FixtureColours.ivory,
  ),
  const PixelCheck(
    'flower centre in the gap: overlay is not slot-clipped',
    600,
    900,
    FixtureColours.gold,
  ),
  const PixelCheck(
    'flower disc over slot A, across its bottom edge',
    600,
    815,
    FixtureColours.gold,
  ),
  const PixelCheck(
    'flower disc over slot B, across its top edge',
    600,
    985,
    FixtureColours.gold,
  ),
  const PixelCheck(
    'flower disc above slot A photo (z-order)',
    615,
    820,
    FixtureColours.gold,
  ),
  PixelCheck(
    'translucent petal over the page in the gap',
    765,
    900,
    FixtureColours.pink.over(FixtureColours.ivory, _petalAlpha),
  ),
  PixelCheck(
    'translucent petal over slot A photo',
    682,
    757,
    FixtureColours.pink.over(FixtureColours.white, _petalAlpha),
  ),
  const PixelCheck(
    'rotated marker: left half now on top',
    1100,
    820,
    FixtureColours.markerLeft,
  ),
  const PixelCheck(
    'rotated marker: right half now below',
    1100,
    980,
    FixtureColours.markerRight,
  ),
  const PixelCheck(
    'unrotated marker footprint stays empty',
    1000,
    900,
    FixtureColours.ivory,
  ),
  const PixelCheck(
    'marker continues to the page edge, then is cropped',
    1199,
    820,
    FixtureColours.markerLeft,
  ),
];

/// Workspace checks for FIX-01 rendered with a 10% margin (120 px, 180 px).
List<PixelCheck> fix01WorkspaceChecks() => [
  const PixelCheck(
    'marker overflow beyond the page is visible in the editor workspace',
    120 + 1220,
    180 + 820,
    FixtureColours.markerLeft,
  ),
  const PixelCheck(
    'workspace outside the page and artwork',
    60,
    60,
    FixtureColours.workspace,
  ),
  const PixelCheck(
    'page interior matches export: flower centre',
    120 + 600,
    180 + 900,
    FixtureColours.gold,
  ),
  const PixelCheck(
    'page edge is outlined',
    119,
    180 + 1000,
    FixtureColours.pageOutline,
  ),
];

/// Export checks for FIX-01 with the flower below both slots.
List<PixelCheck> fix01FlowerBelowChecks() => [
  const PixelCheck(
    'slot A photo now covers the flower disc',
    615,
    820,
    FixtureColours.red,
  ),
  const PixelCheck(
    'flower still visible in the gap outside the slots',
    600,
    900,
    FixtureColours.gold,
  ),
  PixelCheck(
    'translucent petal over the page in the gap',
    765,
    900,
    FixtureColours.pink.over(FixtureColours.ivory, _petalAlpha),
  ),
];

/// FIX-04 halo probe: a scaled, rotated disc whose hidden transparent colour
/// contrasts with both the disc and the page. Every output pixel must stay
/// the page colour.
({TemplateDocument document, Map<String, Uint8List> assets, Rgb expected})
fix04Halo({required bool whiteOnWhite}) {
  final colour = whiteOnWhite ? FixtureColours.pureWhite : FixtureColours.black;
  final hidden = whiteOnWhite ? FixtureColours.black : FixtureColours.pureWhite;
  final assetId = whiteOnWhite
      ? FixtureAssets.haloWhite
      : FixtureAssets.haloBlack;
  return (
    document: TemplateDocument(
      id: 'fix04-$assetId',
      page: const PageSpec(
        width: 2,
        height: 2,
        unit: LengthUnit.inch,
        dpi: 300,
      ),
      backgroundArgb: colour.argb,
      layers: [
        ImageLayer(
          id: 'disc',
          zIndex: 1,
          assetId: assetId,
          frame: const NormalizedRect(
            x: 0.12,
            y: 0.15,
            width: 0.61,
            height: 0.61,
          ),
          rotationDegrees: 17,
        ),
      ],
    ),
    assets: {
      assetId: _png(
        haloDisc(size: 500, colour: colour, transparentRgb: hidden),
      ),
    },
    expected: colour,
  );
}
