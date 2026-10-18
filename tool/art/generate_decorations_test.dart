// Writes the bundled template decorations to assets/decorations/. Not part
// of `flutter test` (it lives outside test/); run it by hand after changing
// tool/art/decorations.dart:
//
//     flutter test tool/art/generate_decorations_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'decorations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('write assets/decorations/*.png', () async {
    final directory = Directory('assets/decorations')
      ..createSync(recursive: true);
    for (final art in decorationArt) {
      File('${directory.path}/${art.file}')
          .writeAsBytesSync(await renderDecoration(art));
    }
  });
}
