import 'package:go_router/go_router.dart';

import '../core/routing/route_paths.dart';
import '../features/booth/guest_preview_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/diagnostics/component_gallery_screen.dart';
import '../features/diagnostics/diagnostics_screen.dart';
import '../features/diagnostics/spikes/camera_spike_screen.dart';
import '../features/diagnostics/spikes/render_spike_screen.dart';
import '../features/events/events_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/studio_shell/studio_shell.dart';
import '../features/template_library/template_library_screen.dart';
import 'route_not_found_screen.dart';

/// Builds the application router.
///
/// Studio is a stateful shell with one branch per section, in the order of
/// `studioDestinations`. [devTools] registers developer routes (M01 spikes,
/// component gallery); it is false in release builds, so they cannot be
/// reached there. First-run setup, the operator PIN guard and the isolated
/// guest subtree arrive in M03 and M07 (UX-04); from then on the not-found
/// fallback must send guests back to the guest welcome route, never to
/// Studio.
GoRouter buildRouter({
  String initialLocation = RoutePaths.home,
  bool devTools = false,
}) {
  GoRoute section(String path, GoRouterWidgetBuilder builder) =>
      GoRoute(path: path, builder: builder);

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: RoutePaths.home, redirect: (_, _) => RoutePaths.dashboard),
      StatefulShellRoute(
        builder: (context, state, shell) => StudioShell(navigationShell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            StudioSectionStack(
              currentIndex: shell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              section(RoutePaths.dashboard, (_, _) => const DashboardScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              section(RoutePaths.events, (_, _) => const EventsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              section(
                RoutePaths.templates,
                (_, _) => const TemplateLibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              section(RoutePaths.gallery, (_, _) => const GalleryScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              section(
                RoutePaths.settings,
                (_, state) => SettingsScreen(
                  section: SettingsSection.fromId(
                    state.uri.queryParameters['section'],
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              section(
                RoutePaths.diagnostics,
                (_, _) => const DiagnosticsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.guestPreview,
        builder: (_, _) => const GuestPreviewScreen(),
      ),
      if (devTools) ...[
        GoRoute(
          path: RoutePaths.renderSpike,
          builder: (_, _) => const RenderSpikeScreen(),
        ),
        GoRoute(
          path: RoutePaths.cameraSpike,
          builder: (_, _) => const CameraSpikeScreen(),
        ),
        GoRoute(
          path: RoutePaths.componentGallery,
          builder: (_, _) => const ComponentGalleryScreen(),
        ),
      ],
    ],
    errorBuilder: (_, _) => const RouteNotFoundScreen(),
  );
}
