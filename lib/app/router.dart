import 'package:go_router/go_router.dart';

import '../core/routing/route_paths.dart';
import '../features/dashboard/baseline_home_screen.dart';
import 'route_not_found_screen.dart';

/// Builds the application router.
///
/// M00 has a single route. The Studio subtree and the isolated guest (Booth
/// Mode) subtree with operator guards arrive in M02/M03 (UX-04). From then
/// on, the not-found fallback must send guests back to the guest welcome
/// route, never to Studio.
GoRouter buildRouter({String initialLocation = RoutePaths.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const BaselineHomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
  );
}
