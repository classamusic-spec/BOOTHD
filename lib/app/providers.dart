import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../core/access/access_controller.dart';
import '../core/di/service_providers.dart';
import '../core/platform/app_environment.dart';
import '../core/routing/route_paths.dart';
import '../infrastructure/camera/camera_driver.dart';
import '../infrastructure/camera/managed_camera_service.dart';
import '../infrastructure/composition/dart_ui_composition_renderer.dart';
import '../infrastructure/database/booth_database.dart';
import '../infrastructure/database/database_connection.dart';
import '../infrastructure/database/drift_booth_settings_repository.dart';
import '../infrastructure/database/drift_event_repository.dart';
import '../infrastructure/database/drift_operator_access_repository.dart';
import '../infrastructure/database/drift_template_catalog.dart';
import '../infrastructure/device/device_capability_probe.dart';
import '../infrastructure/file_store/managed_storage.dart';
import '../infrastructure/file_store/original_store.dart';
import '../infrastructure/security/pbkdf2_pin_hasher.dart';
import '../infrastructure/security/secure_pin_verifier_store.dart';
import 'router.dart';

/// Where the router starts. Tests override it to open a given screen; the
/// access guard still decides what that location may show.
final initialLocationProvider = Provider<String>((ref) => RoutePaths.home);

/// The application router, refreshed whenever the access phase changes.
/// Developer spike routes exist only outside release builds.
final routerProvider = Provider<GoRouter>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final access = ValueNotifier(ref.read(accessControllerProvider));
  ref.listen(accessControllerProvider, (_, next) => access.value = next);
  final router = buildRouter(
    access: access,
    initialLocation: ref.watch(initialLocationProvider),
    devTools: environment.buildMode != BuildMode.release,
  );
  ref.onDispose(() {
    router.dispose();
    access.dispose();
  });
  return router;
});

final _cameraDriverProvider = Provider<PluginCameraDriver>(
  (ref) => PluginCameraDriver(),
);

final _originalStoreProvider = Provider<OriginalStore>(
  (ref) => OriginalStore(root: getApplicationSupportDirectory),
);

/// Managed storage under the app's private support directory (A-11).
final _managedStorageProvider = Provider<FileManagedStorage>(
  (ref) => FileManagedStorage(root: getApplicationSupportDirectory),
);

/// The booth database, opened on first use on a background isolate.
final _boothDatabaseProvider = Provider<BoothDatabase>((ref) {
  final database = BoothDatabase(
    openBoothDatabaseFile(ref.watch(_managedStorageProvider).databaseFile),
    ids: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(database.close);
  return database;
});

/// Binds every domain service to its infrastructure adapter (ADR-0005).
/// Providers are lazy: nothing touches the camera or disk until a screen
/// (or startup) reads them.
List<Override> productionOverrides() => [
  compositionRendererProvider.overrideWithValue(
    const DartUiCompositionRenderer(),
  ),
  capturedStillStoreProvider.overrideWith(
    (ref) => ref.watch(_originalStoreProvider),
  ),
  cameraServiceProvider.overrideWith((ref) {
    final service = ManagedCameraService(
      driver: ref.watch(_cameraDriverProvider),
      store: ref.watch(_originalStoreProvider),
    );
    ref.onDispose(service.dispose);
    return service;
  }),
  cameraPreviewBuilderProvider.overrideWith(
    (ref) => ref.watch(_cameraDriverProvider).buildPreview,
  ),
  managedStorageProvider.overrideWith(
    (ref) => ref.watch(_managedStorageProvider),
  ),
  eventRepositoryProvider.overrideWith(
    (ref) => DriftEventRepository(ref.watch(_boothDatabaseProvider)),
  ),
  boothSettingsRepositoryProvider.overrideWith(
    (ref) => DriftBoothSettingsRepository(
      ref.watch(_boothDatabaseProvider),
      clock: ref.watch(clockProvider),
    ),
  ),
  templateCatalogProvider.overrideWith(
    (ref) => DriftTemplateCatalog(ref.watch(_boothDatabaseProvider)),
  ),
  operatorAccessRepositoryProvider.overrideWith(
    (ref) => DriftOperatorAccessRepository(ref.watch(_boothDatabaseProvider)),
  ),
  pinVerifierStoreProvider.overrideWithValue(SecurePinVerifierStore()),
  pinHasherProvider.overrideWithValue(Pbkdf2PinHasher()),
  boothCapabilityProbeProvider.overrideWith(
    (ref) => DeviceCapabilityProbe(ref.watch(_managedStorageProvider)),
  ),
];
