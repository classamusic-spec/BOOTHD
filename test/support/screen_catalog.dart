import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/session/guest_flow.dart';
import 'package:porcelain_photo_booth/features/booth/booth_copy.dart';
import 'package:porcelain_photo_booth/features/booth/guest_camera_stage.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';
import 'package:porcelain_photo_booth/features/booth/guest_review.dart';
import 'package:porcelain_photo_booth/features/booth/hidden_operator_exit.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_canvas.dart';
import 'package:porcelain_photo_booth/features/template_studio/layers_panel.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/shared/gallery/gallery_copy.dart';
import 'package:porcelain_photo_booth/shared/operator_access/access_copy.dart';

import 'app_harness.dart';
import 'fake_export.dart';
import 'fake_gallery.dart';
import 'gallery_seed.dart';
import 'seed.dart';
import 'simulated_camera.dart';
import 'tablet_viewports.dart';

/// How to reach a screen.
final class ScreenSpec {
  const ScreenSpec(
    this.location, {
    this.startAs = StartAs.operator,
    this.seeded = false,
    this.library = false,
    this.renders = false,
    this.boothEventId,
    this.camera,
    this.event,
    this.then,
    this.session,
    this.gallery,
  });

  final String location;
  final StartAs startAs;

  /// Start with templates and an active, a draft and an archived event.
  final bool seeded;

  /// Start with the five designs in the template library.
  final bool library;

  /// The screen draws templates with the print renderer, which runs in
  /// real time (settleRendering) before the screen settles.
  final bool renders;
  final String? boothEventId;

  /// The simulated camera, when the screen needs a particular one.
  final SimulatedCameraService Function()? camera;

  /// Adjusts the seeded active event, e.g. its theme or retake policy.
  final BoothEvent Function(BoothEvent event)? event;

  /// Steps after the app starts, e.g. to reach a later setup step.
  final Future<void> Function(WidgetTester tester)? then;

  /// Steps of a guest session, with the fakes behind the booth.
  final Future<void> Function(WidgetTester tester, TestBooth booth)? session;

  /// Gallery sessions to add before the app starts, with their finished
  /// photos' bytes registered in [exports].
  final Future<void> Function(BoothDatabase db, FakeExportService exports)?
  gallery;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _toPrivacyStep(WidgetTester tester) => _tap(tester, 'Begin setup');

Future<void> _toPinStep(WidgetTester tester) async {
  await _toPrivacyStep(tester);
  await _tap(tester, 'Continue');
}

Future<void> _toRecoveryStep(WidgetTester tester) async {
  await _toPinStep(tester);
  await enterPin(tester, testPin);
  await enterPin(tester, testPin);
}

Future<void> _toBoothStep(WidgetTester tester) async {
  await _toRecoveryStep(tester);
  await _tap(tester, AccessCopy.recoveryCodeStored);
  await _tap(tester, 'Continue');
}

/// The editor tabs, by their `tab` query value.
const editorTabs = [
  'general',
  'templates',
  'capture',
  'guest',
  'output',
  'privacy',
];

/// Every implemented screen, by name.
final screens = <String, ScreenSpec>{
  'dashboard': const ScreenSpec(RoutePaths.dashboard),
  'dashboard with events': const ScreenSpec(RoutePaths.dashboard, seeded: true),
  'events': const ScreenSpec('/studio/events', seeded: true),
  'events empty': const ScreenSpec('/studio/events'),
  for (final tab in editorTabs)
    'event $tab': ScreenSpec(
      RoutePaths.event(SeedIds.active, tab: tab),
      seeded: true,
      renders: tab == 'templates',
    ),
  'event draft': ScreenSpec(RoutePaths.event(SeedIds.draft), seeded: true),
  'event archived': ScreenSpec(
    RoutePaths.event(SeedIds.archived),
    seeded: true,
  ),
  'new event': const ScreenSpec(RoutePaths.newEvent),
  'new event templates empty': const ScreenSpec(
    '${RoutePaths.newEvent}?tab=templates',
  ),
  'preflight': ScreenSpec(RoutePaths.preflight(SeedIds.active), seeded: true),
  'preflight draft': ScreenSpec(
    RoutePaths.preflight(SeedIds.draft),
    seeded: true,
  ),
  'templates': const ScreenSpec('/studio/templates'),
  'templates library': const ScreenSpec(
    '/studio/templates',
    library: true,
    renders: true,
  ),
  'new template': ScreenSpec(
    '/studio/templates',
    library: true,
    renders: true,
    then: (tester) async {
      await _tap(tester, 'New template');
      await settleRendering(tester, rounds: 10);
      await tester.pumpAndSettle();
    },
  ),
  'template editor': ScreenSpec(
    RoutePaths.templateEditor(SeedIds.floralTemplate),
    library: true,
    renders: true,
  ),
  'template editor selected': ScreenSpec(
    RoutePaths.templateEditor(SeedIds.floralTemplate),
    library: true,
    renders: true,
    then: (tester) async {
      tester
          .widget<EditorCanvas>(find.byType(EditorCanvas))
          .controller
          .select('blossoms-top');
      await tester.pumpAndSettle();
    },
  ),
  'template editor layers': ScreenSpec(
    RoutePaths.templateEditor(SeedIds.floralTemplate),
    library: true,
    renders: true,
    then: (tester) async {
      await tester.tap(find.bySemanticsLabel('Layers').last);
      await tester.pumpAndSettle();
      expect(find.byType(LayersPanel), findsOneWidget);
    },
  ),
  'template preview': ScreenSpec(
    RoutePaths.templatePreview(SeedIds.floralTemplate),
    library: true,
    renders: true,
  ),
  'gallery': const ScreenSpec('/studio/gallery'),
  'gallery sessions': const ScreenSpec(
    RoutePaths.gallery,
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
  ),
  'gallery select': ScreenSpec(
    RoutePaths.gallery,
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
    then: (tester) async {
      await _tap(tester, GalleryCopy.select);
      await _tapSession(tester, 18);
      await _tapSession(tester, 17);
    },
  ),
  'gallery export': ScreenSpec(
    RoutePaths.gallery,
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
    then: (tester) async {
      await _tap(tester, GalleryCopy.select);
      await _tapSession(tester, 18);
      await _tapSession(tester, 15);
      await _tap(tester, GalleryCopy.export);
    },
  ),
  'gallery export report': ScreenSpec(
    RoutePaths.gallery,
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
    then: (tester) async {
      await _tap(tester, GalleryCopy.select);
      await _tapSession(tester, 18);
      await _tapSession(tester, 15);
      await _tap(tester, GalleryCopy.export);
      await _tap(tester, GalleryCopy.chooseDestination);
    },
  ),
  'gallery delete': ScreenSpec(
    RoutePaths.gallery,
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
    then: (tester) async {
      await _tap(tester, GalleryCopy.select);
      await _tapSession(tester, 18);
      await _tap(tester, GalleryCopy.deleteConfirm);
    },
  ),
  'gallery retention': ScreenSpec(
    RoutePaths.gallery,
    seeded: true,
    renders: true,
    event: (event) =>
        event.copyWith(retention: const RetentionPolicy.deleteAfterDays(30)),
    gallery: (db, exports) async {
      await seedGallery(
        db,
        count: 4,
        firstStart: DateTime.utc(2026, 8, 22, 19),
        outputBytes: printStandIn,
      );
      await seedGallery(
        db,
        count: 4,
        firstNumber: 5,
        firstStart: DateTime.utc(2026, 10, 17, 19),
        outputBytes: printStandIn,
      );
      await _registerOutputs(db, exports);
    },
  ),
  'gallery search': ScreenSpec(
    RoutePaths.gallery,
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
    then: (tester) async {
      await _scrollTo(tester, find.byType(EditableText));
      await tester.enterText(find.byType(EditableText).first, '#12');
      await tester.pumpAndSettle();
      await settleRendering(tester, rounds: 4);
      await tester.pumpAndSettle();
    },
  ),
  'session detail': ScreenSpec(
    RoutePaths.gallerySession(GalleryIds.session(8)),
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
  ),
  'session detail not finished': ScreenSpec(
    RoutePaths.gallerySession(GalleryIds.session(5)),
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
  ),
  'session detail failed': ScreenSpec(
    RoutePaths.gallerySession(GalleryIds.session(3)),
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
  ),
  'events archived': ScreenSpec(
    '/studio/events',
    seeded: true,
    then: (tester) => _tap(tester, 'Archived · 1'),
  ),
  'settings': const ScreenSpec('/studio/settings'),
  'settings appearance': const ScreenSpec(
    '/studio/settings?section=appearance',
  ),
  'settings camera': const ScreenSpec('/studio/settings?section=camera'),
  'settings output': const ScreenSpec('/studio/settings?section=output'),
  'settings storage': const ScreenSpec(
    '/studio/settings?section=storage',
    seeded: true,
    gallery: _gallerySessions,
  ),
  'settings booth': const ScreenSpec('/studio/settings?section=booth'),
  'settings about': const ScreenSpec('/studio/settings?section=about'),
  'diagnostics': const ScreenSpec('/studio/diagnostics'),
  'diagnostics self-test': ScreenSpec(
    '/studio/diagnostics',
    then: (tester) => _tap(tester, 'Run self-test'),
  ),
  'camera test': const ScreenSpec(RoutePaths.cameraTest),
  'camera test permission': ScreenSpec(
    RoutePaths.cameraTest,
    camera: () => SimulatedCameraService(
      systemPermission: CameraPermission.notDetermined,
    ),
  ),
  'camera test refused': ScreenSpec(
    RoutePaths.cameraTest,
    camera: () => SimulatedCameraService(
      systemPermission: CameraPermission.permanentlyDenied,
    ),
  ),
  'camera test saved': ScreenSpec(
    RoutePaths.cameraTest,
    then: (tester) async {
      await _tap(tester, 'Take test photo');
      await settleRendering(tester);
      await tester.pumpAndSettle();
    },
  ),
  'guest preview': const ScreenSpec('/preview/guest-welcome'),
  'not found': ScreenSpec(
    RoutePaths.dashboard,
    then: (tester) async {
      routerOf(tester).go('/no-such-page');
      await tester.pumpAndSettle();
    },
  ),
  'component gallery': const ScreenSpec('/dev/components'),
  'setup welcome': const ScreenSpec('/', startAs: StartAs.setup),
  'setup privacy': const ScreenSpec(
    '/',
    startAs: StartAs.setup,
    then: _toPrivacyStep,
  ),
  'setup pin': const ScreenSpec('/', startAs: StartAs.setup, then: _toPinStep),
  'setup recovery code': const ScreenSpec(
    '/',
    startAs: StartAs.setup,
    then: _toRecoveryStep,
  ),
  'setup booth': const ScreenSpec(
    '/',
    startAs: StartAs.setup,
    then: _toBoothStep,
  ),
  'unlock': const ScreenSpec('/', startAs: StartAs.locked),
  'unlock recovery': ScreenSpec(
    '/',
    startAs: StartAs.locked,
    then: (tester) => _tap(tester, AccessCopy.forgotPin),
  ),
  'booth welcome': const ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
  ),
  'booth operator': const ScreenSpec(
    RoutePaths.boothOperator,
    startAs: StartAs.booth,
    seeded: true,
    boothEventId: SeedIds.active,
  ),
};

/// Booth Mode guest sessions (M07), in the booth's own theme as on the
/// reference boards unless the name says otherwise.
final boothSessionScreens = <String, ScreenSpec>{
  'booth template choice': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: (event) => _porcelain(event).copyWith(
      guest: _porcelain(event).guest.copyWith(guestChoosesTemplate: true),
    ),
    session: (tester, booth) async {
      await _start(tester);
      await settleRendering(tester, rounds: 10);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(BoothCopy.chooseTitle), findsOneWidget);
    },
  ),
  'booth get ready': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      await _start(tester);
      expect(find.byType(GuestCameraStage), findsOneWidget);
    },
  ),
  'booth get ready dark': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    session: (tester, booth) async {
      await _start(tester);
      expect(find.byType(GuestCameraStage), findsOneWidget);
    },
  ),
  'booth snap': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      booth.camera.captureGate = Completer<void>();
      await _start(tester);
      await _countdown(tester);
      // Part-way through the flash.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(BoothCopy.snap), findsOneWidget);
    },
  ),
  'booth photo saved': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      await _start(tester);
      await _countdown(tester);
      await _settlePhotos(tester);
      expect(find.text(BoothCopy.nextPhotoSoon), findsOneWidget);
    },
  ),
  'booth review': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      await _toReview(tester);
      await _settlePhotos(tester);
      expect(find.byType(GuestReview), findsOneWidget);
    },
  ),
  'booth review retake all': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: (event) => _porcelain(event).copyWith(
      capture: event.capture.copyWith(retakePolicy: RetakePolicy.wholeSession),
    ),
    session: (tester, booth) async {
      await _toReview(tester);
      await _press(tester, BoothCopy.retakeAll);
      await _settlePhotos(tester);
      expect(find.text(BoothCopy.confirmRetakeTitle), findsOneWidget);
    },
  ),
  'booth creating': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      booth.exports.gate = Completer<void>();
      await _toReview(tester);
      await _press(tester, BoothCopy.keepThese);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(BoothCopy.creatingTitle), findsOneWidget);
    },
  ),
  'booth finished': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      await _toReview(tester);
      await _press(tester, BoothCopy.keepThese);
      await tester.pump();
      await _settlePhotos(tester);
      expect(find.byType(GuestFinished), findsOneWidget);
    },
  ),
  'booth finished dark': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    session: (tester, booth) async {
      await _toReview(tester);
      await _press(tester, BoothCopy.keepThese);
      await tester.pump();
      await _settlePhotos(tester);
      expect(find.byType(GuestFinished), findsOneWidget);
    },
  ),
  'booth paused': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      await _start(tester);
      await _countdown(tester);
      await _settlePhotos(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text(BoothCopy.pausedTitle), findsOneWidget);
    },
  ),
  'booth problem': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      booth.camera.initializeFailure = const CameraFailure(
        CameraFailureCode.cameraUnavailable,
      );
      await _start(tester);
      await tester.pumpAndSettle();
      expect(
        find.text(BoothCopy.problem(GuestProblemKind.camera).$1),
        findsOneWidget,
      );
    },
  ),
  'booth operator problem': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) async {
      booth.camera.initializeFailure = const CameraFailure(
        CameraFailureCode.cameraUnavailable,
      );
      await _start(tester);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HiddenOperatorExit)),
      );
      await tester.pump(const Duration(milliseconds: 3100));
      await gesture.up();
      await tester.pumpAndSettle();
      await enterPin(tester, testPin);
      expect(find.text(BoothOperatorCopy.lastProblemTitle), findsOneWidget);
    },
  ),
};

/// The seeded event in the booth's own theme (Porcelain Studio).
BoothEvent _porcelain(BoothEvent event) =>
    event.copyWith(guest: event.guest.copyWith(themeOverride: null));

/// Taps the guest control [label], scrolled into view first (large text
/// can push it below the fold).
Future<void> _press(WidgetTester tester, String label) async {
  final control = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(control);
  await tester.pump();
  await tester.tap(control);
}

/// Start on the welcome, then the camera opens and the countdown shows 3.
Future<void> _start(WidgetTester tester) async {
  await _press(tester, 'Start');
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// The rest of a three-second countdown, to the photo.
Future<void> _countdown(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

/// Both photos of the seeded event, to the review.
Future<void> _toReview(WidgetTester tester) async {
  await _start(tester);
  await _countdown(tester);
  // The pause between photos, then the second countdown.
  await tester.pump(const Duration(seconds: 3));
  await _countdown(tester);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Decodes the photos on screen (real time) and lets the screen settle.
Future<void> _settlePhotos(WidgetTester tester) async {
  await settleRendering(tester, rounds: 4);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Eighteen sessions of the seeded wedding, the evening before the test
/// clock: print-ready finished photos, retakes, a failed render, sessions
/// the guest left and one waiting to be finished.
Future<void> _gallerySessions(
  BoothDatabase db,
  FakeExportService exports,
) async {
  await seedGallery(
    db,
    count: 18,
    firstStart: DateTime.utc(2026, 10, 17, 19),
    outputBytes: printStandIn,
  );
  await _registerOutputs(db, exports);
}

/// The finished photos' bytes, readable through the stand-in export.
Future<void> _registerOutputs(
  BoothDatabase db,
  FakeExportService exports,
) async {
  for (final output in await db.select(db.sessionOutputs).get()) {
    exports.files[output.relativePath] = printStandIn;
  }
}

/// The gallery page's own scroll view (not the event row's).
Finder get _galleryScroll => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

/// Scrolls the gallery until [target] is built and on screen.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 200, scrollable: _galleryScroll);
  await tester.pumpAndSettle();
}

/// Taps the gallery tile of session [number].
Future<void> _tapSession(WidgetTester tester, int number) async {
  final tile = find.byKey(ValueKey(GalleryIds.session(number)));
  await _scrollTo(tester, tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

/// The component gallery shows a spinner and skeleton that never settle.
bool settles(String name) => name != 'component gallery';

/// Starts the app and brings up the screen called [name].
Future<void> show(
  WidgetTester tester,
  String name, {
  TabletViewport viewport = TabletViewport.ipadLandscape,
  AppearanceSettings appearance = const AppearanceSettings(),
  double pixelRatio = 2,
}) async {
  final spec = screens[name] ?? boothSessionScreens[name]!;
  useViewport(tester, viewport, pixelRatio: pixelRatio);
  final exports = FakeExportService();
  final booth = await pumpApp(
    tester,
    location: spec.location,
    appearance: appearance,
    startAs: spec.startAs,
    boothEventId: spec.boothEventId,
    exports: exports,
    seed: spec.seeded
        ? (db) async {
            await seedEvents(db, active: spec.event);
            await spec.gallery?.call(db, exports);
          }
        : null,
    seedTemplates: spec.library
        ? seedStarterLibrary
        : spec.seeded
        ? seedTemplateDocuments
        : null,
    camera: spec.camera?.call(),
    settle: settles(name) && !spec.renders,
  );
  if (spec.renders) {
    await settleRendering(tester, rounds: 10);
    await tester.pumpAndSettle();
  }
  if (!settles(name)) await tester.pump(const Duration(seconds: 1));
  await spec.then?.call(tester);
  await spec.session?.call(tester, booth);
}
