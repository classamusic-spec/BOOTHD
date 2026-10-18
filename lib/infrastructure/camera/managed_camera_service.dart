import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/services/camera_service.dart';
import '../file_store/original_store.dart';
import 'camera_driver.dart';

/// Maps a plugin error [code] to a failure code and, for permission errors,
/// the permission state it reveals. [operationFailure] covers other codes.
///
/// iOS reports `CameraAccessDeniedWithoutPrompt` and `CameraAccessRestricted`;
/// Android CameraX reports only `CameraAccessDenied` or
/// `CameraPermissionsError`, so "denied forever" is indistinguishable there
/// (ADR-0007).
(CameraFailureCode, CameraPermission?) classifyCameraError(
  String code, {
  required CameraFailureCode operationFailure,
}) => switch (code) {
  'CameraAccessDenied' || 'CameraPermissionsError' || 'cameraPermission' => (
    CameraFailureCode.permissionDenied,
    CameraPermission.denied,
  ),
  'CameraAccessDeniedWithoutPrompt' => (
    CameraFailureCode.permissionDenied,
    CameraPermission.permanentlyDenied,
  ),
  'CameraAccessRestricted' => (
    CameraFailureCode.permissionRestricted,
    CameraPermission.restricted,
  ),
  'cameraNotFound' => (CameraFailureCode.cameraUnavailable, null),
  _ => (operationFailure, null),
};

/// [CameraService] that owns the camera lifecycle (ADR-0002). Spike-grade.
///
/// Every operation runs one at a time in call order. A second capture while
/// one is in flight is refused with [CameraFailureCode.captureBusy] rather
/// than queued, so double taps cannot take extra photos. Captures are
/// refused while the app is not active, and a still is returned only after
/// [OriginalStore] has validated and committed it.
final class ManagedCameraService implements CameraService {
  ManagedCameraService({
    required this._driver,
    required this._store,
    bool Function()? isAppActive,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _isAppActive = isAppActive ?? _appIsResumed,
       _clock = clock ?? DateTime.now,
       _newId = newId ?? _randomId;

  final CameraDriver _driver;
  final OriginalStore _store;
  final bool Function() _isAppActive;
  final DateTime Function() _clock;
  final String Function() _newId;

  final _changes = StreamController<CameraLifecycle>.broadcast();
  var _state = CameraLifecycle.uninitialized;
  var _permission = CameraPermission.notDetermined;
  CameraRequest? _request;
  CameraDescriptor? _camera;
  Future<void> _tail = Future.value();
  var _capturing = false;

  static bool _appIsResumed() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  static String _randomId() {
    final now = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp('[^0-9]'),
      '',
    );
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '$now-${random.padLeft(8, '0')}';
  }

  /// Subscribes to changes synchronously on listen, so no transition that
  /// follows the current state can be missed.
  @override
  Stream<CameraLifecycle> get lifecycle => Stream.multi((listener) {
    listener.add(_state);
    final subscription = _changes.stream.listen(
      listener.add,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<CameraPermission> permission() async => _permission;

  @override
  Future<List<CameraDescriptor>> availableCameras() => _serial(() async {
    try {
      return await _driver.listCameras();
    } on CameraDriverException catch (error) {
      throw _failure(error, CameraFailureCode.cameraUnavailable);
    }
  });

  @override
  Future<void> initialize(CameraRequest request) =>
      _serial(() => _open(request));

  Future<void> _open(CameraRequest request) async {
    _set(CameraLifecycle.initializing);
    try {
      final cameras = await _driver.listCameras();
      final camera = cameras.where((c) => c.id == request.cameraId).firstOrNull;
      if (camera == null) {
        throw const CameraFailure(CameraFailureCode.cameraUnavailable);
      }
      await _driver.open(camera);
      _permission = CameraPermission.granted;
      _request = request;
      _camera = camera;
      _set(CameraLifecycle.ready);
    } on CameraDriverException catch (error) {
      _set(CameraLifecycle.failed);
      throw _failure(error, CameraFailureCode.initializationFailed);
    } on CameraFailure {
      _set(CameraLifecycle.failed);
      rethrow;
    }
  }

  @override
  Future<CapturedStill> captureStill() {
    if (_capturing) {
      return Future.error(const CameraFailure(CameraFailureCode.captureBusy));
    }
    _capturing = true;
    return _serial(() async {
      try {
        final request = _request;
        final camera = _camera;
        if (_state != CameraLifecycle.ready ||
            request == null ||
            camera == null) {
          throw const CameraFailure(
            CameraFailureCode.cameraUnavailable,
            detail: 'camera not ready',
          );
        }
        if (!_isAppActive()) {
          throw const CameraFailure(CameraFailureCode.appNotActive);
        }
        _set(CameraLifecycle.capturing);
        final capturedAt = _clock();
        final bytes = await _driver.capture().onError<CameraDriverException>(
          (error, _) => throw _failure(error, CameraFailureCode.captureFailed),
        );
        try {
          return await _store.commit(
            id: _newId(),
            bytes: bytes,
            context: CaptureContext(
              lens: camera.lens,
              sensorOrientationDegrees: camera.sensorOrientationDegrees,
              mirrorPreviewRequested: request.mirrorPreview,
              mirrorOutputRequested: request.mirrorOutput,
              capturedAtUtc: capturedAt,
            ),
          );
        } on OriginalCommitException catch (error) {
          throw CameraFailure(
            CameraFailureCode.originalNotPersisted,
            detail: error.reason,
          );
        }
      } finally {
        if (_state == CameraLifecycle.capturing) _set(CameraLifecycle.ready);
        _capturing = false;
      }
    });
  }

  @override
  Future<void> suspend() => _serial(() async {
    if (_state == CameraLifecycle.ready ||
        _state == CameraLifecycle.initializing ||
        _state == CameraLifecycle.failed) {
      await _driver.close();
      _set(CameraLifecycle.suspended);
    }
  });

  @override
  Future<void> resume() => _serial(() async {
    final request = _request;
    if (_state == CameraLifecycle.suspended && request != null) {
      await _open(request);
    }
  });

  @override
  Future<void> dispose() => _serial(() async {
    await _driver.close();
    _set(CameraLifecycle.disposed);
    await _changes.close();
  });

  CameraFailure _failure(
    CameraDriverException error,
    CameraFailureCode fallback,
  ) {
    final (code, permission) = classifyCameraError(
      error.code,
      operationFailure: fallback,
    );
    if (permission != null) _permission = permission;
    return CameraFailure(code, detail: error.code);
  }

  void _set(CameraLifecycle state) {
    _state = state;
    if (!_changes.isClosed) _changes.add(state);
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
