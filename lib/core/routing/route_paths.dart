/// Route locations shared by the router and by screens that navigate.
///
/// Kept in core so features can navigate without importing the app layer.
abstract final class RoutePaths {
  /// Entry point; the access guard sends it wherever the app's phase
  /// allows (UX-04).
  static const home = '/';

  /// Shown while storage opens, and if it cannot.
  static const starting = '/starting';
  static const startupProblem = '/startup-problem';

  /// First-run setup (S01).
  static const setup = '/setup';

  /// Operator unlock (S28 for the Studio).
  static const unlock = '/unlock';

  /// Booth Mode: the isolated guest subtree (UX-04). Only reachable while
  /// the booth runs, and nothing else is reachable then.
  static const booth = '/booth';

  /// The operator's way out of Booth Mode (S28): PIN, then Exit Booth.
  static const boothOperator = '/booth/operator';

  /// Studio sections (UX-04), one navigation branch each.
  static const dashboard = '/studio';
  static const events = '/studio/events';
  static const templates = '/studio/templates';
  static const gallery = '/studio/gallery';
  static const settings = '/studio/settings';
  static const diagnostics = '/studio/diagnostics';

  /// The event editor for a new event (S04).
  static const newEvent = '/studio/events/new';

  /// The event editor (S04), optionally open at [tab] (an EventEditorTab
  /// name).
  static String event(String eventId, {String? tab}) =>
      tab == null ? '$events/$eventId' : '$events/$eventId?tab=$tab';

  /// The gallery opened on one event.
  static String galleryEvent(String eventId) => '$gallery?event=$eventId';

  /// One session in the gallery (S14).
  static String gallerySession(String sessionId) => '$gallery/$sessionId';

  /// The launch checklist for an event (S05, S19).
  static String preflight(String eventId) => '$events/$eventId/preflight';

  /// The Template Studio for one template (S07).
  static String templateEditor(String templateId) => '$templates/$templateId';

  /// A template rendered as it prints (S11): the editor's current document
  /// when opened from the editor, otherwise the newest saved revision.
  static String templatePreview(String templateId) =>
      '$templates/$templateId/preview';

  /// A Settings section, kept in the location so it survives rotation and
  /// works in both the two-pane and the single-pane layout.
  static String settingsSection(String section) => '$settings?section=$section';

  /// Operator preview of the guest welcome screen (not Booth Mode).
  static const guestPreview = '/preview/guest-welcome';

  /// The camera test (S18, M06): permission, preview, mirroring and a saved
  /// test photo. In every build.
  static const cameraTest = '$diagnostics/camera';

  /// Developer tools, registered only outside release builds.
  static const renderLab = '/dev/render-lab';
  static const componentGallery = '/dev/components';
}
