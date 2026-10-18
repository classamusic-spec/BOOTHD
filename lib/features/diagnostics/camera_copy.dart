import 'package:flutter/foundation.dart';

import '../../domain/services/camera_service.dart';

/// Operator words for the camera (S18, AC-0601): what happened and how to
/// fix it, never a raw exception.
abstract final class CameraCopy {
  static String lens(CameraLens lens) => switch (lens) {
    CameraLens.front => 'Front camera',
    CameraLens.back => 'Rear camera',
    CameraLens.external => 'External camera',
  };

  static String orientation(CaptureOrientation orientation) =>
      switch (orientation) {
        CaptureOrientation.portraitUp => 'Portrait',
        CaptureOrientation.portraitDown => 'Portrait, upside down',
        CaptureOrientation.landscapeLeft => 'Landscape, turned left',
        CaptureOrientation.landscapeRight => 'Landscape, turned right',
        CaptureOrientation.unknown => 'Not reported',
      };

  /// Where to turn camera access back on.
  static String settingsSteps(TargetPlatform platform) => switch (platform) {
    TargetPlatform.iOS =>
      'Open Settings > Porcelain Photo Booth and turn on Camera.',
    _ =>
      'Open Settings > Apps > Porcelain Photo Booth > Permissions > Camera '
          'and choose Allow.',
  };

  static String permission(CameraPermission permission) => switch (permission) {
    CameraPermission.notDetermined => 'Not asked yet',
    CameraPermission.granted => 'Allowed',
    CameraPermission.denied => 'Refused',
    CameraPermission.permanentlyDenied => 'Turned off in Settings',
    CameraPermission.restricted => 'Blocked by device management',
  };

  /// A permission problem: a title and what to do.
  static (String, String) permissionHelp(
    CameraPermission permission,
    TargetPlatform platform,
  ) => switch (permission) {
    CameraPermission.notDetermined || CameraPermission.granted => (
      'The booth needs the camera',
      'Tap Allow camera, then choose Allow when the tablet asks. Photos '
          'stay on this tablet.',
    ),
    CameraPermission.denied => (
      'Camera access was refused',
      'Tap Allow camera to ask again. If the tablet does not ask: '
          '${settingsSteps(platform)}',
    ),
    CameraPermission.permanentlyDenied => (
      'Camera access is off for this app',
      settingsSteps(platform),
    ),
    CameraPermission.restricted => (
      'The camera is blocked on this tablet',
      "Device management or Screen Time blocks it. Ask the tablet's "
          'administrator to allow the camera for Porcelain Photo Booth.',
    ),
  };

  /// A camera failure: a title and what to do. Permission failures use
  /// [permissionHelp].
  static (String, String) failure(CameraFailure failure) =>
      switch (failure.code) {
        CameraFailureCode.permissionDenied ||
        CameraFailureCode.permissionPermanentlyDenied ||
        CameraFailureCode.permissionRestricted => (
          'Camera access is off',
          'Allow the camera to test it.',
        ),
        CameraFailureCode.noCamera => (
          'No camera found',
          'This tablet reports no built-in camera.',
        ),
        CameraFailureCode.cameraUnavailable => (
          "That camera isn't available",
          'Choose the other camera, or restart the tablet and try again.',
        ),
        CameraFailureCode.cameraInUse => (
          'Another app is using the camera',
          'Close video calls and other camera apps, then try again.',
        ),
        CameraFailureCode.initializationFailed => (
          "The camera didn't start",
          'Try again. If it keeps failing, restart the tablet.',
        ),
        CameraFailureCode.interrupted => (
          'The camera was interrupted',
          'Another app or a system feature took it. Try again when the '
              'booth is in front.',
        ),
        CameraFailureCode.appNotActive => (
          'The booth was not in front',
          'No photo is taken while another app or a system screen is '
              'showing. Try again.',
        ),
        CameraFailureCode.notReady => (
          "The camera isn't open yet",
          'Wait for the picture to appear, then try again.',
        ),
        CameraFailureCode.captureBusy => (
          'Already taking a photo',
          'One photo at a time.',
        ),
        CameraFailureCode.captureFailed => (
          "The photo couldn't be taken",
          'Try again. If it keeps failing, restart the tablet.',
        ),
        CameraFailureCode.originalNotPersisted => (
          "The photo couldn't be saved",
          'Nothing was saved. Check free space in Diagnostics, then try '
              'again.',
        ),
      };

  /// "4032 × 3024 px · 12.2 MP".
  static String size(int width, int height) =>
      '$width × $height px · '
      '${(width * height / 1000000).toStringAsFixed(1)} MP';

  /// "3.1 MB".
  static String bytes(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).ceil()} KB';
}
