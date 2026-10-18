// The render lab on a physical iPad or Android tablet (AC-0402..AC-0407,
// AC-0409). Run in profile mode for representative timings:
//
//   flutter drive --profile -d <device-id> \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/render_lab_test.dart
//
// The driver saves this device's renders and metrics under
// build/device_renders/; compare them with the host goldens using
//   flutter test test/rendering/device_render_comparison_test.dart
// Procedure: docs/device_tests/M04_DEVICE_PROCEDURE.md.
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_lab_runner.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the render lab passes every check on this device', (
    tester,
  ) async {
    final report = (await tester.runAsync(
      () => runRenderLab(DartUiCompositionRenderer(), repeats: 10),
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
      // Saved by the driver under the golden's own file name.
      'renders': {
        for (final result in report.fixtures)
          ?labGoldens[result.fixture.id]: base64Encode(result.export.bytes),
        labGoldens[workspaceGoldenKey]!: base64Encode(report.workspace.bytes),
      },
    };
    expect(report.passed, isTrue, reason: report.summary().join('\n'));
  });
}
