// Render the actual bundled PNGs on light and dark surfaces for edge review.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/bundled_decorations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render the transparent sticker catalog for visual review', () async {
    final fonts = FontLoader('Inter')
      ..addFont(
        File('assets/fonts/inter/Inter-Regular.ttf')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)),
      );
    await fonts.load();
    final stickers = bundledDecorations
        .where((d) => d.kind == DecorationKind.sticker)
        .toList();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xFFF7F2EB), ui.BlendMode.src);
    for (final (index, sticker) in stickers.indexed) {
      final x = (index % 4) * 480.0;
      final y = (index ~/ 4) * 285.0;
      canvas.drawRect(
        ui.Rect.fromLTWH(x + 240, y, 240, 240),
        ui.Paint()..color = const ui.Color(0xFF25313D),
      );
      final codec = await ui.instantiateImageCodec(
        File(sticker.assetPath).readAsBytesSync(),
      );
      final frame = await codec.getNextFrame();
      for (final dx in [0, 240]) {
        canvas.drawImageRect(
          frame.image,
          ui.Rect.fromLTWH(
            0,
            0,
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          ),
          ui.Rect.fromLTWH(x + dx + 15, y + 15, 210, 210),
          ui.Paint(),
        );
      }
      final builder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                textAlign: ui.TextAlign.center,
              ),
            )
            ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF33291F)))
            ..addText(sticker.name);
      final label = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 460));
      canvas.drawParagraph(label, ui.Offset(x + 10, y + 250));
      label.dispose();
      frame.image.dispose();
      codec.dispose();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      1920,
      (stickers.length / 4).ceil() * 285,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/local-verification/atelier-catalog')
      ..createSync(recursive: true);
    File('${directory.path}/sticker-overview.png')
        .writeAsBytesSync(png!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
}
