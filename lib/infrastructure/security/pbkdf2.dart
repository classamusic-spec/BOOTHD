import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2 with HMAC-SHA256 (RFC 8018), returning [length] bytes.
///
/// Pure Dart on the `crypto` package; checked against the RFC 7914 test
/// vectors. Slow by design: run it off the UI isolate.
Uint8List pbkdf2HmacSha256({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int length,
}) {
  if (iterations < 1 || length < 1) {
    throw ArgumentError('iterations and length must be positive');
  }
  final hmac = Hmac(sha256, password);
  final output = Uint8List(length);
  var offset = 0;
  for (var block = 1; offset < length; block++) {
    final first = hmac.convert([
      ...salt,
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ]).bytes;
    final accumulated = Uint8List.fromList(first);
    var previous = first;
    for (var i = 1; i < iterations; i++) {
      previous = hmac.convert(previous).bytes;
      for (var j = 0; j < accumulated.length; j++) {
        accumulated[j] ^= previous[j];
      }
    }
    final take = length - offset < accumulated.length
        ? length - offset
        : accumulated.length;
    output.setRange(offset, offset + take, accumulated);
    offset += take;
  }
  return output;
}

/// Compares two byte lists in time that depends only on their lengths.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}
