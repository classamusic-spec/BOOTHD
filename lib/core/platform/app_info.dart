/// Product identity shown in the app. [version] and [buildNumber] must match
/// `pubspec.yaml` (checked by `test/core/app_info_test.dart`).
abstract final class AppInfo {
  static const name = 'Porcelain Photo Booth';
  static const version = '0.1.0';
  static const buildNumber = 1;
}
