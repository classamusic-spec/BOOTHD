// ignore_for_file: avoid_print -- the output is read by tool/web/smoke.mjs.

// Checks of the web test build's browser adapters that need a real browser
// (ADR-0018). Compiled to JavaScript and run in Chromium by
// tool/web/smoke.mjs, which reads the printed lines:
//   CHECK PASS <name>   or   CHECK FAIL <name>: <detail>
import 'dart:convert';
import 'dart:typed_data';

import 'package:porcelain_photo_booth/infrastructure/background/background_work.dart';
import 'package:porcelain_photo_booth/infrastructure/security/pbkdf2.dart';
import 'package:porcelain_photo_booth/infrastructure/security/pbkdf2_derive.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Future<void> _check(String name, Future<String?> Function() body) async {
  try {
    final problem = await body();
    print(problem == null ? 'CHECK PASS $name' : 'CHECK FAIL $name: $problem');
  } on Object catch (error) {
    print('CHECK FAIL $name: $error');
  }
}

Future<void> main() async {
  await _check('web crypto pbkdf2 matches the tablets', () async {
    final salt = Uint8List.fromList(List.generate(16, (i) => i * 11 % 256));
    for (final (secret, rounds) in [('123456', 1), ('246813', 1000)]) {
      final password = utf8.encode(secret);
      final browser = await derivePbkdf2Sha256(
        password: password,
        salt: salt,
        iterations: rounds,
        length: 32,
      );
      final dart = pbkdf2HmacSha256(
        password: password,
        salt: salt,
        iterations: rounds,
        length: 32,
      );
      if (_hex(browser) != _hex(dart)) return '$rounds rounds differ';
    }
    return null;
  });
  await _check('web crypto pbkdf2 standard vector', () async {
    final derived = await derivePbkdf2Sha256(
      password: utf8.encode('password'),
      salt: Uint8List.fromList(utf8.encode('salt')),
      iterations: 4096,
      length: 32,
    );
    const expected =
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a';
    return _hex(derived) == expected ? null : _hex(derived);
  });
  await _check('background work returns its result', () async {
    final answer = await runInBackground(() => 6 * 7);
    return answer == 42 ? null : '$answer';
  });
  print('CHECKS DONE');
}
