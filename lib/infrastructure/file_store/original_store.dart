import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' as crypto;

import '../../domain/services/camera_service.dart';
import 'jpeg_exif.dart';

/// What the camera adapter knows about a still when committing it.
final class CaptureContext {
  const CaptureContext({
    required this.lens,
    required this.sensorOrientationDegrees,
    required this.mirrorPreviewRequested,
    required this.mirrorOutputRequested,
    required this.capturedAtUtc,
  });

  final CameraLens lens;
  final int sensorOrientationDegrees;
  final bool mirrorPreviewRequested;
  final bool mirrorOutputRequested;
  final DateTime capturedAtUtc;
}

/// An original could not be validated or committed; nothing was stored.
final class OriginalCommitException implements Exception {
  const OriginalCommitException(this.reason);

  final String reason;

  @override
  String toString() => 'OriginalCommitException($reason)';
}

/// Managed, immutable storage for captured originals (A-11, ADR-0002).
///
/// Spike-grade (M01). A commit stages the bytes on the same volume with a
/// flush, re-reads and fully decodes what is on disk, then renames the image
/// into place and finally renames a metadata sidecar beside it. The sidecar
/// is the commit marker: an image without one is an incomplete commit. M06
/// and M10 add the operation journal and startup reconciliation.
final class OriginalStore implements CapturedStillStore {
  OriginalStore({required this._root});

  final Future<Directory> Function() _root;

  static const directoryName = 'originals';
  static const _stagingName = '.staging';
  static final _validId = RegExp(r'^[0-9A-Za-z-]{1,64}$');

  Future<Directory> _directory() async =>
      Directory('${(await _root()).path}/$directoryName');

  /// Validates and stores [bytes] as original [id]. Never overwrites.
  Future<CapturedStill> commit({
    required String id,
    required Uint8List bytes,
    required CaptureContext context,
  }) async {
    if (!_validId.hasMatch(id)) {
      throw OriginalCommitException('invalid id "$id"');
    }
    final directory = await _directory();
    final staging = Directory('${directory.path}/$_stagingName');
    await staging.create(recursive: true);
    final image = File('${directory.path}/$id.jpg');
    final metadata = File('${directory.path}/$id.json');
    if (image.existsSync() || metadata.existsSync()) {
      throw OriginalCommitException('original $id already exists');
    }

    final stagedImage = File('${staging.path}/$id.jpg.tmp');
    final stagedMetadata = File('${staging.path}/$id.json.tmp');
    try {
      await stagedImage.writeAsBytes(bytes, flush: true);
      final onDisk = await stagedImage.readAsBytes();
      if (onDisk.length != bytes.length) {
        throw const OriginalCommitException('short write');
      }
      final size = await _decodedSize(onDisk);
      final still = CapturedStill(
        id: id,
        relativePath: '$directoryName/$id.jpg',
        widthPx: size.$1,
        heightPx: size.$2,
        byteLength: onDisk.length,
        sha256: crypto.sha256.convert(onDisk).toString(),
        lens: context.lens,
        sensorOrientationDegrees: context.sensorOrientationDegrees,
        mirrorPreviewRequested: context.mirrorPreviewRequested,
        mirrorOutputRequested: context.mirrorOutputRequested,
        capturedAtUtc: context.capturedAtUtc.toUtc(),
        exifOrientation: readJpegExifOrientation(onDisk),
      );
      await stagedMetadata.writeAsString(
        jsonEncode(_toJson(still)),
        flush: true,
      );
      await stagedImage.rename(image.path);
      await stagedMetadata.rename(metadata.path);
      return still;
    } on Object {
      for (final file in [stagedImage, stagedMetadata]) {
        if (file.existsSync()) await file.delete();
      }
      rethrow;
    }
  }

  @override
  Future<List<CapturedStill>> listCommitted() async {
    final directory = await _directory();
    if (!directory.existsSync()) return const [];
    final stills = <CapturedStill>[];
    for (final entry in directory.listSync()) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      try {
        final still = _fromJson(
          jsonDecode(await entry.readAsString()) as Map<String, Object?>,
        );
        final bytes = await File(
          '${(await _root()).path}/${still.relativePath}',
        ).readAsBytes();
        if (crypto.sha256.convert(bytes).toString() == still.sha256) {
          stills.add(still);
        }
      } on Object {
        // Unreadable or mismatched entries are left for M10 reconciliation;
        // they are never shown as valid originals.
      }
    }
    return stills..sort((a, b) => a.capturedAtUtc.compareTo(b.capturedAtUtc));
  }

  @override
  Future<Uint8List> read(CapturedStill still) async {
    final bytes = await File('${(await _root()).path}/${still.relativePath}')
        .readAsBytes();
    if (crypto.sha256.convert(bytes).toString() != still.sha256) {
      throw OriginalCommitException('original ${still.id} failed its checksum');
    }
    return bytes;
  }

  /// Fully decodes [bytes] (at a small size, to bound memory) and returns the
  /// oriented dimensions. Truncated or corrupt files fail here.
  static Future<(int, int)> _decodedSize(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (descriptor.width, descriptor.height);
      codec = await descriptor.instantiateCodec(targetWidth: 64);
      (await codec.getNextFrame()).image.dispose();
      return size;
    } on Object {
      throw const OriginalCommitException('not a decodable image');
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static Map<String, Object?> _toJson(CapturedStill still) => {
    'schemaVersion': 1,
    'id': still.id,
    'relativePath': still.relativePath,
    'widthPx': still.widthPx,
    'heightPx': still.heightPx,
    'byteLength': still.byteLength,
    'sha256': still.sha256,
    'lens': still.lens.name,
    'sensorOrientationDegrees': still.sensorOrientationDegrees,
    'mirrorPreviewRequested': still.mirrorPreviewRequested,
    'mirrorOutputRequested': still.mirrorOutputRequested,
    'capturedAtUtc': still.capturedAtUtc.toIso8601String(),
    'exifOrientation': still.exifOrientation,
  };

  static CapturedStill _fromJson(Map<String, Object?> json) => CapturedStill(
    id: json['id']! as String,
    relativePath: json['relativePath']! as String,
    widthPx: json['widthPx']! as int,
    heightPx: json['heightPx']! as int,
    byteLength: json['byteLength']! as int,
    sha256: json['sha256']! as String,
    lens: CameraLens.values.byName(json['lens']! as String),
    sensorOrientationDegrees: json['sensorOrientationDegrees']! as int,
    mirrorPreviewRequested: json['mirrorPreviewRequested']! as bool,
    mirrorOutputRequested: json['mirrorOutputRequested']! as bool,
    capturedAtUtc: DateTime.parse(json['capturedAtUtc']! as String),
    exifOrientation: json['exifOrientation'] as int?,
  );
}
