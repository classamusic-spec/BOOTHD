import 'package:permission_handler/permission_handler.dart';

import '../../domain/services/camera_service.dart';

/// [CameraPermissions] over the maintained `permission_handler` plugin
/// (ADR-0012).
///
/// Android reports a refusal for good only as the answer to a request: its
/// status check says "not allowed" for never asked, refused once and
/// refused for good alike, and a request then resolves at once, without a
/// prompt, to "refused for good". So a status of "not allowed" reads as
/// [CameraPermission.notDetermined], and the screens ask first and show
/// the Settings repair when that is the answer.
final class PermissionHandlerCameraPermissions implements CameraPermissions {
  const PermissionHandlerCameraPermissions();

  @override
  Future<CameraPermission> status() async =>
      statusOf(await Permission.camera.status);

  @override
  Future<CameraPermission> request() async =>
      requestResultOf(await Permission.camera.request());

  @override
  Future<bool> openSettings() => openAppSettings();

  static CameraPermission statusOf(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => CameraPermission.granted,
    PermissionStatus.denied => CameraPermission.notDetermined,
    PermissionStatus.permanentlyDenied => CameraPermission.permanentlyDenied,
    PermissionStatus.restricted => CameraPermission.restricted,
  };

  /// After a request, "not allowed" means the prompt was refused.
  static CameraPermission requestResultOf(PermissionStatus status) =>
      status == PermissionStatus.denied
      ? CameraPermission.denied
      : statusOf(status);
}
