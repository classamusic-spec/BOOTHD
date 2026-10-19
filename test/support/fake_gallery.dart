import 'dart:typed_data';

import 'package:porcelain_photo_booth/domain/gallery/export_plan.dart';
import 'package:porcelain_photo_booth/domain/services/gallery_services.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';

import 'fake_export.dart';
import 'simulated_camera.dart';

/// Thumbnails without decoding: the finished photo's stand-in bytes, or the
/// simulated camera's photo. Records every request, so tests can see that
/// only shown tiles ask for one.
final class FakeThumbnailStore implements ThumbnailStore {
  FakeThumbnailStore({this.exports});

  FakeExportService? exports;

  final requests = <ThumbnailSource>[];

  /// Sources whose thumbnail cannot be made.
  final unavailable = <String>{};
  var cleared = 0;
  var bytesStored = 48 * 1024;

  @override
  Future<Uint8List> thumbnail(ThumbnailSource source) async {
    requests.add(source);
    if (unavailable.contains(source.id)) {
      throw const ThumbnailUnavailable('missing');
    }
    return switch (source.kind) {
      ThumbnailKind.output =>
        exports?.files[source.relativePath] ?? SimulatedStillStore.photoBytes,
      ThumbnailKind.original => SimulatedStillStore.photoBytes,
    };
  }

  @override
  Future<int> clear() async {
    cleared++;
    final freed = bytesStored;
    bytesStored = 0;
    return freed;
  }

  @override
  Future<int> size() async => bytesStored;
}

/// The deletion journal emptied without touching files; can be made to
/// leave files behind.
final class FakeStorageCleanup implements StorageCleanup {
  FakeStorageCleanup(this.db);

  final BoothDatabase db;

  /// Paths removed, in order.
  final removed = <String>[];

  /// While true, nothing is removed (a file the OS will not let go of).
  var stuck = false;
  var runs = 0;

  @override
  Future<CleanupResult> run() async {
    runs++;
    final pending = await db.select(db.pendingFileDeletions).get();
    if (stuck) return CleanupResult(removed: 0, remaining: pending.length);
    for (final entry in pending) {
      removed.add(entry.relativePath);
      await (db.delete(
        db.pendingFileDeletions,
      )..where((p) => p.relativePath.equals(entry.relativePath))).go();
    }
    return CleanupResult(removed: pending.length, remaining: 0);
  }

  /// Startup sweeps, counted (the real sweep is tested on files).
  var sweeps = 0;

  @override
  Future<OrphanSweepResult> sweepOrphans() async {
    sweeps++;
    return const OrphanSweepResult(removed: 0, quarantined: 0);
  }
}

/// The exporter with the share sheet scripted: what it reports, and which
/// files are missing or damaged.
final class FakeGalleryExporter implements GalleryExporter {
  /// What the share sheet reports next (every part).
  ShareReport share = const ShareReport(
    ShareOutcome.shared,
    destination: 'com.apple.DocumentManagerUICore.SaveToFiles',
  );

  /// Source ids whose files are missing or damaged.
  final missing = <String>{};
  final damaged = <String>{};

  /// When set, every part is refused for lack of space.
  int? freeBytes;

  /// Parts offered, with their files.
  final parts = <List<ExportItem>>[];
  var discarded = 0;

  @override
  Future<ExportPartReport> export(
    List<ExportItem> items, {
    required ShareAnchor anchor,
    int part = 1,
    int parts = 1,
  }) async {
    final free = freeBytes;
    if (free != null) {
      return ExportPartReport(
        part: part,
        parts: parts,
        sent: const [],
        failures: [
          for (final item in items)
            ExportFailureItem(
              sessionNumber: item.sessionNumber,
              problem: ExportProblem.noSpace,
              kind: item.kind,
              fileName: item.fileName,
            ),
        ],
        requiredBytes: items.fold<int>(0, (sum, i) => sum + i.byteLength),
        freeBytes: free,
      );
    }
    final sent = <ExportItem>[];
    final failures = <ExportFailureItem>[];
    for (final item in items) {
      final problem = missing.contains(item.sourceId)
          ? ExportProblem.missing
          : damaged.contains(item.sourceId)
          ? ExportProblem.damaged
          : null;
      if (problem == null) {
        sent.add(item);
      } else {
        failures.add(
          ExportFailureItem(
            sessionNumber: item.sessionNumber,
            problem: problem,
            kind: item.kind,
            fileName: item.fileName,
          ),
        );
      }
    }
    if (sent.isNotEmpty) this.parts.add(sent);
    return ExportPartReport(
      part: part,
      parts: parts,
      sent: sent,
      failures: failures,
      share: sent.isEmpty ? null : share,
    );
  }

  @override
  Future<void> discardPrepared() async => discarded++;
}

/// A finished-photo stand-in at print size: 1200 x 1800 pixels tagged 300
/// dpi (4 x 6 inches), ivory paper with two warm photo spaces and a gold
/// rule, as the Two-up classic template lays them out. Made once.
final Uint8List printStandIn = () {
  const width = 1200;
  const height = 1800;
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    final v = y / height;
    final inTop = v >= 0.06 && v < 0.47;
    final inBottom = v >= 0.53 && v < 0.94;
    final rule = v >= 0.497 && v < 0.503;
    for (var x = 0; x < width; x++) {
      final u = x / width;
      final i = (y * width + x) * 4;
      var r = 251, g = 248, b = 243;
      if ((inTop || inBottom) && u >= 0.08 && u < 0.92) {
        final t = inTop ? (v - 0.06) / 0.41 : (v - 0.53) / 0.41;
        r = (196 + 40 * u).round();
        g = (160 + 50 * t).round();
        b = inTop ? 132 : 150;
      } else if (rule && u >= 0.3 && u < 0.7) {
        r = 201;
        g = 168;
        b = 106;
      }
      rgba
        ..[i] = r
        ..[i + 1] = g
        ..[i + 2] = b
        ..[i + 3] = 255;
    }
  }
  return encodeJpeg(rgba, width: width, height: height, quality: 85);
}();
