import 'dart:io';
import 'dart:typed_data';

/// The file operations an atomic write is made of. Tests subclass it to
/// inject failures: a full disk, a short write, a failed rename.
class FileOperations {
  const FileOperations();

  /// Writes [bytes] to [file] and flushes them to storage.
  Future<void> writeAndFlush(File file, Uint8List bytes) =>
      file.writeAsBytes(bytes, flush: true);

  Future<Uint8List> read(File file) => file.readAsBytes();

  Future<void> rename(File file, String newPath) => file.rename(newPath);

  Future<void> delete(File file) => file.delete();
}

enum AtomicWriteFailure {
  /// The volume is full.
  noSpace,

  /// Writing or flushing the staged copy failed.
  writeFailed,

  /// What reached the disk is not what was written, or failed [verify].
  verifyFailed,

  /// The destination already exists; nothing is ever replaced.
  destinationExists,

  /// Moving the staged copy into place failed.
  commitFailed,
}

/// An atomic write failed: the destination is untouched and nothing staged
/// remains.
final class AtomicWriteException implements Exception {
  const AtomicWriteException(this.reason, {this.osErrorCode});

  final AtomicWriteFailure reason;

  /// The OS error number, when the OS reported one. Never a path.
  final int? osErrorCode;

  @override
  String toString() =>
      'AtomicWriteException(${reason.name}'
      '${osErrorCode == null ? '' : ', errno $osErrorCode'})';
}

/// Writes files so each is either absent or complete (A-11).
///
/// The bytes are staged under [staging] (on the same volume as every
/// destination, so the final rename is atomic), flushed, read back and
/// compared, optionally verified further, and only then renamed into
/// place. An existing destination is never replaced. On any failure the
/// staged copy is deleted and the destination is left as it was. Writes to
/// one destination must not race; callers use unique or content-derived
/// names.
final class AtomicFileWriter {
  AtomicFileWriter({
    required this.staging,
    this.operations = const FileOperations(),
  });

  final Directory staging;
  final FileOperations operations;

  /// Staged files are named `<prefix><unique>.tmp`, so startup can tell an
  /// interrupted write from anything else.
  static const stagedSuffix = '.tmp';

  var _counter = 0;

  /// Writes [bytes] to [destination]. [verify] checks the bytes as read
  /// back from the staged file (decodes them, for example) and throws if
  /// they are unusable. [stagedPrefix] labels the staged file.
  Future<void> write(
    File destination,
    Uint8List bytes, {
    Future<void> Function(Uint8List onDisk)? verify,
    String stagedPrefix = 'write-',
  }) async {
    if (destination.existsSync()) {
      throw const AtomicWriteException(AtomicWriteFailure.destinationExists);
    }
    final staged = File(
      '${staging.path}/$stagedPrefix'
      '${DateTime.now().microsecondsSinceEpoch}-${_counter++}$stagedSuffix',
    );
    try {
      try {
        await staging.create(recursive: true);
        await destination.parent.create(recursive: true);
        await operations.writeAndFlush(staged, bytes);
      } on FileSystemException catch (error) {
        throw AtomicWriteException(
          _isNoSpace(error)
              ? AtomicWriteFailure.noSpace
              : AtomicWriteFailure.writeFailed,
          osErrorCode: error.osError?.errorCode,
        );
      }

      final Uint8List onDisk;
      try {
        onDisk = await operations.read(staged);
      } on FileSystemException catch (error) {
        throw AtomicWriteException(
          AtomicWriteFailure.verifyFailed,
          osErrorCode: error.osError?.errorCode,
        );
      }
      if (!_same(onDisk, bytes)) {
        throw const AtomicWriteException(AtomicWriteFailure.verifyFailed);
      }
      if (verify != null) {
        try {
          await verify(onDisk);
        } on Object {
          throw const AtomicWriteException(AtomicWriteFailure.verifyFailed);
        }
      }

      if (destination.existsSync()) {
        throw const AtomicWriteException(AtomicWriteFailure.destinationExists);
      }
      try {
        await operations.rename(staged, destination.path);
      } on FileSystemException catch (error) {
        throw AtomicWriteException(
          _isNoSpace(error)
              ? AtomicWriteFailure.noSpace
              : AtomicWriteFailure.commitFailed,
          osErrorCode: error.osError?.errorCode,
        );
      }
    } on Object {
      await _discard(staged);
      rethrow;
    }
  }

  /// Deletes staged files that interrupted writes left behind. Only safe
  /// when no write is in progress (at startup). Returns how many were
  /// removed.
  static Future<int> discardStaged(Directory staging) async {
    if (!staging.existsSync()) return 0;
    var removed = 0;
    for (final entry in staging.listSync(followLinks: false)) {
      if (entry is File && entry.path.endsWith(stagedSuffix)) {
        try {
          await entry.delete();
          removed++;
        } on FileSystemException {
          // Tried again at the next start.
        }
      }
    }
    return removed;
  }

  Future<void> _discard(File staged) async {
    try {
      if (staged.existsSync()) await operations.delete(staged);
    } on FileSystemException {
      // Removed at the next start (discardStaged).
    }
  }

  static bool _same(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// ENOSPC (28 on Linux, Android, iOS and macOS) and EDQUOT (122 on Linux
  /// and Android, 69 on iOS and macOS).
  static bool _isNoSpace(FileSystemException error) {
    final code = error.osError?.errorCode;
    return code == 28 ||
        ((Platform.isLinux || Platform.isAndroid) && code == 122) ||
        ((Platform.isIOS || Platform.isMacOS) && code == 69);
  }
}
