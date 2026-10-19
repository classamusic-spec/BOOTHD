import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:porcelain_photo_booth/app/app.dart';
import 'package:porcelain_photo_booth/app/providers.dart';
import 'package:porcelain_photo_booth/core/access/access_controller.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/di/service_providers.dart';
import 'package:porcelain_photo_booth/core/diagnostics/device_self_test.dart';
import 'package:porcelain_photo_booth/core/platform/app_environment.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/booth_capabilities.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/services/managed_storage.dart';
import 'package:porcelain_photo_booth/domain/services/operator_auth_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_secrets.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_booth_settings_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_event_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_operator_access_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_session_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';

import 'fake_export.dart';
import 'fakes.dart';
import 'memory_template_store.dart';
import 'simulated_camera.dart';
import 'test_database.dart';

const debugAndroid = AppEnvironment(
  platform: TargetPlatform.android,
  buildMode: BuildMode.debug,
);

const releaseIpad = AppEnvironment(
  platform: TargetPlatform.iOS,
  buildMode: BuildMode.release,
);

/// The operator PIN of every test booth.
const testPin = '482916';

/// Where the app starts.
enum StartAs {
  /// A fresh install: first-run setup.
  setup,

  /// Set up, Studio locked (a cold start).
  locked,

  /// Set up and unlocked: the Studio.
  operator,

  /// Booth Mode for the event given as `boothEventId`.
  booth,
}

/// Managed storage that touches no files; preparation can be made to fail.
final class FakeManagedStorage implements ManagedStorage {
  Exception? prepareError;

  @override
  Future<void> prepare() async {
    final error = prepareError;
    if (error != null) throw error;
  }

  @override
  Future<CapabilityStatus> probeWrite() async => const CapabilityReady();
}

/// The app under test and the fakes behind it.
final class TestBooth {
  TestBooth._({
    required this.db,
    required this.pins,
    required this.probe,
    required this.storage,
    required this.clock,
    required this.recoveryCode,
    required this.templates,
    required this.files,
    required this.camera,
    required this.space,
    required this.exports,
  });

  final BoothDatabase db;
  final MemoryPinVerifierStore pins;
  final FakeCapabilityProbe probe;
  final FakeManagedStorage storage;
  final FakeClock clock;

  /// The recovery code created at setup, or null for a fresh install.
  final String? recoveryCode;

  /// The template library, in memory.
  final MemoryTemplateStore templates;

  /// The document picker and share sheet.
  final FakeOperatorFiles files;

  /// The camera, with no camera, and its committed originals.
  final SimulatedCameraService camera;
  SimulatedStillStore get stills => camera.store;

  /// Free space as the tablet reports it.
  final FakeDeviceStorage space;

  /// Finished photos: a fast stand-in for the renderer and file export.
  final FakeExportService exports;

  /// Guest sessions in the booth database.
  DriftSessionRepository get sessions =>
      DriftSessionRepository(db, clock: clock);

  late final ProviderContainer container;

  DriftEventRepository get events => DriftEventRepository(db);
  DriftBoothSettingsRepository get settings =>
      DriftBoothSettingsRepository(db, clock: clock);
  DriftOperatorAccessRepository get access => DriftOperatorAccessRepository(db);
  OperatorAuthService get auth => container.read(operatorAuthServiceProvider);
  AccessState get accessState => container.read(accessControllerProvider);
  GoRouter get router => container.read(routerProvider);
}

/// Sets up a booth in [db] (unless [startAs] is [StartAs.setup]) and
/// returns its recovery code.
Future<String?> prepareBooth(
  BoothDatabase db, {
  required MemoryPinVerifierStore pins,
  required FakeClock clock,
  required StartAs startAs,
  AppearanceSettings appearance = const AppearanceSettings(),
}) async {
  if (startAs == StartAs.setup) return null;
  final settings = DriftBoothSettingsRepository(db, clock: clock);
  final auth = OperatorAuthService(
    pins: pins,
    access: DriftOperatorAccessRepository(db),
    hasher: FastTestHasher(),
    clock: clock,
  );
  final credentials = await auth.setUp(testPin);
  await settings.completeSetup(
    boothName: 'Test booth',
    theme: appearance.profile,
    recoveryVerifier: credentials.recoveryVerifier,
  );
  await settings.saveAppearance(appearance);
  return credentials.recoveryCode;
}

/// The whole app at [location], over an in-memory database (or [database])
/// with fast fakes for secure storage, hashing and device checks.
///
/// [seed] runs against the database before the app starts, e.g. to add
/// templates and events.
Future<TestBooth> pumpApp(
  WidgetTester tester, {
  String location = RoutePaths.home,
  AppEnvironment environment = debugAndroid,
  AppearanceSettings appearance = const AppearanceSettings(),
  bool settle = true,
  StartAs startAs = StartAs.operator,
  BoothDatabase? database,
  MemoryPinVerifierStore? pins,
  FakeCapabilityProbe? probe,
  FakeManagedStorage? storage,
  FakeClock? clock,
  bool alreadySetUp = false,
  String? boothEventId,
  Future<void> Function(BoothDatabase db)? seed,
  MemoryTemplateStore? templates,
  Future<void> Function(MemoryTemplateStore templates)? seedTemplates,
  SimulatedCameraService? camera,
  FakeDeviceStorage? space,
  FakeExportService? exports,
}) async {
  final testClock = clock ?? FakeClock();
  final db = database ?? memoryDatabase(clock: testClock);
  final store = pins ?? MemoryPinVerifierStore();
  final recoveryCode = alreadySetUp
      ? null
      : await prepareBooth(
          db,
          pins: store,
          clock: testClock,
          startAs: startAs,
          appearance: appearance,
        );
  if (seed != null) await seed(db);
  if (startAs == StartAs.booth) {
    await DriftBoothSettingsRepository(
      db,
      clock: testClock,
    ).setBoothEvent(boothEventId!);
  }

  final library = templates ?? MemoryTemplateStore(clock: testClock);
  if (seedTemplates != null) await seedTemplates(library);
  final booth = TestBooth._(
    db: db,
    pins: store,
    probe: probe ?? FakeCapabilityProbe(),
    storage: storage ?? FakeManagedStorage(),
    clock: testClock,
    recoveryCode: recoveryCode,
    templates: library,
    files: FakeOperatorFiles(),
    camera: camera ?? SimulatedCameraService(),
    space: space ?? FakeDeviceStorage(),
    exports: exports ?? FakeExportService(),
  );
  // Sessions refer to originals, which the real store records in the
  // database too.
  booth.camera.store.database ??= db;

  await tester.pumpWidget(
    ProviderScope(
      // A new scope (and router) for every pump, even within one test.
      key: UniqueKey(),
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        initialLocationProvider.overrideWithValue(location),
        clockProvider.overrideWithValue(testClock),
        idGeneratorProvider.overrideWithValue(SequentialIds()),
        // Seeded, so screenshots of a new recovery code are repeatable.
        recoveryCodeGeneratorProvider.overrideWith((ref) {
          final random = Random(7);
          return () => RecoveryCodes.generate(random);
        }),
        managedStorageProvider.overrideWithValue(booth.storage),
        eventRepositoryProvider.overrideWith((ref) => booth.events),
        boothSettingsRepositoryProvider.overrideWith((ref) => booth.settings),
        templateCatalogProvider.overrideWith((ref) => DriftTemplateCatalog(db)),
        operatorAccessRepositoryProvider.overrideWith((ref) => booth.access),
        pinVerifierStoreProvider.overrideWithValue(store),
        pinHasherProvider.overrideWithValue(FastTestHasher()),
        boothCapabilityProbeProvider.overrideWithValue(booth.probe),
        assetRepositoryProvider.overrideWithValue(library.assets),
        templateRepositoryProvider.overrideWithValue(library.templates),
        templatePackagesProvider.overrideWithValue(library.packages),
        templateDraftRepositoryProvider.overrideWithValue(library.drafts),
        operatorFilesProvider.overrideWithValue(booth.files),
        cameraServiceProvider.overrideWithValue(booth.camera),
        capturedStillStoreProvider.overrideWithValue(booth.stills),
        cameraPreviewBuilderProvider.overrideWithValue(simulatedPreview),
        deviceStorageInfoProvider.overrideWithValue(booth.space),
        sessionRepositoryProvider.overrideWith((ref) => booth.sessions),
        exportServiceProvider.overrideWithValue(booth.exports),
        finishedPhotosProvider.overrideWithValue(booth.exports.finished),
        deviceSelfTestProvider.overrideWith(
          (ref) => DeviceSelfTest(
            camera: booth.camera,
            storage: booth.storage,
            space: booth.space,
            stopwatch: FixedStopwatch.new,
          ),
        ),
        // Engine work (rendering, decoding) completes only in real time:
        // see settleRendering().
        compositionRendererProvider.overrideWithValue(
          TrackedRenderer(DartUiCompositionRenderer()),
        ),
        // The bundle, read from disk without platform messages.
        bundledAssetLoaderProvider.overrideWithValue(
          (path) async => File(path).readAsBytesSync(),
        ),
      ],
      child: const PorcelainApp(),
    ),
  );
  booth.container = ProviderScope.containerOf(
    tester.element(find.byType(PorcelainApp)),
  );

  // Let startup open the database and choose the access phase.
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
  if (startAs == StartAs.operator &&
      booth.accessState.phase == AccessPhase.locked) {
    final check = await booth.auth.verifyPin(testPin);
    booth.container
        .read(accessControllerProvider.notifier)
        .unlock((check as AccessGranted).proof);
    await tester.pump();
  }
  if (settle) await tester.pumpAndSettle();
  return booth;
}

/// The router in use by the app under test.
GoRouter routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(PorcelainApp)))
        .read(routerProvider);

/// Types [pin] on the visible PIN pad.
Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.bySemanticsLabel(digit).last);
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// A renderer that counts the renders in flight, so tests can wait for
/// them rather than for a fixed time (a busy machine renders slower).
final class TrackedRenderer implements CompositionRenderer {
  TrackedRenderer(this._inner) {
    current = this;
  }

  final CompositionRenderer _inner;

  /// The renderer of the app pumped last. Each app counts its own renders:
  /// a render a finished test left behind never completes under its fake
  /// clock, and must not hold up the next test.
  static TrackedRenderer? current;

  /// Renders started and not yet finished.
  var inFlight = 0;

  Future<T> _track<T>(Future<T> Function() render) async {
    inFlight++;
    try {
      return await render();
    } finally {
      inFlight--;
    }
  }

  @override
  Future<RenderArtifact> renderExport(
    TemplateRender render, {
    OutputProfile output = const OutputProfile(),
    int flattenArgb = 0xFFFFFFFF,
    bool includePixels = false,
  }) => _track(
    () => _inner.renderExport(
      render,
      output: output,
      flattenArgb: flattenArgb,
      includePixels: includePixels,
    ),
  );

  @override
  Future<RenderArtifact> renderPreview(
    TemplateRender render, {
    required int maxWidthPx,
    required int maxHeightPx,
    double workspaceMargin = 0,
    bool includePixels = false,
  }) => _track(
    () => _inner.renderPreview(
      render,
      maxWidthPx: maxWidthPx,
      maxHeightPx: maxHeightPx,
      workspaceMargin: workspaceMargin,
      includePixels: includePixels,
    ),
  );
}

/// Lets engine work finish in real time (rendering and image decoding do
/// not advance under the test's fake clock): at least [rounds] short
/// rounds, then until no render has been in flight for three rounds in a
/// row (at most about ten seconds), then decodes every image on screen
/// the same way and rebuilds.
Future<void> settleRendering(WidgetTester tester, {int rounds = 6}) async {
  var idle = 0;
  for (var i = 0; i < rounds || (idle < 3 && i < rounds + 250); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump();
    idle = (TrackedRenderer.current?.inFlight ?? 0) == 0 ? idle + 1 : 0;
  }
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
}
