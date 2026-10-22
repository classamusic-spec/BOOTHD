import 'dart:io' as io;

import 'package:file/file.dart' as pf;
import 'package:flutter/foundation.dart' show kIsWeb;

/// The file at [path] in the same file system as [near] (ADR-0018).
///
/// On tablets every entity is a plain `dart:io` one and so is the result:
/// behaviour is exactly `File(path)`. In the browser, managed storage's
/// root comes from an IndexedDB-backed `package:file` file system, and
/// every file and folder derived from it stays in that file system.
io.File fileNear(io.FileSystemEntity near, String path) =>
    near is pf.FileSystemEntity ? near.fileSystem.file(path) : io.File(path);

/// The directory at [path] in the same file system as [near].
io.Directory directoryNear(io.FileSystemEntity near, String path) =>
    near is pf.FileSystemEntity
    ? near.fileSystem.directory(path)
    : io.Directory(path);

/// Whether [error] says the storage is full: ENOSPC or EDQUOT on tablets;
/// in the browser a quota error, which carries no OS error code.
bool fileSystemFull(io.FileSystemException error) {
  final code = error.osError?.errorCode;
  if (kIsWeb) return error.message.contains('QuotaExceeded');
  return code == 28 ||
      ((io.Platform.isLinux || io.Platform.isAndroid) && code == 122) ||
      ((io.Platform.isIOS || io.Platform.isMacOS) && code == 69);
}

/// The file [relativePath] inside [directory], in its file system.
io.File fileIn(io.Directory directory, String relativePath) =>
    fileNear(directory, '${directory.path}/$relativePath');

/// The directory [relativePath] inside [directory], in its file system.
io.Directory directoryIn(io.Directory directory, String relativePath) =>
    directoryNear(directory, '${directory.path}/$relativePath');
