// M01 render spike on a physical iPad or Android tablet (AC-0104, AC-0105).
// Run in profile mode for representative timings:
//
//   flutter drive --profile -d <device-id> \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/render_spike_test.dart
//
// The driver saves this device's renders and metrics under build/m01_device/;
// compare them with the host golden using
//   flutter test test/rendering/device_render_comparison_test.dart
// Procedure: docs/device_tests/M01_DEVICE_PROCEDURE.md.
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_spike_runner.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FIX-01 renders and passes every check on this device', (
    tester,
  ) async {
    final report = (await tester.runAsync(
      () => runRenderSpike(const DartUiCompositionRenderer(), repeats: 10),
    ))!;
    final totals = [
      for (final stats in report.repeatStats) stats.total.inMilliseconds,
    ]..sort();

    binding.reportData = {
      'platform': defaultTargetPlatform.name,
      'os': Platform.operatingSystemVersion,
      'buildMode': kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
      'passed': report.passed,
      'repeatTotalMsSorted': totals,
      'maxResidentBytes': report.repeatStats.last.maxResidentBytes,
      'summary': report.summary(),
      'exportPngBase64': base64Encode(report.export.png),
      'workspacePngBase64': base64Encode(report.workspace.png),
    };
    expect(report.passed, isTrue, reason: report.summary().join('\n'));
  });
}
