import 'dart:io' show ProcessInfo;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/services/composition_renderer.dart';
import '../../domain/template/document_scene.dart';
import '../../domain/template/geometry.dart';
import '../../domain/template/template_document.dart';
import 'scene_painter.dart';

/// [CompositionRenderer] on Flutter's `dart:ui` canvas (ADR-0003).
///
/// Spike-grade (M01): renders offscreen at exact output pixels from encoded
/// inputs. With [boundDecodeSize], each input is decoded no larger than the
/// scene draws it, which bounds memory for full-size camera originals.
final class DartUiCompositionRenderer implements CompositionRenderer {
  const DartUiCompositionRenderer({this.boundDecodeSize = true});

  final bool boundDecodeSize;

  static const _workspaceArgb = 0xFF8A8A8A;
  static const _pageOutlineArgb = 0xFFE0218A;

  @override
  Future<RenderedImage> renderExport(
    TemplateDocument document, {
    required Map<int, String> slotAssets,
    required Map<String, Uint8List> assets,
    bool includePixels = false,
  }) => _render(
    document,
    slotAssets,
    assets,
    margin: 0,
    includePixels: includePixels,
  );

  @override
  Future<RenderedImage> renderWorkspace(
    TemplateDocument document, {
    required Map<int, String> slotAssets,
    required Map<String, Uint8List> assets,
    double marginFraction = 0.1,
    bool includePixels = false,
  }) {
    if (marginFraction <= 0) {
      throw ArgumentError.value(marginFraction, 'marginFraction');
    }
    return _render(
      document,
      slotAssets,
      assets,
      margin: marginFraction,
      includePixels: includePixels,
    );
  }

  Future<RenderedImage> _render(
    TemplateDocument document,
    Map<int, String> slotAssets,
    Map<String, Uint8List> assets, {
    required double margin,
    required bool includePixels,
  }) async {
    final watch = Stopwatch()..start();
    final sizes = <String, PixelSize>{};
    Future<PixelSize> sizeOf(String assetId) async =>
        sizes[assetId] ??= await _probeSize(assetId, assets[assetId]);

    final bindings = <int, SlotBinding>{};
    for (final slot in document.slotIndexes) {
      final assetId = slotAssets[slot];
      if (assetId == null) {
        throw RenderFailure(
          RenderFailureCode.invalidDocument,
          detail: 'slot $slot has no photo',
        );
      }
      bindings[slot] = SlotBinding(
        assetId: assetId,
        sourceSize: await sizeOf(assetId),
      );
    }

    final DocumentScene scene;
    try {
      scene = compileScene(document, bindings: bindings);
    } on SceneCompileException catch (error) {
      throw RenderFailure(
        RenderFailureCode.invalidDocument,
        detail: error.problems.join('; '),
      );
    }

    final decoded = <String, DecodedAsset>{};
    try {
      for (final assetId in scene.assetIds) {
        final size = await sizeOf(assetId);
        decoded[assetId] = await _decode(
          assetId,
          assets[assetId]!,
          size,
          boundDecodeSize ? _drawScale(scene, assetId, size) : 1,
        );
      }
      final decodeTime = watch.elapsed;
      watch.reset();

      final marginX = (scene.widthPx * margin).round();
      final marginY = (scene.heightPx * margin).round();
      final outWidth = scene.widthPx + 2 * marginX;
      final outHeight = scene.heightPx + 2 * marginY;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      if (margin > 0) {
        canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble()),
          ui.Paint()..color = const ui.Color(_workspaceArgb),
        );
      }
      paintScene(
        canvas,
        scene,
        decoded,
        origin: ui.Offset(marginX.toDouble(), marginY.toDouble()),
        clipToPage: margin == 0,
      );
      if (margin > 0) {
        canvas.drawRect(
          ui.Rect.fromLTWH(
            marginX.toDouble(),
            marginY.toDouble(),
            scene.widthPx.toDouble(),
            scene.heightPx.toDouble(),
          ),
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const ui.Color(_pageOutlineArgb),
        );
      }
      final picture = recorder.endRecording();
      final paintTime = watch.elapsed;
      watch.reset();

      final ui.Image image;
      try {
        image = await picture.toImage(outWidth, outHeight);
      } on Object catch (error) {
        throw RenderFailure(
          RenderFailureCode.rasterizeFailed,
          detail: '$error',
        );
      } finally {
        picture.dispose();
      }

      try {
        Uint8List? rgba;
        if (includePixels) {
          final pixels = await image.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          );
          if (pixels == null) {
            throw const RenderFailure(RenderFailureCode.rasterizeFailed);
          }
          rgba = pixels.buffer.asUint8List();
        }
        final rasterizeTime = watch.elapsed;
        watch.reset();

        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) {
          throw const RenderFailure(RenderFailureCode.encodeFailed);
        }
        final encodeTime = watch.elapsed;

        return RenderedImage(
          widthPx: outWidth,
          heightPx: outHeight,
          png: png.buffer.asUint8List(),
          rgba: rgba,
          stats: RenderStats(
            decode: decodeTime,
            paint: paintTime,
            rasterize: rasterizeTime,
            encode: encodeTime,
            residentBytesAfter: _memory(() => ProcessInfo.currentRss),
            maxResidentBytes: _memory(() => ProcessInfo.maxRss),
          ),
        );
      } finally {
        image.dispose();
      }
    } finally {
      for (final asset in decoded.values) {
        asset.image.dispose();
      }
    }
  }

  /// The largest scale at which the scene draws [assetId], capped at 1.
  static double _drawScale(
    DocumentScene scene,
    String assetId,
    PixelSize size,
  ) {
    var scale = 0.0;
    for (final node in scene.nodes) {
      if (node.assetId != assetId) continue;
      final (sourceWidth, sourceHeight) = switch (node) {
        PhotoNode(:final sourceCrop) => (sourceCrop.width, sourceCrop.height),
        ImageNode() => (size.width.toDouble(), size.height.toDouble()),
      };
      scale = math.max(
        scale,
        math.max(
          node.rect.width / sourceWidth,
          node.rect.height / sourceHeight,
        ),
      );
    }
    return math.min(1, scale);
  }

  static Future<PixelSize> _probeSize(String assetId, Uint8List? bytes) async {
    if (bytes == null) {
      throw RenderFailure(RenderFailureCode.missingAsset, detail: assetId);
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = PixelSize(descriptor.width, descriptor.height);
      descriptor.dispose();
      return size;
    } on Object {
      throw RenderFailure(
        RenderFailureCode.assetDecodeFailed,
        detail: '$assetId is not a supported image',
      );
    } finally {
      buffer.dispose();
    }
  }

  static Future<DecodedAsset> _decode(
    String assetId,
    Uint8List bytes,
    PixelSize size,
    double scale,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      codec = await descriptor.instantiateCodec(
        targetWidth: scale < 1
            ? math.max(1, (size.width * scale).ceil())
            : null,
        targetHeight: scale < 1
            ? math.max(1, (size.height * scale).ceil())
            : null,
      );
      final frame = await codec.getNextFrame();
      return DecodedAsset(frame.image, sourceSize: size);
    } on Object {
      throw RenderFailure(
        RenderFailureCode.assetDecodeFailed,
        detail: '$assetId could not be decoded',
      );
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static int? _memory(int Function() read) {
    try {
      return read();
    } on UnsupportedError {
      return null;
    }
  }
}
