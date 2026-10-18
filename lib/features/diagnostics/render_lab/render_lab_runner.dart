/// Runs the renderer's fixture suite against any [CompositionRenderer]: the
/// same code on the host (tests), on devices (integration test) and in the
/// dev-only render lab screen.
library;

import 'dart:typed_data';

import '../../../domain/models/booth_event.dart';
import '../../../domain/services/composition_renderer.dart';
import '../../../domain/template/template_document.dart';
import '../../../domain/template/template_layers.dart';
import 'memory_render_source.dart';
import 'preview_parity.dart';
import 'render_checks.dart';
import 'render_fixtures.dart';

/// Every fixture the lab exports: the pixel-checked ones and FIX-05 text.
List<RenderFixture> labFixtures() => [...checkedFixtures(), fix05()];

/// The committed golden for each fixture export, and for the FIX-01 editor
/// workspace (key [workspaceGoldenKey]), under
/// `test_assets/expected_renders/`. Device runs save their renders under
/// the same names for comparison.
const labGoldens = {
  'FIX-01': 'fix01_export_1200x1800.png',
  'FIX-02': 'fix02_export_600x1800.png',
  'FIX-03': 'fix03_export_1800x1200.png',
  'FIX-05': 'fix05_export_1200x1800.png',
  'CLIP': 'clip_export_1200x1200.png',
  workspaceGoldenKey: 'fix01_workspace_1440x2160.png',
};

const workspaceGoldenKey = 'FIX-01 workspace';

/// One FIX-05 text block measured in the export: inside its frame, aligned
/// as the document says, on the expected number of lines.
final class TextProbeResult {
  const TextProbeResult(this.probe, this.ink);

  final TextProbe probe;
  final InkBounds? ink;

  bool get passed {
    final ink = this.ink;
    if (ink == null) return false;
    final frame = probe.frame;
    final inside =
        ink.left >= frame.left.round() &&
        ink.right <= frame.right.round() &&
        ink.top >= frame.top.round() &&
        ink.bottom <= frame.bottom.round();
    final leftGap = ink.left - frame.left;
    final rightGap = frame.right - ink.right;
    final aligned = switch (probe.align) {
      TextAlignment.left => leftGap < 10,
      TextAlignment.right => rightGap < 10,
      // Middle alignment centres the line box; the ink sits near it.
      TextAlignment.center =>
        (leftGap - rightGap).abs() <= 4 &&
            ((ink.top + ink.bottom) / 2 - frame.centerY).abs() < 30,
    };
    return inside && aligned && ink.bands == probe.lines;
  }

  @override
  String toString() {
    final ink = this.ink;
    final frame = probe.frame;
    return '${passed ? 'PASS' : 'FAIL'} text "${probe.layerId}" '
        '(${probe.align.name}, ${probe.lines} line(s)) in frame '
        '${frame.left.round()},${frame.top.round()}..'
        '${frame.right.round()},${frame.bottom.round()}: '
        '${ink == null ? 'no ink' : 'ink ${ink.left},${ink.top}..'
                  '${ink.right},${ink.bottom} on ${ink.bands} line(s)'}';
  }
}

/// Measures [probe] in a FIX-05 export, looking well beyond its frame so
/// escaping ink is found.
TextProbeResult evaluateTextProbe(TextProbe probe, Uint8List rgba, int width) {
  final height = rgba.length ~/ (4 * width);
  return TextProbeResult(
    probe,
    inkIn(
      rgba,
      width,
      left: 0,
      top: (probe.frame.top - 40).round().clamp(0, height),
      right: width,
      bottom: (probe.frame.bottom + 40).round().clamp(0, height),
    ),
  );
}

final class FailureProbe {
  const FailureProbe(this.name, this.expected, this.actual);

  final String name;
  final RenderFailureCode expected;

  /// The failure the renderer reported, or null if it rendered anyway.
  final RenderFailureCode? actual;

  bool get passed => actual == expected;

  @override
  String toString() =>
      '${passed ? 'PASS' : 'FAIL'} $name: expected ${expected.diagnostic}, '
      'got ${actual?.diagnostic ?? 'a rendered image'}';
}

/// One fixture's export and its checks.
final class FixtureResult {
  const FixtureResult(this.fixture, this.export, this.checks);

  final RenderFixture fixture;
  final RenderArtifact export;
  final List<PixelCheckResult> checks;

  bool get sizeCorrect =>
      export.widthPx == fixture.widthPx && export.heightPx == fixture.heightPx;

  bool get passed => sizeCorrect && checks.every((check) => check.passed);
}

final class RenderLabReport {
  const RenderLabReport({
    required this.fixtures,
    required this.workspace,
    required this.workspaceChecks,
    required this.haloDark,
    required this.haloLight,
    required this.textProbes,
    required this.parity,
    required this.failureProbes,
    required this.repeatStats,
  });

  final List<FixtureResult> fixtures;

  /// FIX-01 as an editor workspace with a 10% margin.
  final RenderArtifact workspace;
  final List<PixelCheckResult> workspaceChecks;
  final UniformityResult haloDark;
  final UniformityResult haloLight;

  /// FIX-05's text blocks in its export.
  final List<TextProbeResult> textProbes;

  /// Each fixture's quarter-size preview against its export (AC-0407).
  final List<PreviewParity> parity;
  final List<FailureProbe> failureProbes;

  /// Repeated FIX-01 JPEG exports, as the booth will make them.
  final List<RenderStats> repeatStats;

  FixtureResult fixture(String id) =>
      fixtures.firstWhere((result) => result.fixture.id == id);

  bool get passed =>
      fixtures.every((result) => result.passed) &&
      workspaceChecks.every((check) => check.passed) &&
      haloDark.passed &&
      haloLight.passed &&
      textProbes.every((probe) => probe.passed) &&
      parity.every((result) => result.passed) &&
      failureProbes.every((probe) => probe.passed);

  /// Human-readable lines for logs and the render lab screen.
  List<String> summary() => [
    for (final result in fixtures) ...[
      '${result.fixture.id} ${result.fixture.title}: '
          '${result.export.widthPx}x${result.export.heightPx} '
          '(${result.sizeCorrect ? 'PASS' : 'FAIL'})',
      ...result.checks.map((check) => '  $check'),
    ],
    ...workspaceChecks.map((check) => 'workspace: $check'),
    'FIX-04 white on white: $haloDark',
    'FIX-04 black on black: $haloLight',
    ...textProbes.map((probe) => 'FIX-05 $probe'),
    for (final result in parity) ...result.summary(),
    ...failureProbes.map((probe) => 'failure: $probe'),
    for (final (i, stats) in repeatStats.indexed)
      'repeat ${i + 1}: total ${stats.total.inMilliseconds} ms '
          '(decode ${stats.decode.inMilliseconds}, '
          'paint ${stats.paint.inMilliseconds}, '
          'raster ${stats.rasterize.inMilliseconds}, '
          'encode ${stats.encode.inMilliseconds}) '
          'rss ${_mb(stats.residentBytesAfter)} '
          'max ${_mb(stats.maxResidentBytes)}',
  ];

  static String _mb(int? bytes) => bytes == null
      ? 'n/a'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// PNG export with pixels, the form every check reads.
Future<RenderArtifact> exportPixels(
  CompositionRenderer renderer,
  RenderFixture fixture,
) => renderer.renderExport(
  fixture.render,
  output: const OutputProfile(format: OutputFormat.png),
  includePixels: true,
);

Future<RenderLabReport> runRenderLab(
  CompositionRenderer renderer, {
  int repeats = 5,
}) async {
  final results = <FixtureResult>[];
  final parity = <PreviewParity>[];
  for (final fixture in labFixtures()) {
    final export = await exportPixels(renderer, fixture);
    results.add(
      FixtureResult(
        fixture,
        export,
        evaluateChecks(fixture.exportChecks, export.rgba!, export.widthPx),
      ),
    );
    parity.add(await previewParity(renderer, fixture, export: export));
  }
  final fix05Export = results
      .firstWhere((result) => result.fixture.id == 'FIX-05')
      .export;

  final fix01Fixture = fix01();
  final workspace = await renderer.renderPreview(
    fix01Fixture.render,
    maxWidthPx: 1440,
    maxHeightPx: 2160,
    workspaceMargin: 0.1,
    includePixels: true,
  );

  Future<UniformityResult> halo({required bool whiteOnWhite}) async {
    final probe = fix04Halo(whiteOnWhite: whiteOnWhite);
    final image = await exportPixels(renderer, probe.fixture);
    return uniformity(image.rgba!, probe.expected);
  }

  Future<FailureProbe> probe(
    String name,
    RenderFailureCode expected,
    TemplateRender render,
  ) async {
    try {
      await renderer.renderExport(render);
      return FailureProbe(name, expected, null);
    } on RenderFailure catch (failure) {
      return FailureProbe(name, expected, failure.code);
    }
  }

  TemplateRender withSource({
    Map<String, Uint8List>? assets,
    Map<String, Uint8List>? photos,
    TemplateDocument? document,
  }) => TemplateRender(
    document: document ?? fix01Fixture.document,
    photos: fix01Fixture.selections,
    source: MemoryRenderSource(
      assets: assets ?? fix01Fixture.assets,
      photos: photos ?? fix01Fixture.photos,
    ),
  );

  final flowerId = fix01Fixture.assets.keys.firstWhere(
    (id) => fix01Fixture.document.assets[id]!.name == 'flower.png',
  );
  final flowerPng = fix01Fixture.assets[flowerId]!;
  final otherImage = fix02().photos['red']!;
  final failureProbes = [
    await probe(
      'missing decoration asset',
      RenderFailureCode.missingAsset,
      withSource(assets: {...fix01Fixture.assets}..remove(flowerId)),
    ),
    await probe(
      'decoration bytes are not an image',
      RenderFailureCode.unreadableImage,
      withSource(
        assets: {
          ...fix01Fixture.assets,
          flowerId: Uint8List.fromList(List.filled(64, 7)),
        },
      ),
    ),
    await probe(
      'truncated decoration PNG',
      RenderFailureCode.unreadableImage,
      withSource(
        assets: {
          ...fix01Fixture.assets,
          flowerId: Uint8List.sublistView(flowerPng, 0, flowerPng.length ~/ 2),
        },
      ),
    ),
    await probe(
      'decoration replaced by a different image',
      RenderFailureCode.imageMismatch,
      withSource(assets: {...fix01Fixture.assets, flowerId: otherImage}),
    ),
    await probe(
      'missing photo',
      RenderFailureCode.missingPhoto,
      withSource(photos: {...fix01Fixture.photos}..remove('photo-b')),
    ),
    await probe(
      'photo bytes are not an image',
      RenderFailureCode.unreadableImage,
      withSource(
        photos: {
          ...fix01Fixture.photos,
          'photo-a': Uint8List.fromList(List.filled(64, 1)),
        },
      ),
    ),
    await probe(
      'duplicate layer ids',
      RenderFailureCode.invalidDocument,
      withSource(
        document: TemplateDocument(
          page: fix01Fixture.document.page,
          assets: fix01Fixture.document.assets,
          layers: [
            ...fix01Fixture.document.layers,
            fix01Fixture.document.layers.last,
          ],
        ),
      ),
    ),
  ];

  final repeatStats = <RenderStats>[];
  for (var i = 0; i < repeats; i++) {
    final image = await renderer.renderExport(fix01Fixture.render);
    repeatStats.add(image.stats);
  }

  return RenderLabReport(
    fixtures: results,
    workspace: workspace,
    workspaceChecks: evaluateChecks(
      fix01WorkspaceChecks,
      workspace.rgba!,
      workspace.widthPx,
    ),
    haloDark: await halo(whiteOnWhite: true),
    haloLight: await halo(whiteOnWhite: false),
    textProbes: [
      for (final probe in fix05Probes)
        evaluateTextProbe(probe, fix05Export.rgba!, fix05Export.widthPx),
    ],
    parity: parity,
    failureProbes: failureProbes,
    repeatStats: repeatStats,
  );
}
