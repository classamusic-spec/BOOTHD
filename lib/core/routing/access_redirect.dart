import '../access/access_controller.dart';
import 'route_paths.dart';

/// The route guard (UX-04, AC-0305): where [location] may lead in [phase],
/// or null when it is allowed.
///
/// Each phase reaches only its own routes. In Booth Mode every other
/// location, including unknown ones and deep links into the Studio, leads
/// back to the guest welcome. A locked Studio leads to the PIN screen and
/// remembers which Studio page was asked for; so does startup, so a page
/// requested while storage opens is still subject to the guard afterwards.
String? accessRedirect(AccessPhase phase, Uri location) {
  if (phase == AccessPhase.starting) {
    return location.path == RoutePaths.starting
        ? null
        : _withFrom(RoutePaths.starting, location);
  }
  if (location.path == RoutePaths.starting) {
    // Startup is over: go where was asked for, if this phase allows it.
    final target = _from(location) ?? Uri(path: RoutePaths.home);
    return _guard(phase, target) ?? target.toString();
  }
  return _guard(phase, location);
}

String? _guard(AccessPhase phase, Uri location) {
  final path = location.path;
  bool within(String root) => path == root || path.startsWith('$root/');
  String? only(String allowed) => path == allowed ? null : allowed;

  switch (phase) {
    case AccessPhase.starting:
      return only(RoutePaths.starting);
    case AccessPhase.startupFailed:
      return only(RoutePaths.startupProblem);
    case AccessPhase.setup:
      return only(RoutePaths.setup);
    case AccessPhase.booth:
      return within(RoutePaths.booth) ? null : RoutePaths.booth;
    case AccessPhase.locked:
      if (path == RoutePaths.unlock) return null;
      return isStudioLocation(location)
          ? _withFrom(RoutePaths.unlock, location)
          : RoutePaths.unlock;
    case AccessPhase.operator:
      if (path == RoutePaths.unlock) {
        final from = _from(location);
        return from != null && isStudioLocation(from)
            ? from.toString()
            : RoutePaths.dashboard;
      }
      if (path == RoutePaths.startupProblem ||
          path == RoutePaths.setup ||
          within(RoutePaths.booth) ||
          path == RoutePaths.home) {
        return RoutePaths.dashboard;
      }
      return null;
  }
}

String _withFrom(String path, Uri from) =>
    Uri(path: path, queryParameters: {'from': from.toString()}).toString();

Uri? _from(Uri location) {
  final from = location.queryParameters['from'];
  return from == null ? null : Uri.tryParse(from);
}

/// Whether [location] is an operator page worth returning to after
/// unlocking: an in-app path, never another host or scheme.
bool isStudioLocation(Uri location) =>
    !location.hasScheme &&
    !location.hasAuthority &&
    (location.path == RoutePaths.dashboard ||
        location.path.startsWith('${RoutePaths.dashboard}/') ||
        location.path == RoutePaths.guestPreview ||
        location.path.startsWith('/dev/'));
