// Host render timings and memory for AC-0105. Informative only: host numbers
// say nothing about tablet performance, which is measured on devices with
// integration_test/render_spike_test.dart. Writes build/m01/.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';

double _mb(int? bytes) => (bytes ?? 0) / (1024 * 1024);

Map<String, Object> _summarise(List<RenderStats> runs) {
  List<int> ms(Duration Function(RenderStats) pick) =>
      runs.map((s) => pick(s).inMicroseconds ~/ 1000).toList()..sort();
  Map<String, int> spread(List<int> values) => {
    'min': values.first,
    'median': values[values.length ~/ 2],
    'max': values.last,
  };
  return {
    'runs': runs.length,
    'total_ms': spread(ms((s) => s.total)),
    'decode_ms': spread(ms((s) => s.decode)),
    'paint_ms': spread(ms((s) => s.paint)),
    'rasterize_ms': spread(ms((s) => s.rasterize)),
    'encode_ms': spread(ms((s) => s.encode)),
    'rss_after_mb': _mb(runs.last.residentBytesAfter).toStringAsFixed(1),
    'max_rss_mb': _mb(runs.last.maxResidentBytes).toStringAsFixed(1),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('measure FIX-01 render cost and memory on the host', () async {
    final results = <String, Object>{
      'host': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'processors': Platform.numberOfProcessors,
    };

    // 1. FIX-01 as specified (photos 1600x1200 and 1200x1600).
    final assets = fix01Assets();
    Future<RenderStats> exportOnce(
      Map<String, dynamic> inputs, {
      bool bounded = true,
    }) async =>
        (await DartUiCompositionRenderer(boundDecodeSize: bounded).renderExport(
          fix01(),
          slotAssets: fix01SlotAssets,
          assets: inputs.cast(),
        )).stats;

    await exportOnce(assets); // warm-up
    results['fix01_export_1200x1800'] = _summarise([
      for (var i = 0; i < 10; i++) await exportOnce(assets),
    ]);

    // 2. Memory drift across repeated renders, before any large inputs.
    final rssBefore = ProcessInfo.currentRss;
    for (var i = 0; i < 30; i++) {
      await exportOnce(assets);
    }
    results['repeat_30_exports_rss_delta_mb'] = _mb(
      ProcessInfo.currentRss - rssBefore,
    ).toStringAsFixed(1);

    // 3. 12 MP originals (4032x3024), decoded bounded vs full size. maxRss is
    // a high-water mark, so the bounded run goes first.
    final large = fix01Assets(
      photoA: const PixelSize(4032, 3024),
      photoB: const PixelSize(3024, 4032),
    );
    final beforeLarge = ProcessInfo.maxRss;
    final bounded = [for (var i = 0; i < 3; i++) await exportOnce(large)];
    final afterBounded = ProcessInfo.maxRss;
    final full = [
      for (var i = 0; i < 3; i++) await exportOnce(large, bounded: false),
    ];
    final afterFull = ProcessInfo.maxRss;
    results['fix01_12mp_bounded_decode'] = {
      ..._summarise(bounded),
      'max_rss_increase_mb': _mb(afterBounded - beforeLarge).toStringAsFixed(1),
    };
    results['fix01_12mp_full_decode'] = {
      ..._summarise(full),
      'max_rss_increase_mb': _mb(afterFull - afterBounded).toStringAsFixed(1),
    };

    final json = const JsonEncoder.withIndent('  ').convert(results);
    File('build/m01/host_render_metrics.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(json);
    // ignore: avoid_print
    print(json);

    // Sanity only: every run produced its stats.
    expect(bounded, hasLength(3));
  });
}
