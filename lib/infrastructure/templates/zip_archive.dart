/// A deliberately small, strict ZIP reader and writer for template packages
/// (A-06, AC-0408, ADR-0010). Only what packages need: stored and deflated
/// entries, read fully into memory under hard limits, never extracted to a
/// path.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../codecs/crc32.dart';

enum ZipProblem {
  /// Not a ZIP file, or one whose structure does not hold together
  /// (including a CRC or size that does not match the data).
  invalid,

  /// An entry that could reach outside the package when extracted: an
  /// absolute or parent path, a link, a duplicate name.
  unsafe,

  /// Over the archive, entry count, entry size, total size or compression
  /// ratio limits.
  tooLarge,

  /// Encrypted, ZIP64, split, or compressed with something other than
  /// deflate.
  unsupported,
}

final class ZipException implements Exception {
  const ZipException(this.problem, this.detail);

  final ZipProblem problem;

  /// What was wrong, naming at most the entry; never file contents.
  final String detail;

  @override
  String toString() => 'ZipException(${problem.name}: $detail)';
}

final class ZipLimits {
  const ZipLimits({
    required this.maxArchiveBytes,
    required this.maxEntries,
    required this.maxEntryBytes,
    required this.maxTotalBytes,
    required this.maxRatio,
  });

  final int maxArchiveBytes;
  final int maxEntries;

  /// Largest uncompressed entry.
  final int maxEntryBytes;

  /// Largest sum of uncompressed entries.
  final int maxTotalBytes;

  /// Largest uncompressed-to-compressed ratio for a deflated entry over
  /// 64 KB: real images and fonts barely compress; bombs compress a
  /// thousandfold.
  final int maxRatio;
}

/// One entry's name and contents.
typedef ZipEntry = ({String name, Uint8List bytes});

/// Reads every file entry of [archive] that [wanted] accepts (all, by
/// default) after checking the whole archive: structure, names, sizes and
/// limits. Directory entries are checked and skipped. Also returns every
/// entry name, so callers can refuse unexpected ones. Throws
/// [ZipException].
({List<String> names, Map<String, Uint8List> files}) readZip(
  Uint8List archive, {
  required ZipLimits limits,
  bool Function(String name)? wanted,
}) {
  if (archive.length > limits.maxArchiveBytes) {
    throw const ZipException(ZipProblem.tooLarge, 'archive too large');
  }
  final data = ByteData.sublistView(archive);
  final end = _endOfCentralDirectory(archive, data);
  final entries = _centralDirectory(archive, data, end, limits);

  final files = <String, Uint8List>{};
  final ranges = <(int, int)>[];
  for (final entry in entries) {
    final dataStart = _localHeader(archive, data, entry, end.directoryOffset);
    final dataEnd = dataStart + entry.compressedSize;
    ranges.add((entry.headerOffset, dataEnd));
    if (entry.isDirectory || !(wanted?.call(entry.name) ?? true)) continue;
    final compressed = Uint8List.sublistView(archive, dataStart, dataEnd);
    final bytes = entry.method == 0
        ? Uint8List.fromList(compressed)
        : _inflate(compressed, entry.size, entry.name);
    if (bytes.length != entry.size) {
      throw ZipException(ZipProblem.invalid, '${entry.name}: wrong size');
    }
    if (Crc32.of(bytes) != entry.crc32) {
      throw ZipException(ZipProblem.invalid, '${entry.name}: CRC mismatch');
    }
    files[entry.name] = bytes;
  }
  // Entries may not share bytes: overlapping entries are how
  // non-recursive zip bombs multiply one compressed block.
  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  for (var i = 1; i < ranges.length; i++) {
    if (ranges[i].$1 < ranges[i - 1].$2) {
      throw const ZipException(ZipProblem.unsafe, 'entries overlap');
    }
  }
  return (names: [for (final entry in entries) entry.name], files: files);
}

/// A ZIP of [entries] in the given order, stored uncompressed with a fixed
/// timestamp, so the same entries always give the same bytes.
Uint8List writeZip(List<ZipEntry> entries) {
  final out = BytesBuilder(copy: false);
  final central = BytesBuilder(copy: false);
  var offset = 0;
  for (final (:name, :bytes) in entries) {
    final nameBytes = utf8.encode(name);
    final crc = Crc32.of(bytes);
    final local = ByteData(30)
      ..setUint32(0, _localSignature, Endian.little)
      ..setUint16(4, 20, Endian.little) // version needed: 2.0
      ..setUint16(6, _utf8Flag, Endian.little)
      ..setUint16(8, 0, Endian.little) // stored
      ..setUint16(10, 0, Endian.little) // 00:00:00
      ..setUint16(12, _dosDate1980, Endian.little)
      ..setUint32(14, crc, Endian.little)
      ..setUint32(18, bytes.length, Endian.little)
      ..setUint32(22, bytes.length, Endian.little)
      ..setUint16(26, nameBytes.length, Endian.little)
      ..setUint16(28, 0, Endian.little);
    out
      ..add(local.buffer.asUint8List())
      ..add(nameBytes)
      ..add(bytes);
    final header = ByteData(46)
      ..setUint32(0, _centralSignature, Endian.little)
      ..setUint16(4, 20, Endian.little) // made by: MS-DOS, 2.0
      ..setUint16(6, 20, Endian.little)
      ..setUint16(8, _utf8Flag, Endian.little)
      ..setUint16(10, 0, Endian.little)
      ..setUint16(12, 0, Endian.little)
      ..setUint16(14, _dosDate1980, Endian.little)
      ..setUint32(16, crc, Endian.little)
      ..setUint32(20, bytes.length, Endian.little)
      ..setUint32(24, bytes.length, Endian.little)
      ..setUint16(28, nameBytes.length, Endian.little)
      ..setUint32(42, offset, Endian.little);
    central
      ..add(header.buffer.asUint8List())
      ..add(nameBytes);
    offset += 30 + nameBytes.length + bytes.length;
  }
  final directory = central.takeBytes();
  final eocd = ByteData(22)
    ..setUint32(0, _endSignature, Endian.little)
    ..setUint16(8, entries.length, Endian.little)
    ..setUint16(10, entries.length, Endian.little)
    ..setUint32(12, directory.length, Endian.little)
    ..setUint32(16, offset, Endian.little);
  return (out
        ..add(directory)
        ..add(eocd.buffer.asUint8List()))
      .takeBytes();
}

const _localSignature = 0x04034b50;
const _centralSignature = 0x02014b50;
const _endSignature = 0x06054b50;
const _zip64LocatorSignature = 0x07064b50;
const _utf8Flag = 0x0800;
const _dosDate1980 = (0 << 9) | (1 << 5) | 1;

final class _End {
  const _End(this.entryCount, this.directoryOffset, this.directorySize);

  final int entryCount;
  final int directoryOffset;
  final int directorySize;
}

final class _Entry {
  const _Entry({
    required this.name,
    required this.nameBytes,
    required this.method,
    required this.flags,
    required this.crc32,
    required this.compressedSize,
    required this.size,
    required this.headerOffset,
  });

  final String name;
  final Uint8List nameBytes;
  final int method;
  final int flags;
  final int crc32;
  final int compressedSize;
  final int size;
  final int headerOffset;

  bool get isDirectory => name.endsWith('/');
}

_End _endOfCentralDirectory(Uint8List archive, ByteData data) {
  const fixed = 22;
  if (archive.length < fixed) {
    throw const ZipException(ZipProblem.invalid, 'not a ZIP file');
  }
  // The record is at the end, after a comment of at most 64 KB. The comment
  // must run exactly to the end: nothing may trail the archive.
  final lowest = math.max(0, archive.length - fixed - 0xFFFF);
  for (var at = archive.length - fixed; at >= lowest; at--) {
    if (data.getUint32(at, Endian.little) != _endSignature) continue;
    final commentLength = data.getUint16(at + 20, Endian.little);
    if (at + fixed + commentLength != archive.length) continue;
    final disk = data.getUint16(at + 4, Endian.little);
    final directoryDisk = data.getUint16(at + 6, Endian.little);
    final onDisk = data.getUint16(at + 8, Endian.little);
    final total = data.getUint16(at + 10, Endian.little);
    final size = data.getUint32(at + 12, Endian.little);
    final offset = data.getUint32(at + 16, Endian.little);
    if (total == 0xFFFF || size == 0xFFFFFFFF || offset == 0xFFFFFFFF) {
      throw const ZipException(ZipProblem.unsupported, 'ZIP64');
    }
    if (at >= 20 &&
        data.getUint32(at - 20, Endian.little) == _zip64LocatorSignature) {
      throw const ZipException(ZipProblem.unsupported, 'ZIP64');
    }
    if (disk != 0 || directoryDisk != 0 || onDisk != total) {
      throw const ZipException(ZipProblem.unsupported, 'split archive');
    }
    if (offset + size != at) {
      throw const ZipException(
        ZipProblem.invalid,
        'central directory out of place',
      );
    }
    return _End(total, offset, size);
  }
  throw const ZipException(ZipProblem.invalid, 'not a ZIP file');
}

List<_Entry> _centralDirectory(
  Uint8List archive,
  ByteData data,
  _End end,
  ZipLimits limits,
) {
  if (end.entryCount > limits.maxEntries) {
    throw const ZipException(ZipProblem.tooLarge, 'too many entries');
  }
  final entries = <_Entry>[];
  final seen = <String>{};
  var total = 0;
  var at = end.directoryOffset;
  final stop = end.directoryOffset + end.directorySize;
  for (var i = 0; i < end.entryCount; i++) {
    if (at + 46 > stop ||
        data.getUint32(at, Endian.little) != _centralSignature) {
      throw const ZipException(ZipProblem.invalid, 'damaged central directory');
    }
    final madeBy = data.getUint16(at + 4, Endian.little);
    final flags = data.getUint16(at + 8, Endian.little);
    final method = data.getUint16(at + 10, Endian.little);
    final crc = data.getUint32(at + 16, Endian.little);
    final compressedSize = data.getUint32(at + 20, Endian.little);
    final size = data.getUint32(at + 24, Endian.little);
    final nameLength = data.getUint16(at + 28, Endian.little);
    final extraLength = data.getUint16(at + 30, Endian.little);
    final commentLength = data.getUint16(at + 32, Endian.little);
    final startDisk = data.getUint16(at + 34, Endian.little);
    final externalAttributes = data.getUint32(at + 38, Endian.little);
    final headerOffset = data.getUint32(at + 42, Endian.little);
    final next = at + 46 + nameLength + extraLength + commentLength;
    if (next > stop) {
      throw const ZipException(ZipProblem.invalid, 'damaged central directory');
    }
    final nameBytes = Uint8List.sublistView(
      archive,
      at + 46,
      at + 46 + nameLength,
    );
    final name = _name(nameBytes, utf8Flagged: flags & _utf8Flag != 0);
    // First, so every later message names a safe, printable entry.
    _checkName(name);
    at = next;

    if (flags & 0x0001 != 0 || flags & 0x0040 != 0) {
      throw ZipException(ZipProblem.unsupported, '$name: encrypted');
    }
    if (method != 0 && method != 8) {
      throw ZipException(ZipProblem.unsupported, '$name: compression $method');
    }
    if (compressedSize == 0xFFFFFFFF ||
        size == 0xFFFFFFFF ||
        headerOffset == 0xFFFFFFFF) {
      throw ZipException(ZipProblem.unsupported, '$name: ZIP64');
    }
    if (startDisk != 0) {
      throw ZipException(ZipProblem.unsupported, '$name: split archive');
    }
    // Unix hosts keep the file type in the high bits: refuse links.
    if (madeBy >> 8 == 3 && (externalAttributes >> 16) & 0xF000 == 0xA000) {
      throw ZipException(ZipProblem.unsafe, '$name: symbolic link');
    }
    if (!seen.add(name.toLowerCase())) {
      throw ZipException(ZipProblem.unsafe, '$name: duplicate entry');
    }
    final directory = name.endsWith('/');
    if (directory && (size != 0 || compressedSize != 0)) {
      throw ZipException(ZipProblem.invalid, '$name: directory with data');
    }
    if (method == 0 && compressedSize != size) {
      throw ZipException(ZipProblem.invalid, '$name: wrong size');
    }
    if (size > limits.maxEntryBytes) {
      throw ZipException(ZipProblem.tooLarge, '$name: too large');
    }
    total += size;
    if (total > limits.maxTotalBytes) {
      throw const ZipException(ZipProblem.tooLarge, 'contents too large');
    }
    if (method == 8 &&
        size > 64 * 1024 &&
        size > compressedSize * limits.maxRatio) {
      throw ZipException(ZipProblem.tooLarge, '$name: compression ratio');
    }
    if (headerOffset + 30 > end.directoryOffset) {
      throw ZipException(ZipProblem.invalid, '$name: header out of place');
    }
    entries.add(
      _Entry(
        name: name,
        nameBytes: nameBytes,
        method: method,
        flags: flags,
        crc32: crc,
        compressedSize: compressedSize,
        size: size,
        headerOffset: headerOffset,
      ),
    );
  }
  if (at != stop) {
    throw const ZipException(ZipProblem.invalid, 'damaged central directory');
  }
  return entries;
}

/// Checks [entry]'s local header against the central directory and returns
/// where its data starts.
int _localHeader(Uint8List archive, ByteData data, _Entry entry, int limit) {
  final at = entry.headerOffset;
  if (data.getUint32(at, Endian.little) != _localSignature) {
    throw ZipException(ZipProblem.invalid, '${entry.name}: damaged header');
  }
  final flags = data.getUint16(at + 6, Endian.little);
  final method = data.getUint16(at + 8, Endian.little);
  final nameLength = data.getUint16(at + 26, Endian.little);
  final extraLength = data.getUint16(at + 28, Endian.little);
  if (flags & 0x0001 != 0 || method != entry.method) {
    throw ZipException(ZipProblem.invalid, '${entry.name}: headers disagree');
  }
  if (at + 30 + nameLength > limit) {
    throw ZipException(ZipProblem.invalid, '${entry.name}: damaged header');
  }
  final localName = Uint8List.sublistView(
    archive,
    at + 30,
    at + 30 + nameLength,
  );
  if (!_sameBytes(localName, entry.nameBytes)) {
    throw ZipException(ZipProblem.unsafe, '${entry.name}: names disagree');
  }
  final start = at + 30 + nameLength + extraLength;
  if (start + entry.compressedSize > limit) {
    throw ZipException(ZipProblem.invalid, '${entry.name}: data out of place');
  }
  return start;
}

String _name(Uint8List bytes, {required bool utf8Flagged}) {
  if (!utf8Flagged && bytes.any((b) => b >= 0x80)) {
    // Legacy code page names are ambiguous; packages use UTF-8.
    throw const ZipException(ZipProblem.invalid, 'entry name not UTF-8');
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    throw const ZipException(ZipProblem.invalid, 'entry name not UTF-8');
  }
}

/// Refuses names that could address anything outside the package.
void _checkName(String name) {
  // Detail names the entry only when it is printable and short.
  final shown = name.length <= 120 && !name.contains(RegExp(r'[\x00-\x1F\x7F]'))
      ? name
      : 'an entry';
  if (name.isEmpty || name.length > 255) {
    throw ZipException(ZipProblem.unsafe, '$shown: bad name');
  }
  if (name.startsWith('/') ||
      name.contains(r'\') ||
      name.contains(':') ||
      name.contains(RegExp(r'[\x00-\x1F\x7F]'))) {
    throw ZipException(ZipProblem.unsafe, '$shown: unsafe path');
  }
  final segments = name.endsWith('/')
      ? name.substring(0, name.length - 1).split('/')
      : name.split('/');
  for (final segment in segments) {
    if (segment.isEmpty || segment == '.' || segment == '..') {
      throw ZipException(ZipProblem.unsafe, '$shown: unsafe path');
    }
  }
}

/// Inflates raw deflate [data], stopping as soon as the output passes
/// [expected] bytes.
Uint8List _inflate(Uint8List data, int expected, String name) {
  final sink = _CappedSink(expected, name);
  final input = ZLibDecoder(raw: true).startChunkedConversion(sink);
  try {
    for (var i = 0; i < data.length; i += 64 * 1024) {
      input.add(
        Uint8List.sublistView(data, i, math.min(data.length, i + 64 * 1024)),
      );
    }
    input.close();
  } on ZipException {
    rethrow;
  } on Object {
    throw ZipException(ZipProblem.invalid, '$name: damaged data');
  }
  return sink.takeBytes();
}

final class _CappedSink implements Sink<List<int>> {
  _CappedSink(this.cap, this.name);

  final int cap;
  final String name;
  final _builder = BytesBuilder(copy: false);

  @override
  void add(List<int> chunk) {
    if (_builder.length + chunk.length > cap) {
      throw ZipException(ZipProblem.invalid, '$name: more data than declared');
    }
    _builder.add(chunk);
  }

  @override
  void close() {}

  Uint8List takeBytes() => _builder.takeBytes();
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
