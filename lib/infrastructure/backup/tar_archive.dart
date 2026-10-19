/// A small, strict POSIX ustar writer and reader for booth backups (M10,
/// AC-1006, ADR-0016). Streams file contents in chunks, so a backup of
/// thousands of photos never sits in memory. The reader accepts only what
/// the writer makes: regular files and directories under one root, ustar
/// headers with valid checksums, safe relative names, sizes under limits;
/// links, devices, pax and GNU extensions are refused.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

const _block = 512;
const _chunk = 64 * 1024;

enum TarProblem {
  /// Not a tar archive the booth wrote, or one cut short or corrupted.
  invalid,

  /// An entry that could reach outside the restore folder: absolute or
  /// parent paths, links, devices, duplicates, names outside the root.
  unsafe,

  /// Over the entry count, entry size or total size limits.
  tooLarge,
}

final class TarException implements Exception {
  const TarException(this.problem, this.detail);

  final TarProblem problem;

  /// What was wrong, naming at most the entry; never contents.
  final String detail;

  @override
  String toString() => 'TarException(${problem.name}: $detail)';
}

final class TarLimits {
  const TarLimits({
    required this.root,
    required this.maxEntries,
    required this.maxEntryBytes,
    required this.maxTotalBytes,
  });

  /// Every entry's first path component.
  final String root;
  final int maxEntries;
  final int maxEntryBytes;
  final int maxTotalBytes;
}

/// Writes a ustar archive to [sink] entry by entry, hashing as it goes.
final class TarWriter {
  TarWriter(this._sink);

  final IOSink _sink;
  final _names = <String>{};
  var _bytes = 0;

  /// Bytes written so far.
  int get length => _bytes;

  /// Adds a directory entry.
  void addDirectory(String name, {required DateTime modified}) {
    final path = name.endsWith('/') ? name : '$name/';
    _header(path, 0, modified, directory: true);
  }

  /// Adds [bytes] as [name]; returns their SHA-256.
  String addBytes(String name, Uint8List bytes, {required DateTime modified}) {
    _header(name, bytes.length, modified);
    _sink.add(bytes);
    _bytes += bytes.length;
    _pad(bytes.length);
    return crypto.sha256.convert(bytes).toString();
  }

  /// Streams [source] in as [name]; returns its SHA-256. Throws
  /// [FileSystemException] if the file cannot be read or changes size.
  Future<String> addFile(
    String name,
    File source, {
    required DateTime modified,
  }) async {
    final size = await source.length();
    _header(name, size, modified);
    final output = _DigestSink();
    final digest = crypto.sha256.startChunkedConversion(output);
    var copied = 0;
    final file = await source.open();
    try {
      final buffer = Uint8List(_chunk);
      while (copied < size) {
        final want = size - copied < _chunk ? size - copied : _chunk;
        final read = await file.readInto(buffer, 0, want);
        if (read <= 0) {
          throw FileSystemException('file shrank while copying', name);
        }
        final piece = Uint8List.fromList(
          Uint8List.sublistView(buffer, 0, read),
        );
        _sink.add(piece);
        digest.add(piece);
        copied += read;
      }
    } finally {
      await file.close();
    }
    digest.close();
    _bytes += size;
    _pad(size);
    return output.value.toString();
  }

  /// Ends the archive (two empty blocks) and flushes.
  Future<void> close() async {
    _sink.add(Uint8List(_block * 2));
    _bytes += _block * 2;
    await _sink.flush();
  }

  void _pad(int size) {
    final rest = size % _block;
    if (rest == 0) return;
    _sink.add(Uint8List(_block - rest));
    _bytes += _block - rest;
  }

  void _header(
    String name,
    int size,
    DateTime modified, {
    bool directory = false,
  }) {
    if (!_names.add(name)) {
      throw ArgumentError.value(name, 'name', 'already in the archive');
    }
    final header = Uint8List(_block);
    final (prefix, base) = _split(name);
    _put(header, 0, 100, utf8.encode(base));
    _octal(header, 100, 8, directory ? 0x1ed : 0x1a4); // 0755 / 0644
    _octal(header, 108, 8, 0);
    _octal(header, 116, 8, 0);
    _octal(header, 124, 12, size);
    _octal(header, 136, 12, modified.toUtc().millisecondsSinceEpoch ~/ 1000);
    header.fillRange(148, 156, 0x20); // checksum: spaces while summing
    header[156] = directory ? 0x35 : 0x30; // '5' or '0'
    _put(header, 257, 6, ascii.encode('ustar\u0000'));
    _put(header, 263, 2, ascii.encode('00'));
    _put(header, 345, 155, utf8.encode(prefix));
    final sum = header.fold<int>(0, (total, byte) => total + byte);
    _octal(header, 148, 7, sum);
    header[155] = 0x20;
    _sink.add(header);
    _bytes += _block;
  }

  /// Splits a path of up to 255 bytes into ustar's prefix (155) and name
  /// (100) at a slash.
  static (String, String) _split(String name) {
    final bytes = utf8.encode(name);
    if (bytes.length <= 100) return ('', name);
    for (
      var i = name.lastIndexOf('/');
      i > 0;
      i = name.lastIndexOf('/', i - 1)
    ) {
      final prefix = name.substring(0, i);
      final base = name.substring(i + 1);
      if (utf8.encode(prefix).length <= 155 &&
          utf8.encode(base).length <= 100) {
        return (prefix, base);
      }
    }
    throw ArgumentError.value(name, 'name', 'too long for ustar');
  }

  static void _put(Uint8List header, int at, int width, List<int> value) {
    if (value.length > width) throw ArgumentError('field too long');
    header.setRange(at, at + value.length, value);
  }

  static void _octal(Uint8List header, int at, int width, int value) {
    final digits = value.toRadixString(8).padLeft(width - 1, '0');
    if (digits.length > width - 1) throw ArgumentError('value too large');
    _put(header, at, width, ascii.encode('$digits\u0000'));
  }
}

/// One entry as read: its name, size and, for files, its SHA-256.
typedef TarEntryInfo = ({
  String name,
  int size,
  bool directory,
  String? sha256,
});

/// Reads every entry of the archive at [file], checking structure, names
/// and limits, and returns each entry's name, size and SHA-256. When
/// [extractTo] is given, files are written below it (directories created),
/// each flushed. The contents of entries named in [capture] (at most 8 MB
/// each) are put in [captured]. Throws [TarException]; a
/// [FileSystemException] when the destination cannot be written.
Future<List<TarEntryInfo>> readTar(
  File file, {
  required TarLimits limits,
  Directory? extractTo,
  Set<String> capture = const {},
  Map<String, List<int>>? captured,
}) async {
  final entries = <TarEntryInfo>[];
  final seen = <String>{};
  var total = 0;
  final input = await file.open();
  try {
    final length = await input.length();
    var offset = 0;
    var zeros = 0;
    final header = Uint8List(_block);
    while (true) {
      if (offset + _block > length) {
        throw const TarException(TarProblem.invalid, 'cut short');
      }
      await input.setPosition(offset);
      if (await input.readInto(header) != _block) {
        throw const TarException(TarProblem.invalid, 'cut short');
      }
      offset += _block;
      if (header.every((byte) => byte == 0)) {
        zeros++;
        if (zeros == 2) break;
        continue;
      }
      if (zeros > 0) throw const TarException(TarProblem.invalid, 'stray end');
      final info = _parseHeader(header, limits);
      if (!seen.add(info.name)) {
        throw TarException(TarProblem.unsafe, '${info.name}: duplicate');
      }
      if (seen.length > limits.maxEntries) {
        throw const TarException(TarProblem.tooLarge, 'too many entries');
      }
      total += info.size;
      if (total > limits.maxTotalBytes) {
        throw const TarException(TarProblem.tooLarge, 'too large in total');
      }
      final padded = (info.size + _block - 1) ~/ _block * _block;
      if (offset + padded > length) {
        throw TarException(TarProblem.invalid, '${info.name}: cut short');
      }
      if (info.directory) {
        if (extractTo != null) {
          await Directory(_target(extractTo, info.name))
              .create(recursive: true);
        }
        entries.add((name: info.name, size: 0, directory: true, sha256: null));
        continue;
      }
      final output = _DigestSink();
      final digest = crypto.sha256.startChunkedConversion(output);
      final keep = capture.contains(info.name) && info.size <= 8 * 1024 * 1024
          ? BytesBuilder(copy: false)
          : null;
      RandomAccessFile? out;
      if (extractTo != null) {
        final target = File(_target(extractTo, info.name));
        await target.parent.create(recursive: true);
        out = await target.open(mode: FileMode.writeOnly);
      }
      try {
        final buffer = Uint8List(_chunk);
        var left = info.size;
        await input.setPosition(offset);
        while (left > 0) {
          final want = left < _chunk ? left : _chunk;
          final read = await input.readInto(buffer, 0, want);
          if (read <= 0) {
            throw TarException(TarProblem.invalid, '${info.name}: cut short');
          }
          final piece = Uint8List.sublistView(buffer, 0, read);
          digest.add(piece);
          keep?.add(Uint8List.fromList(piece));
          await out?.writeFrom(piece);
          left -= read;
        }
        await out?.flush();
      } finally {
        await out?.close();
      }
      digest.close();
      if (keep != null) captured?[info.name] = keep.takeBytes();
      offset += padded;
      entries.add((
        name: info.name,
        size: info.size,
        directory: false,
        sha256: output.value.toString(),
      ));
    }
  } finally {
    await input.close();
  }
  return entries;
}

({String name, int size, bool directory}) _parseHeader(
  Uint8List header,
  TarLimits limits,
) {
  final stored = _readOctal(header, 148, 8);
  var sum = 0;
  for (var i = 0; i < _block; i++) {
    sum += i >= 148 && i < 156 ? 0x20 : header[i];
  }
  if (stored != sum) {
    throw const TarException(TarProblem.invalid, 'header checksum');
  }
  if (ascii.decode(header.sublist(257, 262), allowInvalid: true) != 'ustar') {
    throw const TarException(TarProblem.invalid, 'not ustar');
  }
  final base = _readString(header, 0, 100);
  final prefix = _readString(header, 345, 155);
  final name = prefix.isEmpty ? base : '$prefix/$base';
  final type = header[156];
  final directory = type == 0x35;
  if (!directory && type != 0x30 && type != 0) {
    throw TarException(TarProblem.unsafe, '$name: not a regular file');
  }
  final path = directory && name.endsWith('/')
      ? name.substring(0, name.length - 1)
      : name;
  final parts = path.split('/');
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains(r'\') ||
      path.contains('\u0000') ||
      parts.any((part) => part.isEmpty || part == '.' || part == '..') ||
      parts.first != limits.root) {
    throw TarException(TarProblem.unsafe, 'unsafe name');
  }
  final size = _readOctal(header, 124, 12);
  if (size < 0 || (directory && size != 0)) {
    throw TarException(TarProblem.invalid, '$path: size');
  }
  if (size > limits.maxEntryBytes) {
    throw TarException(TarProblem.tooLarge, '$path: too large');
  }
  return (name: path, size: size, directory: directory);
}

String _target(Directory root, String name) {
  // Names were checked: relative, no parent parts, under the root.
  return '${root.path}/$name';
}

String _readString(Uint8List header, int at, int width) {
  var end = at;
  while (end < at + width && header[end] != 0) {
    end++;
  }
  try {
    return utf8.decode(header.sublist(at, end));
  } on FormatException {
    throw const TarException(TarProblem.invalid, 'name encoding');
  }
}

int _readOctal(Uint8List header, int at, int width) {
  final text = ascii
      .decode(header.sublist(at, at + width), allowInvalid: true)
      .replaceAll('\u0000', '')
      .trim();
  if (text.isEmpty || !RegExp(r'^[0-7]+$').hasMatch(text)) {
    throw const TarException(TarProblem.invalid, 'number field');
  }
  return int.parse(text, radix: 8);
}

final class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? _value;

  crypto.Digest get value => _value!;

  @override
  void add(crypto.Digest data) => _value = data;

  @override
  void close() {}
}
