// Runs only on a physical tablet whose camera access is already allowed
// (M06 device procedure, AC-0603, AC-0604, AC-0607, AC-0608):
//   Android: adb shell pm grant com.example.porcelain_photo_booth \
//              android.permission.CAMERA
//   iPad:    Diagnostics > Camera test > Allow camera, once
//   then:    flutter test integration_test/camera_capture_test.dart -d <id>
// Emulators and simulators have no real camera; a run there is not
// evidence. It drives the production service, plugin driver and originals
// store in a temporary area, so the booth's own photos are untouched, and
// prints the facts to record.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/value_objects/clock.dart';
import 'package:porcelain_photo_booth/domain/value_objects/entity_id.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/camera_driver.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/managed_camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/permission_handler_camera_permissions.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/database_connection.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('each built-in lens saves one full-resolution original per '
      'press, intact after the store reopens', (tester) async {
    final root = await Directory.systemTemp.createTemp('porcelain_camera_it');
    addTearDown(() => root.delete(recursive: true));
    final storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    BoothDatabase open() => BoothDatabase(
      openBoothDatabaseFile(storage.databaseFile),
      ids: RandomIdGenerator(),
      clock: const SystemClock(),
    );
    OriginalStore storeOver(BoothDatabase database) => OriginalStore(
      database: database,
      root: () async => root,
      writer: storage.writer,
      clock: const SystemClock(),
    );

    final database = open();
    final store = storeOver(database);
    final service = ManagedCameraService(
      driver: PluginCameraDriver(),
      permissions: const PermissionHandlerCameraPermissions(),
      store: store,
    );
    expect(
      await service.permission(),
      CameraPermission.granted,
      reason: 'allow the camera first (see the header)',
    );

    final cameras = await service.availableCameras();
    final saved = <CapturedStill>[];
    for (final lens in [CameraLens.front, CameraLens.back]) {
      final choice = CameraChoice.of(cameras, lens);
      final camera = choice.camera;
      if (camera == null || choice.fellBack) {
        // ignore: avoid_print
        print('M06 ${lens.name}: not on this tablet');
        continue;
      }
      final capabilities = await service.initialize(
        CameraRequest(
          cameraId: camera.id,
          mirrorPreview: lens == CameraLens.front,
          mirrorOutput: false,
        ),
      );

      // Two presses at once: one photo (AC-0607).
      final watch = Stopwatch()..start();
      final first = service.captureStill(origin: CaptureOrigin.diagnostics);
      await expectLater(
        service.captureStill(origin: CaptureOrigin.diagnostics),
        throwsA(
          isA<CameraFailure>().having(
            (f) => f.code,
            'code',
            CameraFailureCode.captureBusy,
          ),
        ),
      );
      final still = await first;
      watch.stop();
      saved.add(still);

      // A real still: well over a megapixel and at least as large as the
      // preview stream, so never a picture of the screen (AC-0608).
      expect(still.widthPx * still.heightPx, greaterThan(1000000));
      expect(
        math.max(still.widthPx, still.heightPx),
        greaterThanOrEqualTo(
          math.max(capabilities.previewWidthPx, capabilities.previewHeightPx),
        ),
      );
      expect(still.lens, lens);
      expect(still.mirrorOutputRequested, isFalse);
      expect((await store.read(still)).length, still.byteLength);
      // ignore: avoid_print
      print(
        'M06 ${lens.name}: ${still.widthPx}x${still.heightPx}, '
        '${still.byteLength} bytes, EXIF ${still.exifOrientation}, '
        'held ${still.deviceOrientation.name}, sensor '
        '${still.sensorOrientationDegrees}, stream '
        '${capabilities.previewWidthPx}x${capabilities.previewHeightPx}, '
        'zoom ${capabilities.minZoom}-${capabilities.maxZoom}, '
        '${watch.elapsedMilliseconds} ms press to saved',
      );
    }
    expect(saved, isNotEmpty, reason: 'the tablet reports no built-in camera');

    // Release the camera, close the database, open everything again.
    await service.dispose();
    await database.close();
    final reopenedDatabase = open();
    addTearDown(reopenedDatabase.close);
    final reopened = storeOver(reopenedDatabase);
    expect((await reopened.reconcile()).changedAnything, isFalse);
    final listed = await reopened.listCommitted();
    expect(listed.toSet(), saved.toSet());
    for (final still in listed) {
      expect((await reopened.read(still)).length, still.byteLength);
    }
  });
}
