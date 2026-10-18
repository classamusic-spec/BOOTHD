/// The renderer boundary (A-04 CompositionRenderer, A-07, ADR-0003,
/// ADR-0010). Renders template documents from original encoded images,
/// never from widget screenshots.
library;

import 'dart:typed_data';

import '../models/booth_event.dart';
import '../template/template_document.dart';

/// Version of the rendering rules, recorded with every output so a later
/// re-render can tell whether it should match (A-05
/// RenderedOutput.renderVersion). Bump it when output pixels can change.
const rendererVersion = 1;

/// Why a render failed; each maps to a `RENDER_*` diagnostic (A-14).
enum RenderFailureCode {
  invalidDocument('RENDER_INVALID_DOCUMENT'),
  missingAsset('RENDER_MISSING_ASSET'),
  missingPhoto('RENDER_MISSING_PHOTO'),
  unreadableImage('RENDER_UNREADABLE_IMAGE'),
  imageMismatch('RENDER_IMAGE_MISMATCH'),
  rasterizeFailed('RENDER_RASTERIZE_FAILED'),
  encodeFailed('RENDER_ENCODE_FAILED');

  const RenderFailureCode(this.diagnostic);

  final String diagnostic;
}

/// A render failed; no output was produced.
final class RenderFailure implements Exception {
  const RenderFailure(this.code, {this.detail});

  final RenderFailureCode code;

  /// Sanitised detail for operators and logs: ids and field names, never
  /// file paths, photo bytes or guest data. Never shown to guests.
  final String? detail;

  @override
  String toString() =>
      'RenderFailure(${code.diagnostic}${detail == null ? '' : ': $detail'})';
}

enum RenderWarningCode {
  /// A text layer's font could not be loaded; the bundled default was used.
  fontFallback('RENDER_FONT_FALLBACK'),

  /// Text did not fit its frame; the extra lines were still drawn.
  textOverflow('RENDER_TEXT_OVERFLOW');

  const RenderWarningCode(this.diagnostic);

  final String diagnostic;
}

/// Something worth telling the operator about a render that succeeded.
final class RenderWarning {
  const RenderWarning(this.code, this.layerId, this.message);

  final RenderWarningCode code;
  final String layerId;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is RenderWarning &&
      other.code == code &&
      other.layerId == layerId &&
      other.message == message;

  @override
  int get hashCode => Object.hash(code, layerId, message);

  @override
  String toString() => '${code.diagnostic} ($layerId): $message';
}

/// Where a render reads encoded image and font bytes from: managed assets
/// and session originals in the app, memory in tests.
abstract interface class RenderSource {
  /// The bytes of a template asset; throws [RenderFailure] with
  /// [RenderFailureCode.missingAsset] when absent.
  Future<Uint8List> readAsset(String assetId);

  /// The bytes of a guest photo; throws [RenderFailure] with
  /// [RenderFailureCode.missingPhoto] when absent.
  Future<Uint8List> readPhoto(String photoId);
}

/// The photo chosen for one slot, and whether guests see it mirrored
/// (the event's output mirroring, P-05).
final class SlotPhoto {
  const SlotPhoto(this.photoId, {this.mirrored = false});

  final String photoId;
  final bool mirrored;
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

  /// Reading and measuring every input, compiling the scene, decoding
  /// images and loading fonts.
  final Duration decode;

  /// Recording paint commands.
  final Duration paint;

  /// Rasterising at output size, including pixel readback.
  final Duration rasterize;

  /// Encoding the output file.
  final Duration encode;

  final int? residentBytesAfter;
  final int? maxResidentBytes;

  Duration get total => decode + paint + rasterize + encode;
}

/// An encoded render: a print file, or a preview.
final class RenderArtifact {
  const RenderArtifact({
    required this.widthPx,
    required this.heightPx,
    required this.format,
    required this.bytes,
    required this.warnings,
    required this.stats,
    this.rgba,
  });

  final int widthPx;
  final int heightPx;
  final OutputFormat format;

  /// The encoded file.
  final Uint8List bytes;

  /// Straight-alpha RGBA pixels, row-major; present only when requested.
  final Uint8List? rgba;
  final List<RenderWarning> warnings;
  final RenderStats stats;

  String get mimeType => switch (format) {
    OutputFormat.jpeg => 'image/jpeg',
    OutputFormat.png => 'image/png',
  };
}

/// Renders template documents. Failures throw [RenderFailure].
abstract interface class CompositionRenderer {
  /// Print output at exactly the page's pixel size, cropped at the page
  /// edge (A-07): PNG keeps transparency, JPEG is flattened onto
  /// [flattenArgb] (paper white unless the template has a background).
  Future<RenderArtifact> renderExport(
    TemplateRender render, {
    OutputProfile output = const OutputProfile(),
    int flattenArgb = 0xFFFFFFFF,
    bool includePixels = false,
  });

  /// The same scene scaled to fit [maxWidthPx] x [maxHeightPx], as PNG.
  /// With [workspaceMargin] (a fraction of the page on every side) it shows
  /// artwork beyond the page edge and outlines the page, as the editor
  /// does; such previews are never print output.
  Future<RenderArtifact> renderPreview(
    TemplateRender render, {
    required int maxWidthPx,
    required int maxHeightPx,
    double workspaceMargin = 0,
    bool includePixels = false,
  });
}

/// One document with its photos and the source to read them from.
final class TemplateRender {
  const TemplateRender({
    required this.document,
    required this.photos,
    required this.source,
  });

  final TemplateDocument document;
  final Map<int, SlotPhoto> photos;
  final RenderSource source;
}
