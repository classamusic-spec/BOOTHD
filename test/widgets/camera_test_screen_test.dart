// The camera test and the Diagnostics self-test (S18; AC-0601, AC-0602,
// AC-0605..AC-0608) on the simulated camera. They prove the screens and the
// lifecycle rules; physical cameras are proved by the M06 device procedure.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/features/diagnostics/camera_test_screen.dart';

import '../support/app_harness.dart';
import '../support/simulated_camera.dart';
import '../support/tablet_viewports.dart';

/// Scrolls [finder] into view, then taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The app leaves the foreground and comes back, as the OS reports it.
Future<void> _background(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _foreground(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<TestBooth> _openCameraTest(
  WidgetTester tester, {
  SimulatedCameraService? camera,
  TabletViewport viewport = TabletViewport.ipadLandscape,
}) async {
  useViewport(tester, viewport);
  final booth = await pumpApp(
    tester,
    location: RoutePaths.cameraTest,
    camera: camera,
  );
  expect(find.byType(CameraTestScreen), findsOneWidget);
  return booth;
}

Finder _preview({required bool mirrored}) => find.bySemanticsLabel(
  mirrored ? 'Simulated preview, mirrored' : 'Simulated preview',
);

void main() {
  group('camera test', () {
    testWidgets('opens the booth default camera live and saves a test photo '
        'read back from storage', (tester) async {
      final booth = await _openCameraTest(tester);
      final camera = booth.camera;

      expect(camera.status.isReady, isTrue);
      expect(camera.status.request?.cameraId, frontCamera.id);
      expect(_preview(mirrored: true), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Stream 1920 × 1440'), findsOneWidget);
      expect(find.text('Allowed'), findsOneWidget);

      await _tap(tester, find.text('Take test photo'));
      expect(camera.shutters, 1);
      final still = booth.stills.stills.single;
      expect(still.origin, CaptureOrigin.diagnostics);
      expect(still.mirrorPreviewRequested, isTrue);
      expect(still.mirrorOutputRequested, isFalse);
      expect(find.text('Test photo saved'), findsOneWidget);
      expect(find.text('Checked'), findsOneWidget);
      expect(find.text('64 × 48 px · 0.0 MP'), findsWidgets);
      expect(find.text('As taken'), findsOneWidget);
      expect(find.text('Landscape, turned left'), findsOneWidget);
      // It is listed with the earlier test photos, checked again.
      expect(find.text('Intact'), findsOneWidget);
    });

    testWidgets('a double tap takes one photo', (tester) async {
      final booth = await _openCameraTest(tester);
      final camera = booth.camera..captureGate = Completer<void>();

      final shutter = find.text('Take test photo');
      await tester.ensureVisible(shutter);
      await tester.pumpAndSettle();
      await tester.tap(shutter);
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      await tester.tap(find.text('Saving…'), warnIfMissed: false);
      await tester.pump();
      camera.captureGate!.complete();
      await tester.pumpAndSettle();

      expect(camera.shutters, 1);
      expect(booth.stills.stills, hasLength(1));
      expect(find.text('Test photo saved'), findsOneWidget);
    });

    testWidgets('never asked: explains first and asks only on "Allow '
        'camera"', (tester) async {
      final booth = await _openCameraTest(
        tester,
        camera: SimulatedCameraService(
          systemPermission: CameraPermission.notDetermined,
        ),
      );
      final camera = booth.camera;
      expect(find.text('The booth needs the camera'), findsOneWidget);
      expect(find.text('No camera access yet'), findsOneWidget);
      expect(camera.prompts, 0);
      expect(camera.initializations, 0);

      await _tap(tester, find.text('Allow camera'));
      expect(camera.prompts, 1);
      expect(camera.status.isReady, isTrue);
      expect(_preview(mirrored: true), findsOneWidget);
      expect(find.text('The booth needs the camera'), findsNothing);
    });

    testWidgets('refused for good: shows the Settings repair for the '
        'platform', (tester) async {
      final booth = await _openCameraTest(
        tester,
        camera: SimulatedCameraService(
          systemPermission: CameraPermission.permanentlyDenied,
        ),
      );
      final camera = booth.camera;
      expect(find.text('Camera access is off for this app'), findsOneWidget);
      expect(
        find.text(
          'Open Settings > Apps > Porcelain Photo Booth > Permissions > '
          'Camera and choose Allow.',
        ),
        findsOneWidget,
      );
      expect(find.text('Allow camera'), findsNothing, reason: 'it cannot ask');
      expect(find.text('Turned off in Settings'), findsOneWidget);

      await _tap(tester, find.text('Open Settings'));
      expect(camera.settingsOpened, 1);
      expect(camera.prompts, 0);
    });

    testWidgets('blocked by device management: no dead buttons', (
      tester,
    ) async {
      await _openCameraTest(
        tester,
        camera: SimulatedCameraService(
          systemPermission: CameraPermission.restricted,
        ),
      );
      expect(find.text('The camera is blocked on this tablet'), findsOneWidget);
      expect(find.text('Allow camera'), findsNothing);
      expect(find.text('Open Settings'), findsNothing);
    });

    testWidgets('turned on in Settings while away: the camera opens when the '
        'booth is back in front, and no photo is taken', (tester) async {
      final booth = await _openCameraTest(
        tester,
        camera: SimulatedCameraService(
          systemPermission: CameraPermission.permanentlyDenied,
        ),
      );
      final camera = booth.camera;
      await _tap(tester, find.text('Open Settings'));
      await _background(tester);
      camera.systemPermission = CameraPermission.granted;
      await _foreground(tester);

      expect(camera.status.isReady, isTrue);
      expect(_preview(mirrored: true), findsOneWidget);
      expect(find.text('Camera access is off for this app'), findsNothing);
      expect(camera.shutters, 0);
      expect(camera.prompts, 0);
    });

    testWidgets('allowed in Settings before ever being asked: opens on '
        'return', (tester) async {
      final booth = await _openCameraTest(
        tester,
        camera: SimulatedCameraService(
          systemPermission: CameraPermission.notDetermined,
        ),
      );
      final camera = booth.camera;
      await _background(tester);
      camera.systemPermission = CameraPermission.granted;
      await _foreground(tester);
      expect(camera.status.isReady, isTrue);
      expect(camera.prompts, 0);
    });

    testWidgets('in the background the camera is released; back in front it '
        'reopens without a delayed shutter', (tester) async {
      final booth = await _openCameraTest(tester);
      final camera = booth.camera;

      // Hidden apps draw no frames, so only the service can be asked.
      await _background(tester);
      expect(camera.status.lifecycle, CameraLifecycle.suspended);
      expect(camera.suspensions, 1);

      await _foreground(tester);
      expect(camera.status.isReady, isTrue);
      expect(camera.resumptions, 1);
      expect(camera.shutters, 0);
      expect(_preview(mirrored: true), findsOneWidget);
    });

    testWidgets('a photo in flight when the booth leaves the foreground is '
        'never fired later', (tester) async {
      final booth = await _openCameraTest(tester);
      final camera = booth.camera..appActive = false;
      // The OS reports the change after the tap reaches the app.
      await _tap(tester, find.text('Take test photo'));
      expect(camera.shutters, 0);
      expect(find.text('The booth was not in front'), findsOneWidget);
      expect(find.textContaining('CAMERA_APP_NOT_ACTIVE'), findsOneWidget);
      camera.appActive = true;
      await _background(tester);
      await _foreground(tester);
      expect(camera.shutters, 0);
      expect(booth.stills.stills, isEmpty);
    });

    testWidgets('closing the screen releases the camera', (tester) async {
      final booth = await _openCameraTest(tester);
      await _tap(tester, find.text('Back'));
      expect(find.byType(CameraTestScreen), findsNothing);
      expect(booth.camera.status.lifecycle, CameraLifecycle.suspended);
    });

    testWidgets('a failed save is explained with its code and nothing is '
        'claimed saved', (tester) async {
      final booth = await _openCameraTest(tester);
      booth.camera.captureFailure = const CameraFailure(
        CameraFailureCode.originalNotPersisted,
        detail: 'no-space',
      );
      await _tap(tester, find.text('Take test photo'));
      expect(find.text("The photo couldn't be saved"), findsOneWidget);
      expect(find.textContaining('CAMERA_ORIGINAL_NOT_SAVED'), findsOneWidget);
      expect(find.text('Test photo saved'), findsNothing);
      expect(find.textContaining('no-space'), findsNothing);
      // The camera is still usable.
      await _tap(tester, find.text('Take test photo'));
      expect(find.text('Test photo saved'), findsOneWidget);
    });

    testWidgets('a camera that fails to open says why and can be retried', (
      tester,
    ) async {
      final camera = SimulatedCameraService()
        ..initializeFailure = const CameraFailure(
          CameraFailureCode.cameraInUse,
        );
      await _openCameraTest(tester, camera: camera);
      expect(find.text('Another app is using the camera'), findsOneWidget);
      expect(find.textContaining('CAMERA_IN_USE'), findsOneWidget);
      expect(find.text('Not working'), findsOneWidget);
      await _tap(tester, find.text('Try again'));
      expect(camera.status.isReady, isTrue);
      expect(_preview(mirrored: true), findsOneWidget);
    });

    testWidgets('offers only built-in lenses and switches between them', (
      tester,
    ) async {
      final booth = await _openCameraTest(tester);
      expect(find.text('Front camera'), findsWidgets);
      expect(find.text('Rear camera'), findsWidgets);
      await _tap(tester, find.text('Rear camera').first);
      expect(booth.camera.status.request?.cameraId, rearCamera.id);
      expect(find.text('Zoom 1.0–5.0×'), findsOneWidget);
    });

    testWidgets('a single-lens tablet says so and uses the lens it has', (
      tester,
    ) async {
      final booth = await _openCameraTest(
        tester,
        camera: SimulatedCameraService(
          cameras: const [
            rearCamera,
            CameraDescriptor(
              id: 'usb',
              lens: CameraLens.external,
              sensorOrientationDegrees: 0,
            ),
          ],
        ),
      );
      expect(find.text('This tablet has only a rear camera.'), findsOneWidget);
      expect(booth.camera.status.request?.cameraId, rearCamera.id);
      expect(find.text('External camera'), findsNothing);
    });

    testWidgets('preview and saved-photo mirroring are independent and '
        'recorded with the photo', (tester) async {
      final booth = await _openCameraTest(tester);
      await _tap(tester, find.text('Mirror the live preview'));
      expect(_preview(mirrored: false), findsOneWidget);
      expect(find.text('True preview'), findsOneWidget);
      await _tap(tester, find.text('Mirror saved photos'));
      expect(booth.camera.status.request?.mirrorOutput, isTrue);
      expect(booth.camera.status.request?.mirrorPreview, isFalse);

      await _tap(tester, find.text('Take test photo'));
      final still = booth.stills.stills.single;
      expect(still.mirrorPreviewRequested, isFalse);
      expect(still.mirrorOutputRequested, isTrue);
      expect(find.text('Mirrored'), findsOneWidget);
      // The booth's defaults for new events are untouched.
      final defaults = (await booth.settings.load()).profile.defaults;
      expect(defaults.mirrorPreview, isTrue);
      expect(defaults.mirrorOutput, isFalse);
    });

    testWidgets('earlier test photos survive and are checked again; a '
        'damaged one says so', (tester) async {
      final store = SimulatedStillStore();
      DateTime at(int minute) => DateTime.utc(2026, 11, 14, 18, minute);
      final older = store.commit(
        lens: CameraLens.back,
        sensorOrientationDegrees: 90,
        mirrorPreview: false,
        mirrorOutput: false,
        capturedAtUtc: at(1),
        origin: CaptureOrigin.diagnostics,
      );
      store
        ..commit(
          lens: CameraLens.front,
          sensorOrientationDegrees: 270,
          mirrorPreview: true,
          mirrorOutput: false,
          capturedAtUtc: at(2),
        )
        ..commit(
          lens: CameraLens.front,
          sensorOrientationDegrees: 270,
          mirrorPreview: true,
          mirrorOutput: false,
          capturedAtUtc: at(3),
          origin: CaptureOrigin.diagnostics,
        )
        ..damage(older);

      await _openCameraTest(
        tester,
        camera: SimulatedCameraService(store: store),
      );
      expect(find.text('Earlier test photos'), findsOneWidget);
      expect(find.text('Intact'), findsOneWidget);
      expect(find.text('Missing or changed'), findsOneWidget);
      expect(
        find.textContaining('Rear camera · 64 × 48'),
        findsOneWidget,
        reason: 'guest photos are not listed here',
      );
    });

    testWidgets('fits a portrait tablet', (tester) async {
      await _openCameraTest(tester, viewport: TabletViewport.ipadPortrait);
      expect(tester.takeException(), isNull);
      expect(_preview(mirrored: true), findsOneWidget);
      await _tap(tester, find.text('Take test photo'));
      expect(find.text('Test photo saved'), findsOneWidget);
    });
  });

  group('Diagnostics', () {
    testWidgets('the self-test measures each check without asking for or '
        'opening anything', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final booth = await pumpApp(tester, location: RoutePaths.diagnostics);
      expect(find.text('Not run'), findsNWidgets(3));

      await _tap(tester, find.text('Run self-test'));
      expect(find.text('Passed'), findsNWidgets(3));
      expect(find.text('Allowed · front and rear cameras.'), findsOneWidget);
      expect(
        find.textContaining('A test file was written, read back and removed'),
        findsOneWidget,
      );
      expect(
        find.text('64.0 GB free · room for about 1638 guest sessions.'),
        findsOneWidget,
      );
      expect(find.textContaining('Last run'), findsOneWidget);

      booth.camera.systemPermission = CameraPermission.permanentlyDenied;
      booth.space.free = 500 * 1024 * 1024;
      await _tap(tester, find.text('Run again'));
      expect(find.text('Problem'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(
        find.textContaining('Turned off. Open Settings > Apps'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Only 500 MB free; the booth needs at least 1.0 GB',
        ),
        findsOneWidget,
      );
      expect(booth.camera.prompts, 0);
      expect(booth.camera.initializations, 0);
    });

    testWidgets('free space the tablet will not report is a problem with a '
        'repair', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      final booth = await pumpApp(
        tester,
        location: RoutePaths.diagnostics,
        environment: releaseIpad,
        space: FakeDeviceStorage(free: null),
      );
      booth.camera.cameras = const [];
      await _tap(tester, find.text('Run self-test'));
      expect(find.text('Problem'), findsNWidgets(2));
      expect(
        find.textContaining('Settings > General > iPad Storage'),
        findsOneWidget,
      );
      expect(
        find.text('The tablet reports no built-in camera.'),
        findsOneWidget,
      );
    });

    testWidgets('reaches the camera test from Diagnostics and Settings', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(tester, location: RoutePaths.diagnostics);
      await _tap(tester, find.text('Camera test'));
      expect(find.byType(CameraTestScreen), findsOneWidget);
      await _tap(tester, find.text('Back'));
      expect(find.text('Self-test'), findsOneWidget);

      await pumpApp(tester, location: '/studio/settings?section=camera');
      expect(find.text('Front and rear'), findsOneWidget);
      expect(find.text('Highest'), findsOneWidget);
      await _tap(tester, find.text('Camera test'));
      expect(find.byType(CameraTestScreen), findsOneWidget);
    });

    testWidgets('release builds keep the camera test, never the developer '
        'tools', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(
        tester,
        location: RoutePaths.cameraTest,
        environment: releaseIpad,
      );
      expect(find.byType(CameraTestScreen), findsOneWidget);
    });
  });
}
