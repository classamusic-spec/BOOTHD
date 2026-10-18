/// Runs the whole M01 render spike against any [CompositionRenderer]: the
/// same code path on the host (tests), on devices (integration test) and in
/// the dev-only spike screen.
library;

import 'dart:typed_data';

import '../../../../domain/services/composition_renderer.dart';
import '../../../../domain/template/template_document.dart';
import 'render_checks.dart';
import 'render_fixtures.dart';

final class FailureProbe {
  const FailureProbe(this.name, this.expected, this.actual);

  final String name;
  final RenderFailureCode expected;

  /// The failure the renderer reported, or null if it rendered anyway.
  final RenderFailureCode? actual;

  bool get passed => actual == expected;

  @override
  String toString() =>
      '${passed ? 'PASS' : 'FAIL'} $name: expected ${expected.name}, '
      'got ${actual?.name ?? 'a rendered image'}';
}

final class RenderSpikeReport {
  const RenderSpikeReport({
    required this.export,
    required this.workspace,
    required this.exportChecks,
    required this.workspaceChecks,
    required this.flowerBelowChecks,
    required this.haloDark,
    required this.haloLight,
    required this.failureProbes,
    required this.repeatStats,
  });

  final RenderedImage export;
  final RenderedImage workspace;
  final List<PixelCheckResult> exportChecks;
  final List<PixelCheckResult> workspaceChecks;
  final List<PixelCheckResult> flowerBelowChecks;
  final UniformityResult haloDark;
  final UniformityResult haloLight;
  final List<FailureProbe> failureProbes;

  /// Stats for repeated FIX-01 exports (without pixel readback).
  final List<RenderStats> repeatStats;

  bool get exportSizeCorrect =>
      export.widthPx == 1200 && export.heightPx == 1800;

  bool get passed =>
      exportSizeCorrect &&
      [
        ...exportChecks,
        ...workspaceChecks,
        ...flowerBelowChecks,
      ].every((r) => r.passed) &&
      haloDark.passed &&
      haloLight.passed &&
      failureProbes.every((p) => p.passed);

  /// Human-readable lines for logs and the spike screen.
  List<String> summary() => [
    'export ${export.widthPx}x${export.heightPx} '
        '(${exportSizeCorrect ? 'PASS' : 'FAIL'}), PNG ${export.png.length} bytes',
    ...exportChecks.map((r) => 'export: $r'),
    ...workspaceChecks.map((r) => 'workspace: $r'),
    ...flowerBelowChecks.map((r) => 'flower below slots: $r'),
    'FIX-04 white on white: $haloDark',
    'FIX-04 black on black: $haloLight',
    ...failureProbes.map((p) => 'failure: $p'),
    for (final (i, s) in repeatStats.indexed)
      'repeat ${i + 1}: total ${s.total.inMilliseconds} ms '
          '(decode ${s.decode.inMilliseconds}, paint ${s.paint.inMilliseconds}, '
          'raster ${s.rasterize.inMilliseconds}, encode ${s.encode.inMilliseconds}) '
          'rss ${_mb(s.residentBytesAfter)} max ${_mb(s.maxResidentBytes)}',
  ];

  static String _mb(int? bytes) => bytes == null
      ? 'n/a'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Future<RenderSpikeReport> runRenderSpike(
  CompositionRenderer renderer, {
  int repeats = 5,
}) async {
  final assets = fix01Assets();

  final export = await renderer.renderExport(
    fix01(),
    slotAssets: fix01SlotAssets,
    assets: assets,
    includePixels: true,
  );
  final workspace = await renderer.renderWorkspace(
    fix01(),
    slotAssets: fix01SlotAssets,
    assets: assets,
    includePixels: true,
  );
  final flowerBelow = await renderer.renderExport(
    fix01(flowerBelowSlots: true),
    slotAssets: fix01SlotAssets,
    assets: assets,
    includePixels: true,
  );

  Future<UniformityResult> halo({required bool whiteOnWhite}) async {
    final fixture = fix04Halo(whiteOnWhite: whiteOnWhite);
    final image = await renderer.renderExport(
      fixture.document,
      slotAssets: const {},
      assets: fixture.assets,
      includePixels: true,
    );
    return uniformity(image.rgba!, fixture.expected);
  }

  Future<FailureProbe> probe(
    String name,
    RenderFailureCode expected,
    TemplateDocument document,
    Map<String, Uint8List> probeAssets,
  ) async {
    try {
      await renderer.renderExport(
        document,
        slotAssets: fix01SlotAssets,
        assets: probeAssets,
      );
      return FailureProbe(name, expected, null);
    } on RenderFailure catch (failure) {
      return FailureProbe(name, expected, failure.code);
    }
  }

  final flowerPng = assets[FixtureAssets.flower]!;
  final failureProbes = [
    await probe(
      'missing decoration asset',
      RenderFailureCode.missingAsset,
      fix01(),
      {...assets}..remove(FixtureAssets.flower),
    ),
    await probe(
      'corrupt decoration bytes',
      RenderFailureCode.assetDecodeFailed,
      fix01(),
      {...assets, FixtureAssets.flower: Uint8List.fromList(List.filled(64, 7))},
    ),
    await probe(
      'truncated decoration PNG',
      RenderFailureCode.assetDecodeFailed,
      fix01(),
      {
        ...assets,
        FixtureAssets.flower: Uint8List.sublistView(
          flowerPng,
          0,
          flowerPng.length ~/ 2,
        ),
      },
    ),
    await probe(
      'duplicate layer ids',
      RenderFailureCode.invalidDocument,
      TemplateDocument(
        id: 'broken',
        page: fix01().page,
        backgroundArgb: fix01().backgroundArgb,
        layers: [fix01().layers.first, fix01().layers.first],
      ),
      assets,
    ),
  ];

  final repeatStats = <RenderStats>[];
  for (var i = 0; i < repeats; i++) {
    final image = await renderer.renderExport(
      fix01(),
      slotAssets: fix01SlotAssets,
      assets: assets,
    );
    repeatStats.add(image.stats);
  }

  return RenderSpikeReport(
    export: export,
    workspace: workspace,
    exportChecks: evaluateChecks(fix01ExportChecks(), export.rgba!, 1200),
    workspaceChecks: evaluateChecks(
      fix01WorkspaceChecks(),
      workspace.rgba!,
      workspace.widthPx,
    ),
    flowerBelowChecks: evaluateChecks(
      fix01FlowerBelowChecks(),
      flowerBelow.rgba!,
      1200,
    ),
    haloDark: await halo(whiteOnWhite: true),
    haloLight: await halo(whiteOnWhite: false),
    failureProbes: failureProbes,
    repeatStats: repeatStats,
  );
}
