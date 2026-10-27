import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/template/editing/document_edits.dart';
import 'package:porcelain_photo_booth/domain/template/editing/editor_geometry.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';

import '../../support/template_builders.dart';

bool _overlaps(PixelRect a, PixelRect b) =>
    a.left < b.right &&
    a.right > b.left &&
    a.top < b.bottom &&
    a.bottom > b.top;

void main() {
  for (final page in [
    PageSpec.twoBySix,
    PageSpec.fourBySixPortrait,
    PageSpec.fourBySixLandscape,
    PageSpec.fourByFour,
  ]) {
    for (final aspect in [0.4, 1.0, 2.5]) {
      test(
        '${page.widthPx}×${page.heightPx}: $aspect sticker is whole and print-safe',
        () {
          final document = TemplateDocument(page: page, layers: const []);
          final image = NewLayers.image(
            document,
            'sticker',
            TestAssets.flower,
            TemplateAsset(
              mediaType: AssetMediaType.png,
              byteLength: 10,
              widthPx: (1000 * aspect).round(),
              heightPx: 1000,
            ),
            sticker: true,
          );
          final rect = LayerGeometry.of(image, page).rect;
          expect(rect.width / rect.height, closeTo(aspect, 1e-9));
          expect(rect.width, lessThanOrEqualTo(page.widthPx * 0.24 + 1e-9));
          expect(rect.height, lessThanOrEqualTo(page.heightPx * 0.24 + 1e-9));
          expect(rect.left, greaterThanOrEqualTo(page.dpi / 8));
          expect(rect.top, greaterThanOrEqualTo(page.dpi / 8));
          expect(rect.right, lessThanOrEqualTo(page.widthPx - page.dpi / 8));
          expect(rect.bottom, lessThanOrEqualTo(page.heightPx - page.dpi / 8));
          expect(image.fit, ImageFit.contain);
          expect(image.crop, NormalizedRect.page);
        },
      );
    }
  }

  test('clear space is preferred over photos, text and an earlier sticker', () {
    const page = PageSpec.fourBySixPortrait;
    var document = TemplateDocument(page: page, layers: const []);
    document = DocumentEdits.add(
      document,
      NewLayers.photoSlot(document, 'photo'),
    );
    document = DocumentEdits.add(document, NewLayers.text(document, 'caption'));
    final first = NewLayers.image(
      document,
      'first',
      TestAssets.flower,
      TestAssets.png,
      sticker: true,
    );
    document = DocumentEdits.add(
      document,
      first,
      assets: {TestAssets.flower: TestAssets.png},
    );
    final second = NewLayers.image(
      document,
      'second',
      TestAssets.flower,
      TestAssets.png,
      sticker: true,
    );
    final secondBounds = LayerGeometry.of(second, page).bounds;
    for (final layer in document.layers.whereType<FramedLayer>()) {
      expect(
        _overlaps(secondBounds, LayerGeometry.of(layer, page).bounds),
        isFalse,
        reason: 'avoid ${layer.id}',
      );
    }
    expect(second.frame, isNot(first.frame));
  });

  test(
    'a sticker added to a strip stays inside the full print-safe margin',
    () {
      const page = PageSpec.twoBySix;
      var document = TemplateDocument(page: page, layers: const []);
      document = DocumentEdits.add(
        document,
        NewLayers.photoSlot(document, 'photo'),
      );
      final image = NewLayers.image(
        document,
        'sticker',
        TestAssets.flower,
        TestAssets.png,
        sticker: true,
      );
      final rect = LayerGeometry.of(image, page).bounds;
      expect(rect.left, greaterThanOrEqualTo(page.dpi / 8));
      expect(rect.top, greaterThanOrEqualTo(page.dpi / 8));
      expect(rect.right, lessThanOrEqualTo(page.widthPx - page.dpi / 8));
      expect(rect.bottom, lessThanOrEqualTo(page.heightPx - page.dpi / 8));
    },
  );

  test(
    'hidden content and a full-page painting do not force stickers over photos',
    () {
      const page = PageSpec.fourBySixPortrait;
      var document = TemplateDocument(
        page: page,
        layers: [
          ImageLayer(
            id: 'painting',
            zIndex: 0,
            frame: NormalizedRect.page,
            assetId: TestAssets.flower,
          ),
          const TextLayer(
            id: 'hidden',
            zIndex: 1,
            frame: NormalizedRect.page,
            text: 'Hidden',
            visible: false,
            font: BundledFont(BundledFontFamily.inter),
            sizePt: 12,
            color: ArgbColor(0xFF000000),
          ),
        ],
        assets: {TestAssets.flower: TestAssets.png},
      );
      document = DocumentEdits.add(
        document,
        NewLayers.photoSlot(document, 'photo'),
      );
      final sticker = NewLayers.image(
        document,
        'sticker',
        TestAssets.flower,
        TestAssets.png,
        sticker: true,
      );
      expect(
        _overlaps(
          LayerGeometry.of(sticker, page).bounds,
          LayerGeometry.of(document.photoSlots.single, page).bounds,
        ),
        isFalse,
      );
    },
  );
}
