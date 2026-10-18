/// Route locations shared by the router and by screens that navigate.
///
/// Kept in core so features can navigate without importing the app layer.
abstract final class RoutePaths {
  /// Entry point. Redirects to the Studio dashboard until first-run setup
  /// and the operator PIN arrive (M03), which will gate it.
  static const home = '/';

  /// Studio sections (UX-04), one navigation branch each.
  static const dashboard = '/studio';
  static const events = '/studio/events';
  static const templates = '/studio/templates';
  static const gallery = '/studio/gallery';
  static const settings = '/studio/settings';
  static const diagnostics = '/studio/diagnostics';

  /// A Settings section, kept in the location so it survives rotation and
  /// works in both the two-pane and the single-pane layout.
  static String settingsSection(String section) => '$settings?section=$section';

  /// Operator preview of the guest welcome screen (not Booth Mode).
  static const guestPreview = '/preview/guest-welcome';

  /// Developer tools, registered only outside release builds.
  static const renderSpike = '/dev/render-spike';
  static const cameraSpike = '/dev/camera-spike';
  static const componentGallery = '/dev/components';
}
