import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/di/service_providers.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/camera_spike_screen.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render/png_encoder.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render_spike_screen.dart';

const _front = CameraDescriptor(
  id: 'front-0',
  lens: CameraLens.front,
  sensorOrientationDegrees: 270,
);
const _back = CameraDescriptor(
  id: 'back-0',
  lens: CameraLens.back,
  sensorOrientationDegrees: 90,
);

final _tinyPng = encodePngRgba(
  width: 2,
  height: 2,
  rgba: Uint8List.fromList(List.filled(16, 200)),
);

final class _FakeCamera implements CameraService {
  final _changes = StreamController<CameraLifecycle>.broadcast();
  var state = CameraLifecycle.uninitialized;
  var permissionState = CameraPermission.notDetermined;
  CameraFailure? initFailure;
  final saved = <CapturedStill>[];

  void _set(CameraLifecycle next) {
    state = next;
    _changes.add(next);
  }

  @override
  Stream<CameraLifecycle> get lifecycle => Stream.multi((listener) {
    listener.add(state);
    final subscription = _changes.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<CameraPermission> permission() async => permissionState;

  @override
  Future<List<CameraDescriptor>> availableCameras() async => const [
    _back,
    _front,
  ];

  @override
  Future<void> initialize(CameraRequest request) async {
    if (initFailure case final failure?) {
      permissionState = CameraPermission.denied;
      _set(CameraLifecycle.failed);
      throw failure;
    }
    permissionState = CameraPermission.granted;
    _set(CameraLifecycle.ready);
  }

  @override
  Future<CapturedStill> captureStill() async {
    final still = CapturedStill(
      id: 'shot-${saved.length + 1}',
      relativePath: 'originals/shot-${saved.length + 1}.jpg',
      widthPx: 3024,
      heightPx: 4032,
      byteLength: _tinyPng.length,
      sha256: 'ab' * 32,
      lens: CameraLens.front,
      sensorOrientationDegrees: 270,
      mirrorPreviewRequested: true,
      mirrorOutputRequested: false,
      capturedAtUtc: DateTime.utc(2026, 10, 18),
      exifOrientation: 6,
    );
    saved.add(still);
    return still;
  }

  @override
  Future<void> suspend() async {
    if (state == CameraLifecycle.ready) _set(CameraLifecycle.suspended);
  }

  @override
  Future<void> resume() async {}

  @override
  Future<void> dispose() async {}
}

final class _FakeStore implements CapturedStillStore {
  _FakeStore(this.camera);

  final _FakeCamera camera;

  @override
  Future<List<CapturedStill>> listCommitted() async => [...camera.saved];

  @override
  Future<Uint8List> read(CapturedStill still) async => _tinyPng;
}

final class _FailingRenderer implements CompositionRenderer {
  @override
  Future<RenderedImage> renderExport(
    TemplateDocument document, {
    required Map<int, String> slotAssets,
    required Map<String, Uint8List> assets,
    bool includePixels = false,
  }) async => throw const RenderFailure(RenderFailureCode.missingAsset);

  @override
  Future<RenderedImage> renderWorkspace(
    TemplateDocument document, {
    required Map<int, String> slotAssets,
    required Map<String, Uint8List> assets,
    double marginFraction = 0.1,
    bool includePixels = false,
  }) async => throw const RenderFailure(RenderFailureCode.missingAsset);
}

void main() {
  late _FakeCamera camera;

  setUp(() => camera = _FakeCamera());

  Widget cameraSpike() => ProviderScope(
    overrides: [
      cameraServiceProvider.overrideWithValue(camera),
      capturedStillStoreProvider.overrideWithValue(_FakeStore(camera)),
      cameraPreviewBuilderProvider.overrideWithValue(
        (context, {required mirror}) =>
            ColoredBox(key: const Key('preview'), color: Colors.black),
      ),
    ],
    child: const MaterialApp(home: CameraSpikeScreen()),
  );

  void tallView(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 2400);
    addTearDown(tester.view.reset);
  }

  testWidgets('camera spike prefers the front camera, previews and captures', (
    tester,
  ) async {
    tallView(tester);
    await tester.pumpWidget(cameraSpike());
    await tester.pumpAndSettle();

    expect(find.text('front · sensor 270° · front-0'), findsOneWidget);
    expect(find.byKey(const Key('preview')), findsNothing);

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();
    expect(find.text('Camera: ready · permission: granted'), findsOneWidget);
    expect(find.byKey(const Key('preview')), findsOneWidget);

    await tester.tap(find.text('Capture still'));
    await tester.pumpAndSettle();
    expect(find.text('Last capture'), findsOneWidget);
    expect(
      find.text('Stored originals (1), re-verified from disk'),
      findsOneWidget,
    );
    expect(find.textContaining('EXIF orientation 6'), findsWidgets);
  });

  testWidgets('a denied permission explains how to repair it', (tester) async {
    tallView(tester);
    camera.initFailure = const CameraFailure(
      CameraFailureCode.permissionDenied,
    );
    await tester.pumpWidget(cameraSpike());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    expect(find.text('Camera: failed · permission: denied'), findsOneWidget);
    expect(
      find.textContaining('Settings > Porcelain Photo Booth > Camera'),
      findsOneWidget,
    );
  });

  testWidgets('leaving the camera spike releases the camera', (tester) async {
    tallView(tester);
    await tester.pumpWidget(cameraSpike());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(camera.state, CameraLifecycle.suspended);
  });

  testWidgets('render spike reports renderer failures instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionRendererProvider.overrideWithValue(_FailingRenderer()),
        ],
        child: const MaterialApp(home: RenderSpikeScreen()),
      ),
    );
    await tester.tap(find.text('Run FIX-01 render spike'));
    await tester.pumpAndSettle();

    expect(
      find.text('Render spike failed: RenderFailure(missingAsset)'),
      findsOneWidget,
    );
  });
}
