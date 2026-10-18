import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';

/// Well-formed asset ids for documents built in tests.
abstract final class TestAssets {
  static final flower = assetIdOf('flower'.codeUnits);
  static final mask = assetIdOf('mask'.codeUnits);
  static final paper = assetIdOf('paper'.codeUnits);
  static final font = assetIdOf('font'.codeUnits);

  static const png = TemplateAsset(
    mediaType: AssetMediaType.png,
    byteLength: 1000,
    widthPx: 800,
    heightPx: 600,
    name: 'flower.png',
  );

  static const ttf = TemplateAsset(
    mediaType: AssetMediaType.ttf,
    byteLength: 5000,
    name: 'script.ttf',
  );
}

const ivory = ArgbColor(0xFFF5F0E9);
const ink = ArgbColor(0xFF33291F);

/// A 4x6 portrait document with two slots, a decoration, text and a shape.
TemplateDocument sampleDocument({
  PageSpec page = PageSpec.fourBySixPortrait,
  List<TemplateLayer>? layers,
  Map<String, TemplateAsset>? assets,
}) => TemplateDocument(
  page: page,
  assets:
      assets ??
      {TestAssets.flower: TestAssets.png, TestAssets.font: TestAssets.ttf},
  layers:
      layers ??
      [
        const BackgroundLayer(id: 'bg', zIndex: 0, fill: SolidFill(ivory)),
        const PhotoSlotLayer(
          id: 'slot-1',
          zIndex: 10,
          slotIndex: 0,
          frame: NormalizedRect(x: 0.1, y: 0.06, width: 0.8, height: 0.4),
        ),
        const PhotoSlotLayer(
          id: 'slot-2',
          zIndex: 11,
          slotIndex: 1,
          frame: NormalizedRect(x: 0.1, y: 0.54, width: 0.8, height: 0.4),
          clip: RoundedRectClip(0.05),
          border: Stroke(widthPt: 2, color: ArgbColor(0xFFFFFFFF)),
        ),
        ImageLayer(
          id: 'flower',
          zIndex: 20,
          assetId: TestAssets.flower,
          frame: const NormalizedRect(
            x: 0.25,
            y: 0.33,
            width: 0.5,
            height: 0.33,
          ),
          rotationDegrees: 15,
        ),
        TextLayer(
          id: 'title',
          zIndex: 30,
          frame: const NormalizedRect(
            x: 0.1,
            y: 0.94,
            width: 0.8,
            height: 0.05,
          ),
          text: 'Hannah & Theo',
          font: AssetFont(TestAssets.font),
          sizePt: 18,
          color: ink,
        ),
        const ShapeLayer(
          id: 'frame',
          zIndex: 40,
          frame: NormalizedRect(x: 0.02, y: 0.02, width: 0.96, height: 0.96),
          shape: ShapeKind.roundedRect,
          cornerRadius: 0.03,
          stroke: Stroke(widthPt: 1.5, color: ink),
        ),
      ],
);
