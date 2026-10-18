import 'package:flutter/foundation.dart';

import '../../core/diagnostics/device_self_test.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/camera_service.dart';
import 'camera_copy.dart';

/// Operator words for the self-test (S18): what was measured and, for a
/// problem, how to repair it.
abstract final class SelfTestCopy {
  static String title(SelfTestCheck check) => switch (check) {
    SelfTestCheck.camera => 'Camera',
    SelfTestCheck.fileWrite => 'File write',
    SelfTestCheck.freeStorage => 'Free storage',
  };

  /// Before the first run.
  static String waiting(SelfTestCheck check) => switch (check) {
    SelfTestCheck.camera => 'Camera access and the built-in cameras.',
    SelfTestCheck.fileWrite => 'Writes, reads back and removes a test file.',
    SelfTestCheck.freeStorage => 'Space left for photos.',
  };

  /// The measured outcome and, for a problem, the repair.
  static String outcome(SelfTestResult result, TargetPlatform platform) {
    final code = result.problemCode;
    return switch (result.check) {
      SelfTestCheck.camera when code == null =>
        'Allowed · ${_lenses(result.lenses)}.',
      SelfTestCheck.camera => switch (code) {
        'CAMERA_PERMISSION_NOT_ASKED' =>
          'Not asked yet. Open the camera test and allow it.',
        'CAMERA_PERMISSION_DENIED' =>
          'Refused. Open the camera test to ask again. If the tablet does '
              'not ask: ${CameraCopy.settingsSteps(platform)}',
        'CAMERA_PERMISSION_PERMANENTLY_DENIED' =>
          'Turned off. ${CameraCopy.settingsSteps(platform)}',
        'CAMERA_PERMISSION_RESTRICTED' =>
          "Blocked by device management. Ask the tablet's administrator to "
              'allow the camera for Porcelain Photo Booth.',
        'CAMERA_NONE' => 'The tablet reports no built-in camera.',
        _ =>
          "The cameras couldn't be listed ($code). Restart the tablet and "
              'run the self-test again.',
      },
      SelfTestCheck.fileWrite when code == null =>
        'A test file was written, read back and removed in '
            '${milliseconds(result.took)}.',
      SelfTestCheck.fileWrite =>
        "A test file couldn't be written and read back ($code), so photos "
            "can't be saved. Restart the tablet and run the self-test again.",
      SelfTestCheck.freeStorage when code == null =>
        '${storage(result.freeBytes!)} free · room for about '
            '${StorageBudget.sessionsFor(result.freeBytes!)} guest sessions.',
      SelfTestCheck.freeStorage when code == 'STORAGE_LOW' =>
        'Only ${storage(result.freeBytes!)} free; the booth needs at least '
            '${storage(StorageBudget.minimumFreeBytes)}. Remove apps, videos '
            "or downloads the tablet doesn't need.",
      SelfTestCheck.freeStorage =>
        "The tablet didn't say how much space is free ($code). "
            '${_storageSettings(platform)}',
    };
  }

  static String _lenses(Set<CameraLens> lenses) =>
      lenses.containsAll(const {CameraLens.front, CameraLens.back})
      ? 'front and rear cameras'
      : lenses.contains(CameraLens.front)
      ? 'front camera only'
      : 'rear camera only';

  static String _storageSettings(TargetPlatform platform) => switch (platform) {
    TargetPlatform.iOS => 'Check it in Settings > General > iPad Storage.',
    _ => 'Check it in Settings > Storage.',
  };

  /// "23.1 GB", "640 MB".
  static String storage(int bytes) {
    const gigabyte = 1024 * 1024 * 1024;
    return bytes >= gigabyte
        ? '${(bytes / gigabyte).toStringAsFixed(1)} GB'
        : '${bytes ~/ (1024 * 1024)} MB';
  }

  /// "12 ms", "1.4 s".
  static String milliseconds(Duration duration) =>
      duration.inMilliseconds < 1000
      ? '${duration.inMilliseconds} ms'
      : '${(duration.inMilliseconds / 1000).toStringAsFixed(1)} s';
}
