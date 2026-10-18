// Launch checks (S19, A-14): storage, the renderer and template assets are
// checked for real (M03, M04); the rest name the milestone that adds them
// and are never reported as ready.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/services/booth_capabilities.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/infrastructure/device/device_capability_probe.dart';

import '../support/template_store_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixtures = [fix01(), fix02(), fix03(), clipAndFit(), fix05()];
  late TemplateStoreHarness harness;
  late DeviceCapabilityProbe probe;
  late List<TemplateRevisionSummary> templates;

  setUp(() async {
    harness = await TemplateStoreHarness.create();
    probe = DeviceCapabilityProbe(
      harness.storage,
      renderer: DartUiCompositionRenderer(),
      templates: harness.templates,
      assets: harness.assets,
    );
    templates = [
      for (final (i, fixture) in fixtures.indexed)
        await harness.storeFixture(fixture, name: 'Template $i'),
    ];
  });

  tearDown(() => harness.dispose());

  String? problem(CapabilityStatus status) => switch (status) {
    CapabilityProblem(:final code) => code,
    _ => null,
  };

  test('intact templates render in both formats and pass the audit', () async {
    expect(await probe.templateAssets(templates), isA<CapabilityReady>());
    for (final format in OutputFormat.values) {
      expect(
        await probe.renderer(OutputProfile(format: format), templates),
        isA<CapabilityReady>(),
        reason: format.name,
      );
    }
  });

  test('with no templates yet, the renderer still makes a test page', () async {
    expect(
      await probe.renderer(const OutputProfile(), const []),
      isA<CapabilityReady>(),
    );
    expect(await probe.templateAssets(const []), isA<CapabilityReady>());
  });

  test('a missing or changed asset blocks both checks', () async {
    final flowerId = fix01().document.assets.keys.firstWhere(
      (id) => fix01().document.assets[id]!.name == 'flower.png',
    );
    final file = harness.file('assets/$flowerId.png');
    final bytes = file.readAsBytesSync();

    file.deleteSync();
    expect(
      problem(await probe.templateAssets(templates)),
      'TEMPLATE_ASSET_MISSING',
    );
    expect(
      problem(await probe.renderer(const OutputProfile(), templates)),
      'RENDER_MISSING_ASSET',
    );

    file.writeAsBytesSync([...bytes.reversed]);
    expect(
      problem(await probe.templateAssets(templates)),
      'TEMPLATE_ASSET_MISMATCH',
    );
  });

  test('a damaged manifest blocks both checks', () async {
    final row = await harness.db.select(harness.db.templateRevisions).get();
    final manifest = harness.file(row.first.manifestPath);
    manifest.writeAsStringSync('${manifest.readAsStringSync()} ');
    final first = templates.where((t) => t.revisionId == row.first.id).toList();
    expect(
      problem(await probe.templateAssets(first)),
      'TEMPLATE_MANIFEST_DAMAGED',
    );
    expect(
      problem(await probe.renderer(const OutputProfile(), first)),
      'TEMPLATE_MANIFEST_DAMAGED',
    );
  });

  test('storage is checked for real; the rest name their milestone', () async {
    expect(await probe.storageWrite(), isA<CapabilityReady>());
    String? milestone(CapabilityStatus status) =>
        (status as CapabilityNotYetAvailable).milestone;
    const capture = CaptureSettings(
      lens: CameraLens.front,
      mirrorPreview: true,
      mirrorOutput: false,
      orientation: GuestOrientationPreference.portrait,
    );
    expect(milestone(await probe.camera(capture)), 'M06');
    expect(milestone(await probe.freeSpace()), 'M06');
    expect(milestone(await probe.kioskLock()), 'M10');
    expect(
      Directory('${harness.root.path}/outputs').listSync(),
      isEmpty,
      reason: 'the renderer check saves nothing',
    );
  });
}
