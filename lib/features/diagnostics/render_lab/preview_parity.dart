/// Preview-to-export parity (AC-0407), shared by the host tests and the
/// device run: a fixture's preview against its full-resolution export
/// box-filtered down to the preview's size.
library;

import 'dart:typed_data';

import '../../../core/composition/scene_preparation.dart';
import '../../../domain/services/composition_renderer.dart';
import '../../../domain/template/document_scene.dart';
import 'fixture_images.dart';
import 'render_checks.dart';
import 'render_fixtures.dart';
import 'render_lab_runner.dart';

typedef InkBounds = ({int left, int top, int right, int bottom, int bands});

/// One text layer's ink in the preview and in the reduced export.
final class TextParityResult {
  const TextParityResult(this.layerId, this.preview, this.export);

  final String layerId;
  final InkBounds? preview;
  final InkBounds? export;

  bool get passed {
    final (a, b) = (preview, export);
    if (a == null || b == null) return a == b;
    return a.bands == b.bands &&
        (a.left - b.left).abs() <= TextParity.maxEdgeShift &&
        (a.top - b.top).abs() <= TextParity.maxEdgeShift &&
        (a.right - b.right).abs() <= TextParity.maxEdgeShift &&
        (a.bottom - b.bottom).abs() <= TextParity.maxEdgeShift;
  }

  @override
  String toString() =>
      '${passed ? 'PASS' : 'FAIL'} text "$layerId": preview ${_ink(preview)}, '
      'export ${_ink(export)}';

  static String _ink(InkBounds? ink) => ink == null
      ? 'no ink'
      : '${ink.left},${ink.top}..${ink.right},${ink.bottom} '
            '(${ink.bands} line(s))';
}

final class PreviewParity {
  const PreviewParity({
    required this.fixture,
    required this.factor,
    required this.preview,
    required this.reference,
    required this.diff,
    required this.text,
    required this.checks,
  });

  final RenderFixture fixture;

  /// Page pixels per preview pixel.
  final int factor;
  final RenderArtifact preview;

  /// The export, box-filtered to the preview's size.
  final Uint8List reference;

  /// Preview against [reference] outside text.
  final ImageDiff diff;
  final List<TextParityResult> text;

  /// The fixture's export checks at the preview's scale, where the reduced
  /// export is uniform around the point.
  final List<PixelCheckResult> checks;

  bool get passed =>
      preview.widthPx == fixture.widthPx ~/ factor &&
      preview.heightPx == fixture.heightPx ~/ factor &&
      PreviewTolerance.accepts(diff) &&
      text.every((result) => result.passed) &&
      checks.every((check) => check.passed);

  List<String> summary() => [
    '${fixture.id} preview 1/$factor '
        '(${preview.widthPx}x${preview.heightPx}): '
        '${PreviewTolerance.accepts(diff) ? 'PASS' : 'FAIL'} $diff',
    ...text.map((result) => '  $result'),
    ...checks.map((check) => '  scaled $check'),
  ];
}

/// Renders [fixture]'s preview at 1/[factor] size and compares it with its
/// [export] (rendered here when not given; PNG with pixels). With
/// [shiftPreview], the preview is moved by that many pixels right and down
/// first: a negative control that must fail.
Future<PreviewParity> previewParity(
  CompositionRenderer renderer,
  RenderFixture fixture, {
  RenderArtifact? export,
  int factor = 4,
  int shiftPreview = 0,
}) async {
  export ??= await exportPixels(renderer, fixture);
  final preview = await renderer.renderPreview(
    fixture.render,
    maxWidthPx: fixture.widthPx ~/ factor,
    maxHeightPx: fixture.heightPx ~/ factor,
    includePixels: true,
  );
  final width = preview.widthPx;
  final height = preview.heightPx;
  final reference = downscale(
    export.rgba!,
    export.widthPx,
    export.heightPx,
    factor,
  );
  final pixels = shiftPreview == 0
      ? preview.rgba!
      : _shifted(preview.rgba!, width, height, shiftPreview);

  // Text, and a margin for glyphs that overhang their frame, is compared
  // by geometry instead of pixels.
  final scene = (await compileRender(fixture.render)).scene;
  final mask = Uint8List(width * height)..fillRange(0, width * height, 1);
  final text = <TextParityResult>[];
  for (final node in scene.nodes.whereType<TextNode>()) {
    final bounds = node.placement.bounds;
    final margin = 2 * factor;
    final left = ((bounds.left - margin) / factor).floor().clamp(0, width);
    final top = ((bounds.top - margin) / factor).floor().clamp(0, height);
    final right = ((bounds.right + margin) / factor).ceil().clamp(0, width);
    final bottom = ((bounds.bottom + margin) / factor).ceil().clamp(0, height);
    for (var y = top; y < bottom; y++) {
      mask.fillRange(y * width + left, y * width + right, 0);
    }
    InkBounds? ink(Uint8List rgba) =>
        inkIn(rgba, width, left: left, top: top, right: right, bottom: bottom);
    text.add(TextParityResult(node.layerId, ink(pixels), ink(reference)));
  }

  final checks = <PixelCheckResult>[];
  for (final check in fixture.exportChecks) {
    final x = check.x ~/ factor;
    final y = check.y ~/ factor;
    if (!_uniformAround(reference, width, height, x, y, check)) continue;
    final scaled = PixelCheck(
      check.name,
      x,
      y,
      check.expected,
      tolerance: check.tolerance,
    );
    checks.addAll(evaluateChecks([scaled], pixels, width));
  }

  return PreviewParity(
    fixture: fixture,
    factor: factor,
    preview: preview,
    reference: reference,
    diff: compareRgba(
      pixels,
      reference,
      threshold: PreviewTolerance.threshold,
      mask: mask,
    ),
    text: text,
    checks: checks,
  );
}

/// Whether the reduced export already shows [check]'s colour on the pixel
/// at ([x], [y]) and its eight neighbours, so the preview must too.
bool _uniformAround(
  Uint8List rgba,
  int width,
  int height,
  int x,
  int y,
  PixelCheck check,
) {
  for (var dy = -1; dy <= 1; dy++) {
    for (var dx = -1; dx <= 1; dx++) {
      final px = x + dx;
      final py = y + dy;
      if (px < 0 || py < 0 || px >= width || py >= height) return false;
      final actual = pixelAt(rgba, width, px, py);
      if (_delta(actual, check.expected) > check.tolerance) return false;
    }
  }
  return true;
}

int _delta(Rgb a, Rgb b) => [
  (a.r - b.r).abs(),
  (a.g - b.g).abs(),
  (a.b - b.b).abs(),
].reduce((m, d) => d > m ? d : m);

Uint8List _shifted(Uint8List rgba, int width, int height, int by) {
  final out = Uint8List(rgba.length);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final sx = (x - by).clamp(0, width - 1);
      final sy = (y - by).clamp(0, height - 1);
      final from = (sy * width + sx) * 4;
      out.setRange((y * width + x) * 4, (y * width + x) * 4 + 4, rgba, from);
    }
  }
  return out;
}
