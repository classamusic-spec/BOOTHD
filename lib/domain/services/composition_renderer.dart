/// DRAFT renderer boundary (ADR-0003, ADR-0007). Spike-grade contract from
/// M01; M04 replaces raw asset bytes with asset references and adds atomic
/// output commits.
library;

import 'dart:typed_data';

import '../template/template_document.dart';

/// Why a render failed. Each value maps to a `RENDER_*` diagnostic code.
enum RenderFailureCode {
  invalidDocument,
  missingAsset,
  assetDecodeFailed,
  rasterizeFailed,
  encodeFailed,
}

/// A render failed; no output was produced.
final class RenderFailure implements Exception {
  const RenderFailure(this.code, {this.detail});

  final RenderFailureCode code;

  /// Sanitised detail for operators and logs; never shown to guests.
  final String? detail;

  @override
  String toString() =>
      'RenderFailure(${code.name}${detail == null ? '' : ': $detail'})';
}

/// Where one render spent its time, plus process memory afterwards.
///
/// Memory figures are process-wide resident set sizes, so they include
/// everything else the app holds; they are null where unavailable.
final class RenderStats {
  const RenderStats({
    required this.decode,
    required this.paint,
    required this.rasterize,
    required this.encode,
    this.residentBytesAfter,
    this.maxResidentBytes,
  });

  /// Reading image headers and decoding every input.
  final Duration decode;

  /// Compiling the scene and recording paint commands.
  final Duration paint;

  /// Rasterising at output size, including optional pixel readback.
  final Duration rasterize;

  /// Encoding the output PNG.
  final Duration encode;

  final int? residentBytesAfter;
  final int? maxResidentBytes;

  Duration get total => decode + paint + rasterize + encode;
}

/// A rendered page, or editor workspace, as a PNG.
final class RenderedImage {
  const RenderedImage({
    required this.widthPx,
    required this.heightPx,
    required this.png,
    required this.stats,
    this.rgba,
  });

  final int widthPx;
  final int heightPx;
  final Uint8List png;

  /// Straight-alpha RGBA pixels, row-major; present only when requested.
  final Uint8List? rgba;
  final RenderStats stats;
}

/// Renders template documents from original encoded image bytes, never from
/// widget screenshots.
///
/// [assets] maps asset ids, including the photos named in [slotAssets], to
/// encoded image bytes. [slotAssets] maps each photo slot index to the asset
/// id of its photo. Failures throw [RenderFailure].
abstract interface class CompositionRenderer {
  /// Print output: exactly the page's pixel size, cropped at the page edge.
  Future<RenderedImage> renderExport(
    TemplateDocument document, {
    required Map<int, String> slotAssets,
    required Map<String, Uint8List> assets,
    bool includePixels = false,
  });

  /// Editor-style view: the page plus [marginFraction] of its size on every
  /// side, so artwork that overflows the page stays visible; the page edge
  /// is outlined. Never used as print output.
  Future<RenderedImage> renderWorkspace(
    TemplateDocument document, {
    required Map<int, String> slotAssets,
    required Map<String, Uint8List> assets,
    double marginFraction = 0.1,
    bool includePixels = false,
  });
}
