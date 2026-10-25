// Regenerate the local review catalog with:
// flutter test tool/art/render_occasions_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/slot_placeholder.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

import '../../test/support/template_store_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render the occasion print catalog for visual review', () async {
    for (final (family, files) in {
      'Cormorant Garamond': [
        'assets/fonts/cormorant_garamond/CormorantGaramond-SemiBold.ttf',
      ],
      'Poiret One': ['assets/fonts/poiret_one/PoiretOne-Regular.ttf'],
      'Pixelify Sans': ['assets/fonts/pixelify_sans/PixelifySans-Variable.ttf'],
      'Fredoka': ['assets/fonts/fredoka/Fredoka-Variable.ttf'],
      'Inter': ['assets/fonts/inter/Inter-Regular.ttf'],
    }.entries.map((e) => (e.key, e.value))) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(
          File(file).readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      }
      await loader.load();
    }
    final harness = await TemplateStoreHarness.create();
    addTearDown(harness.dispose);
    final directory = Directory('build/local-verification/occasion-catalog')
      ..createSync(recursive: true);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const cellWidth = 300.0;
    const cellHeight = 470.0;
    canvas.drawColor(const ui.Color(0xFFF0EBE3), ui.BlendMode.src);
    for (final (index, design) in occasionStarterDesigns.indexed) {
      final saved = await harness.library.create(design, name: design.name);
      final revision = await harness.templates.loadRevision(saved.revisionId);
      final rendered = await DartUiCompositionRenderer().renderExport(
        placeholderRender(revision.document, harness.assets),
      );
      expect(rendered.warnings, isEmpty, reason: design.name);
      File('${directory.path}/${design.id}.png')
          .writeAsBytesSync(rendered.bytes);
      final codec = await ui.instantiateImageCodec(rendered.bytes);
      final frame = await codec.getNextFrame();
      final x = (index % 6) * cellWidth;
      final y = (index ~/ 6) * cellHeight;
      final width = 390 * rendered.widthPx / rendered.heightPx;
      canvas.drawImageRect(
        frame.image,
        ui.Rect.fromLTWH(
          0,
          0,
          rendered.widthPx.toDouble(),
          rendered.heightPx.toDouble(),
        ),
        ui.Rect.fromLTWH(x + (cellWidth - width) / 2, y + 12, width, 390),
        ui.Paint(),
      );
      final builder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                textAlign: ui.TextAlign.center,
              ),
            )
            ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF3A3028)))
            ..addText(design.name);
      final text = builder.build()
        ..layout(const ui.ParagraphConstraints(width: cellWidth - 24));
      canvas.drawParagraph(text, ui.Offset(x + 12, y + 415));
      text.dispose();
      frame.image.dispose();
      codec.dispose();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      1800,
      (occasionStarterDesigns.length / 6).ceil() * 470,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${directory.path}/occasion-overview.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
