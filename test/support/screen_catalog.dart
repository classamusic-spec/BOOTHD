import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/platform/app_environment.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/backup/backup_manifest.dart';
import 'package:porcelain_photo_booth/domain/delivery/consent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_intent.dart';
import 'package:porcelain_photo_booth/domain/delivery/delivery_settings.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/backup_service.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/kiosk_lock.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/domain/session/guest_flow.dart';
import 'package:porcelain_photo_booth/features/booth/booth_copy.dart';
import 'package:porcelain_photo_booth/features/booth/delivery_copy.dart';
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
import 'fake_backup.dart';
import 'fake_delivery.dart';
import 'fake_export.dart';
import 'fake_gallery.dart';
import 'fakes.dart';
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
    this.paired = false,
    this.offline = false,
    this.texts,
    this.backups,
    this.kiosk = KioskLock.none,
    this.environment = debugAndroid,
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

  /// The booth is paired with the (stand-in) delivery service, which is
  /// ready to send (M09).
  final bool paired;

  /// The delivery service cannot be reached.
  final bool offline;

  /// Texts guests asked for, stored before the app starts.
  final Future<void> Function(
    BoothDatabase db,
    FakeDeliveryApi api,
    MemoryDeliverySecrets secrets,
  )?
  texts;

  /// Backups and restores, when the screen needs a particular state (M10).
  final FakeBackupService Function()? backups;

  /// The kiosk lock the tablet reports (M10).
  final KioskLock kiosk;

  /// The platform, for screens that differ between iPad and Android.
  final AppEnvironment environment;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

/// A named kids' party at the new event's look step.
Future<void> _toNewEventLook(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, 'Spring fair');
  await tester.pumpAndSettle();
  await _tap(tester, 'Kids party');
  await _tap(tester, 'Next: choose the look');
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

Future<void> _toRestore(WidgetTester tester) =>
    _tap(tester, 'Restore from a backup');

/// Chooses a backup on the first screen; [FakeBackupService] checks it.
Future<void> _chooseBackup(WidgetTester tester, TestBooth booth) async {
  await _toRestore(tester);
  booth.files.nextStream = PickedStream(
    name: 'porcelain-backup-20261114-2341.tar',
    length: 1887436800,
    open: () => const Stream.empty(),
  );
  await _tap(tester, 'Choose backup file');
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
  'delivery',
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
      paired: tab == 'delivery',
    ),
  'event delivery unpaired': ScreenSpec(
    RoutePaths.event(SeedIds.active, tab: 'delivery'),
    seeded: true,
  ),
  'event draft': ScreenSpec(RoutePaths.event(SeedIds.draft), seeded: true),
  'event archived': ScreenSpec(
    RoutePaths.event(SeedIds.archived),
    seeded: true,
  ),
  // The new-event flow (UX-P1, CR-003): its three steps.
  'new event': const ScreenSpec(RoutePaths.newEvent),
  'new event look': ScreenSpec(
    RoutePaths.newEvent,
    seeded: true,
    renders: true,
    then: (tester) async {
      await _toNewEventLook(tester);
      await settleRendering(tester, rounds: 10);
    },
  ),
  'new event ready': ScreenSpec(
    RoutePaths.newEvent,
    seeded: true,
    renders: true,
    then: (tester) async {
      await _toNewEventLook(tester);
      await _tap(tester, 'Next: review');
      await settleRendering(tester, rounds: 10);
    },
  ),
  'experience preview': ScreenSpec(
    RoutePaths.event(SeedIds.active, tab: 'guest'),
    seeded: true,
    then: (tester) => _tap(tester, 'Preview the whole guest journey'),
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
  'session detail texts': ScreenSpec(
    RoutePaths.gallerySession(GalleryIds.session(8)),
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
    paired: true,
    texts: _texts,
    then: _toTexts,
  ),
  'session detail text unknown': ScreenSpec(
    RoutePaths.gallerySession(GalleryIds.session(6)),
    seeded: true,
    renders: true,
    gallery: _gallerySessions,
    paired: true,
    texts: _texts,
    then: _toTexts,
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
  'settings delivery': const ScreenSpec('/studio/settings?section=delivery'),
  'settings delivery paired': const ScreenSpec(
    '/studio/settings?section=delivery',
    seeded: true,
    gallery: _gallerySessions,
    paired: true,
    texts: _texts,
  ),
  'settings backup': const ScreenSpec('/studio/settings?section=backup'),
  'settings backup made': ScreenSpec(
    '/studio/settings?section=backup',
    then: (tester) => _tap(tester, 'Make a backup'),
  ),
  'settings booth': const ScreenSpec('/studio/settings?section=booth'),
  'settings kiosk': const ScreenSpec('/studio/settings?section=kiosk'),
  'settings kiosk ipad locked': const ScreenSpec(
    '/studio/settings?section=kiosk',
    kiosk: KioskLock.guidedAccess,
    environment: releaseIpad,
  ),
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
  'setup restore': const ScreenSpec(
    '/',
    startAs: StartAs.setup,
    then: _toRestore,
  ),
  'setup restore checked': const ScreenSpec(
    '/',
    startAs: StartAs.setup,
    session: _chooseBackup,
  ),
  'setup restore refused': ScreenSpec(
    '/',
    startAs: StartAs.setup,
    backups: () =>
        FakeBackupService()
          ..nextFailure = const BackupException(BackupProblem.unsafeArchive),
    session: _chooseBackup,
  ),
  'setup restored': ScreenSpec(
    '/',
    startAs: StartAs.setup,
    backups: () => FakeBackupService()
      ..pendingReport = RestoreReport(
        createdAtUtc: FakeBackupService.made,
        boothName: 'Front entrance',
        counts: FakeBackupService.counts,
        closedDeliveries: 2,
      ),
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
  'booth text offer': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _texting,
    paired: true,
    session: (tester, booth) async {
      await _toFinished(tester);
      expect(find.bySemanticsLabel(DeliveryCopy.textMyPhotos), findsOneWidget);
    },
  ),
  'booth text offline': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _texting,
    paired: true,
    offline: true,
    session: (tester, booth) async {
      await _toFinished(tester);
      expect(find.text(DeliveryCopy.offlineNote), findsOneWidget);
    },
  ),
  'booth text number': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _texting,
    paired: true,
    session: (tester, booth) async {
      await _toTextEntry(tester);
      expect(find.bySemanticsLabel(_consent), findsOneWidget);
    },
  ),
  'booth text number entered': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _texting,
    paired: true,
    session: (tester, booth) async {
      await _toTextEntry(tester);
      await _typeNumber(tester);
      await _press(tester, _consent);
      await _settlePhotos(tester);
      // The last keys' release animations.
      await tester.pump(const Duration(seconds: 1));
    },
  ),
  'booth text confirm': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _texting,
    paired: true,
    session: (tester, booth) async {
      await _toTextEntry(tester);
      await _typeNumber(tester);
      await _press(tester, _consent);
      await _press(tester, DeliveryCopy.sendMyPhotos);
      await _settlePhotos(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(DeliveryCopy.confirmTitle), findsOneWidget);
    },
  ),
  'booth text privacy': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _texting,
    paired: true,
    session: (tester, booth) async {
      await _toTextEntry(tester);
      await _press(tester, DeliveryCopy.privacy);
      await _settlePhotos(tester);
      expect(find.text(DeliveryCopy.privacyTitle), findsOneWidget);
    },
  ),
  'booth text sent': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _texting,
    paired: true,
    session: (tester, booth) async {
      await _sendText(tester);
      expect(find.text('Text request sent'), findsOneWidget);
    },
  ),
  'booth text waiting': ScreenSpec(
    RoutePaths.booth,
    startAs: StartAs.booth,
    seeded: true,
    renders: true,
    boothEventId: SeedIds.active,
    event: _texting,
    paired: true,
    offline: true,
    session: (tester, booth) async {
      await _sendText(tester);
      expect(find.text('Waiting for a connection'), findsOneWidget);
    },
  ),
};

/// The seeded event in the booth's own theme, offering texting.
BoothEvent _texting(BoothEvent event) =>
    _porcelain(event)
        .copyWith(delivery: const EventDeliverySettings(enabled: true));

/// The consent box, by its wording.
final _consent = const ConsentText(brand: 'Porcelain Booth', linkDays: 7).text;

/// Both photos kept: the finished screen.
Future<void> _toFinished(WidgetTester tester) async {
  await _toReview(tester);
  await _press(tester, BoothCopy.keepThese);
  await tester.pump();
  await _settlePhotos(tester);
  await _settlePhotos(tester);
  expect(find.byType(GuestFinished), findsOneWidget);
}

/// The finished screen, then Text my photos: the number and the consent.
Future<void> _toTextEntry(WidgetTester tester) async {
  await _toFinished(tester);
  await _press(tester, DeliveryCopy.textMyPhotos);
  await _settlePhotos(tester);
}

/// 212-555-0147 on the booth keypad.
Future<void> _typeNumber(WidgetTester tester) async {
  for (final digit in '2125550147'.split('')) {
    await _press(tester, digit);
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A number, the box checked, Send my photos, Send: the result.
Future<void> _sendText(WidgetTester tester) async {
  await _toTextEntry(tester);
  await _typeNumber(tester);
  await _press(tester, _consent);
  await tester.pump(const Duration(milliseconds: 400));
  await _press(tester, DeliveryCopy.sendMyPhotos);
  await tester.pump(const Duration(milliseconds: 400));
  await _press(tester, DeliveryCopy.send);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await _settlePhotos(tester);
}

/// Scrolls a session's page to its Texts.
Future<void> _toTexts(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Texts'));
  await tester.pumpAndSettle();
}

/// Texts for five of the gallery's sessions, one in each state an operator
/// meets, the evening before the test clock.
Future<void> _texts(
  BoothDatabase db,
  FakeDeliveryApi api,
  MemoryDeliverySecrets secrets,
) => seedTexts(
  db,
  api,
  secrets,
  const [
    (8, '0147', DeliveryPhase.delivered, null),
    (7, '2291', DeliveryPhase.sent, null),
    (6, '8830', DeliveryPhase.unknown, 'PROVIDER_TIMEOUT'),
    (4, '4410', DeliveryPhase.queuedLocally, 'OFFLINE'),
    (2, '6052', DeliveryPhase.failed, 'RECIPIENT_OPTED_OUT'),
  ],
  sessionId: GalleryIds.session,
  outputId: GalleryIds.output,
);

/// The seeded event in the booth's own theme (Porcelain Studio).
BoothEvent _porcelain(BoothEvent event) =>
    event.copyWith(experience: const EventExperienceConfiguration());

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
  final clock = FakeClock();
  final delivery = FakeDeliveryApi();
  final secrets = MemoryDeliverySecrets();
  final booth = await pumpApp(
    tester,
    location: spec.location,
    appearance: appearance,
    startAs: spec.startAs,
    boothEventId: spec.boothEventId,
    exports: exports,
    clock: clock,
    delivery: delivery,
    secrets: secrets,
    seed: spec.seeded || spec.paired
        ? (db) async {
            if (spec.seeded) await seedEvents(db, active: spec.event);
            await spec.gallery?.call(db, exports);
            if (spec.paired) {
              await seedPairing(db, secrets, at: clock.now(), api: delivery);
            }
            await spec.texts?.call(db, delivery, secrets);
            delivery.offline = spec.offline;
          }
        : null,
    seedTemplates: spec.library
        ? seedStarterLibrary
        : spec.seeded
        ? seedTemplateDocuments
        : null,
    camera: spec.camera?.call(),
    backups: spec.backups?.call(),
    kiosk: spec.kiosk,
    environment: spec.environment,
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
