import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/camera_driver.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/managed_camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';

const _front = CameraDescriptor(
  id: 'front-0',
  lens: CameraLens.front,
  sensorOrientationDegrees: 270,
);
const _request = CameraRequest(
  cameraId: 'front-0',
  mirrorPreview: true,
  mirrorOutput: false,
);

final class _FakeDriver implements CameraDriver {
  _FakeDriver(this.photo);

  Uint8List photo;
  String? openError;
  Completer<void>? captureGate;
  int opens = 0;
  int closes = 0;
  int captures = 0;

  @override
  Future<List<CameraDescriptor>> listCameras() async => const [_front];

  @override
  Future<void> open(CameraDescriptor camera) async {
    opens++;
    if (openError case final code?) throw CameraDriverException(code);
  }

  @override
  Future<Uint8List> capture() async {
    captures++;
    await captureGate?.future;
    return photo;
  }

  @override
  Future<void> close() async => closes++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final jpeg = File('test_assets/input_photos/exif_orientation_1_640x480.jpg')
      .readAsBytesSync();

  late Directory root;
  late OriginalStore store;
  late _FakeDriver driver;
  late bool appActive;
  late ManagedCameraService service;
  var ids = 0;

  setUp(() {
    ids = 0;
    root = Directory.systemTemp.createTempSync('porcelain_camera_');
    store = OriginalStore(root: () async => root);
    driver = _FakeDriver(jpeg);
    appActive = true;
    service = ManagedCameraService(
      driver: driver,
      store: store,
      isAppActive: () => appActive,
      clock: () => DateTime.utc(2026, 10, 18, 12),
      newId: () => 'shot-${++ids}',
    );
  });

  tearDown(() async {
    await service.dispose();
    root.deleteSync(recursive: true);
  });

  Matcher failsWith(CameraFailureCode code) =>
      throwsA(isA<CameraFailure>().having((f) => f.code, 'code', code));

  test('initialises and reports the lifecycle in order', () async {
    final states = <CameraLifecycle>[];
    final subscription = service.lifecycle.listen(states.add);
    await service.initialize(_request);
    await pumpEventQueue();
    expect(states, [
      CameraLifecycle.uninitialized,
      CameraLifecycle.initializing,
      CameraLifecycle.ready,
    ]);
    expect(await service.permission(), CameraPermission.granted);
    await subscription.cancel();
  });

  for (final (code, failure, permission) in [
    (
      'CameraAccessDenied',
      CameraFailureCode.permissionDenied,
      CameraPermission.denied,
    ),
    (
      'CameraAccessDeniedWithoutPrompt',
      CameraFailureCode.permissionDenied,
      CameraPermission.permanentlyDenied,
    ),
    (
      'CameraAccessRestricted',
      CameraFailureCode.permissionRestricted,
      CameraPermission.restricted,
    ),
    (
      'CameraPermissionsError',
      CameraFailureCode.permissionDenied,
      CameraPermission.denied,
    ),
  ]) {
    test('plugin error $code becomes ${failure.name}', () async {
      driver.openError = code;
      await expectLater(service.initialize(_request), failsWith(failure));
      expect(await service.permission(), permission);
    });
  }

  test('an unknown camera is unavailable', () async {
    await expectLater(
      service.initialize(
        const CameraRequest(
          cameraId: 'missing',
          mirrorPreview: false,
          mirrorOutput: false,
        ),
      ),
      failsWith(CameraFailureCode.cameraUnavailable),
    );
  });

  test('captures a validated, committed original', () async {
    await service.initialize(_request);
    final still = await service.captureStill();
    expect(still.id, 'shot-1');
    expect(still.lens, CameraLens.front);
    expect(still.sensorOrientationDegrees, 270);
    expect(still.mirrorPreviewRequested, isTrue);
    expect(still.mirrorOutputRequested, isFalse);
    expect(still.capturedAtUtc, DateTime.utc(2026, 10, 18, 12));
    expect((await store.listCommitted()).single.id, 'shot-1');
  });

  test('a second tap while capturing is refused, not queued', () async {
    await service.initialize(_request);
    driver.captureGate = Completer<void>();
    final first = service.captureStill();
    await expectLater(
      service.captureStill(),
      failsWith(CameraFailureCode.captureBusy),
    );
    driver.captureGate!.complete();
    await first;
    expect(driver.captures, 1);
    expect(await store.listCommitted(), hasLength(1));
  });

  test('no shutter fires while the app is not active', () async {
    await service.initialize(_request);
    appActive = false;
    await expectLater(
      service.captureStill(),
      failsWith(CameraFailureCode.appNotActive),
    );
    expect(driver.captures, 0);
  });

  test('capturing before initialisation fails cleanly', () async {
    await expectLater(
      service.captureStill(),
      failsWith(CameraFailureCode.cameraUnavailable),
    );
    expect(driver.captures, 0);
  });

  test('an undecodable capture is not persisted', () async {
    await service.initialize(_request);
    driver.photo = Uint8List.fromList(List.filled(512, 3));
    await expectLater(
      service.captureStill(),
      failsWith(CameraFailureCode.originalNotPersisted),
    );
    expect(await store.listCommitted(), isEmpty);
    // The camera stays usable after a failed capture.
    driver.photo = jpeg;
    expect((await service.captureStill()).id, 'shot-2');
  });

  test(
    'suspend releases the camera; resume reopens the same request',
    () async {
      await service.initialize(_request);
      await service.suspend();
      expect(driver.closes, 1);
      await expectLater(
        service.captureStill(),
        failsWith(CameraFailureCode.cameraUnavailable),
      );
      await service.resume();
      expect(driver.opens, 2);
      expect((await service.captureStill()).id, 'shot-1');
    },
  );

  test('operations run in call order without awaiting each other', () async {
    final init = service.initialize(_request);
    final capture = service.captureStill();
    await init;
    expect((await capture).id, 'shot-1');
  });
}
