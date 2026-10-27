import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

/// One stored entry: a folder, or a file with its size and change time.
final class BlobEntry {
  const BlobEntry.directory() : isDirectory = true, size = 0, modified = null;

  const BlobEntry.file(this.size, this.modified) : isDirectory = false;

  final bool isDirectory;
  final int size;
  final DateTime? modified;
}

/// Where a [BlobFileSystem] keeps its folders and file contents (in the
/// browser, IndexedDB). Every call is one atomic change: it either
/// happens completely or not at all. Failures throw
/// [io.FileSystemException]; a full store says `QuotaExceeded`.
abstract interface class BlobStore {
  /// Every stored entry, by absolute path.
  Future<Map<String, BlobEntry>> load();

  Future<Uint8List> read(String path);

  /// Stores [bytes] at [path], replacing any file there.
  Future<void> write(String path, Uint8List bytes, DateTime modified);

  Future<void> makeDirectories(Iterable<String> paths);

  /// Moves every `from` to its `to` together (a rename of a file or of a
  /// folder with everything in it), replacing files at the destinations.
  Future<void> move(Map<String, String> moves);

  Future<void> remove(Iterable<String> paths);
}

/// A [BlobStore] in memory, for tests.
final class MemoryBlobStore implements BlobStore {
  final _entries = <String, BlobEntry>{};
  final _contents = <String, Uint8List>{};

  /// The next write fails with this message (e.g. `QuotaExceeded`), once.
  String? failNextWrite;

  @override
  Future<Map<String, BlobEntry>> load() async => Map.of(_entries);

  @override
  Future<Uint8List> read(String path) async =>
      _contents[path]?.sublist(0) ??
      (throw io.FileSystemException('Cannot open file', path));

  @override
  Future<void> write(String path, Uint8List bytes, DateTime modified) async {
    final failure = failNextWrite;
    if (failure != null) {
      failNextWrite = null;
      throw io.FileSystemException(failure, path);
    }
    _contents[path] = Uint8List.fromList(bytes);
    _entries[path] = BlobEntry.file(bytes.length, modified);
  }

  @override
  Future<void> makeDirectories(Iterable<String> paths) async {
    for (final path in paths) {
      _entries[path] = const BlobEntry.directory();
    }
  }

  @override
  Future<void> move(Map<String, String> moves) async {
    final entries = {for (final from in moves.keys) from: _entries[from]};
    final contents = {for (final from in moves.keys) from: _contents[from]};
    for (final from in moves.keys) {
      _entries.remove(from);
      _contents.remove(from);
    }
    for (final MapEntry(key: from, value: to) in moves.entries) {
      if (entries[from] case final entry?) _entries[to] = entry;
      if (contents[from] case final bytes?) _contents[to] = bytes;
    }
  }

  @override
  Future<void> remove(Iterable<String> paths) async {
    for (final path in paths) {
      _entries.remove(path);
      _contents.remove(path);
    }
  }
}

/// A `package:file` file system over a [BlobStore] (ADR-0018): the browser's
/// managed storage. The index of folders and file sizes is held in memory
/// (loaded once by [open]), so existence checks and listings answer at
/// once as `dart:io` does; contents are read from the store when asked.
///
/// It implements what the booth's stores use: create, exists, read, write,
/// rename, delete, length and listing, with `dart:io`'s rules (a file needs
/// its folder, a folder must be empty to delete without `recursive`, a
/// rename replaces a file at the destination). Anything else is
/// unsupported and says so.
final class BlobFileSystem extends FileSystem {
  BlobFileSystem._(this._store, Map<String, BlobEntry> index) : _index = index;

  /// The file system stored in [store], with `/` always present.
  static Future<BlobFileSystem> open(BlobStore store) async =>
      BlobFileSystem._(store, await store.load());

  final BlobStore _store;
  final Map<String, BlobEntry> _index;

  // Check paths, commit the store transaction and update the index as one
  // operation. Otherwise overlapping appends or a write racing a rename
  // can use stale metadata and silently lose bytes.
  Future<void> _pending = Future.value();

  Future<T> _mutate<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static final _context = p.Context(style: p.Style.posix, current: '/');

  String _normal(dynamic path) {
    final text = getPath(path);
    return _context.normalize(_context.absolute(text));
  }

  bool _isDirectory(String path) =>
      path == '/' || (_index[path]?.isDirectory ?? false);

  bool _isFile(String path) =>
      _index[path] != null && !_index[path]!.isDirectory;

  Iterable<String> _children(String directory) {
    final prefix = directory == '/' ? '/' : '$directory/';
    return _index.keys.where(
      (path) =>
          path.startsWith(prefix) &&
          !path.substring(prefix.length).contains('/'),
    );
  }

  Iterable<String> _descendants(String directory) {
    final prefix = directory == '/' ? '/' : '$directory/';
    return _index.keys.where((path) => path.startsWith(prefix));
  }

  @override
  Directory directory(dynamic path) => _BlobDirectory(this, _normal(path));

  @override
  File file(dynamic path) => _BlobFile(this, _normal(path));

  @override
  Link link(dynamic path) =>
      throw UnsupportedError('Links are not supported in the browser');

  @override
  p.Context get path => _context;

  @override
  Directory get systemTempDirectory => directory('/tmp');

  @override
  Directory get currentDirectory => directory('/');

  @override
  set currentDirectory(dynamic path) =>
      throw UnsupportedError('The current directory is always /');

  @override
  Future<io.FileStat> stat(String path) async => statSync(path);

  @override
  io.FileStat statSync(String path) =>
      throw UnsupportedError('stat is not supported in the browser');

  @override
  Future<bool> identical(String path1, String path2) async =>
      identicalSync(path1, path2);

  @override
  bool identicalSync(String path1, String path2) =>
      _normal(path1) == _normal(path2);

  @override
  bool get isWatchSupported => false;

  @override
  Future<io.FileSystemEntityType> type(
    String path, {
    bool followLinks = true,
  }) async => typeSync(path);

  @override
  io.FileSystemEntityType typeSync(String path, {bool followLinks = true}) {
    final normal = _normal(path);
    if (_isDirectory(normal)) return io.FileSystemEntityType.directory;
    if (_isFile(normal)) return io.FileSystemEntityType.file;
    return io.FileSystemEntityType.notFound;
  }

  static io.FileSystemException _missing(String message, String path) =>
      io.FileSystemException(
        message,
        path,
        const io.OSError('No such file or directory', 2),
      );

  void _requireParent(String path) {
    final parent = _context.dirname(path);
    if (!_isDirectory(parent)) {
      throw _missing('Cannot create file', path);
    }
  }

  Future<void> _makeDirectories(String path, {required bool recursive}) async {
    if (_isDirectory(path)) return;
    if (_isFile(path)) {
      throw io.FileSystemException('A file is in the way', path);
    }
    final missing = <String>[];
    var current = path;
    while (current != '/' && !_isDirectory(current)) {
      if (_isFile(current)) {
        throw io.FileSystemException('A file is in the way', current);
      }
      missing.add(current);
      current = _context.dirname(current);
    }
    if (missing.length > 1 && !recursive) {
      throw _missing('Cannot create directory', path);
    }
    await _store.makeDirectories(missing.reversed);
    for (final directory in missing) {
      _index[directory] = const BlobEntry.directory();
    }
  }

  Future<void> _write(String path, Uint8List bytes) async {
    if (_isDirectory(path)) {
      throw io.FileSystemException('Is a directory', path);
    }
    _requireParent(path);
    final now = DateTime.now();
    await _store.write(path, bytes, now);
    _index[path] = BlobEntry.file(bytes.length, now);
  }

  Future<Uint8List> _read(String path) {
    if (!_isFile(path)) throw _missing('Cannot open file', path);
    return _store.read(path);
  }

  Future<void> _move(String from, String to) async {
    if (!_isFile(from) && !_isDirectory(from)) {
      throw _missing('Cannot rename', from);
    }
    if (from == to) return;
    if (_isFile(from)) {
      if (_isDirectory(to)) {
        throw io.FileSystemException('Is a directory', to);
      }
      _requireParent(to);
      await _store.move({from: to});
      _index[to] = _index.remove(from)!;
      return;
    }
    if (from == '/' || _context.isWithin(from, to)) {
      throw io.FileSystemException('Cannot move a directory inside itself', to);
    }
    if (_index.containsKey(to)) {
      throw io.FileSystemException('Destination exists', to);
    }
    _requireParent(to);
    final moves = {
      from: to,
      for (final path in _descendants(from))
        path: '$to${path.substring(from.length)}',
    };
    await _store.move(moves);
    final moved = {for (final from in moves.keys) from: _index.remove(from)!};
    for (final MapEntry(key: from, value: entry) in moved.entries) {
      _index[moves[from]!] = entry;
    }
  }

  Future<void> _delete(String path, {required bool recursive}) async {
    if (_isFile(path)) {
      await _store.remove([path]);
      _index.remove(path);
      return;
    }
    if (!_isDirectory(path) || path == '/') {
      throw _missing('Cannot delete', path);
    }
    final inside = _descendants(path).toList();
    if (inside.isNotEmpty && !recursive) {
      throw io.FileSystemException(
        'Directory not empty',
        path,
        const io.OSError('Directory not empty', 39),
      );
    }
    await _store.remove([...inside, path]);
    for (final entry in [...inside, path]) {
      _index.remove(entry);
    }
  }

  List<io.FileSystemEntity> _list(String directory, {required bool recursive}) {
    if (!_isDirectory(directory)) {
      throw _missing('Cannot list directory', directory);
    }
    final paths =
        (recursive ? _descendants(directory) : _children(directory)).toList()
          ..sort();
    return [
      for (final path in paths)
        if (_isDirectory(path))
          _BlobDirectory(this, path)
        else
          _BlobFile(this, path),
    ];
  }
}

/// What files and folders share.
abstract class _BlobEntity implements FileSystemEntity {
  _BlobEntity(this.fileSystem, this.path);

  @override
  final BlobFileSystem fileSystem;

  @override
  final String path;

  @override
  String get basename => fileSystem.path.basename(path);

  @override
  String get dirname => fileSystem.path.dirname(path);

  @override
  Directory get parent => _BlobDirectory(fileSystem, dirname);

  @override
  Uri get uri => Uri(scheme: 'file', path: path);

  @override
  bool get isAbsolute => true;

  @override
  Future<bool> exists() async => existsSync();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not supported in the browser',
  );

  @override
  String toString() => "${runtimeType.toString().substring(1)}: '$path'";
}

final class _BlobFile extends _BlobEntity implements File {
  _BlobFile(super.fileSystem, super.path);

  @override
  File get absolute => this;

  @override
  bool existsSync() => fileSystem._isFile(path);

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) =>
      fileSystem._mutate(() async {
        if (exclusive && existsSync()) {
          throw io.FileSystemException('File exists', path);
        }
        if (recursive) {
          await fileSystem._makeDirectories(dirname, recursive: true);
        }
        if (!existsSync()) await fileSystem._write(path, Uint8List(0));
        return this;
      });

  @override
  Future<Uint8List> readAsBytes() => fileSystem._read(path);

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      encoding.decode(await readAsBytes());

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) {
    final contents = Uint8List.fromList(bytes);
    return fileSystem._mutate(() async {
      if (mode == io.FileMode.read) {
        throw ArgumentError.value(mode, 'mode', 'File is not writable');
      }
      if (mode == io.FileMode.append || mode == io.FileMode.writeOnlyAppend) {
        final before = existsSync() ? await readAsBytes() : Uint8List(0);
        await fileSystem._write(
          path,
          Uint8List.fromList([...before, ...contents]),
        );
      } else {
        await fileSystem._write(path, contents);
      }
      return this;
    });
  }

  @override
  Future<File> writeAsString(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => writeAsBytes(encoding.encode(contents), mode: mode, flush: flush);

  @override
  Future<int> length() async => lengthSync();

  @override
  int lengthSync() {
    final entry = fileSystem._index[path];
    if (entry == null || entry.isDirectory) {
      throw BlobFileSystem._missing('Cannot retrieve length of file', path);
    }
    return entry.size;
  }

  @override
  Future<DateTime> lastModified() async => lastModifiedSync();

  @override
  DateTime lastModifiedSync() {
    final entry = fileSystem._index[path];
    if (entry == null || entry.isDirectory) {
      throw BlobFileSystem._missing('Cannot retrieve modification time', path);
    }
    return entry.modified ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Future<File> rename(String newPath) => fileSystem._mutate(() async {
    if (!existsSync()) {
      throw BlobFileSystem._missing('Cannot rename file', path);
    }
    final target = fileSystem._normal(newPath);
    await fileSystem._move(path, target);
    return _BlobFile(fileSystem, target);
  });

  @override
  Future<File> copy(String newPath) async {
    final target = fileSystem.file(newPath);
    await target.writeAsBytes(await readAsBytes());
    return target;
  }

  @override
  Future<File> delete({bool recursive = false}) => fileSystem._mutate(() async {
    if (!existsSync()) {
      throw BlobFileSystem._missing('Cannot delete file', path);
    }
    await fileSystem._delete(path, recursive: false);
    return this;
  });
}

final class _BlobDirectory extends _BlobEntity implements Directory {
  _BlobDirectory(super.fileSystem, super.path);

  @override
  Directory get absolute => this;

  @override
  bool existsSync() => fileSystem._isDirectory(path);

  @override
  Future<Directory> create({bool recursive = false}) =>
      fileSystem._mutate(() async {
        await fileSystem._makeDirectories(path, recursive: recursive);
        return this;
      });

  @override
  Directory childDirectory(String basename) =>
      _BlobDirectory(fileSystem, fileSystem.path.join(path, basename));

  @override
  File childFile(String basename) =>
      _BlobFile(fileSystem, fileSystem.path.join(path, basename));

  @override
  Future<Directory> rename(String newPath) => fileSystem._mutate(() async {
    if (!existsSync()) {
      throw BlobFileSystem._missing('Cannot rename directory', path);
    }
    final target = fileSystem._normal(newPath);
    await fileSystem._move(path, target);
    return _BlobDirectory(fileSystem, target);
  });

  @override
  Future<Directory> delete({bool recursive = false}) =>
      fileSystem._mutate(() async {
        if (!existsSync()) {
          throw BlobFileSystem._missing('Cannot delete directory', path);
        }
        await fileSystem._delete(path, recursive: recursive);
        return this;
      });

  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) => fileSystem._list(path, recursive: recursive).cast<FileSystemEntity>();

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => Stream.fromIterable(listSync(recursive: recursive));
}
