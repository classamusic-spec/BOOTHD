import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/access/access_controller.dart';
import '../core/routing/access_redirect.dart';
import '../core/routing/route_paths.dart';
import '../domain/template/template_document.dart';
import '../features/booth/booth_operator_screen.dart';
import '../features/booth/booth_screen.dart';
import '../features/booth/guest_preview_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/diagnostics/camera_test_screen.dart';
import '../features/diagnostics/component_gallery_screen.dart';
import '../features/diagnostics/diagnostics_screen.dart';
import '../features/diagnostics/render_lab/render_lab_screen.dart';
import '../features/events/event_editor_screen.dart';
import '../features/events/events_screen.dart';
import '../features/events/preflight_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/onboarding/setup_screen.dart';
import '../features/operator_access/unlock_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/studio_shell/studio_shell.dart';
import '../features/template_library/template_library_screen.dart';
import '../features/template_studio/template_editor_screen.dart';
import '../features/template_studio/template_preview_screen.dart';
import 'route_not_found_screen.dart';
import 'startup_screens.dart';

/// Builds the application router.
///
/// Every navigation, including deep links and unknown locations, first
/// passes the access guard ([accessRedirect]) for the current [access]
/// phase (UX-04, AC-0305): setup, the PIN screen, the Studio and Booth
/// Mode each reach only their own routes. Studio is a stateful shell with
/// one branch per section, in the order of `studioDestinations`; the event
/// editor and launch checks open above it. [devTools] registers developer
/// routes (M01 spikes, component gallery); it is false in release builds.
GoRouter buildRouter({
  required ValueListenable<AccessState> access,
  String initialLocation = RoutePaths.home,
  bool devTools = false,
}) {
  final root = GlobalKey<NavigatorState>(debugLabel: 'root');
  GoRoute section(String path, GoRouterWidgetBuilder builder) =>
      GoRoute(path: path, builder: builder);

  return GoRouter(
    navigatorKey: root,
    initialLocation: initialLocation,
    refreshListenable: access,
    redirect: (context, state) => accessRedirect(access.value.phase, state.uri),
    routes: [
      GoRoute(path: RoutePaths.home, redirect: (_, _) => RoutePaths.dashboard),
      GoRoute(
        path: RoutePaths.starting,
        builder: (_, _) => const StartingScreen(),
      ),
      GoRoute(
        path: RoutePaths.startupProblem,
        builder: (_, _) => const StartupProblemScreen(),
      ),
      GoRoute(path: RoutePaths.setup, builder: (_, _) => const SetupScreen()),
      GoRoute(path: RoutePaths.unlock, builder: (_, _) => const UnlockScreen()),
      GoRoute(
        path: RoutePaths.booth,
        builder: (_, _) => const BoothScreen(),
        routes: [
          GoRoute(
            path: 'operator',
            builder: (_, _) => const BoothOperatorScreen(),
          ),
        ],
      ),
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
              GoRoute(
                path: RoutePaths.events,
                builder: (_, _) => const EventsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: root,
                    builder: (_, _) => const EventEditorScreen.create(),
                  ),
                  GoRoute(
                    path: ':eventId',
                    parentNavigatorKey: root,
                    builder: (_, state) => EventEditorScreen(
                      eventId: state.pathParameters['eventId']!,
                      tab: EventEditorTab.fromName(
                        state.uri.queryParameters['tab'],
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'preflight',
                        parentNavigatorKey: root,
                        builder: (_, state) => PreflightScreen(
                          eventId: state.pathParameters['eventId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.templates,
                builder: (_, _) => const TemplateLibraryScreen(),
                routes: [
                  GoRoute(
                    path: ':templateId',
                    parentNavigatorKey: root,
                    builder: (_, state) => TemplateEditorScreen(
                      templateId: state.pathParameters['templateId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'preview',
                        parentNavigatorKey: root,
                        builder: (_, state) => TemplatePreviewScreen(
                          templateId: state.pathParameters['templateId']!,
                          document: switch (state.extra) {
                            final TemplateDocument document => document,
                            _ => null,
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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
              GoRoute(
                path: RoutePaths.diagnostics,
                builder: (_, _) => const DiagnosticsScreen(),
                routes: [
                  GoRoute(
                    path: 'camera',
                    parentNavigatorKey: root,
                    builder: (_, _) => const CameraTestScreen(),
                  ),
                ],
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
          path: RoutePaths.renderLab,
          builder: (_, _) => const RenderLabScreen(),
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
