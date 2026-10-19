import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../models/booth_event.dart';

/// What an image file says about itself, read from its bytes without
/// decoding (S14 print-ready check, AC-0807): its format, pixel size,
/// print resolution tag (JFIF density or PNG pHYs) and whether it ends
/// properly (JPEG end-of-image marker, PNG IEND chunk).
@immutable
final class PrintFileFacts {
  const PrintFileFacts({
    this.format,
    this.widthPx,
    this.heightPx,
    this.dpi,
    this.complete = false,
  });

  /// Null when the bytes are neither JPEG nor PNG.
  final OutputFormat? format;
  final int? widthPx;
  final int? heightPx;

  /// Dots per inch from the file's own resolution tag; null when it has
  /// none.
  final int? dpi;
  final bool complete;

  static PrintFileFacts read(Uint8List bytes) {
    if (bytes.length >= 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return _jpeg(bytes);
    }
    const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (bytes.length >= 8) {
      var png = true;
      for (var i = 0; i < 8; i++) {
        if (bytes[i] != signature[i]) png = false;
      }
      if (png) return _png(bytes);
    }
    return const PrintFileFacts();
  }

  static int _u16(Uint8List b, int i) => b[i] << 8 | b[i + 1];
  static int _u32(Uint8List b, int i) =>
      b[i] << 24 | b[i + 1] << 16 | b[i + 2] << 8 | b[i + 3];

  static PrintFileFacts _jpeg(Uint8List b) {
    int? width;
    int? height;
    int? dpi;
    var i = 2;
    while (i + 4 <= b.length) {
      if (b[i] != 0xFF) break;
      final marker = b[i + 1];
      if (marker == 0xD8 || (marker >= 0xD0 && marker <= 0xD7)) {
        i += 2;
        continue;
      }
      if (marker == 0xDA || marker == 0xD9) break;
      final length = _u16(b, i + 2);
      final data = i + 4;
      if (length < 2 || data + length - 2 > b.length) break;
      final isApp0Jfif =
          marker == 0xE0 &&
          length >= 16 &&
          b[data] == 0x4A &&
          b[data + 1] == 0x46 &&
          b[data + 2] == 0x49 &&
          b[data + 3] == 0x46 &&
          b[data + 4] == 0;
      if (isApp0Jfif) {
        final units = b[data + 7];
        final x = _u16(b, data + 8);
        dpi = switch (units) {
          1 => x,
          2 => (x * 2.54).round(),
          _ => null,
        };
      }
      final isFrame =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isFrame && length >= 7) {
        height = _u16(b, data + 1);
        width = _u16(b, data + 3);
      }
      i = data + length - 2;
    }
    var end = b.length;
    while (end > 2 && b[end - 1] == 0) {
      end--;
    }
    return PrintFileFacts(
      format: OutputFormat.jpeg,
      widthPx: width,
      heightPx: height,
      dpi: dpi,
      complete: end >= 2 && b[end - 2] == 0xFF && b[end - 1] == 0xD9,
    );
  }

  static PrintFileFacts _png(Uint8List b) {
    int? width;
    int? height;
    int? dpi;
    var complete = false;
    var i = 8;
    while (i + 12 <= b.length) {
      final length = _u32(b, i);
      final type = String.fromCharCodes(b.sublist(i + 4, i + 8));
      final data = i + 8;
      if (length < 0 || data + length + 4 > b.length) break;
      switch (type) {
        case 'IHDR' when length >= 8:
          width = _u32(b, data);
          height = _u32(b, data + 4);
        case 'pHYs' when length >= 9:
          if (b[data + 8] == 1) dpi = (_u32(b, data) * 0.0254).round();
        case 'IEND':
          complete = true;
      }
      if (complete) break;
      i = data + length + 4;
    }
    return PrintFileFacts(
      format: OutputFormat.png,
      widthPx: width,
      heightPx: height,
      dpi: dpi,
      complete: complete,
    );
  }
}

/// One check of a finished photo's file.
enum PrintCheckId {
  /// The bytes match the recorded checksum (read back intact).
  intact,

  /// The file is the recorded format and ends properly.
  format,

  /// The pixel size is the recorded one and the template's page.
  pixelSize,

  /// The file carries a print resolution, so it opens at print size.
  resolution,
}

/// A finished photo's file checked against its record and its template's
/// page (S14, AC-0807).
@immutable
final class PrintReadiness {
  const PrintReadiness(this.facts, this.failed);

  /// Checks [bytes] (already read back against [recordedSha256] when
  /// [intact]) against the recorded format and size and the template's
  /// page size.
  factory PrintReadiness.check({
    required Uint8List? bytes,
    required bool intact,
    required OutputFormat format,
    required int widthPx,
    required int heightPx,
    int? pageWidthPx,
    int? pageHeightPx,
  }) {
    final facts = bytes == null
        ? const PrintFileFacts()
        : PrintFileFacts.read(bytes);
    final failed = <PrintCheckId>{
      if (!intact) PrintCheckId.intact,
      if (facts.format != format || !facts.complete) PrintCheckId.format,
      if (facts.widthPx != widthPx ||
          facts.heightPx != heightPx ||
          (pageWidthPx != null && pageWidthPx != widthPx) ||
          (pageHeightPx != null && pageHeightPx != heightPx))
        PrintCheckId.pixelSize,
      if (facts.dpi == null || facts.dpi! < 72) PrintCheckId.resolution,
    };
    return PrintReadiness(facts, failed);
  }

  final PrintFileFacts facts;
  final Set<PrintCheckId> failed;

  bool get ready => failed.isEmpty;

  /// Print size in inches at the file's own resolution.
  (double, double)? get inches {
    final dpi = facts.dpi;
    final width = facts.widthPx;
    final height = facts.heightPx;
    if (dpi == null || dpi <= 0 || width == null || height == null) {
      return null;
    }
    return (width / dpi, height / dpi);
  }
}
