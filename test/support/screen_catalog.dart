import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/features/booth/booth_copy.dart';
import 'package:porcelain_photo_booth/features/template_studio/editor_canvas.dart';
import 'package:porcelain_photo_booth/features/template_studio/layers_panel.dart';
import 'package:porcelain_photo_booth/shared/operator_access/access_copy.dart';

import 'app_harness.dart';
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
  'settings': const ScreenSpec('/studio/settings'),
  'settings appearance': const ScreenSpec(
    '/studio/settings?section=appearance',
  ),
  'settings camera': const ScreenSpec('/studio/settings?section=camera'),
  'settings output': const ScreenSpec('/studio/settings?section=output'),
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
    },
  ),
  'booth get ready': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _porcelain,
    session: (tester, booth) => _start(tester),
  ),
  'booth get ready dark': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    session: (tester, booth) => _start(tester),
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
      await tester.tap(find.bySemanticsLabel(BoothCopy.retakeAll));
      await _settlePhotos(tester);
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
      await tester.tap(find.bySemanticsLabel(BoothCopy.keepThese));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
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
      await tester.tap(find.bySemanticsLabel(BoothCopy.keepThese));
      await tester.pump();
      await _settlePhotos(tester);
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
      await tester.tap(find.bySemanticsLabel(BoothCopy.keepThese));
      await tester.pump();
      await _settlePhotos(tester);
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
    },
  ),
};

/// The seeded event in the booth's own theme (Porcelain Studio).
BoothEvent _porcelain(BoothEvent event) =>
    event.copyWith(guest: event.guest.copyWith(themeOverride: null));

/// Start on the welcome, then the camera opens and the countdown shows 3.
Future<void> _start(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Start'));
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
  final booth = await pumpApp(
    tester,
    location: spec.location,
    appearance: appearance,
    startAs: spec.startAs,
    boothEventId: spec.boothEventId,
    seed: spec.seeded ? (db) => seedEvents(db, active: spec.event) : null,
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
