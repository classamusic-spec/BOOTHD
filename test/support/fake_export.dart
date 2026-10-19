import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/services/export_service.dart';
import 'package:porcelain_photo_booth/domain/services/finished_photos.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';

/// An export service for screens and flows that need finished photos fast:
/// it checks what a real export needs (every photo space has a photo and
/// every photo can be read from the render source) and saves a small
/// stand-in JPEG in memory: ivory paper of the page's shape with a warm
/// block where each photo goes. The real renderer and file export are
/// tested on their own (M04) and end to end in `booth_render_test.dart`.
final class FakeExportService implements ExportService {
  FakeExportService({this.idPrefix = 'd0000000-0000-4000-9000'});

  final String idPrefix;

  /// The next export fails with this, once.
  Exception? failure;

  /// While set, an export waits for it: a render in progress.
  Completer<void>? gate;

  /// The next saved file is damaged after its checksum was taken, once:
  /// it no longer reads back intact.
  bool corruptNext = false;

  /// Every render asked for, in order.
  final renders = <TemplateRender>[];

  /// Saved finished photos by relative path.
  final files = <String, Uint8List>{};
  var _count = 0;

  late final FinishedPhotos finished = _FakeFinishedPhotos(this);

  @override
  Future<ExportedFile> export(
    TemplateRender render, {
    OutputProfile output = const OutputProfile(),
    int flattenArgb = 0xFFFFFFFF,
  }) async {
    renders.add(render);
    await gate?.future;
    final failed = failure;
    if (failed != null) {
      failure = null;
      throw failed;
    }
    for (final slot in render.document.photoSlots) {
      final photo = render.photos[slot.slotIndex];
      if (photo == null) {
        throw RenderFailure(
          RenderFailureCode.missingPhoto,
          detail: 'slot ${slot.slotIndex}',
        );
      }
      await render.source.readPhoto(photo.photoId);
    }
    final page = render.document.page;
    final width = page.widthPx;
    final height = page.heightPx;
    final small = _standIn(render.document);
    final id = '$idPrefix-${(++_count).toString().padLeft(12, '0')}';
    final extension = output.format == OutputFormat.png ? 'png' : 'jpg';
    final relativePath = 'outputs/$id.$extension';
    final sha256 = crypto.sha256.convert(small).toString();
    files[relativePath] = corruptNext
        ? (Uint8List.fromList(small)..[small.length ~/ 2] ^= 0xFF)
        : small;
    corruptNext = false;
    return ExportedFile(
      id: id,
      relativePath: relativePath,
      sha256: sha256,
      byteLength: small.length,
      widthPx: width,
      heightPx: height,
      format: output.format,
      renderVersion: rendererVersion,
      warnings: const [],
      stats: const RenderStats(
        decode: Duration.zero,
        paint: Duration.zero,
        rasterize: Duration.zero,
        encode: Duration.zero,
      ),
    );
  }

  /// The page at a sixth of its size (at most 300 pixels a side): ivory
  /// paper, and a warm gradient in each photo space.
  static Uint8List _standIn(TemplateDocument document) {
    final page = document.page;
    final shrink = math.max(6, math.max(page.widthPx, page.heightPx) / 300);
    final w = math.max(1, (page.widthPx / shrink).round());
    final h = math.max(1, (page.heightPx / shrink).round());
    final rgba = Uint8List(w * h * 4);
    for (var i = 0; i < rgba.length; i += 4) {
      rgba
        ..[i] = 251
        ..[i + 1] = 248
        ..[i + 2] = 243
        ..[i + 3] = 255;
    }
    for (final slot in document.photoSlots) {
      final frame = slot.frame;
      final left = (frame.x * w).round().clamp(0, w);
      final top = (frame.y * h).round().clamp(0, h);
      final right = ((frame.x + frame.width) * w).round().clamp(0, w);
      final bottom = ((frame.y + frame.height) * h).round().clamp(0, h);
      for (var y = top; y < bottom; y++) {
        for (var x = left; x < right; x++) {
          final i = (y * w + x) * 4;
          final u = (x - left) / math.max(1, right - left);
          final v = (y - top) / math.max(1, bottom - top);
          rgba
            ..[i] = (200 + 30 * u).round()
            ..[i + 1] = (170 + 40 * v).round()
            ..[i + 2] = 140;
        }
      }
    }
    return encodeJpeg(rgba, width: w, height: h);
  }
}

final class _FakeFinishedPhotos implements FinishedPhotos {
  _FakeFinishedPhotos(this._export);

  final FakeExportService _export;

  @override
  Future<Uint8List> read({
    required String relativePath,
    required String sha256,
  }) async {
    final bytes = _export.files[relativePath];
    if (bytes == null) throw const FinishedPhotoUnreadable('missing');
    if (crypto.sha256.convert(bytes).toString() != sha256) {
      throw const FinishedPhotoUnreadable('checksum');
    }
    return bytes;
  }
}
