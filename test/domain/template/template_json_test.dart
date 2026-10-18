// AC-0401: versioned JSON documents validate and round-trip, including
// out-of-page layer bounds and rotation; FIX-06 format cases (unknown layer
// type, unknown version) are refused with a reason.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/template/document_issues.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_json.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';
import 'package:porcelain_photo_booth/domain/template/template_migrations.dart';

import '../../support/template_builders.dart';

/// Every layer type and option, with off-page bounds and rotations.
TemplateDocument everything() => sampleDocument(
  assets: {
    TestAssets.flower: TestAssets.png,
    TestAssets.font: TestAssets.ttf,
    TestAssets.mask: const TemplateAsset(
      mediaType: AssetMediaType.png,
      byteLength: 321,
      widthPx: 64,
      heightPx: 64,
    ),
    TestAssets.paper: const TemplateAsset(
      mediaType: AssetMediaType.jpeg,
      byteLength: 99999,
      widthPx: 1800,
      heightPx: 1200,
      name: 'paper.jpg',
    ),
  },
  layers: [
    BackgroundLayer(
      id: 'bg',
      name: 'Paper',
      zIndex: -5,
      opacity: 0.9,
      fill: ImageFill(TestAssets.paper, fit: ImageFit.contain),
    ),
    PhotoSlotLayer(
      id: 'slot-1',
      name: 'Photo 1',
      zIndex: 1,
      slotIndex: 0,
      frame: const NormalizedRect(x: -0.05, y: 0.1, width: 0.6, height: 0.4),
      rotationDegrees: -7.5,
      pivot: const NormalizedPoint(0, 1),
      fit: PhotoFit.contain,
      focal: const NormalizedPoint(0.25, 0.75),
      clip: MaskClip(TestAssets.mask),
      locked: true,
    ),
    const PhotoSlotLayer(
      id: 'slot-2',
      zIndex: 2,
      slotIndex: 1,
      frame: NormalizedRect(x: 0.4, y: 0.55, width: 0.5, height: 0.35),
      clip: EllipseClip(),
      border: Stroke(widthPt: 3.25, color: ArgbColor(0x80FFFFFF)),
    ),
    ImageLayer(
      id: 'flower',
      zIndex: 3,
      assetId: TestAssets.flower,
      frame: const NormalizedRect(x: 0.8, y: -0.1, width: 0.45, height: 0.3),
      rotationDegrees: 135,
      fit: ImageFit.cover,
      crop: const NormalizedRect(x: 0.1, y: 0.2, width: 0.5, height: 0.6),
      visible: false,
    ),
    TextLayer(
      id: 'names',
      zIndex: 4,
      frame: const NormalizedRect(x: 0.05, y: 0.9, width: 0.9, height: 0.08),
      text: 'Ünïcödé & “quotes”\nsecond line',
      font: AssetFont(TestAssets.font),
      sizePt: 21.5,
      color: ink,
      align: TextAlignment.left,
      verticalAlign: VerticalAlignment.bottom,
      lineHeight: 1.05,
      letterSpacingPt: -0.5,
    ),
    const TextLayer(
      id: 'date',
      zIndex: 5,
      frame: NormalizedRect(x: 0.05, y: 0.02, width: 0.9, height: 0.05),
      text: '14.11.2026',
      font: BundledFont(BundledFontFamily.cormorantGaramond, weight: 600),
      sizePt: 12,
      color: ArgbColor(0xFF9A7646),
      align: TextAlignment.right,
      verticalAlign: VerticalAlignment.top,
    ),
    const ShapeLayer(
      id: 'badge',
      zIndex: 6,
      frame: NormalizedRect(x: 0.7, y: 0.7, width: 0.2, height: 0.2),
      shape: ShapeKind.roundedRect,
      cornerRadius: 0.5,
      fill: ArgbColor(0xFFE6CD9B),
      stroke: Stroke(widthPt: 1, color: ink),
      opacity: 0.5,
    ),
    const ShapeLayer(
      id: 'gradient-free',
      zIndex: 7,
      frame: NormalizedRect(x: 0, y: 0, width: 1, height: 1),
      shape: ShapeKind.ellipse,
      fill: ArgbColor(0x00000000),
    ),
  ],
);

Map<String, Object?> jsonOf(TemplateDocument document) =>
    jsonDecode(TemplateJson.encode(document)) as Map<String, Object?>;

List<DocumentIssueCode> codesOf(void Function() read) {
  try {
    read();
  } on TemplateDocumentException catch (error) {
    return [for (final issue in error.issues) issue.code];
  }
  fail('expected the document to be refused');
}

void main() {
  test('every layer type round-trips exactly, including off-page bounds, '
      'rotation, pivots and Unicode text', () {
    final document = everything();
    expect(document.errors, isEmpty);
    final text = TemplateJson.encode(document);
    final read = TemplateJson.decode(text);
    expect(read, document);
    expect(TemplateJson.encode(read), text);
    expect(TemplateJson.checksumOf(read), TemplateJson.checksumOf(document));
  });

  test('gradient backgrounds round-trip', () {
    final document = sampleDocument(
      layers: const [
        BackgroundLayer(
          id: 'bg',
          zIndex: 0,
          fill: LinearGradientFill(
            angleDegrees: 33.3,
            stops: [
              GradientStop(0, ivory),
              GradientStop(0.42, ArgbColor(0xFFE6CD9B)),
              GradientStop(1, ink),
            ],
          ),
        ),
      ],
      assets: const {},
    );
    expect(TemplateJson.decode(TemplateJson.encode(document)), document);
  });

  test('the canonical text is stable, sorted and indented', () {
    final text = TemplateJson.encode(everything());
    expect(text, endsWith('}\n'));
    expect(text, contains('\n  "page": {\n'));
    final assets = (jsonOf(everything())['assets']! as Map).keys.toList();
    expect(assets, [...assets]..sort());
    // Defaults are written out, so the file says what it means.
    final layer = (jsonOf(sampleDocument())['layers']! as List)[1] as Map;
    expect(layer['rotation'], 0.0);
    expect(layer['pivot'], {'x': 0.5, 'y': 0.5});
    expect(layer['clip'], {'shape': 'rect'});
  });

  test('omitted optional fields take their documented defaults', () {
    final document = TemplateJson.decode('''
{
  "schemaVersion": 1,
  "page": {"width": 4, "height": 6, "unit": "in", "dpi": 300},
  "layers": [
    {"type": "photoSlot", "id": "s", "z": 1, "slotIndex": 0,
     "frame": {"x": 0.1, "y": 0.1, "w": 0.8, "h": 0.4}},
    {"type": "text", "id": "t", "z": 2, "text": "Hi",
     "font": {"family": "Inter"}, "size": 12, "color": "#ff000000",
     "frame": {"x": 0, "y": 0, "w": 1, "h": 0.1}}
  ]
}
''');
    final slot = document.layers[0] as PhotoSlotLayer;
    expect(slot.opacity, 1);
    expect(slot.visible, isTrue);
    expect(slot.rotationDegrees, 0);
    expect(slot.pivot, NormalizedPoint.center);
    expect(slot.fit, PhotoFit.cover);
    expect(slot.clip, const RectClip());
    final text = document.layers[1] as TextLayer;
    expect(text.font, const BundledFont(BundledFontFamily.inter));
    expect(text.color, const ArgbColor(0xFF000000));
    expect(text.align, TextAlignment.center);
    expect(text.lineHeight, 1.2);
    expect(document.assets, isEmpty);
  });

  group('strict reading', () {
    String withLayer(String layer) =>
        '{"schemaVersion": 1, "page": {"width": 4, "height": 6, "unit": "in", '
        '"dpi": 300}, "layers": [$layer]}';

    test('an unknown layer type is refused, not skipped', () {
      expect(
        codesOf(
          () => TemplateJson.decode(
            withLayer('{"type": "sticker", "id": "x", "z": 1}'),
          ),
        ),
        [DocumentIssueCode.unknownLayerType],
      );
    });

    test('unknown and missing fields are named with their path', () {
      try {
        TemplateJson.decode(
          withLayer(
            '{"type": "shape", "id": "x", "z": 1, "shape": "rect", '
            '"frame": {"x": 0, "y": 0, "w": 1}, "glow": true}',
          ),
        );
        fail('expected refusal');
      } on TemplateDocumentException catch (error) {
        expect(
          [
            for (final issue in error.issues)
              '${issue.code.name} ${issue.path}',
          ],
          ['unknownField layers[0].glow', 'missingField layers[0].frame.h'],
        );
      }
    });

    test('wrong types and bad values are refused', () {
      expect(
        codesOf(
          () => TemplateJson.decode(
            withLayer(
              '{"type": "shape", "id": 7, "z": 1.5, "shape": "star", '
              '"fill": "red", "frame": {"x": "0", "y": 0, "w": 1, "h": 1}}',
            ),
          ),
        ),
        [
          DocumentIssueCode.wrongType,
          DocumentIssueCode.wrongType,
          DocumentIssueCode.wrongType,
          DocumentIssueCode.invalidValue,
          DocumentIssueCode.invalidValue,
        ],
      );
    });

    test('unknown bundled fonts and malformed asset ids are refused', () {
      expect(
        codesOf(
          () => TemplateJson.decode(
            withLayer(
              '{"type": "text", "id": "t", "z": 1, "text": "x", "size": 9, '
              '"color": "#FF000000", "font": {"family": "Comic Sans"}, '
              '"frame": {"x": 0, "y": 0, "w": 1, "h": 1}}',
            ),
          ),
        ),
        [DocumentIssueCode.invalidValue],
      );
      expect(
        codesOf(
          () => TemplateJson.decode(
            withLayer(
              '{"type": "image", "id": "i", "z": 1, "assetId": "../x.png", '
              '"frame": {"x": 0, "y": 0, "w": 1, "h": 1}}',
            ),
          ),
        ),
        [DocumentIssueCode.invalidValue],
      );
    });

    test('documents from newer apps, without a version or not JSON are '
        'refused', () {
      expect(
        codesOf(
          () => TemplateJson.decode(
            '{"schemaVersion": 2, "page": {}, "layers": []}',
          ),
        ),
        [DocumentIssueCode.newerVersion],
      );
      expect(codesOf(() => TemplateJson.decode('{"page": {}, "layers": []}')), [
        DocumentIssueCode.unsupportedVersion,
      ]);
      expect(codesOf(() => TemplateJson.decode('[1, 2]')), [
        DocumentIssueCode.notAnObject,
      ]);
      expect(codesOf(() => TemplateJson.decode('{"schemaVersion": 1,')), [
        DocumentIssueCode.notAnObject,
      ]);
    });

    test('oversized documents are refused before parsing', () {
      final huge = '{"pad": "${'x' * TemplateJson.maxDocumentBytes}"}';
      expect(codesOf(() => TemplateJson.decode(huge)), [
        DocumentIssueCode.tooLarge,
      ]);
    });

    test('decodeValid also refuses documents that read but are invalid', () {
      final invalid = TemplateJson.encode(
        sampleDocument(assets: {TestAssets.flower: TestAssets.png}),
      );
      expect(TemplateJson.decode(invalid), isA<TemplateDocument>());
      expect(codesOf(() => TemplateJson.decodeValid(invalid)), [
        DocumentIssueCode.missingAsset,
      ]);
    });
  });

  group('versions (A-15)', () {
    test('version 1 is current and needs no steps', () {
      expect(TemplateDocument.currentSchemaVersion, 1);
      expect(TemplateMigrations.steps, isEmpty);
    });

    test('the committed version 1 fixture still reads and re-encodes to '
        'the same bytes', () {
      final file = File('test_assets/templates/v1/everything.json');
      // Written once, then frozen: a later format change that cannot read
      // it fails here instead of breaking operators' saved templates.
      if (autoUpdateGoldenFiles && !file.existsSync()) {
        file
          ..createSync(recursive: true)
          ..writeAsStringSync(TemplateJson.encode(everything()));
      }
      expect(file.existsSync(), isTrue, reason: 'missing v1 fixture');
      final text = file.readAsStringSync();
      final document = TemplateJson.decodeValid(text);
      expect(document, everything());
      expect(TemplateJson.encode(document), text);
    });
  });
}
