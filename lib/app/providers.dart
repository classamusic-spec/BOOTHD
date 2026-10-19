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
import '../infrastructure/camera/permission_handler_camera_permissions.dart';
import '../infrastructure/composition/dart_ui_composition_renderer.dart';
import '../infrastructure/database/booth_database.dart';
import '../infrastructure/database/database_connection.dart';
import '../infrastructure/database/drift_booth_settings_repository.dart';
import '../infrastructure/database/drift_event_repository.dart';
import '../infrastructure/database/drift_gallery_repository.dart';
import '../infrastructure/database/drift_operator_access_repository.dart';
import '../infrastructure/database/drift_session_repository.dart';
import '../infrastructure/database/drift_template_catalog.dart';
import '../infrastructure/device/device_capability_probe.dart';
import '../infrastructure/device/platform_device_storage.dart';
import '../infrastructure/file_store/file_export_service.dart';
import '../infrastructure/file_store/managed_finished_photos.dart';
import '../infrastructure/file_store/managed_storage.dart';
import '../infrastructure/file_store/managed_storage_cleanup.dart';
import '../infrastructure/file_store/managed_thumbnail_store.dart';
import '../infrastructure/file_store/original_store.dart';
import '../infrastructure/files/managed_gallery_exporter.dart';
import '../infrastructure/files/platform_operator_files.dart';
import '../infrastructure/security/pbkdf2_pin_hasher.dart';
import '../infrastructure/security/secure_pin_verifier_store.dart';
import '../infrastructure/templates/drift_asset_repository.dart';
import '../infrastructure/templates/drift_template_draft_repository.dart';
import '../infrastructure/templates/drift_template_repository.dart';
import '../infrastructure/templates/zip_template_packages.dart';
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

/// Camera originals: files in managed storage, records in the booth
/// database (M06, A-11).
final _originalStoreProvider = Provider<OriginalStore>((ref) {
  final storage = ref.watch(_managedStorageProvider);
  return OriginalStore(
    database: ref.watch(_boothDatabaseProvider),
    root: getApplicationSupportDirectory,
    writer: storage.writer,
    clock: ref.watch(clockProvider),
  );
});

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
  compositionRendererProvider.overrideWithValue(DartUiCompositionRenderer()),
  capturedStillStoreProvider.overrideWith(
    (ref) => ref.watch(_originalStoreProvider),
  ),
  cameraServiceProvider.overrideWith((ref) {
    final service = ManagedCameraService(
      driver: ref.watch(_cameraDriverProvider),
      permissions: const PermissionHandlerCameraPermissions(),
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
  assetRepositoryProvider.overrideWith(
    (ref) => DriftAssetRepository(
      ref.watch(_boothDatabaseProvider),
      storage: ref.watch(_managedStorageProvider),
      clock: ref.watch(clockProvider),
    ),
  ),
  templateRepositoryProvider.overrideWith(
    (ref) => DriftTemplateRepository(
      ref.watch(_boothDatabaseProvider),
      storage: ref.watch(_managedStorageProvider),
      assets: ref.watch(assetRepositoryProvider),
      ids: ref.watch(idGeneratorProvider),
      clock: ref.watch(clockProvider),
    ),
  ),
  templatePackagesProvider.overrideWith(
    (ref) => ZipTemplatePackages(
      assets: ref.watch(assetRepositoryProvider),
      templates: ref.watch(templateRepositoryProvider),
    ),
  ),
  templateDraftRepositoryProvider.overrideWith(
    (ref) => DriftTemplateDraftRepository(ref.watch(_boothDatabaseProvider)),
  ),
  operatorFilesProvider.overrideWithValue(PlatformOperatorFiles()),
  exportServiceProvider.overrideWith(
    (ref) => FileExportService(
      renderer: ref.watch(compositionRendererProvider),
      storage: ref.watch(_managedStorageProvider),
      ids: ref.watch(idGeneratorProvider),
    ),
  ),
  deviceStorageInfoProvider.overrideWithValue(const PlatformDeviceStorage()),
  sessionRepositoryProvider.overrideWith(
    (ref) => DriftSessionRepository(
      ref.watch(_boothDatabaseProvider),
      clock: ref.watch(clockProvider),
    ),
  ),
  finishedPhotosProvider.overrideWithValue(
    ManagedFinishedPhotos(root: getApplicationSupportDirectory),
  ),
  galleryRepositoryProvider.overrideWith(
    (ref) => DriftGalleryRepository(
      ref.watch(_boothDatabaseProvider),
      clock: ref.watch(clockProvider),
      templates: ref.watch(templateCatalogProvider),
    ),
  ),
  galleryExporterProvider.overrideWith(
    (ref) => ManagedGalleryExporter(
      storage: ref.watch(_managedStorageProvider),
      space: ref.watch(deviceStorageInfoProvider),
      ids: ref.watch(idGeneratorProvider),
      share: shareFilesWithPlatformSheet,
    ),
  ),
  thumbnailStoreProvider.overrideWith(
    (ref) => ManagedThumbnailStore(storage: ref.watch(_managedStorageProvider)),
  ),
  storageCleanupProvider.overrideWith(
    (ref) => ManagedStorageCleanup(
      database: ref.watch(_boothDatabaseProvider),
      root: getApplicationSupportDirectory,
    ),
  ),
  boothCapabilityProbeProvider.overrideWith(
    (ref) => DeviceCapabilityProbe(
      ref.watch(_managedStorageProvider),
      renderer: ref.watch(compositionRendererProvider),
      templates: ref.watch(templateRepositoryProvider),
      assets: ref.watch(assetRepositoryProvider),
      camera: ref.watch(cameraServiceProvider),
      space: ref.watch(deviceStorageInfoProvider),
    ),
  ),
];
