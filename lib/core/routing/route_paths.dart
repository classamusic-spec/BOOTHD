/// Route locations shared by the router and by screens that navigate.
///
/// Kept in core so features can navigate without importing the app layer.
abstract final class RoutePaths {
  static const home = '/';

  /// Developer spikes (M01), registered only outside release builds.
  static const renderSpike = '/dev/render-spike';
  static const cameraSpike = '/dev/camera-spike';
}
