// Runs only on a physical tablet whose camera access is already allowed
// (M07 device procedure, the scripted half of the exit gate; AC-0701,
// AC-0704, AC-0705, AC-0709):
//   Android: adb shell pm grant com.example.porcelain_photo_booth \
//              android.permission.CAMERA
//   iPad:    Diagnostics > Camera test > Allow camera, once
//   then:    flutter test integration_test/guest_session_test.dart -d <id>
// Put the tablet in airplane mode first: nothing here uses the network.
// Emulators and simulators have no real camera; a run there is not
// evidence. It runs one guest session with the production camera service,
// originals store, template store, renderer, file export and session
// records in a temporary area (the booth's own data is untouched), with
// nobody at the booth: the camera photographs whatever is in front of it.
// It prints the facts to record.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:porcelain_photo_booth/core/booth/booth_session_controller.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/core/templates/template_library.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/event_service.dart';
import 'package:porcelain_photo_booth/domain/session/guest_flow.dart';
import 'package:porcelain_photo_booth/domain/value_objects/clock.dart';
import 'package:porcelain_photo_booth/domain/value_objects/entity_id.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/camera_driver.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/managed_camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/permission_handler_camera_permissions.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/database_connection.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_booth_settings_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';
import 'package:porcelain_photo_booth/infrastructure/device/platform_device_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/file_export_service.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_finished_photos.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/drift_asset_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/drift_template_draft_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/drift_template_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/zip_template_packages.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('one guest session from Start to a saved, verified finished '
      'photo and back to the welcome, offline', (tester) async {
    final root = await Directory.systemTemp.createTemp('porcelain_session_it');
    addTearDown(() => root.delete(recursive: true));
    final storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    const clock = SystemClock();
    final ids = RandomIdGenerator();
    final db = BoothDatabase(
      openBoothDatabaseFile(storage.databaseFile),
      ids: ids,
      clock: clock,
    );
    addTearDown(db.close);

    // A template from the bundled designs, and an active event for it.
    final assets = DriftAssetRepository(db, storage: storage, clock: clock);
    final templates = DriftTemplateRepository(
      db,
      storage: storage,
      assets: assets,
      ids: ids,
      clock: clock,
    );
    final library = TemplateLibrary(
      assets: assets,
      templates: templates,
      packages: ZipTemplatePackages(assets: assets, templates: templates),
      drafts: DriftTemplateDraftRepository(db),
      clock: clock,
      loadBundled: (path) async =>
          (await rootBundle.load(path)).buffer.asUint8List(),
    );
    final design = starterDesigns.firstWhere((d) => d.id == 'floral-elegance');
    final template = await library.create(design, name: 'Device session');
    final document = (await templates.loadRevision(template.revisionId))
        .document;
    final events = EventService(
      events: DriftEventRepository(db),
      templates: DriftTemplateCatalog(db),
      clock: clock,
      ids: ids,
    );
    final booth = (await DriftBoothSettingsRepository(
      db,
      clock: clock,
    ).load()).profile;
    final draft = events.newDraft(booth);
    final saved = await events.save(
      draft.copyWith(
        title: 'Device session test',
        capture: draft.capture.copyWith(
          lens: CameraLens.front,
          mirrorPreview: true,
          mirrorOutput: false,
          shotCount: document.photoSlots.length,
          countdownSeconds: 2,
          shotIntervalSeconds: 1,
        ),
        templates: TemplateSelection(
          revisionIds: [template.revisionId],
          defaultRevisionId: template.revisionId,
        ),
      ),
    );
    final event = await events.activate(saved.id);

    final originals = OriginalStore(
      database: db,
      root: () async => root,
      writer: storage.writer,
      clock: clock,
    );
    final camera = ManagedCameraService(
      driver: PluginCameraDriver(),
      permissions: const PermissionHandlerCameraPermissions(),
      store: originals,
    );
    addTearDown(camera.dispose);
    expect(
      await camera.permission(),
      CameraPermission.granted,
      reason: 'allow the camera first (see the header)',
    );
    final sessions = DriftSessionRepository(db, clock: clock);
    final controller = BoothSessionController(
      event: event,
      camera: camera,
      originals: originals,
      sessions: sessions,
      export: FileExportService(
        renderer: DartUiCompositionRenderer(),
        storage: storage,
        ids: ids,
      ),
      finished: ManagedFinishedPhotos(root: () async => root),
      templates: templates,
      assets: assets,
      space: const PlatformDeviceStorage(),
      clock: clock,
      ids: ids,
    );
    addTearDown(controller.dispose);

    Future<void> until(GuestStage stage, Duration limit) async {
      final watch = Stopwatch()..start();
      while (controller.flow.stage != stage) {
        if (controller.flow.stage == GuestStage.failed) {
          fail('problem: ${controller.lastProblem?.code}');
        }
        if (watch.elapsed > limit) {
          fail('still ${controller.flow.stage.name} after $limit');
        }
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    final session = Stopwatch()..start();
    await controller.start();
    await until(GuestStage.review, const Duration(minutes: 2));
    final captured = session.elapsed;
    final render = Stopwatch()..start();
    controller.keep();
    await until(GuestStage.completed, const Duration(minutes: 2));
    render.stop();

    final output = controller.output!;
    final record = (await sessions.find(output.sessionId))!;
    expect(record.status, SessionStatus.completed);
    expect(record.photos, hasLength(document.photoSlots.length));
    final file = File('${root.path}/${output.relativePath}');
    expect(file.readAsBytesSync(), controller.finishedPhoto);
    final codec = await ui.instantiateImageCodec(controller.finishedPhoto!);
    final frame = await codec.getNextFrame();
    expect(
      (frame.image.width, frame.image.height),
      (document.page.widthPx, document.page.heightPx),
    );
    final stills = await originals.listCommitted();
    // ignore: avoid_print
    print(
      'M07 session: ${document.photoSlots.length} photos in '
      '${captured.inMilliseconds} ms; finished photo '
      '${frame.image.width}x${frame.image.height} '
      '${output.byteLength} bytes in ${render.elapsedMilliseconds} ms; '
      'originals ${[for (final s in stills) '${s.widthPx}x${s.heightPx}']}',
    );
    frame.image.dispose();
    codec.dispose();

    await controller.nextGuest();
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.flow.stage, GuestStage.idle);
    expect(controller.finishedPhoto, isNull);
    expect(camera.status.lifecycle, CameraLifecycle.suspended);
  });
}
