import 'dart:async';
import 'dart:io' show ProcessInfo;
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../core/composition/scene_painter.dart';
import '../../core/composition/scene_preparation.dart';
import '../../core/composition/template_fonts.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/services/composition_renderer.dart';
import '../codecs/jpeg_encoder.dart';
import '../codecs/png_metadata.dart';

/// [CompositionRenderer] on Flutter's `dart:ui` canvas (ADR-0003,
/// ADR-0010).
///
/// Exports render offscreen at exactly the page's pixels from the original
/// encoded inputs, one at a time (they hold the most memory); previews
/// paint the same scene scaled. JPEG files are encoded on a background
/// isolate; PNG files by the engine, then tagged with their print
/// resolution.
final class DartUiCompositionRenderer implements CompositionRenderer {
  DartUiCompositionRenderer({TemplateFontLoader? fonts})
    : _fonts = fonts ?? TemplateFontLoader();

  final TemplateFontLoader _fonts;
  Future<void> _exports = Future.value();

  static const _workspaceArgb = 0xFF8A8A8A;
  static const _pageOutlineArgb = 0xFFE0218A;

  @override
  Future<RenderArtifact> renderExport(
    TemplateRender render, {
    OutputProfile output = const OutputProfile(),
    int flattenArgb = 0xFFFFFFFF,
    bool includePixels = false,
  }) {
    final result = _exports.then(
      (_) => _export(render, output, flattenArgb, includePixels),
    );
    _exports = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  Future<RenderArtifact> renderPreview(
    TemplateRender render, {
    required int maxWidthPx,
    required int maxHeightPx,
    double workspaceMargin = 0,
    bool includePixels = false,
  }) async {
    if (maxWidthPx < 1 || maxHeightPx < 1) {
      throw ArgumentError('Preview bounds must be positive.');
    }
    if (!workspaceMargin.isFinite ||
        workspaceMargin < 0 ||
        workspaceMargin > 1) {
      throw ArgumentError.value(workspaceMargin, 'workspaceMargin');
    }
    final watch = Stopwatch()..start();
    final compiled = await compileRender(render);
    final scene = compiled.scene;
    final totalWidth = scene.widthPx * (1 + 2 * workspaceMargin);
    final totalHeight = scene.heightPx * (1 + 2 * workspaceMargin);
    final scale = math.min(
      1.0,
      math.min(maxWidthPx / totalWidth, maxHeightPx / totalHeight),
    );
    final outWidth = math.max(1, (totalWidth * scale).round());
    final outHeight = math.max(1, (totalHeight * scale).round());
    final resources = await loadRenderResources(
      compiled,
      fonts: _fonts,
      scale: scale,
    );
    try {
      final decode = watch.elapsed;
      watch.reset();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final page = ui.Rect.fromLTWH(
        scene.widthPx * workspaceMargin * scale,
        scene.heightPx * workspaceMargin * scale,
        scene.widthPx * scale,
        scene.heightPx * scale,
      );
      if (workspaceMargin > 0) {
        canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble()),
          ui.Paint()..color = const ui.Color(_workspaceArgb),
        );
      }
      final warnings = paintScene(
        canvas,
        scene,
        resources,
        origin: page.topLeft,
        scale: scale,
        clipToPage: workspaceMargin == 0,
      );
      if (workspaceMargin > 0) {
        canvas.drawRect(
          page,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = math.max(1, 3 * scale)
            ..color = const ui.Color(_pageOutlineArgb),
        );
      }
      return await _finish(
        recorder,
        outWidth,
        outHeight,
        decode: decode,
        watch: watch,
        warnings: warnings,
        format: OutputFormat.png,
        includePixels: includePixels,
      );
    } finally {
      resources.dispose();
    }
  }

  Future<RenderArtifact> _export(
    TemplateRender render,
    OutputProfile output,
    int flattenArgb,
    bool includePixels,
  ) async {
    final watch = Stopwatch()..start();
    final compiled = await compileRender(render);
    final scene = compiled.scene;
    final resources = await loadRenderResources(compiled, fonts: _fonts);
    try {
      final decode = watch.elapsed;
      watch.reset();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      if (output.format == OutputFormat.jpeg) {
        // JPEG has no transparency: flatten onto an opaque colour on
        // purpose rather than leave it to the encoder (AC-0406).
        canvas.drawRect(
          ui.Rect.fromLTWH(
            0,
            0,
            scene.widthPx.toDouble(),
            scene.heightPx.toDouble(),
          ),
          ui.Paint()..color = ui.Color(flattenArgb | 0xFF000000),
        );
      }
      final warnings = paintScene(canvas, scene, resources);
      return await _finish(
        recorder,
        scene.widthPx,
        scene.heightPx,
        decode: decode,
        watch: watch,
        warnings: warnings,
        format: output.format,
        jpegQuality: output.jpegQuality,
        dpi: render.document.page.dpi,
        includePixels: includePixels,
      );
    } finally {
      resources.dispose();
    }
  }

  Future<RenderArtifact> _finish(
    ui.PictureRecorder recorder,
    int width,
    int height, {
    required Duration decode,
    required Stopwatch watch,
    required List<RenderWarning> warnings,
    required OutputFormat format,
    int jpegQuality = 92,
    int? dpi,
    required bool includePixels,
  }) async {
    final picture = recorder.endRecording();
    final paint = watch.elapsed;
    watch.reset();
    final ui.Image image;
    try {
      image = await picture.toImage(width, height);
    } on Object catch (error) {
      throw RenderFailure(RenderFailureCode.rasterizeFailed, detail: '$error');
    } finally {
      picture.dispose();
    }
    try {
      Uint8List? rgba;
      if (includePixels || format == OutputFormat.jpeg) {
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        if (pixels == null) {
          throw const RenderFailure(RenderFailureCode.rasterizeFailed);
        }
        rgba = pixels.buffer.asUint8List();
      }
      final rasterize = watch.elapsed;
      watch.reset();

      final Uint8List bytes;
      switch (format) {
        case OutputFormat.png:
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          if (png == null) {
            throw const RenderFailure(RenderFailureCode.encodeFailed);
          }
          bytes = dpi == null
              ? png.buffer.asUint8List()
              : withPrintMetadata(png.buffer.asUint8List(), dpi: dpi);
        case OutputFormat.jpeg:
          final pixels = rgba!;
          try {
            bytes = await Isolate.run(
              () => encodeJpeg(
                pixels,
                width: width,
                height: height,
                quality: jpegQuality,
                dpi: dpi ?? 72,
              ),
            );
          } on Object catch (error) {
            throw RenderFailure(
              RenderFailureCode.encodeFailed,
              detail: '$error',
            );
          }
      }
      final encode = watch.elapsed;
      return RenderArtifact(
        widthPx: width,
        heightPx: height,
        format: format,
        bytes: bytes,
        rgba: includePixels ? rgba : null,
        warnings: List.unmodifiable(warnings),
        stats: RenderStats(
          decode: decode,
          paint: paint,
          rasterize: rasterize,
          encode: encode,
          residentBytesAfter: _memory(() => ProcessInfo.currentRss),
          maxResidentBytes: _memory(() => ProcessInfo.maxRss),
        ),
      );
    } finally {
      image.dispose();
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
