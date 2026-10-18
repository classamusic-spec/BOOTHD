// Compares renders made on devices (saved by test_driver/integration_test.dart
// under build/device_renders/) with the host goldens, using the provisional
// cross-platform tolerance (AC-0407, ADR-0007). Skipped when there are no
// device results.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_checks.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_lab_runner.dart';

import 'support/pixels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final results = Directory('build/device_renders');
  final runs = results.existsSync()
      ? (results.listSync().whereType<Directory>().toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <Directory>[];

  test(
    'device renders match the host goldens within tolerance',
    () async {
      for (final run in runs) {
        for (final name in labGoldens.values) {
          final device = File('${run.path}/$name');
          expect(device.existsSync(), isTrue, reason: '${run.path}: $name');
          final actual = await decodeRgba(device.readAsBytesSync());
          final golden = await decodeRgba(
            File('test_assets/expected_renders/$name').readAsBytesSync(),
          );
          expect(
            (actual.width, actual.height),
            (golden.width, golden.height),
            reason: '${run.path}: $name',
          );
          final diff = compareRgba(
            actual.rgba,
            golden.rgba,
            threshold: GoldenTolerance.threshold,
          );
          // Recorded as device evidence.
          // ignore: avoid_print
          print('${run.path}/$name: $diff');
          expect(GoldenTolerance.accepts(diff), isTrue, reason: '$diff');
        }
      }
    },
    skip: runs.isEmpty
        ? 'no device results; see docs/device_tests/M04_DEVICE_PROCEDURE.md'
        : false,
  );
}
