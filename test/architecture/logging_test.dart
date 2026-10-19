// AC-1007: SafeLog is the only way the app writes to the device log. No
// other file in lib/ prints, dumps or uses dart:developer's log, so
// nothing can bypass sanitization.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _safeLog = 'lib/core/diagnostics/safe_log.dart';

final _forbidden = <String, RegExp>{
  'print': RegExp(r'(?<![\w.$])print\('),
  'debugPrint': RegExp(r'\bdebugPrint\b'),
  'dart:developer': RegExp('''import ['"]dart:developer['"]'''),
  'stdout/stderr': RegExp(r'\b(?:stdout|stderr)\.'),
  'debugDump': RegExp(r'\bdebugDump\w*\('),
};

/// [source] without comments, so documentation may mention these names.
String _code(String source) => source
    .split('\n')
    .map((line) => line.replaceFirst(RegExp(r'^\s*//.*'), ''))
    .join('\n');

void main() {
  test('only SafeLog writes to the device log', () {
    final offences = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll(r'\', '/');
      if (path == _safeLog || path.endsWith('.g.dart')) continue;
      final code = _code(file.readAsStringSync());
      for (final MapEntry(key: name, value: pattern) in _forbidden.entries) {
        if (pattern.hasMatch(code)) offences.add('$path uses $name');
      }
    }
    expect(offences, isEmpty);
  });

  test('the check finds what it looks for', () {
    for (final (source, name) in [
      ("  print('x');", 'print'),
      ('  debugPrint(x);', 'debugPrint'),
      ("import 'dart:developer';", 'dart:developer'),
      ('  stderr.writeln(x);', 'stdout/stderr'),
      ('  debugDumpApp();', 'debugDump'),
    ]) {
      expect(_forbidden[name]!.hasMatch(_code(source)), isTrue, reason: name);
    }
    expect(_forbidden['print']!.hasMatch(_code('  // print(x)')), isFalse);
    expect(_forbidden['print']!.hasMatch('  blueprint(x);'), isFalse);
  });
}
