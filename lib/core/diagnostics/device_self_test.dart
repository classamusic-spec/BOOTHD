import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/managed_storage.dart';
import '../di/service_providers.dart';

/// The checks of the Diagnostics self-test (S18).
enum SelfTestCheck { camera, fileWrite, freeStorage }

/// One check's measured outcome; [problemCode] is null when it passed.
@immutable
final class SelfTestResult {
  const SelfTestResult(
    this.check, {
    required this.took,
    this.problemCode,
    this.permission,
    this.lenses = const {},
    this.freeBytes,
  });

  final SelfTestCheck check;
  final Duration took;

  /// A `CAMERA_*` or `STORAGE_*` code (A-14).
  final String? problemCode;

  /// Camera: the permission as read (never asked for here) and the
  /// built-in lenses found.
  final CameraPermission? permission;
  final Set<CameraLens> lenses;

  /// Free storage: what the tablet reported, when it did.
  final int? freeBytes;

  bool get passed => problemCode == null;
}

/// The Diagnostics self-test (S18): reads the camera permission and lists
/// the built-in cameras, writes a test file, reads it back and removes it,
/// and measures free space against the booth's budget. Each check is
/// timed. Nothing opens the camera, asks for permission or keeps a file:
/// the camera test does those on purpose.
final class DeviceSelfTest {
  DeviceSelfTest({
    required this._camera,
    required this._storage,
    required this._space,
    Stopwatch Function()? stopwatch,
  }) : _stopwatch = stopwatch ?? Stopwatch.new;

  final CameraService _camera;
  final ManagedStorage _storage;
  final DeviceStorageInfo _space;
  final Stopwatch Function() _stopwatch;

  /// Runs the checks one after another, in [SelfTestCheck] order.
  Future<List<SelfTestResult>> run() async => [
    for (final check in SelfTestCheck.values) await this.check(check),
  ];

  Future<SelfTestResult> check(SelfTestCheck check) async {
    final watch = _stopwatch()..start();
    switch (check) {
      case SelfTestCheck.camera:
        try {
          final permission = await _camera.permission();
          if (permission.problemCode case final code?) {
            return SelfTestResult(
              check,
              took: watch.elapsed,
              problemCode: code,
              permission: permission,
            );
          }
          final lenses = {
            for (final camera in await _camera.availableCameras())
              if (camera.lens != CameraLens.external) camera.lens,
          };
          return SelfTestResult(
            check,
            took: watch.elapsed,
            problemCode: lenses.isEmpty ? 'CAMERA_NONE' : null,
            permission: permission,
            lenses: lenses,
          );
        } on CameraFailure catch (failure) {
          return SelfTestResult(
            check,
            took: watch.elapsed,
            problemCode: failure.code.diagnostic,
          );
        }
      case SelfTestCheck.fileWrite:
        final status = await _storage.probeWrite();
        return SelfTestResult(
          check,
          took: watch.elapsed,
          problemCode: switch (status) {
            CapabilityProblem(:final code) => code,
            CapabilityNotYetAvailable() => 'STORAGE_NOT_CHECKED',
            CapabilityReady() => null,
          },
        );
      case SelfTestCheck.freeStorage:
        final free = await _space.freeBytes();
        return SelfTestResult(
          check,
          took: watch.elapsed,
          freeBytes: free,
          problemCode: switch (free) {
            null => 'STORAGE_FREE_UNKNOWN',
            < StorageBudget.minimumFreeBytes => 'STORAGE_LOW',
            _ => null,
          },
        );
    }
  }
}

final deviceSelfTestProvider = Provider<DeviceSelfTest>(
  (ref) => DeviceSelfTest(
    camera: ref.watch(cameraServiceProvider),
    storage: ref.watch(managedStorageProvider),
    space: ref.watch(deviceStorageInfoProvider),
  ),
);
