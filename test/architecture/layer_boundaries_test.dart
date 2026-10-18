import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'layer_rules.dart';

void main() {
  final packageName = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;

  group('lib/ follows the layered architecture', () {
    final files =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    test('lib/ contains Dart sources', () => expect(files, isNotEmpty));

    for (final file in files) {
      final libPath = file.path.replaceAll(r'\', '/').substring('lib/'.length);
      test(libPath, () {
        final violations = [
          if (layerOf(libPath) == null)
            '$libPath is outside the approved lib/ layout',
          for (final uri in directiveUris(file.readAsStringSync()))
            ...violationsFor(
              libPath: libPath,
              importUri: uri,
              packageName: packageName,
            ),
        ];
        expect(violations, isEmpty);
      });
    }
  });

  group('layer rules reject violations', () {
    List<String> check(String libPath, String importUri) => violationsFor(
      libPath: libPath,
      importUri: importUri,
      packageName: 'porcelain_photo_booth',
    );

    test('domain may not import Flutter or plugins', () {
      expect(
        check('domain/a.dart', 'package:flutter/widgets.dart'),
        isNotEmpty,
      );
      expect(check('domain/a.dart', 'package:camera/camera.dart'), isNotEmpty);
    });

    test('domain may not import dart:ui or dart:io', () {
      expect(check('domain/a.dart', 'dart:ui'), isNotEmpty);
      expect(check('domain/a.dart', 'dart:io'), isNotEmpty);
    });

    test('domain may not import outer layers', () {
      expect(check('domain/a.dart', '../core/b.dart'), isNotEmpty);
      expect(
        check('domain/a.dart', 'package:porcelain_photo_booth/app/app.dart'),
        isNotEmpty,
      );
    });

    test('features may not import infrastructure or app', () {
      expect(
        check('features/booth/x.dart', '../../infrastructure/camera/y.dart'),
        isNotEmpty,
      );
      expect(
        check('features/booth/x.dart', '../../app/router.dart'),
        isNotEmpty,
      );
    });

    test('features may not import each other', () {
      expect(
        check('features/booth/x.dart', '../gallery/gallery_screen.dart'),
        isNotEmpty,
      );
    });

    test('features may not import plugins or dart:io', () {
      expect(
        check('features/booth/x.dart', 'package:camera/camera.dart'),
        isNotEmpty,
      );
      expect(check('features/booth/x.dart', 'dart:io'), isNotEmpty);
    });

    test('core and shared may not import features', () {
      expect(check('core/a.dart', '../features/booth/x.dart'), isNotEmpty);
      expect(check('shared/w.dart', '../features/booth/x.dart'), isNotEmpty);
    });

    test('relative imports may not escape lib/', () {
      expect(check('core/a.dart', '../../test/helper.dart'), isNotEmpty);
    });

    test('unknown top-level directories are rejected', () {
      expect(layerOf('misc/a.dart'), isNull);
      expect(layerOf('stray.dart'), isNull);
    });

    test('conditional import alternatives are checked too', () {
      expect(
        directiveUris(
          "import 'a.dart' if (dart.library.io) 'b.dart';\n"
          'export "c.dart" show C;',
        ),
        ['a.dart', 'b.dart', 'c.dart'],
      );
    });

    test('allowed dependencies pass', () {
      expect(check('domain/a.dart', 'dart:async'), isEmpty);
      expect(check('domain/a.dart', 'b.dart'), isEmpty);
      expect(check('features/booth/x.dart', '../../domain/y.dart'), isEmpty);
      expect(
        check('features/booth/x.dart', 'package:go_router/go_router.dart'),
        isEmpty,
      );
      expect(
        check('infrastructure/camera/c.dart', 'package:camera/camera.dart'),
        isEmpty,
      );
      expect(check('infrastructure/camera/c.dart', 'dart:io'), isEmpty);
      expect(
        check('app/providers.dart', '../infrastructure/camera/c.dart'),
        isEmpty,
      );
    });
  });
}
