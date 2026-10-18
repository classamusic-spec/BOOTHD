import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/camera_service.dart';
import '../../domain/services/composition_renderer.dart';

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

/// Builds the live camera preview; [mirror] flips it horizontally on top of
/// whatever the platform already does.
typedef CameraPreviewBuilder = Widget Function(
  BuildContext context, {
  required bool mirror,
});

final cameraPreviewBuilderProvider = Provider<CameraPreviewBuilder>(
  (ref) => _unbound('cameraPreviewBuilderProvider'),
);
