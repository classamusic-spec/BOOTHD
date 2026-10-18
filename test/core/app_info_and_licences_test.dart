// AC-0211: bundled fonts carry their licences into the app's licence page,
// and every shipped asset is listed with its source, licence and hash.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/bundled_licences.dart';
import 'package:porcelain_photo_booth/core/platform/app_info.dart';

void main() {
  test('AppInfo matches the pubspec version', () {
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
    expect(version, '${AppInfo.version}+${AppInfo.buildNumber}');
  });

  test('bundled font licences are registered with their full text', () async {
    registerBundledLicences(rootBundle);
    final entries = await LicenseRegistry.licenses.toList();
    for (final name in bundledFontLicences.keys) {
      final entry = entries.singleWhere((e) => e.packages.contains(name));
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
    }
  });

  test('every bundled asset is in the provenance record with its hash', () {
    final record = File('docs/ASSET_PROVENANCE.md').readAsStringSync();
    final rows = <String, String>{
      for (final match in RegExp(
        r'^\| `(assets/[^`]+)` \| `([0-9a-f]{64})` \|',
        multiLine: true,
      ).allMatches(record))
        match.group(1)!: match.group(2)!,
    };
    final files =
        Directory('assets')
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => f.path.replaceAll(r'\', '/'))
            .toList()
          ..sort();
    expect(files, isNotEmpty);
    expect(
      rows.keys.toList()..sort(),
      files,
      reason:
          'docs/ASSET_PROVENANCE.md must list exactly the files in '
          'assets/',
    );
    for (final path in files) {
      expect(
        sha256.convert(File(path).readAsBytesSync()).toString(),
        rows[path],
        reason: '$path changed; update its provenance row',
      );
    }
  });
}
