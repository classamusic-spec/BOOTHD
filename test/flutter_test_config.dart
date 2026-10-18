import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file under `test/`.
///
/// Loads the app's bundled fonts, so goldens and the text-contrast
/// guideline see the real Inter, Cormorant Garamond and Material Symbols
/// glyphs instead of the test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  await testMain();
}

/// The icon styles the app does not use are skipped to keep start-up fast.
const _unusedFamilies = {'MaterialSymbolsOutlined', 'MaterialSymbolsSharp'};

Future<void> loadAppFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<Object?>;
  for (final entry in manifest.cast<Map<String, Object?>>()) {
    final family = entry['family']! as String;
    if (_unusedFamilies.any(family.endsWith)) continue;
    final loader = FontLoader(family);
    for (final font
        in (entry['fonts']! as List<Object?>).cast<Map<String, Object?>>()) {
      loader.addFont(rootBundle.load(font['asset']! as String));
    }
    await loader.load();
  }
}
