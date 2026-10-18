// The production camera service (AC-0601, AC-0602, AC-0605..AC-0608) over
// a fake plugin driver and fake permissions, with the real originals store
// on a temporary directory and database. These prove the service's rules;
// physical cameras are proved by the M06 device procedure.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/camera_driver.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/managed_camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/permission_handler_camera_permissions.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';

import '../support/fakes.dart';
import '../support/test_database.dart';

const _front = CameraDescriptor(
  id: 'front-0',
  lens: CameraLens.front,
  sensorOrientationDegrees: 270,
);
const _rear = CameraDescriptor(
  id: 'rear-0',
  lens: CameraLens.back,
  sensorOrientationDegrees: 90,
);
const _frontRequest = CameraRequest(
  cameraId: 'front-0',
  mirrorPreview: true,
  mirrorOutput: false,
);
const _rearRequest = CameraRequest(
  cameraId: 'rear-0',
  mirrorPreview: false,
  mirrorOutput: true,
);

final class _FakeDriver implements CameraDriver {
  _FakeDriver(this.photo);

  Uint8List photo;
  List<CameraDescriptor> cameras = const [_front, _rear];
  String? openError;
  Error? openThrows;
  String? captureError;
  Error? captureThrows;
  Completer<void>? captureGate;
  CaptureOrientation orientation = CaptureOrientation.landscapeRight;
  final opened = <String>[];

  /// The camera open now; opening another closes it, like the plugin.
  String? openCamera;
  int closes = 0;
  int captures = 0;
  final _errors = StreamController<CameraDriverException>.broadcast();

  /// The open camera's own report, e.g. another app took it.
  void report(String code) => _errors.add(CameraDriverException(code));

  @override
  Stream<CameraDriverException> get errors => _errors.stream;

  @override
  Future<List<CameraDescriptor>> listCameras() async => cameras;

  @override
  Future<CameraCapabilities> open(CameraDescriptor camera) async {
    if (openCamera != null) await close();
    opened.add(camera.id);
    if (openError case final code?) throw CameraDriverException(code);
    if (openThrows case final error?) throw error;
    openCamera = camera.id;
    return CameraCapabilities(
      camera: camera,
      previewWidthPx: 1920,
      previewHeightPx: 1080,
      minZoom: 1,
      maxZoom: 4,
      focusPointSupported: true,
      exposurePointSupported: true,
    );
  }

  @override
  Future<DriverStill> capture() async {
    captures++;
    await captureGate?.future;
    if (captureError case final code?) throw CameraDriverException(code);
    if (captureThrows case final error?) throw error;
    return DriverStill(photo, orientation);
  }

  @override
  Future<void> close() async {
    openCamera = null;
    closes++;
  }
}

final class _FakePermissions implements CameraPermissions {
  CameraPermission current = CameraPermission.granted;
  CameraPermission answer = CameraPermission.granted;
  Exception? fails;
  bool settingsFail = false;
  int prompts = 0;
  int settingsOpened = 0;

  @override
  Future<CameraPermission> status() async {
    if (fails case final error?) throw error;
    return current;
  }

  @override
  Future<CameraPermission> request() async {
    if (fails case final error?) throw error;
    if (current.canAsk) {
      prompts++;
      current = answer;
    }
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    if (settingsFail) throw PlatformException(code: 'no-activity');
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final jpeg = File('test_assets/input_photos/exif_orientation_1_640x480.jpg')
      .readAsBytesSync();

  late Directory root;
  late File databaseFile;
  late BoothDatabase db;
  late FileManagedStorage storage;
  late OriginalStore store;
  late _FakeDriver driver;
  late _FakePermissions permissions;
  late bool appActive;
  late ManagedCameraService service;
  var ids = 0;

  OriginalStore storeOver(BoothDatabase database) => OriginalStore(
    database: database,
    root: () async => root,
    writer: storage.writer,
    clock: FakeClock(),
  );

  setUp(() async {
    ids = 0;
    root = Directory.systemTemp.createTempSync('porcelain_camera_');
    databaseFile = File('${root.path}/booth.sqlite');
    db = fileDatabase(databaseFile);
    storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    store = storeOver(db);
    driver = _FakeDriver(jpeg);
    permissions = _FakePermissions();
    appActive = true;
    service = ManagedCameraService(
      driver: driver,
      permissions: permissions,
      store: store,
      isAppActive: () => appActive,
      clock: () => DateTime.utc(2026, 10, 18, 12),
      newId: () => 'shot-${++ids}',
    );
  });

  tearDown(() async {
    await service.dispose();
    await db.close();
    root.deleteSync(recursive: true);
  });

  Matcher failsWith(CameraFailureCode code) =>
      throwsA(isA<CameraFailure>().having((f) => f.code, 'code', code));

  group('permission (AC-0601)', () {
    test('never asked: opening asks once, then opens', () async {
      permissions
        ..current = CameraPermission.notDetermined
        ..answer = CameraPermission.granted;
      await service.initialize(_frontRequest);
      expect(permissions.prompts, 1);
      expect(service.status.permission, CameraPermission.granted);
      expect(service.status.isReady, isTrue);
    });

    for (final (permission, code) in [
      (CameraPermission.denied, CameraFailureCode.permissionDenied),
      (
        CameraPermission.permanentlyDenied,
        CameraFailureCode.permissionPermanentlyDenied,
      ),
      (CameraPermission.restricted, CameraFailureCode.permissionRestricted),
    ]) {
      test('${permission.name}: fails as ${code.name} without asking or '
          'opening', () async {
        permissions.current = permission;
        await expectLater(service.initialize(_frontRequest), failsWith(code));
        expect(permissions.prompts, 0);
        expect(driver.opened, isEmpty);
        expect(service.status.lifecycle, CameraLifecycle.failed);
        expect(service.status.permission, permission);
        expect(service.status.request, _frontRequest, reason: 'kept to resume');
      });
    }

    test('refused at the prompt: fails and says so', () async {
      permissions
        ..current = CameraPermission.notDetermined
        ..answer = CameraPermission.permanentlyDenied;
      await expectLater(
        service.initialize(_frontRequest),
        failsWith(CameraFailureCode.permissionPermanentlyDenied),
      );
      expect(permissions.prompts, 1);
      expect(driver.opened, isEmpty);
    });

    test('asking and the Settings repair are reported, and plugin errors '
        'never escape untyped', () async {
      permissions
        ..current = CameraPermission.denied
        ..answer = CameraPermission.granted;
      expect(await service.requestPermission(), CameraPermission.granted);
      expect(service.status.permission, CameraPermission.granted);
      expect(await service.openPermissionSettings(), isTrue);
      permissions.settingsFail = true;
      expect(await service.openPermissionSettings(), isFalse);
      expect(permissions.settingsOpened, 2);

      permissions.fails = PlatformException(code: 'channel-error');
      await expectLater(
        service.permission(),
        failsWith(CameraFailureCode.initializationFailed),
      );
      await expectLater(
        service.requestPermission(),
        failsWith(CameraFailureCode.initializationFailed),
      );
    });

    for (final (code, failure, permission) in [
      (
        'CameraAccessDenied',
        CameraFailureCode.permissionDenied,
        CameraPermission.denied,
      ),
      (
        'CameraAccessDeniedWithoutPrompt',
        CameraFailureCode.permissionPermanentlyDenied,
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
        await expectLater(
          service.initialize(_frontRequest),
          failsWith(failure),
        );
        expect(service.status.permission, permission);
        expect(service.status.failure?.detail, code);
      });
    }

    test('permission_handler statuses read as the booth means them', () {
      // Android reports "not allowed" for never asked and refused alike;
      // only a request's answer says it was refused (ADR-0012).
      expect(
        PermissionHandlerCameraPermissions.statusOf(PermissionStatus.denied),
        CameraPermission.notDetermined,
      );
      expect(
        PermissionHandlerCameraPermissions.requestResultOf(
          PermissionStatus.denied,
        ),
        CameraPermission.denied,
      );
      for (final (status, permission) in [
        (PermissionStatus.granted, CameraPermission.granted),
        (PermissionStatus.limited, CameraPermission.granted),
        (
          PermissionStatus.permanentlyDenied,
          CameraPermission.permanentlyDenied,
        ),
        (PermissionStatus.restricted, CameraPermission.restricted),
      ]) {
        expect(PermissionHandlerCameraPermissions.statusOf(status), permission);
        expect(
          PermissionHandlerCameraPermissions.requestResultOf(status),
          permission,
        );
      }
    });
  });

  group('cameras and preview (AC-0602, AC-0605)', () {
    test('lists the cameras and opens the one asked for', () async {
      expect(await service.availableCameras(), [_front, _rear]);
      final rear = await service.initialize(_rearRequest);
      expect(rear.camera, _rear);
      expect(driver.opened, ['rear-0']);
      // Switching lens reopens; asking again for the open camera does not.
      await service.initialize(_frontRequest);
      await service.initialize(_frontRequest);
      expect(driver.opened, ['rear-0', 'front-0']);
    });

    test('a camera that went away is unavailable; none at all is no '
        'camera', () async {
      driver.cameras = const [_front];
      await expectLater(
        service.initialize(_rearRequest),
        failsWith(CameraFailureCode.cameraUnavailable),
      );
      driver.cameras = const [];
      await expectLater(
        service.initialize(_frontRequest),
        failsWith(CameraFailureCode.noCamera),
      );
    });

    test('the preview keeps its shape whatever the orientation', () async {
      final capabilities = await service.initialize(_rearRequest);
      expect(capabilities.previewAspectRatio, closeTo(16 / 9, 1e-9));
      const portraitStream = CameraCapabilities(
        camera: _rear,
        previewWidthPx: 1080,
        previewHeightPx: 1920,
        minZoom: 1,
        maxZoom: 1,
        focusPointSupported: false,
        exposurePointSupported: false,
      );
      expect(portraitStream.previewAspectRatio, closeTo(16 / 9, 1e-9));
    });

    test('preview mirroring is exactly what the booth asks for, on both '
        'lenses', () {
      // Both platforms mirror the front preview themselves (ADR-0012).
      expect(platformMirrorsPreview(CameraLens.front), isTrue);
      expect(platformMirrorsPreview(CameraLens.back), isFalse);
      for (final lens in [CameraLens.front, CameraLens.back]) {
        for (final mirror in [true, false]) {
          final shownMirrored =
              platformMirrorsPreview(lens) !=
              previewFlipFor(lens, mirror: mirror);
          expect(shownMirrored, mirror, reason: '${lens.name} mirror=$mirror');
        }
      }
    });

    test('camera state errors are sorted by their description', () {
      expect(
        classifyCameraErrorDescription('Camera is already in use'),
        'cameraInUse',
      );
      expect(
        classifyCameraErrorDescription('Too many open cameras'),
        'cameraInUse',
      );
      expect(
        classifyCameraErrorDescription('Do Not Disturb mode is on'),
        'doNotDisturb',
      );
      expect(
        classifyCameraErrorDescription('Disabled by device policy'),
        'cameraDisabled',
      );
      expect(classifyCameraErrorDescription('Fatal error'), 'cameraFatal');
      expect(classifyCameraErrorDescription(null), 'cameraInterrupted');
    });
  });

  group('capture (AC-0607, AC-0608)', () {
    test('saves a validated, committed original with its context', () async {
      await service.initialize(_frontRequest);
      final still = await service.captureStill(
        origin: CaptureOrigin.diagnostics,
      );
      expect(still.id, 'shot-1');
      expect(still.lens, CameraLens.front);
      expect(still.sensorOrientationDegrees, 270);
      expect(still.deviceOrientation, CaptureOrientation.landscapeRight);
      expect(still.mirrorPreviewRequested, isTrue);
      expect(still.mirrorOutputRequested, isFalse);
      expect(still.capturedAtUtc, DateTime.utc(2026, 10, 18, 12));
      expect(still.origin, CaptureOrigin.diagnostics);
      expect((still.widthPx, still.heightPx), (640, 480));
      expect(await store.read(still), jpeg, reason: 'never altered');
      expect(service.status.lifecycle, CameraLifecycle.ready);
    });

    test('a second press while capturing is refused at once, not '
        'queued', () async {
      await service.initialize(_frontRequest);
      driver.captureGate = Completer<void>();
      final first = service.captureStill();
      await expectLater(
        service.captureStill(),
        failsWith(CameraFailureCode.captureBusy),
      );
      expect(service.status.lifecycle, CameraLifecycle.capturing);
      driver.captureGate!.complete();
      await first;
      expect(driver.captures, 1);
      expect(await store.listCommitted(), hasLength(1));
      // Once it is done the next press works.
      expect((await service.captureStill()).id, 'shot-2');
    });

    test('no shutter fires while the app is not active', () async {
      await service.initialize(_frontRequest);
      appActive = false;
      await expectLater(
        service.captureStill(),
        failsWith(CameraFailureCode.appNotActive),
      );
      expect(driver.captures, 0);
      // Back in front, nothing fires by itself.
      appActive = true;
      await pumpEventQueue();
      expect(driver.captures, 0);
    });

    test('capturing before the camera is open fails cleanly', () async {
      await expectLater(
        service.captureStill(),
        failsWith(CameraFailureCode.notReady),
      );
      expect(driver.captures, 0);
    });

    test('a truncated or undecodable still is not saved, and the camera '
        'stays usable', () async {
      await service.initialize(_frontRequest);
      for (final (bytes, reason) in [
        (Uint8List.sublistView(jpeg, 0, jpeg.length - 100), 'truncated'),
        (Uint8List.fromList(List.filled(512, 3)), 'not-jpeg'),
      ]) {
        driver.photo = bytes;
        await expectLater(
          service.captureStill(),
          throwsA(
            isA<CameraFailure>()
                .having(
                  (f) => f.code,
                  'code',
                  CameraFailureCode.originalNotPersisted,
                )
                .having((f) => f.detail, 'detail', reason),
          ),
        );
      }
      expect(await store.listCommitted(), isEmpty);
      driver.photo = jpeg;
      expect((await service.captureStill()).id, 'shot-3');
    });

    test('plugin and platform failures become typed failures', () async {
      driver.openThrows = StateError('channel down');
      await expectLater(
        service.initialize(_frontRequest),
        failsWith(CameraFailureCode.initializationFailed),
      );
      expect(service.status.failure?.detail, 'StateError');
      driver.openThrows = null;
      await service.initialize(_frontRequest);

      driver.captureError = 'captureFailure';
      await expectLater(
        service.captureStill(),
        failsWith(CameraFailureCode.captureFailed),
      );
      driver
        ..captureError = null
        ..captureThrows = StateError('sensor gone');
      await expectLater(
        service.captureStill(),
        failsWith(CameraFailureCode.captureFailed),
      );
      driver.captureThrows = null;
      expect(
        (await service.captureStill()).id,
        'shot-1',
        reason: 'failed shutters use no id',
      );
    });

    test('operations run in call order without awaiting each other', () async {
      final opening = service.initialize(_frontRequest);
      final capture = service.captureStill();
      await opening;
      expect((await capture).id, 'shot-1');
    });

    test('originals survive a restart and are read back intact', () async {
      await service.initialize(_rearRequest);
      final still = await service.captureStill();
      await service.dispose();
      await db.close();

      db = fileDatabase(databaseFile);
      await storage.prepare();
      final reopened = storeOver(db);
      expect((await reopened.reconcile()).changedAnything, isFalse);
      final listed = await reopened.listCommitted();
      expect(listed, [still]);
      expect(listed.single.mirrorOutputRequested, isTrue);
      expect(await reopened.read(listed.single), jpeg);
      service = ManagedCameraService(
        driver: _FakeDriver(jpeg),
        permissions: permissions,
        store: reopened,
      );
    });
  });

  group('lifecycle (AC-0606)', () {
    test('suspend releases the camera; resume reopens it without '
        'prompting or taking a photo', () async {
      await service.initialize(_frontRequest);
      await service.suspend();
      expect(driver.openCamera, isNull);
      expect(service.status.lifecycle, CameraLifecycle.suspended);
      await expectLater(
        service.captureStill(),
        failsWith(CameraFailureCode.notReady),
      );
      await service.resume();
      expect(driver.opened, ['front-0', 'front-0']);
      expect(service.status.isReady, isTrue);
      expect(driver.captures, 0, reason: 'no delayed shutter');
      expect(permissions.prompts, 0);
    });

    test('access turned off while away: resume fails without '
        'prompting', () async {
      await service.initialize(_frontRequest);
      await service.suspend();
      permissions.current = CameraPermission.permanentlyDenied;
      await service.resume();
      expect(service.status.lifecycle, CameraLifecycle.failed);
      expect(
        service.status.failure?.code,
        CameraFailureCode.permissionPermanentlyDenied,
      );
      expect(permissions.prompts, 0);
      // Turned back on in Settings: the next resume opens it.
      permissions.current = CameraPermission.granted;
      await service.resume();
      expect(service.status.isReady, isTrue);
    });

    test('resume does nothing when nothing was opened', () async {
      await service.resume();
      expect(driver.opened, isEmpty);
      expect(service.status.lifecycle, CameraLifecycle.uninitialized);
    });

    test('an interruption closes the camera and says why; resume opens '
        'it again', () async {
      await service.initialize(_frontRequest);
      driver.report('cameraInUse');
      await pumpEventQueue();
      expect(service.status.lifecycle, CameraLifecycle.failed);
      expect(service.status.failure?.code, CameraFailureCode.cameraInUse);
      expect(driver.openCamera, isNull);
      await expectLater(
        service.captureStill(),
        failsWith(CameraFailureCode.notReady),
      );
      await service.resume();
      expect(service.status.isReady, isTrue);
      expect(service.status.failure, isNull);
      expect(driver.captures, 0);
    });

    test('an interruption during a capture waits for it to finish', () async {
      await service.initialize(_frontRequest);
      driver.captureGate = Completer<void>();
      final capture = service.captureStill();
      await pumpEventQueue();
      driver.report('cameraInterrupted');
      driver.captureGate!.complete();
      expect((await capture).id, 'shot-1', reason: 'the photo was saved');
      await pumpEventQueue();
      expect(service.status.lifecycle, CameraLifecycle.failed);
      expect(service.status.failure?.code, CameraFailureCode.interrupted);
    });

    test('suspending while a photo is being taken lets it finish '
        'first', () async {
      await service.initialize(_frontRequest);
      driver.captureGate = Completer<void>();
      final capture = service.captureStill();
      final suspended = service.suspend();
      await pumpEventQueue();
      expect(
        driver.openCamera,
        'front-0',
        reason: 'never closed under a capture',
      );
      driver.captureGate!.complete();
      await capture;
      await suspended;
      expect(driver.openCamera, isNull);
      expect(service.status.lifecycle, CameraLifecycle.suspended);
    });

    test('every open is closed by dispose (no leaked camera)', () async {
      await service.initialize(_frontRequest);
      await service.initialize(_rearRequest);
      await service.suspend();
      await service.resume();
      expect(driver.openCamera, 'rear-0');
      await service.dispose();
      expect(service.status.lifecycle, CameraLifecycle.disposed);
      expect(driver.openCamera, isNull);
      final statuses = <CameraLifecycle>[];
      final subscription = service.statusChanges.listen(
        (status) => statuses.add(status.lifecycle),
      );
      await pumpEventQueue();
      expect(statuses, [CameraLifecycle.disposed]);
      await subscription.cancel();
    });

    test('status changes arrive in order, starting with the current '
        'status', () async {
      final lifecycles = <CameraLifecycle>[];
      final subscription = service.statusChanges.listen(
        (status) => lifecycles.add(status.lifecycle),
      );
      await service.initialize(_frontRequest);
      await service.captureStill();
      await service.suspend();
      await pumpEventQueue();
      expect(lifecycles.first, CameraLifecycle.uninitialized);
      expect(lifecycles.toSet().toList(), [
        CameraLifecycle.uninitialized,
        CameraLifecycle.initializing,
        CameraLifecycle.ready,
        CameraLifecycle.capturing,
        CameraLifecycle.suspended,
      ]);
      await subscription.cancel();
    });
  });
}
