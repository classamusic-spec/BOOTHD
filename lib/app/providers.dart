import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../core/di/service_providers.dart';
import '../core/platform/app_environment.dart';
import '../infrastructure/camera/camera_driver.dart';
import '../infrastructure/camera/managed_camera_service.dart';
import '../infrastructure/composition/dart_ui_composition_renderer.dart';
import '../infrastructure/file_store/original_store.dart';
import 'router.dart';

/// The application router. Developer spike routes exist only outside
/// release builds. Overridden in tests to start at other locations.
final routerProvider = Provider<GoRouter>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final router = buildRouter(
    devTools: environment.buildMode != BuildMode.release,
  );
  ref.onDispose(router.dispose);
  return router;
});

final _cameraDriverProvider = Provider<PluginCameraDriver>(
  (ref) => PluginCameraDriver(),
);

final _originalStoreProvider = Provider<OriginalStore>(
  (ref) => OriginalStore(root: getApplicationSupportDirectory),
);

/// Binds every domain service to its infrastructure adapter (ADR-0005).
/// Providers are lazy: nothing touches the camera or disk until a screen
/// reads them.
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
];
