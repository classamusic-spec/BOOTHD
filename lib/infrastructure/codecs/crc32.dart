import 'dart:typed_data';

/// CRC-32 (IEEE 802.3, as used by PNG and ZIP).
abstract final class Crc32 {
  static final Uint32List _table = () {
    final table = Uint32List(256);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
      table[n] = c;
    }
    return table;
  }();

  /// The CRC of [bytes] from [start] to [end], continuing from [crc] (the
  /// value returned by an earlier call; 0 to begin).
  static int of(List<int> bytes, {int start = 0, int? end, int crc = 0}) {
    var c = crc ^ 0xFFFFFFFF;
    final stop = end ?? bytes.length;
    for (var i = start; i < stop; i++) {
      c = _table[(c ^ bytes[i]) & 0xFF] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
  }
}
