// Compares FIX-01 exports rendered on devices (saved by
// test_driver/integration_test.dart under build/m01_device/) with the host
// golden, using the provisional cross-platform tolerance (AC-0104).
// Skipped when there are no device results.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_checks.dart';

Future<Uint8List> _rgba(File file) async {
  final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
  final frame = await codec.getNextFrame();
  final bytes = await frame.image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  frame.image.dispose();
  codec.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final results = Directory('build/m01_device');
  final runs = results.existsSync()
      ? (results
            .listSync()
            .whereType<Directory>()
            .where((d) => File('${d.path}/fix01_export.png').existsSync())
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <Directory>[];

  test(
    'device FIX-01 exports match the host golden within tolerance',
    () async {
      final golden = await _rgba(
        File('test_assets/expected_renders/fix01_export_1200x1800.png'),
      );
      for (final run in runs) {
        final device = await _rgba(File('${run.path}/fix01_export.png'));
        final diff = compareRgba(
          device,
          golden,
          threshold: GoldenTolerance.threshold,
        );
        // ignore: avoid_print
        print('${run.path}: $diff');
        expect(GoldenTolerance.accepts(diff), isTrue, reason: '$diff');
      }
    },
    skip: runs.isEmpty
        ? 'no device results; see docs/device_tests/M01_DEVICE_PROCEDURE.md'
        : false,
  );
}
