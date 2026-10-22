import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../core/composition/scene_images.dart';
import '../../domain/services/gallery_services.dart';
import '../background/background_work.dart';
import '../codecs/jpeg_encoder.dart';
import 'atomic_file_writer.dart';
import 'file_system.dart';
import 'managed_storage.dart';

/// [ThumbnailStore] under managed storage's `thumbnails/` (S13).
///
/// A thumbnail is the source decoded at reduced size by the platform
/// decoder (which applies EXIF orientation), encoded as a small JPEG on a
/// background isolate and written atomically as
/// `thumbnails/<kind>-<id>.jpg`. Sources are immutable, so a stored
/// thumbnail never goes stale. At most two are made at once, and a second
/// request for one being made waits for it.
final class ManagedThumbnailStore implements ThumbnailStore {
  ManagedThumbnailStore({
    required this._storage,
    this.quality = 82,
    this.maxConcurrent = 2,
  });

  final FileManagedStorage _storage;
  final int quality;
  final int maxConcurrent;

  final _inFlight = <ThumbnailSource, Future<Uint8List>>{};
  final _waiting = <Completer<void>>[];
  var _running = 0;

  static final _sourcePath = RegExp(
    r'^(outputs/[0-9a-f-]{36}\.(jpg|png)|originals/[0-9A-Za-z-]{1,64}\.jpg)$',
  );
  static final _id = RegExp(r'^[0-9A-Za-z-]{1,64}$');

  /// Where the thumbnail of [kind] [id] is kept, relative to managed
  /// storage.
  static String relativePathFor(ThumbnailKind kind, String id) =>
      '${ManagedArea.thumbnails.directoryName}/${kind.name}-$id.jpg';

  @override
  Future<Uint8List> thumbnail(ThumbnailSource source) =>
      _inFlight[source] ??= _thumbnail(source).whenComplete(() {
        // A block body: returning the removed future would make this wait
        // for itself.
        _inFlight.remove(source);
      });

  Future<Uint8List> _thumbnail(ThumbnailSource source) async {
    if (!_id.hasMatch(source.id) ||
        !_sourcePath.hasMatch(source.relativePath)) {
      throw const ThumbnailUnavailable('invalid');
    }
    final root = (await _storage.directory(ManagedArea.thumbnails)).parent;
    final file = fileIn(root, relativePathFor(source.kind, source.id));
    try {
      final stored = await file.readAsBytes();
      if (stored.length > 4 && stored[0] == 0xFF && stored[1] == 0xD8) {
        return stored;
      }
      await file.delete();
    } on FileSystemException {
      // Not made yet.
    }

    await _acquire();
    try {
      final Uint8List original;
      try {
        original = await fileIn(root, source.relativePath).readAsBytes();
      } on FileSystemException {
        throw const ThumbnailUnavailable('missing');
      }
      final ui.Image image;
      try {
        final size = await probeImageSize(original);
        final scale = math.min(
          1.0,
          ThumbnailStore.maxSide / math.max(size.width, size.height),
        );
        image = await decodeImage(original, scale: scale);
      } on Object {
        throw const ThumbnailUnavailable('undecodable');
      }
      final width = image.width;
      final height = image.height;
      final ByteData? pixels;
      try {
        pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      } finally {
        image.dispose();
      }
      if (pixels == null) throw const ThumbnailUnavailable('undecodable');
      final rgba = pixels.buffer.asUint8List(
        pixels.offsetInBytes,
        pixels.lengthInBytes,
      );
      final quality = this.quality;
      final jpeg = await runInBackground(
        () => encodeJpeg(
          rgba,
          width: width,
          height: height,
          quality: quality,
          dpi: 72,
        ),
      );
      try {
        await (await _storage.writer()).write(
          file,
          jpeg,
          stagedPrefix: 'thumbnail-',
        );
      } on AtomicWriteException {
        // Shown anyway; made again next time.
      }
      return jpeg;
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_running < maxConcurrent) {
      _running++;
      return;
    }
    final turn = Completer<void>();
    _waiting.add(turn);
    await turn.future;
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    } else {
      _running--;
    }
  }

  @override
  Future<int> clear() async {
    final directory = await _storage.directory(ManagedArea.thumbnails);
    if (!directory.existsSync()) return 0;
    var freed = 0;
    for (final entry in directory.listSync(followLinks: false)) {
      if (entry is! File) continue;
      try {
        final length = entry.lengthSync();
        await entry.delete();
        freed += length;
      } on FileSystemException {
        // Left; cleared next time.
      }
    }
    return freed;
  }

  @override
  Future<int> size() async {
    final directory = await _storage.directory(ManagedArea.thumbnails);
    if (!directory.existsSync()) return 0;
    var total = 0;
    for (final entry in directory.listSync(followLinks: false)) {
      if (entry is File) {
        try {
          total += entry.lengthSync();
        } on FileSystemException {
          // Gone meanwhile.
        }
      }
    }
    return total;
  }
}
