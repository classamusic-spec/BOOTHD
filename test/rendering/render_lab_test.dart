// AC-0402 (order, visibility, opacity), AC-0403 (overlay crosses slots
// unclipped), AC-0404 (photo clip, mask, crop), AC-0405 (page sizes),
// AC-0407 (preview parity), FIX-05 text and FIX-06 render failures: the
// whole render lab on the host renderer, as devices run it.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_lab_runner.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RenderLabReport report;

  setUpAll(() async {
    report = await runRenderLab(DartUiCompositionRenderer(), repeats: 2);
    // Recorded in CI logs as evidence.
    // ignore: avoid_print
    print(report.summary().join('\n'));
  });

  test('every fixture renders at its exact page size (AC-0405)', () {
    expect(
      {
        for (final result in report.fixtures)
          result.fixture.id: (result.export.widthPx, result.export.heightPx),
      },
      {
        'FIX-01': (1200, 1800),
        'FIX-01b': (1200, 1800),
        'FIX-02': (600, 1800),
        'FIX-03': (1800, 1200),
        'CLIP': (1200, 1200),
        'GRADIENT': (600, 600),
        'FIX-05': (1200, 1800),
      },
    );
  });

  for (final id in [
    'FIX-01',
    'FIX-01b',
    'FIX-02',
    'FIX-03',
    'CLIP',
    'GRADIENT',
  ]) {
    test('$id: every pixel check passes', () {
      final result = report.fixture(id);
      final failed = result.checks.where((check) => !check.passed).toList();
      expect(failed, isEmpty, reason: failed.join('\n'));
      expect(result.checks, isNotEmpty);
    });
  }

  test('the editor workspace shows artwork beyond the page edge', () {
    expect((report.workspace.widthPx, report.workspace.heightPx), (1440, 2160));
    final failed = report.workspaceChecks.where((c) => !c.passed).toList();
    expect(failed, isEmpty, reason: failed.join('\n'));
  });

  test('FIX-04: no halo around scaled, rotated transparent edges', () {
    expect(report.haloDark.passed, isTrue, reason: '${report.haloDark}');
    expect(report.haloLight.passed, isTrue, reason: '${report.haloLight}');
  });

  test('FIX-05: every text block stays in its frame, aligned', () {
    final failed = report.textProbes.where((p) => !p.passed).toList();
    expect(failed, isEmpty, reason: failed.join('\n'));
    expect(report.textProbes, hasLength(4));
  });

  test('every fixture\'s preview matches its export (AC-0407)', () {
    expect(report.parity, hasLength(report.fixtures.length));
    for (final result in report.parity) {
      expect(result.passed, isTrue, reason: result.summary().join('\n'));
    }
  });

  test('FIX-06: unusable inputs fail with their own code, never a picture', () {
    final failed = report.failureProbes.where((p) => !p.passed).toList();
    expect(failed, isEmpty, reason: failed.join('\n'));
    expect(report.failureProbes, hasLength(7));
  });

  test('repeated exports report their timings', () {
    expect(report.repeatStats, hasLength(2));
    expect(report.passed, isTrue);
  });
}
