import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// PBKDF2-HMAC-SHA256 with the browser's Web Crypto (ADR-0018): the same
/// standard derivation as the tablets' Dart one, at native speed and off
/// the page's thread, so the stored verifiers are interchangeable.
Future<Uint8List> derivePbkdf2Sha256({
  required List<int> password,
  required Uint8List salt,
  required int iterations,
  required int length,
}) async {
  final subtle = web.window.crypto.subtle;
  final key = await subtle
      .importKey(
        'raw',
        Uint8List.fromList(password).toJS,
        'PBKDF2'.toJS,
        false,
        ['deriveBits'.toJS].toJS,
      )
      .toDart;
  final params = JSObject()
    ..setProperty('name'.toJS, 'PBKDF2'.toJS)
    ..setProperty('hash'.toJS, 'SHA-256'.toJS)
    ..setProperty('salt'.toJS, salt.toJS)
    ..setProperty('iterations'.toJS, iterations.toJS);
  final bits = await subtle.deriveBits(params, key, length * 8).toDart;
  return bits.toDart.asUint8List();
}
