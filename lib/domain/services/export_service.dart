/// Saving renders as print files (A-07 steps 6-7, AC-0409).
library;

import '../models/booth_event.dart';
import 'composition_renderer.dart';

/// Why a render could not be saved; each maps to an `EXPORT_*` diagnostic
/// (A-14).
enum ExportFailureCode {
  /// The device is out of storage.
  noSpace('EXPORT_NO_SPACE'),

  /// The file could not be written.
  writeFailed('EXPORT_WRITE_FAILED'),

  /// The written file did not read back intact, or did not decode to the
  /// page size.
  verifyFailed('EXPORT_VERIFY_FAILED'),

  /// The verified file could not be moved into place.
  commitFailed('EXPORT_COMMIT_FAILED');

  const ExportFailureCode(this.diagnostic);

  final String diagnostic;
}

/// A render could not be saved. Nothing was saved and no existing file
/// changed.
final class ExportFailure implements Exception {
  const ExportFailure(this.code, {this.detail});

  final ExportFailureCode code;

  /// Sanitised detail for operators: an OS error number at most, never a
  /// path or guest data.
  final String? detail;

  @override
  String toString() =>
      'ExportFailure(${code.diagnostic}${detail == null ? '' : ': $detail'})';
}

/// A saved print file: complete, verified and immutable (A-05
/// RenderedOutput's file facts).
final class ExportedFile {
  const ExportedFile({
    required this.id,
    required this.relativePath,
    required this.sha256,
    required this.byteLength,
    required this.widthPx,
    required this.heightPx,
    required this.format,
    required this.renderVersion,
    required this.warnings,
    required this.stats,
  });

  final String id;

  /// Relative to managed storage, e.g. `outputs/<id>.jpg`.
  final String relativePath;

  /// Lowercase hex SHA-256 of the file.
  final String sha256;
  final int byteLength;
  final int widthPx;
  final int heightPx;
  final OutputFormat format;

  /// [rendererVersion] when the file was made.
  final int renderVersion;
  final List<RenderWarning> warnings;
  final RenderStats stats;

  String get mimeType => switch (format) {
    OutputFormat.jpeg => 'image/jpeg',
    OutputFormat.png => 'image/png',
  };
}

abstract interface class ExportService {
  /// Renders [render] at full resolution and saves it as a new file.
  ///
  /// Throws [RenderFailure] when it cannot be rendered and [ExportFailure]
  /// when it cannot be saved. Either way nothing is saved, and no original
  /// photo or earlier output is touched: every export is a new file.
  Future<ExportedFile> export(
    TemplateRender render, {
    OutputProfile output = const OutputProfile(),
    int flattenArgb = 0xFFFFFFFF,
  });
}
