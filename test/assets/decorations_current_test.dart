// The bundled decorations in assets/decorations/ are exactly what
// tool/art/decorations.dart draws, and the app offers exactly those files.
// After changing the artwork, regenerate the files with
//
//     flutter test tool/art/generate_decorations_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/bundled_decorations.dart';
import 'package:porcelain_photo_booth/domain/template/asset_formats.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_checks.dart';

import '../../tool/art/decorations.dart';
import '../rendering/support/pixels.dart';

void main() {
  test('each committed decoration matches its generator', () async {
    for (final art in decorationArt) {
      final committed = await decodeRgba(
        File('assets/decorations/${art.file}').readAsBytesSync(),
      );
      final fresh = await decodeRgba(
        Uint8List.fromList(await renderDecoration(art)),
      );
      expect(
        (committed.width, committed.height),
        (art.width, art.height),
        reason: art.file,
      );
      final diff = compareRgba(
        committed.rgba,
        fresh.rgba,
        threshold: GoldenTolerance.threshold,
      );
      expect(
        GoldenTolerance.accepts(diff),
        isTrue,
        reason: '${art.file}: $diff',
      );
    }
  });

  test('the app offers exactly the generated files, all transparent', () {
    final generated = {for (final art in decorationArt) art.file};
    final offered = {
      for (final decoration in bundledDecorations)
        decoration.assetPath.split('/').last,
    };
    final onDisk = {
      for (final file in Directory('assets/decorations').listSync())
        file.uri.pathSegments.last,
    };
    expect(offered, generated);
    expect(onDisk, generated);
    for (final file in generated) {
      final bytes = File('assets/decorations/$file').readAsBytesSync();
      expect(pngHasTransparency(bytes), isTrue, reason: file);
    }
    expect(
      {for (final decoration in bundledDecorations) decoration.id}.length,
      bundledDecorations.length,
      reason: 'ids are unique',
    );
  });
}
