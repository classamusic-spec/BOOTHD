// AC-0701, AC-0703, AC-0705 to AC-0707, AC-0709 and the layout half of
// AC-0708, end to end on the simulated camera with a fast stand-in export:
// guests go from Start to the next guest with no operator, in portrait and
// landscape at every tablet size; they can never leave Booth Mode or reach
// another guest's photos; "saved" appears only once the finished photo is
// verified; problems are guest-safe; an unfinished finished photo is made
// after a restart; and the welcome that follows shows nothing of the last
// guest. Device runs are BLOCKED until hardware is available (M07 device
// procedure); nothing here stands in for them.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/booth/booth_providers.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/export_service.dart';
import 'package:porcelain_photo_booth/domain/session/guest_flow.dart';
import 'package:porcelain_photo_booth/features/booth/booth_copy.dart';
import 'package:porcelain_photo_booth/features/booth/booth_operator_screen.dart';
import 'package:porcelain_photo_booth/features/booth/booth_screen.dart';
import 'package:porcelain_photo_booth/features/booth/guest_camera_stage.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';
import 'package:porcelain_photo_booth/features/booth/guest_parts.dart';
import 'package:porcelain_photo_booth/features/booth/guest_review.dart';
import 'package:porcelain_photo_booth/features/booth/hidden_operator_exit.dart';
import 'package:porcelain_photo_booth/features/studio_shell/studio_shell.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';

import '../support/app_harness.dart';
import '../support/fake_export.dart';
import '../support/seed.dart';
import '../support/simulated_camera.dart';
import '../support/tablet_viewports.dart';
import '../support/test_database.dart';
import 'guest_isolation_test.dart' show actionable, forbiddenWords;

Future<TestBooth> _booth(
  WidgetTester tester, {
  TabletViewport viewport = TabletViewport.ipadPortrait,
  BoothEvent Function(BoothEvent event)? event,
  AppearanceSettings appearance = const AppearanceSettings(),
  BoothDatabase? database,
  SimulatedCameraService? camera,
  FakeExportService? exports,
}) async {
  useViewport(tester, viewport);
  return pumpApp(
    tester,
    startAs: StartAs.booth,
    boothEventId: SeedIds.active,
    appearance: appearance,
    database: database,
    alreadySetUp: database != null,
    seed: database == null ? (db) => seedEvents(db, active: event) : null,
    seedTemplates: seedTemplateDocuments,
    camera: camera,
    exports: exports,
  );
}

/// A few frames, so taps, the database and the camera can do their work.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(label).last);
  await _frames(tester);
}

/// Three seconds of countdown, to the photo saved.
Future<void> _countdown(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await _frames(tester);
}

/// Start, two photos, to the review.
Future<void> _toReview(WidgetTester tester) async {
  await _tap(tester, 'Start');
  await _countdown(tester);
  await tester.pump(const Duration(seconds: 3));
  await _countdown(tester);
  expect(find.byType(GuestReview), findsOneWidget);
}

/// Labels of the controls a guest can use now (the hidden corner is not
/// one: it is outside the accessibility tree).
List<String> _controls(WidgetTester tester) => [
  for (final node in actionable(tester.getSemantics(find.byType(BoothScreen))))
    node.label,
];

/// The booth's one guest session so far.
Future<SessionRecord> _only(TestBooth booth) async {
  final rows = await booth.db.select(booth.db.captureSessions).get();
  expect(rows, hasLength(1));
  return (await booth.sessions.find(rows.single.id))!;
}

/// The image a widget shows, without any resizing wrapper.
ImageProvider<Object> _unwrap(ImageProvider<Object> image) =>
    image is ResizeImage ? _unwrap(image.imageProvider) : image;

void main() {
  for (final viewport in TabletViewport.values) {
    testWidgets('a guest goes from Start to the next guest with no operator '
        'at ${viewport.name} (AC-0701, AC-0709)', (tester) async {
      final semantics = tester.ensureSemantics();
      final booth = await _booth(tester, viewport: viewport);
      expect(_controls(tester), ['Start']);

      await _tap(tester, 'Start');
      expect(find.byType(GuestCameraStage), findsOneWidget);
      expect(
        find.bySemanticsLabel(BoothCopy.countdownLabel(3)),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(BoothCopy.photoOf(1, 2)), findsWidgets);
      expect(_controls(tester), isEmpty, reason: 'guests only pose');
      expect(find.bySemanticsLabel('Simulated preview, mirrored'), findsOne);

      await _countdown(tester);
      expect(find.text(BoothCopy.nextPhotoSoon), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await _countdown(tester);

      expect(find.byType(GuestReview), findsOneWidget);
      expect(_controls(tester), [
        BoothCopy.retake,
        BoothCopy.retake,
        BoothCopy.keepThese,
      ]);
      expect(find.text(BoothCopy.retakesLeft(1)), findsNWidgets(2));
      expect(find.text(BoothCopy.savedToGallery), findsNothing);

      await _tap(tester, BoothCopy.keepThese);
      expect(find.byType(GuestFinished), findsOneWidget);
      expect(find.text(BoothCopy.readyTitle), findsOneWidget);
      expect(find.text(BoothCopy.savedToGallery), findsOneWidget);
      expect(_controls(tester), [BoothCopy.nextGuest]);
      expect(
        find.textContaining(RegExp('print', caseSensitive: false)),
        findsNothing,
      );
      final record = await _only(booth);
      expect(record.status, SessionStatus.completed);
      final finished = booth.exports.files.values.single;

      await _tap(tester, BoothCopy.nextGuest);
      expect(_controls(tester), ['Start']);
      expect(find.byType(GuestFinished), findsNothing);
      expect(find.byType(GuestPhoto), findsNothing);
      final shown = [
        for (final image in tester.widgetList<Image>(find.byType(Image)))
          _unwrap(image.image),
      ];
      final last = <Object>[finished, ...booth.stills.stills.map((s) => s.id)];
      expect(
        shown.whereType<MemoryImage>().where(
          (image) => image.bytes == finished,
        ),
        isEmpty,
        reason: 'nothing of the last guest on the welcome: $last',
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('guests cannot leave Booth Mode or reach Studio, the gallery '
      'or a share sheet during a session (AC-0706)', (tester) async {
    final semantics = tester.ensureSemantics();
    final booth = await _booth(tester);
    await _tap(tester, 'Start');

    Future<void> tryToLeave() async {
      expect(await tester.binding.handlePopRoute(), isTrue);
      await _frames(tester);
      for (final location in [
        RoutePaths.dashboard,
        RoutePaths.gallery,
        RoutePaths.templates,
        RoutePaths.settings,
        RoutePaths.diagnostics,
        RoutePaths.cameraTest,
        RoutePaths.guestPreview,
        RoutePaths.boothOperator,
      ]) {
        booth.router.go(location);
        await _frames(tester);
        if (location == RoutePaths.boothOperator) {
          // Only the PIN screen, and it never shows the Studio.
          expect(find.byType(StudioShell), findsNothing);
          booth.router.go(RoutePaths.booth);
          await _frames(tester);
        }
        expect(find.byType(BoothScreen), findsOneWidget, reason: location);
        expect(find.byType(StudioShell), findsNothing, reason: location);
      }
    }

    await tryToLeave();
    await _countdown(tester);
    await tester.pump(const Duration(seconds: 3));
    await _countdown(tester);
    expect(find.byType(GuestReview), findsOneWidget);
    await tryToLeave();
    for (final label in _controls(tester)) {
      expect(forbiddenWords.hasMatch(label), isFalse, reason: label);
    }
    await _tap(tester, BoothCopy.keepThese);
    for (final label in _controls(tester)) {
      expect(forbiddenWords.hasMatch(label), isFalse, reason: label);
    }
    expect(booth.files.shared, isEmpty);
    expect(booth.files.picks, isEmpty);
    expect(booth.accessState.boothEventId, SeedIds.active);
    semantics.dispose();
  });

  testWidgets("the operator's hidden hold ends the session first, then "
      'asks for the PIN', (tester) async {
    final booth = await _booth(tester);
    await _toReview(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HiddenOperatorExit)),
    );
    await tester.pump(const Duration(milliseconds: 3100));
    await gesture.up();
    await _frames(tester);
    expect(find.byType(BoothOperatorScreen), findsOneWidget);
    final record = await _only(booth);
    expect(record.status, SessionStatus.abandoned);
    expect(record.endReason, SessionEndReason.operatorExit);
    expect(record.photos, hasLength(2), reason: 'the photos are kept');

    await _tap(tester, 'Back to the guest screen');
    expect(find.bySemanticsLabel('Start'), findsOneWidget);
    expect(find.byType(GuestReview), findsNothing);
  });

  testWidgets('the operator, not the guest, sees what went wrong; leaving '
      'Booth Mode clears it', (tester) async {
    final camera = SimulatedCameraService()
      ..initializeFailure = const CameraFailure(
        CameraFailureCode.cameraUnavailable,
      );
    final booth = await _booth(tester, camera: camera);
    await _tap(tester, 'Start');
    final code = CameraFailureCode.cameraUnavailable.diagnostic;
    expect(find.textContaining(code), findsNothing, reason: 'not to guests');

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HiddenOperatorExit)),
    );
    await tester.pump(const Duration(milliseconds: 3100));
    await gesture.up();
    await _frames(tester);
    expect(find.text(BoothOperatorCopy.lastProblemTitle), findsNothing);
    await enterPin(tester, testPin);
    expect(find.text(BoothOperatorCopy.lastProblemTitle), findsOneWidget);
    expect(
      find.text(BoothOperatorCopy.problem(GuestProblemKind.camera)),
      findsOneWidget,
    );
    expect(find.textContaining(code), findsOneWidget);

    await _tap(tester, 'Exit Booth Mode');
    expect(find.byType(StudioShell), findsOneWidget);
    expect(booth.container.read(lastGuestProblemProvider), isNull);
  });

  testWidgets('the guest picks a template, and that revision is used', (
    tester,
  ) async {
    final booth = await _booth(
      tester,
      event: (event) => event.copyWith(
        guest: event.guest.copyWith(guestChoosesTemplate: true),
      ),
    );
    await _tap(tester, 'Start');
    expect(find.bySemanticsLabel(BoothCopy.chooseTitle), findsOneWidget);
    await _frames(tester);
    expect(_controls(tester), [
      'Two-up classic',
      'Retro strip',
      BoothCopy.continueLabel,
    ]);
    await _tap(tester, 'Retro strip');
    await _tap(tester, BoothCopy.continueLabel);
    expect(find.byType(GuestCameraStage), findsOneWidget);
    final record = await _only(booth);
    expect(record.plan.templateRevisionId, TestIds.revisionB1);
  });

  testWidgets('a retake from the review is a new photo; the count of '
      'retakes left goes down (AC-0703)', (tester) async {
    final booth = await _booth(tester);
    await _toReview(tester);
    await tester.tap(find.bySemanticsLabel(BoothCopy.retake).first);
    await _frames(tester);
    expect(find.byType(GuestCameraStage), findsOneWidget);
    expect(find.bySemanticsLabel(BoothCopy.retaking(1)), findsWidgets);
    await _countdown(tester);
    expect(find.byType(GuestReview), findsOneWidget);
    expect(find.text(BoothCopy.noRetakesLeft), findsOneWidget);
    expect(find.text(BoothCopy.retakesLeft(1)), findsOneWidget);
    expect(_controls(tester), [BoothCopy.retake, BoothCopy.keepThese]);
    expect(booth.stills.stills, hasLength(3), reason: 'every original kept');
    final record = await _only(booth);
    expect(record.shots.slotBindings.values, [
      booth.stills.stills[2].id,
      booth.stills.stills[1].id,
    ]);
  });

  testWidgets('retaking every photo asks first', (tester) async {
    await _booth(
      tester,
      event: (event) => event.copyWith(
        capture: event.capture.copyWith(
          retakePolicy: RetakePolicy.wholeSession,
        ),
      ),
    );
    await _toReview(tester);
    expect(_controls(tester), [BoothCopy.retakeAll, BoothCopy.keepThese]);
    await _tap(tester, BoothCopy.retakeAll);
    expect(find.text(BoothCopy.confirmRetakeTitle), findsOneWidget);
    await _tap(tester, BoothCopy.cancel);
    expect(find.text(BoothCopy.confirmRetakeTitle), findsNothing);
    expect(find.byType(GuestReview), findsOneWidget);

    await _tap(tester, BoothCopy.retakeAll);
    await tester.tap(find.bySemanticsLabel(BoothCopy.retakeAll).last);
    await _frames(tester);
    expect(find.byType(GuestCameraStage), findsOneWidget);
    expect(find.bySemanticsLabel(BoothCopy.photoOf(1, 2)), findsWidgets);
  });

  testWidgets('"Saved" appears only once the finished photo is verified '
      'and recorded (AC-0705)', (tester) async {
    final exports = FakeExportService()..gate = Completer<void>();
    final booth = await _booth(tester, exports: exports);
    await _toReview(tester);
    await _tap(tester, BoothCopy.keepThese);
    expect(find.text(BoothCopy.creatingTitle), findsOneWidget);
    expect(find.text(BoothCopy.savedToGallery), findsNothing);
    expect(_controls(tester), isEmpty, reason: 'nothing to cancel');
    expect((await _only(booth)).status, SessionStatus.rendering);

    exports.corruptNext = true;
    exports.gate!.complete();
    exports.gate = null;
    await _frames(tester);
    expect(find.text(BoothCopy.savedToGallery), findsNothing);
    expect(
      find.text(BoothCopy.problem(GuestProblemKind.render).$1),
      findsOneWidget,
    );
    expect(find.textContaining('EXPORT'), findsNothing, reason: 'no codes');

    await _tap(tester, BoothCopy.tryAgain);
    expect(find.text(BoothCopy.savedToGallery), findsOneWidget);
  });

  testWidgets('problems are told in plain words, with a way on', (
    tester,
  ) async {
    final camera = SimulatedCameraService()
      ..initializeFailure = const CameraFailure(
        CameraFailureCode.cameraUnavailable,
      );
    final booth = await _booth(tester, camera: camera);
    await _tap(tester, 'Start');
    final (title, body) = BoothCopy.problem(GuestProblemKind.camera);
    expect(find.text(title), findsOneWidget);
    expect(find.text(body), findsOneWidget);
    expect(find.textContaining('CAMERA_'), findsNothing);
    expect(_controls(tester), [BoothCopy.startOver, BoothCopy.tryAgain]);
    await _tap(tester, BoothCopy.tryAgain);
    expect(find.byType(GuestCameraStage), findsOneWidget);
    expect(booth.camera.initializations, 2);
  });

  testWidgets('a full tablet tells the guest to ask the host', (tester) async {
    final booth = await _booth(tester);
    booth.space.free = 10 * 1024 * 1024;
    await _tap(tester, 'Start');
    expect(
      find.text(BoothCopy.problem(GuestProblemKind.storage).$1),
      findsOneWidget,
    );
    expect(_controls(tester), [BoothCopy.done]);
    await _tap(tester, BoothCopy.done);
    expect(_controls(tester), ['Start']);
    expect(await booth.sessions.unfinished(), isEmpty);
  });

  testWidgets('a pause shows Welcome back, and nothing happens until the '
      'guest taps Continue (AC-0702)', (tester) async {
    final booth = await _booth(tester);
    await _tap(tester, 'Start');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await _frames(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester);
    expect(find.text(BoothCopy.pausedTitle), findsOneWidget);
    await tester.pump(const Duration(seconds: 20));
    expect(booth.camera.shutters, 0);
    expect(_controls(tester), [BoothCopy.continueLabel]);
    await _tap(tester, BoothCopy.continueLabel);
    expect(find.byType(GuestCameraStage), findsOneWidget);
    await _countdown(tester);
    expect(booth.camera.shutters, 1);
  });

  testWidgets('after a restart, a finished photo left unmade is made while '
      'the booth waits for guests (AC-0707)', (tester) async {
    final exports = FakeExportService()
      ..failure = const ExportFailure(ExportFailureCode.writeFailed);
    final first = await _booth(tester, exports: exports);
    await _toReview(tester);
    await _tap(tester, BoothCopy.keepThese);
    expect(
      find.text(BoothCopy.problem(GuestProblemKind.render).$1),
      findsOneWidget,
    );
    expect((await _only(first)).status, SessionStatus.rendering);

    // The app is closed and opened again in Booth Mode.
    final second = await pumpApp(
      tester,
      startAs: StartAs.booth,
      boothEventId: SeedIds.active,
      database: first.db,
      pins: first.pins,
      alreadySetUp: true,
      seedTemplates: seedTemplateDocuments,
      camera: first.camera,
    );
    await _frames(tester);
    expect(_controls(tester), ['Start'], reason: 'the welcome, not the error');
    final record = await _only(second);
    expect(record.status, SessionStatus.completed);
    expect(record.renderAttempts, 2);
    expect(record.photos, hasLength(2));
  });

  testWidgets('with reduced motion there is no flash', (tester) async {
    final camera = SimulatedCameraService()..captureGate = Completer<void>();
    await _booth(
      tester,
      camera: camera,
      appearance: const AppearanceSettings(motion: MotionPreference.reduced),
    );
    await _tap(tester, 'Start');
    await _countdown(tester);
    expect(find.text(BoothCopy.snap), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Flash'),
      findsNothing,
    );
    camera.captureGate!.complete();
    await _frames(tester);
  });

  testWidgets('with motion, a soft flash plays as the photo is taken', (
    tester,
  ) async {
    final camera = SimulatedCameraService()..captureGate = Completer<void>();
    await _booth(tester, camera: camera);
    await _tap(tester, 'Start');
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Flash'),
      findsOneWidget,
    );
    camera.captureGate!.complete();
    await _frames(tester);
  });
}
