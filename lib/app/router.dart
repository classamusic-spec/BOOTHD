import 'package:go_router/go_router.dart';

import '../core/routing/route_paths.dart';
import '../features/dashboard/baseline_home_screen.dart';
import '../features/diagnostics/spikes/camera_spike_screen.dart';
import '../features/diagnostics/spikes/render_spike_screen.dart';
import 'route_not_found_screen.dart';

/// Builds the application router.
///
/// [devTools] registers the M01 developer spike routes; it is false in
/// release builds, so those screens cannot be reached there. The Studio
/// subtree and the isolated guest (Booth Mode) subtree with operator guards
/// arrive in M02/M03 (UX-04). From then on, the not-found fallback must send
/// guests back to the guest welcome route, never to Studio.
GoRouter buildRouter({
  String initialLocation = RoutePaths.home,
  bool devTools = false,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const BaselineHomeScreen(),
      ),
      if (devTools) ...[
        GoRoute(
          path: RoutePaths.renderSpike,
          builder: (context, state) => const RenderSpikeScreen(),
        ),
        GoRoute(
          path: RoutePaths.cameraSpike,
          builder: (context, state) => const CameraSpikeScreen(),
        ),
      ],
    ],
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
  );
}
