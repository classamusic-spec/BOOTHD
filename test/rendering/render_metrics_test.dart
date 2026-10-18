// Host render benchmarks (AC-0409; TEST_AND_DEVICE_PLAN: 4x6 render time
// p50/p95 with representative layers, image memory, no drift over 100
// sessions). Host numbers say nothing about tablets, which run the same
// render lab through integration_test/render_lab_test.dart; these are a
// regression baseline. Writes build/m04/host_render_benchmark.json.
//
// The memory assertion is deliberately coarse: process RSS includes the
// test runner and the allocator's caches, but a leaked decode or page
// buffer per render (8 MB or more) would add hundreds of MB over 100
// renders.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/composition/scene_preparation.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/template/document_scene.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/fixture_images.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/memory_render_source.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

double _mb(int? bytes) => (bytes ?? 0) / (1024 * 1024);

int _percentile(List<int> sorted, double p) =>
    sorted[((sorted.length - 1) * p).round()];

Map<String, Object> _summarise(List<RenderStats> runs) {
  Map<String, int> spread(Duration Function(RenderStats) pick) {
    final ms = runs.map((s) => pick(s).inMicroseconds ~/ 1000).toList()..sort();
    return {
      'min': ms.first,
      'p50': _percentile(ms, 0.5),
      'p95': _percentile(ms, 0.95),
      'max': ms.last,
    };
  }

  return {
    'runs': runs.length,
    'total_ms': spread((s) => s.total),
    'decode_ms': spread((s) => s.decode),
    'paint_ms': spread((s) => s.paint),
    'rasterize_ms': spread((s) => s.rasterize),
    'encode_ms': spread((s) => s.encode),
    'max_rss_mb': _mb(runs.last.maxResidentBytes).toStringAsFixed(1),
  };
}

/// A 12 MP camera original as a q92 JPEG: stripes, so decoding and
/// resampling do real work.
Uint8List _cameraJpeg(int width, int height, {required bool vertical}) {
  final image = stripes(
    width: width,
    height: height,
    stripePx: 120,
    vertical: vertical,
    even: FixtureColours.red,
    odd: FixtureColours.white,
  );
  return encodeJpeg(image.pixels, width: width, height: height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render latency and memory on the host', () async {
    final renderer = DartUiCompositionRenderer();
    final results = <String, Object>{
      'host': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'processors': Platform.numberOfProcessors,
    };
    const jpeg = OutputProfile();
    const png = OutputProfile(format: OutputFormat.png);

    // FIX-01 as specified: two slots, a translucent overlay across both and
    // a rotated image, photos 1600x1200 and 1200x1600 PNG.
    final fixture = fix01();
    Future<RenderStats> export(TemplateRender render, OutputProfile output) =>
        renderer.renderExport(render, output: output).then((a) => a.stats);
    await export(fixture.render, jpeg); // warm-up
    results['fix01_jpeg_export_1200x1800'] = _summarise([
      for (var i = 0; i < 20; i++) await export(fixture.render, jpeg),
    ]);
    results['fix01_png_export_1200x1800'] = _summarise([
      for (var i = 0; i < 10; i++) await export(fixture.render, png),
    ]);

    // The same template with 12 MP camera originals, as the booth will
    // render it.
    final camera = TemplateRender(
      document: fixture.document,
      photos: fixture.selections,
      source: MemoryRenderSource(
        assets: fixture.assets,
        photos: {
          'photo-a': _cameraJpeg(4032, 3024, vertical: true),
          'photo-b': _cameraJpeg(3024, 4032, vertical: false),
        },
      ),
    );
    final scene = (await compileRender(camera)).scene;
    results['fix01_12mp_decode_scale'] = {
      for (final id in ['photo-a', 'photo-b'])
        id: scene.drawScale(PhotoImageRef(id)).toStringAsFixed(3),
    };
    await export(camera, jpeg); // warm-up
    results['fix01_12mp_jpeg_export_1200x1800'] = _summarise([
      for (var i = 0; i < 20; i++) await export(camera, jpeg),
    ]);
    results['fix01_12mp_preview_300x450'] = _summarise([
      for (var i = 0; i < 10; i++)
        (await renderer.renderPreview(
          camera,
          maxWidthPx: 300,
          maxHeightPx: 450,
        )).stats,
    ]);

    // 100 sessions' worth of exports: resident memory must not climb.
    final rssBefore = ProcessInfo.currentRss;
    final drift = <int>[];
    for (var i = 0; i < 100; i++) {
      await export(camera, jpeg);
      if (i % 10 == 9) drift.add(ProcessInfo.currentRss - rssBefore);
    }
    results['repeat_100_12mp_exports_rss_delta_mb'] = [
      for (final delta in drift) _mb(delta).toStringAsFixed(1),
    ];

    final json = const JsonEncoder.withIndent('  ').convert(results);
    File('build/m04/host_render_benchmark.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(json);
    // ignore: avoid_print
    print(json);

    expect(drift.last, lessThan(128 * 1024 * 1024), reason: '$drift');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
