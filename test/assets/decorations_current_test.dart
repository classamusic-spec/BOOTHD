// Bundled artwork must match its procedural source or generated-art manifest.
// Every sticker is decoded to verify useful, genuinely transparent artwork.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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

  test('the app offers all procedural and manifested original artwork', () {
    final generated = {for (final art in decorationArt) art.file};
    final manifest = [
      ...jsonDecode(
        File('docs/artwork/atelier-manifest.json').readAsStringSync(),
      ) as List,
      ...jsonDecode(
        File('docs/artwork/sticker-manifest.json').readAsStringSync(),
      ) as List,
      ...jsonDecode(
        File('docs/artwork/occasion-manifest.json').readAsStringSync(),
      ) as List,
    ];
    final paintings = <String>{};
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final file = File(entry['path'] as String);
      final bytes = file.readAsBytesSync();
      paintings.add(file.uri.pathSegments.last);
      expect(sha256.convert(bytes).toString(), entry['sha256']);
      final header = sniffAsset(bytes).asset!;
      expect(
        (header.widthPx, header.heightPx),
        (entry['width'], entry['height']),
      );
      expect(header.widthPx, greaterThanOrEqualTo(1024));
    }
    expect(paintings, hasLength(76));
    final offered = {
      for (final decoration in bundledDecorations)
        decoration.assetPath.split('/').last,
    };
    final onDisk = {
      for (final file in Directory('assets/decorations').listSync())
        file.uri.pathSegments.last,
    };
    expect(offered, {...generated, ...paintings});
    expect(onDisk, {...generated, ...paintings});
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

  test('all 56 stickers have real alpha and visible artwork', () async {
    final stickers = bundledDecorations.where(
      (d) => d.kind == DecorationKind.sticker,
    );
    expect(stickers, hasLength(56));
    for (final sticker in stickers) {
      final pixels = await decodeRgba(
        File(sticker.assetPath).readAsBytesSync(),
      );
      var transparent = 0;
      var opaque = 0;
      for (var i = 3; i < pixels.rgba.length; i += 4) {
        if (pixels.rgba[i] == 0) transparent++;
        if (pixels.rgba[i] > 240) opaque++;
      }
      final count = pixels.width * pixels.height;
      expect(transparent / count, greaterThan(0.2), reason: sticker.id);
      expect(opaque / count, greaterThan(0.03), reason: sticker.id);
      for (final (x, y) in [
        (0, 0),
        (pixels.width - 1, 0),
        (0, pixels.height - 1),
        (pixels.width - 1, pixels.height - 1),
      ]) {
        expect(
          pixels.rgba[(y * pixels.width + x) * 4 + 3],
          lessThanOrEqualTo(2), // Allow sub-percent alpha quantization noise.
          reason: '${sticker.id}: transparent corners',
        );
      }
    }
  });
}
