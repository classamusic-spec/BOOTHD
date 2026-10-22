import 'dart:isolate';
import 'dart:typed_data';

import 'pbkdf2.dart';

/// PBKDF2-HMAC-SHA256 on a short-lived isolate, never the UI isolate.
Future<Uint8List> derivePbkdf2Sha256({
  required List<int> password,
  required Uint8List salt,
  required int iterations,
  required int length,
}) => Isolate.run(
  () => pbkdf2HmacSha256(
    password: password,
    salt: salt,
    iterations: iterations,
    length: length,
  ),
);
