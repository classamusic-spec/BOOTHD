// AC-0401 (validation part), AC-0402 (one global z-order): the template
// document's rules, enforced before anything is saved or rendered.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/template/document_issues.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';

import '../../support/template_builders.dart';

List<DocumentIssueCode> errorCodes(TemplateDocument document) => [
  for (final issue in document.errors) issue.code,
];

List<DocumentIssueCode> warningCodes(TemplateDocument document) => [
  for (final issue in document.validate())
    if (!issue.isError) issue.code,
];

PhotoSlotLayer slot(int index, {String? id, int z = 10}) => PhotoSlotLayer(
  id: id ?? 'slot-$index',
  zIndex: z + index,
  slotIndex: index,
  frame: const NormalizedRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3),
);

void main() {
  group('page presets (AC-0405)', () {
    test('release 1 formats have the exact pixel sizes at 300 dpi', () {
      expect(
        {
          for (final preset in PagePreset.all)
            preset.id: (preset.page.widthPx, preset.page.heightPx),
        },
        {
          '2x6': (600, 1800),
          '4x6': (1200, 1800),
          '6x4': (1800, 1200),
          '4x4': (1200, 1200),
        },
      );
    });

    test('millimetre pages and other resolutions convert exactly', () {
      const a6 = PageSpec(
        width: 105,
        height: 148,
        unit: LengthUnit.millimetre,
        dpi: 300,
      );
      expect((a6.widthPx, a6.heightPx), (1240, 1748));
      expect(PageSpec.fourBySixPortrait.pixelsPerPoint, 300 / 72);
    });

    test('pages outside the limits are refused', () {
      for (final page in [
        const PageSpec(width: 0, height: 6, unit: LengthUnit.inch, dpi: 300),
        const PageSpec(width: 4, height: 6, unit: LengthUnit.inch, dpi: 50),
        const PageSpec(width: 4, height: 6, unit: LengthUnit.inch, dpi: 5000),
        const PageSpec(width: 70, height: 4, unit: LengthUnit.inch, dpi: 300),
        const PageSpec(width: 40, height: 40, unit: LengthUnit.inch, dpi: 300),
        const PageSpec(
          width: double.nan,
          height: 6,
          unit: LengthUnit.inch,
          dpi: 300,
        ),
      ]) {
        expect(
          errorCodes(sampleDocument(page: page)),
          contains(DocumentIssueCode.invalidPage),
          reason: '$page',
        );
      }
    });
  });

  test('the sample document is valid, with no warnings', () {
    expect(sampleDocument().validate(), isEmpty);
  });

  group('global z-order (AC-0402)', () {
    test('paint order is ascending z, ties in document order, for every '
        'layer type', () {
      final document = sampleDocument(
        layers: [
          const ShapeLayer(
            id: 'top',
            zIndex: 50,
            frame: NormalizedRect.page,
            shape: ShapeKind.rect,
            fill: ink,
          ),
          slot(0, z: 20),
          ImageLayer(
            id: 'under-slot',
            zIndex: 5,
            assetId: TestAssets.flower,
            frame: NormalizedRect.page,
          ),
          const ShapeLayer(
            id: 'tie-a',
            zIndex: 30,
            frame: NormalizedRect.page,
            shape: ShapeKind.rect,
            fill: ink,
          ),
          const ShapeLayer(
            id: 'tie-b',
            zIndex: 30,
            frame: NormalizedRect.page,
            shape: ShapeKind.rect,
            fill: ink,
          ),
        ],
        assets: {TestAssets.flower: TestAssets.png},
      );
      expect(
        [for (final layer in document.paintOrder) layer.id],
        ['under-slot', 'slot-0', 'tie-a', 'tie-b', 'top'],
      );
    });

    test('there is at most one background, and it is the lowest layer', () {
      expect(
        errorCodes(
          sampleDocument(
            layers: const [
              BackgroundLayer(id: 'a', zIndex: 0, fill: SolidFill(ivory)),
              BackgroundLayer(id: 'b', zIndex: 1, fill: SolidFill(ink)),
            ],
            assets: const {},
          ),
        ),
        contains(DocumentIssueCode.multipleBackgrounds),
      );
      expect(
        errorCodes(
          sampleDocument(
            layers: [
              slot(0, z: 0),
              const BackgroundLayer(
                id: 'bg',
                zIndex: 5,
                fill: SolidFill(ivory),
              ),
            ],
            assets: const {},
          ),
        ),
        [DocumentIssueCode.backgroundNotLowest],
      );
    });
  });

  group('layers', () {
    test('ids are well formed and unique', () {
      expect(
        errorCodes(
          sampleDocument(
            layers: [slot(0, id: 'a b')],
            assets: {},
          ),
        ),
        [DocumentIssueCode.invalidLayerId],
      );
      expect(
        errorCodes(
          sampleDocument(
            layers: [
              slot(0, id: 'same'),
              slot(1, id: 'same'),
            ],
            assets: {},
          ),
        ),
        [DocumentIssueCode.duplicateLayerId],
      );
    });

    test('photo slots take photos 1 to n without gaps or repeats', () {
      expect(
        errorCodes(sampleDocument(layers: [slot(0), slot(2)], assets: {})),
        [DocumentIssueCode.slotsNotContiguous],
      );
      expect(
        errorCodes(
          sampleDocument(
            layers: [
              slot(0),
              slot(0, id: 'again'),
            ],
            assets: {},
          ),
        ),
        [DocumentIssueCode.duplicateSlotIndex],
      );
      expect(errorCodes(sampleDocument(layers: [slot(8)], assets: {})), [
        DocumentIssueCode.invalidSlotIndex,
      ]);
    });

    test('frames may leave the page, within limits, and a layer wholly '
        'off the page is only a warning', () {
      final offPage = sampleDocument(
        layers: [
          const ShapeLayer(
            id: 'outside',
            zIndex: 1,
            frame: NormalizedRect(x: 1.2, y: 0.1, width: 0.3, height: 0.3),
            shape: ShapeKind.rect,
            fill: ink,
          ),
          const ShapeLayer(
            id: 'crossing',
            zIndex: 2,
            frame: NormalizedRect(x: -0.2, y: 0.9, width: 0.5, height: 0.3),
            shape: ShapeKind.rect,
            fill: ink,
          ),
        ],
        assets: {},
      );
      expect(offPage.errors, isEmpty);
      expect(warningCodes(offPage), [DocumentIssueCode.offPage]);

      for (final frame in [
        const NormalizedRect(x: 0, y: 0, width: 0, height: 0.2),
        const NormalizedRect(x: 11, y: 0, width: 0.2, height: 0.2),
        const NormalizedRect(x: 0, y: 0, width: 25, height: 0.2),
        const NormalizedRect(x: double.infinity, y: 0, width: 1, height: 1),
      ]) {
        expect(
          errorCodes(
            sampleDocument(
              layers: [
                ShapeLayer(
                  id: 's',
                  zIndex: 1,
                  frame: frame,
                  shape: ShapeKind.rect,
                  fill: ink,
                ),
              ],
              assets: {},
            ),
          ),
          [DocumentIssueCode.invalidGeometry],
          reason: '$frame',
        );
      }
    });

    test('rotation that brings a layer back onto the page is not off-page', () {
      // A tall bar just right of the page, turned 90° about its left edge's
      // middle, swings onto the page.
      final document = sampleDocument(
        layers: const [
          ShapeLayer(
            id: 'swing',
            zIndex: 1,
            frame: NormalizedRect(x: 1.01, y: 0.3, width: 0.1, height: 0.4),
            shape: ShapeKind.rect,
            fill: ink,
            rotationDegrees: 90,
            pivot: NormalizedPoint(-1, 0.5),
          ),
        ],
        assets: {},
      );
      expect(document.validate(), isEmpty);
    });

    test('opacity, corner radii, focal points and crops stay in range', () {
      final bad = sampleDocument(
        layers: [
          const PhotoSlotLayer(
            id: 's',
            zIndex: 1,
            slotIndex: 0,
            frame: NormalizedRect(x: 0, y: 0, width: 0.5, height: 0.5),
            opacity: 1.5,
            focal: NormalizedPoint(1.2, 0.5),
            clip: RoundedRectClip(0.6),
          ),
          ImageLayer(
            id: 'i',
            zIndex: 2,
            assetId: TestAssets.flower,
            frame: NormalizedRect.page,
            crop: const NormalizedRect(x: 0.5, y: 0, width: 0.6, height: 1),
          ),
        ],
        assets: {TestAssets.flower: TestAssets.png},
      );
      expect(errorCodes(bad), [
        DocumentIssueCode.invalidValue,
        DocumentIssueCode.invalidGeometry,
        DocumentIssueCode.invalidGeometry,
        DocumentIssueCode.invalidGeometry,
      ]);
    });

    test('borders are not allowed on mask-shaped slots', () {
      final document = sampleDocument(
        layers: [
          PhotoSlotLayer(
            id: 's',
            zIndex: 1,
            slotIndex: 0,
            frame: const NormalizedRect(x: 0, y: 0, width: 0.5, height: 0.5),
            clip: MaskClip(TestAssets.mask),
            border: const Stroke(widthPt: 1, color: ink),
          ),
        ],
        assets: {TestAssets.mask: TestAssets.png},
      );
      expect(errorCodes(document), [DocumentIssueCode.borderWithMask]);
    });

    test('bundled fonts are used only at their bundled weights', () {
      TemplateDocument withFont(FontRef font) => sampleDocument(
        layers: [
          TextLayer(
            id: 't',
            zIndex: 1,
            frame: NormalizedRect.page,
            text: 'Hi',
            font: font,
            sizePt: 12,
            color: ink,
          ),
        ],
        assets: const {},
      );
      expect(
        withFont(
          const BundledFont(BundledFontFamily.cormorantGaramond, weight: 600),
        ).validate(),
        isEmpty,
      );
      expect(
        errorCodes(
          withFont(const BundledFont(BundledFontFamily.cormorantGaramond)),
        ),
        [DocumentIssueCode.unsupportedFontWeight],
      );
      expect(errorCodes(withFont(AssetFont(TestAssets.font))), [
        DocumentIssueCode.missingAsset,
      ]);
    });

    test('text, shape and stroke values stay in range; empty text and '
        'invisible shapes are warnings', () {
      final document = sampleDocument(
        layers: const [
          TextLayer(
            id: 't',
            zIndex: 1,
            frame: NormalizedRect.page,
            text: ' ',
            font: BundledFont(BundledFontFamily.inter),
            sizePt: 0,
            color: ink,
            lineHeight: 9,
          ),
          ShapeLayer(
            id: 's',
            zIndex: 2,
            frame: NormalizedRect.page,
            shape: ShapeKind.ellipse,
          ),
          ShapeLayer(
            id: 'stroked',
            zIndex: 3,
            frame: NormalizedRect.page,
            shape: ShapeKind.rect,
            stroke: Stroke(widthPt: 0, color: ink),
          ),
        ],
        assets: {},
      );
      expect(errorCodes(document), [
        DocumentIssueCode.invalidValue,
        DocumentIssueCode.invalidValue,
        DocumentIssueCode.invalidValue,
      ]);
      expect(warningCodes(document), [
        DocumentIssueCode.emptyText,
        DocumentIssueCode.invisibleShape,
      ]);
    });

    test('gradients have 2 to 8 stops in order', () {
      TemplateDocument gradient(List<GradientStop> stops) => sampleDocument(
        layers: [
          BackgroundLayer(
            id: 'bg',
            zIndex: 0,
            fill: LinearGradientFill(angleDegrees: 90, stops: stops),
          ),
        ],
        assets: {},
      );
      expect(
        gradient(const [GradientStop(0, ivory), GradientStop(1, ink)])
            .validate(),
        isEmpty,
      );
      expect(errorCodes(gradient(const [GradientStop(0, ivory)])), [
        DocumentIssueCode.invalidValue,
      ]);
      expect(
        errorCodes(
          gradient(const [GradientStop(0.6, ivory), GradientStop(0.4, ink)]),
        ),
        [DocumentIssueCode.invalidValue],
      );
    });
  });

  group('assets', () {
    test('every referenced asset is listed with the right kind', () {
      final missing = sampleDocument(
        assets: {TestAssets.flower: TestAssets.png},
      );
      expect(errorCodes(missing), [DocumentIssueCode.missingAsset]);

      final wrongKind = sampleDocument(
        assets: {
          TestAssets.flower: TestAssets.ttf,
          TestAssets.font: TestAssets.ttf,
        },
      );
      expect(errorCodes(wrongKind), [DocumentIssueCode.wrongAssetKind]);
    });

    test('asset records are checked, and unused ones are warnings', () {
      final document = sampleDocument(
        assets: {
          TestAssets.flower: TestAssets.png,
          TestAssets.font: TestAssets.ttf,
          'NOT-A-HASH': TestAssets.png,
          TestAssets.paper: const TemplateAsset(
            mediaType: AssetMediaType.png,
            byteLength: 10,
            widthPx: 20000,
            heightPx: 20000,
          ),
        },
      );
      expect(errorCodes(document), [
        DocumentIssueCode.invalidAsset,
        DocumentIssueCode.invalidAsset,
        DocumentIssueCode.invalidAsset,
      ]);
      expect(warningCodes(document), [
        DocumentIssueCode.unusedAsset,
        DocumentIssueCode.unusedAsset,
      ]);
    });

    test('asset ids are the SHA-256 of the bytes', () {
      expect(
        assetIdOf('abc'.codeUnits),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(isAssetId(TestAssets.flower), isTrue);
      expect(isAssetId(TestAssets.flower.toUpperCase()), isFalse);
    });
  });

  test('documents compare by value', () {
    expect(sampleDocument(), sampleDocument());
    expect(sampleDocument().hashCode, sampleDocument().hashCode);
    expect(sampleDocument(page: PageSpec.fourByFour), isNot(sampleDocument()));
  });
}
