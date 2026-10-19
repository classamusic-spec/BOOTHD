import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/booth_settings_repository.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../../domain/repositories/operator_access_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/template_catalog.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/services/delivery_api.dart';
import '../../domain/services/event_service.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/finished_photos.dart';
import '../../domain/services/gallery_services.dart';
import '../../domain/services/managed_storage.dart';
import '../../domain/services/operator_auth_service.dart';
import '../../domain/services/operator_files.dart';
import '../../domain/services/operator_secrets.dart';
import '../../domain/services/print_service.dart';
import '../../domain/value_objects/clock.dart';
import '../../domain/value_objects/entity_id.dart';
import '../booth/session_renderer.dart';
import '../templates/template_library.dart';

/// Service providers that features depend on, typed by domain interfaces.
///
/// The composition root binds each one to an infrastructure adapter
/// (`productionOverrides` in lib/app/providers.dart); tests bind fakes.
/// Reading an unbound provider fails loudly (ADR-0005).
Never _unbound(String name) => throw UnimplementedError(
  '$name is not bound; see productionOverrides (ADR-0005).',
);

final compositionRendererProvider = Provider<CompositionRenderer>(
  (ref) => _unbound('compositionRendererProvider'),
);

final cameraServiceProvider = Provider<CameraService>(
  (ref) => _unbound('cameraServiceProvider'),
);

final capturedStillStoreProvider = Provider<CapturedStillStore>(
  (ref) => _unbound('capturedStillStoreProvider'),
);

/// Builds the live camera preview of the open camera, never stretched;
/// [mirror] true shows guests themselves as in a mirror, whatever the
/// platform does by default (ADR-0012).
typedef CameraPreviewBuilder = Widget Function(
  BuildContext context, {
  required bool mirror,
});

final cameraPreviewBuilderProvider = Provider<CameraPreviewBuilder>(
  (ref) => _unbound('cameraPreviewBuilderProvider'),
);

/// Guest sessions, their photos and finished photos (M07, ADR-0013).
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => _unbound('sessionRepositoryProvider'),
);

/// Finished photos read back from storage (M07).
final finishedPhotosProvider = Provider<FinishedPhotos>(
  (ref) => _unbound('finishedPhotosProvider'),
);

// The operator gallery (M08, ADR-0014).

/// Sessions, their files and storage, as the gallery sees them.
final galleryRepositoryProvider = Provider<GalleryRepository>(
  (ref) => _unbound('galleryRepositoryProvider'),
);

/// Hands verified copies of gallery files to the platform share sheet.
final galleryExporterProvider = Provider<GalleryExporter>(
  (ref) => _unbound('galleryExporterProvider'),
);

/// Gallery thumbnails, kept in managed storage.
final thumbnailStoreProvider = Provider<ThumbnailStore>(
  (ref) => _unbound('thumbnailStoreProvider'),
);

/// Removes the files of deleted records (the deletion journal).
final storageCleanupProvider = Provider<StorageCleanup>(
  (ref) => _unbound('storageCleanupProvider'),
);

/// Phone delivery (M09, ADR-0015): the local queue, the service client,
/// secure storage for the booth credential and pending numbers, and the
/// MMS preview maker.
final deliveryRepositoryProvider = Provider<DeliveryRepository>(
  (ref) => _unbound('deliveryRepositoryProvider'),
);

final deliveryApiProvider = Provider<DeliveryApi>(
  (ref) => _unbound('deliveryApiProvider'),
);

final deliverySecretsProvider = Provider<DeliverySecrets>(
  (ref) => _unbound('deliverySecretsProvider'),
);

final previewMakerProvider = Provider<PreviewMaker>(
  (ref) => _unbound('previewMakerProvider'),
);

/// Printing (A-13). Release 1 is export-only: the unconfigured adapter is
/// the only one, so nothing can be printed or appear printed (AC-0806).
final printServiceProvider = Provider<PrintService>(
  (ref) => const UnconfiguredPrintService(),
);

/// Free space on the booth's volume (M06, ADR-0012).
final deviceStorageInfoProvider = Provider<DeviceStorageInfo>(
  (ref) => _unbound('deviceStorageInfoProvider'),
);

// Storage and security (M03, ADR-0009).

final managedStorageProvider = Provider<ManagedStorage>(
  (ref) => _unbound('managedStorageProvider'),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => _unbound('eventRepositoryProvider'),
);

final boothSettingsRepositoryProvider = Provider<BoothSettingsRepository>(
  (ref) => _unbound('boothSettingsRepositoryProvider'),
);

final templateCatalogProvider = Provider<TemplateCatalog>(
  (ref) => _unbound('templateCatalogProvider'),
);

// Templates and exports (M04, ADR-0010).

final assetRepositoryProvider = Provider<AssetRepository>(
  (ref) => _unbound('assetRepositoryProvider'),
);

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => _unbound('templateRepositoryProvider'),
);

final templatePackagesProvider = Provider<TemplatePackages>(
  (ref) => _unbound('templatePackagesProvider'),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => _unbound('exportServiceProvider'),
);

// Template Studio (M05, ADR-0011).

final templateDraftRepositoryProvider = Provider<TemplateDraftRepository>(
  (ref) => _unbound('templateDraftRepositoryProvider'),
);

/// The platform document picker and share sheet, for Studio screens only.
final operatorFilesProvider = Provider<OperatorFiles>(
  (ref) => _unbound('operatorFilesProvider'),
);

/// Reads a file bundled with the app (the template decorations).
final bundledAssetLoaderProvider =
    Provider<Future<Uint8List> Function(String assetPath)>(
      (ref) =>
          (path) async => (await rootBundle.load(path)).buffer.asUint8List(),
    );

final operatorAccessRepositoryProvider = Provider<OperatorAccessRepository>(
  (ref) => _unbound('operatorAccessRepositoryProvider'),
);

final pinVerifierStoreProvider = Provider<PinVerifierStore>(
  (ref) => _unbound('pinVerifierStoreProvider'),
);

final pinHasherProvider = Provider<PinHasher>(
  (ref) => _unbound('pinHasherProvider'),
);

final boothCapabilityProbeProvider = Provider<BoothCapabilityProbe>(
  (ref) => _unbound('boothCapabilityProbeProvider'),
);

/// Pure-Dart defaults; tests override them for predictable values.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>((ref) => RandomIdGenerator());

/// Makes each new operator recovery code.
final recoveryCodeGeneratorProvider = Provider<String Function()>(
  (ref) => RecoveryCodes.generate,
);

/// Domain services composed from the bindings above.
final operatorAuthServiceProvider = Provider<OperatorAuthService>(
  (ref) => OperatorAuthService(
    pins: ref.watch(pinVerifierStoreProvider),
    access: ref.watch(operatorAccessRepositoryProvider),
    hasher: ref.watch(pinHasherProvider),
    clock: ref.watch(clockProvider),
    newRecoveryCode: ref.watch(recoveryCodeGeneratorProvider),
  ),
);

final templateLibraryProvider = Provider<TemplateLibrary>(
  (ref) => TemplateLibrary(
    assets: ref.watch(assetRepositoryProvider),
    templates: ref.watch(templateRepositoryProvider),
    packages: ref.watch(templatePackagesProvider),
    drafts: ref.watch(templateDraftRepositoryProvider),
    clock: ref.watch(clockProvider),
    loadBundled: ref.watch(bundledAssetLoaderProvider),
  ),
);

final eventServiceProvider = Provider<EventService>(
  (ref) => EventService(
    events: ref.watch(eventRepositoryProvider),
    templates: ref.watch(templateCatalogProvider),
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);

/// Makes finished photos for the booth and the gallery (M07, M08).
final sessionRendererProvider = Provider<SessionRenderer>(
  (ref) => SessionRenderer(
    export: ref.watch(exportServiceProvider),
    finished: ref.watch(finishedPhotosProvider),
    templates: ref.watch(templateRepositoryProvider),
    assets: ref.watch(assetRepositoryProvider),
    originals: ref.watch(capturedStillStoreProvider),
  ),
);
