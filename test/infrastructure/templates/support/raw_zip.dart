// Builds ZIP archives field by field, including the malformed and hostile
// ones a strict reader must refuse.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:porcelain_photo_booth/infrastructure/codecs/crc32.dart';

final class RawEntry {
  RawEntry(
    this.name,
    List<int> data, {
    this.method = 0,
    this.flags = 0x0800,
    this.crc,
    this.size,
    this.madeBy = 20,
    this.externalAttributes = 0,
    this.localName,
    this.offset,
    this.writeLocal = true,
  }) : data = Uint8List.fromList(data);

  final String name;
  final Uint8List data;
  final int method;
  final int flags;

  /// Overrides for the recorded CRC and uncompressed size.
  final int? crc;
  final int? size;
  final int madeBy;
  final int externalAttributes;

  /// A different name in the local header.
  final String? localName;

  /// Where the central directory says the local header is.
  final int? offset;

  /// Whether to write a local header and data at all.
  final bool writeLocal;

  Uint8List get stored => method == 8
      ? Uint8List.fromList(ZLibEncoder(raw: true, level: 9).convert(data))
      : data;

  /// This entry's local header and data, as they would sit in an archive.
  Uint8List local() {
    final nameBytes = utf8.encode(localName ?? name);
    final body = stored;
    final header = ByteData(30)
      ..setUint32(0, 0x04034b50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, flags, Endian.little)
      ..setUint16(8, method, Endian.little)
      ..setUint32(14, crc ?? Crc32.of(data), Endian.little)
      ..setUint32(18, body.length, Endian.little)
      ..setUint32(22, size ?? data.length, Endian.little)
      ..setUint16(26, nameBytes.length, Endian.little);
    return (BytesBuilder()
          ..add(header.buffer.asUint8List())
          ..add(nameBytes)
          ..add(body))
        .takeBytes();
  }
}

Uint8List rawZip(
  List<RawEntry> entries, {
  int disk = 0,
  bool zip64Locator = false,
  List<int> trailing = const [],
  int? entryCountOverride,
}) {
  final out = BytesBuilder();
  final central = BytesBuilder();
  for (final entry in entries) {
    final offset = out.length;
    if (entry.writeLocal) out.add(entry.local());
    final nameBytes = utf8.encode(entry.name);
    final header = ByteData(46)
      ..setUint32(0, 0x02014b50, Endian.little)
      ..setUint16(4, entry.madeBy, Endian.little)
      ..setUint16(6, 20, Endian.little)
      ..setUint16(8, entry.flags, Endian.little)
      ..setUint16(10, entry.method, Endian.little)
      ..setUint32(16, entry.crc ?? Crc32.of(entry.data), Endian.little)
      ..setUint32(20, entry.stored.length, Endian.little)
      ..setUint32(24, entry.size ?? entry.data.length, Endian.little)
      ..setUint16(28, nameBytes.length, Endian.little)
      ..setUint32(38, entry.externalAttributes, Endian.little)
      ..setUint32(42, entry.offset ?? offset, Endian.little);
    central
      ..add(header.buffer.asUint8List())
      ..add(nameBytes);
  }
  final directory = central.takeBytes();
  final directoryOffset = out.length;
  out.add(directory);
  if (zip64Locator) {
    out.add(
      (ByteData(
        20,
      )..setUint32(0, 0x07064b50, Endian.little)).buffer.asUint8List(),
    );
  }
  final count = entryCountOverride ?? entries.length;
  final eocd = ByteData(22)
    ..setUint32(0, 0x06054b50, Endian.little)
    ..setUint16(4, disk, Endian.little)
    ..setUint16(8, count, Endian.little)
    ..setUint16(10, count, Endian.little)
    ..setUint32(12, directory.length, Endian.little)
    ..setUint32(16, directoryOffset, Endian.little);
  out
    ..add(eocd.buffer.asUint8List())
    ..add(trailing);
  return out.takeBytes();
}
