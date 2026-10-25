import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../domain/services/camera_service.dart';
import '../file_store/original_store.dart';
import 'camera_driver.dart';

/// Maps a driver error [code] to a failure code and, for permission errors,
/// the permission state it reveals. [operationFailure] covers other codes.
///
/// iOS reports `CameraAccessDeniedWithoutPrompt` and `CameraAccessRestricted`;
/// Android CameraX reports only `CameraAccessDenied` or
/// `CameraPermissionsError` (ADR-0007). The codes `cameraInUse`,
/// `cameraInterrupted` and the rest come from [classifyCameraErrorDescription].
(CameraFailureCode, CameraPermission?) classifyCameraError(
  String code, {
  required CameraFailureCode operationFailure,
}) => switch (code) {
  'CameraAccessDenied' || 'CameraPermissionsError' || 'cameraPermission' => (
    CameraFailureCode.permissionDenied,
    CameraPermission.denied,
  ),
  'CameraAccessDeniedWithoutPrompt' => (
    CameraFailureCode.permissionPermanentlyDenied,
    CameraPermission.permanentlyDenied,
  ),
  'CameraAccessRestricted' => (
    CameraFailureCode.permissionRestricted,
    CameraPermission.restricted,
  ),
  'cameraNotFound' ||
  'doNotDisturb' ||
  'cameraDisabled' ||
  'cameraFatal' => (CameraFailureCode.cameraUnavailable, null),
  'cameraInUse' => (CameraFailureCode.cameraInUse, null),
  'cameraInterrupted' => (CameraFailureCode.interrupted, null),
  'notOpen' => (CameraFailureCode.notReady, null),
  _ => (operationFailure, null),
};

/// The failure that a permission other than granted means.
CameraFailure permissionFailure(CameraPermission permission) =>
    CameraFailure(switch (permission) {
      CameraPermission.permanentlyDenied =>
        CameraFailureCode.permissionPermanentlyDenied,
      CameraPermission.restricted => CameraFailureCode.permissionRestricted,
      _ => CameraFailureCode.permissionDenied,
    });

/// [CameraService] that owns the camera lifecycle (ADR-0002, ADR-0012).
///
/// Every operation runs one at a time in call order. A second capture while
/// one is in flight is refused at once with [CameraFailureCode.captureBusy]
/// rather than queued, so double taps cannot take extra photos. Captures
/// are refused while the app is not active, and a still is returned only
/// after [OriginalStore] has validated and committed it. Permission is
/// checked before the camera opens; it is asked for only if never asked.
/// When the open camera reports an error by itself (an interruption,
/// another app), it is closed and the status says why; [resume] opens it
/// again and never takes a photo.
final class ManagedCameraService implements CameraService {
  ManagedCameraService({
    required this._driver,
    required this._permissions,
    required this._store,
    bool Function()? isAppActive,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _isAppActive = isAppActive ?? _appIsResumed,
       _clock = clock ?? DateTime.now,
       _newId = newId ?? _randomId {
    _driverErrors = _driver.errors.listen(_onDriverError);
  }

  final CameraDriver _driver;
  final CameraPermissions _permissions;
  final OriginalStore _store;
  final bool Function() _isAppActive;
  final DateTime Function() _clock;
  final String Function() _newId;
  late final StreamSubscription<CameraDriverException> _driverErrors;

  final _changes = StreamController<CameraStatus>.broadcast();
  var _status = CameraStatus.initial;
  Future<void> _tail = Future.value();
  var _capturing = false;

  /// Before the first lifecycle report the app is starting in the
  /// foreground.
  static bool _appIsResumed() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  static String _randomId() {
    final now = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp('[^0-9]'),
      '',
    );
    final random = Random.secure().nextInt(0x100000000).toRadixString(16);
    return '$now-${random.padLeft(8, '0')}';
  }

  @override
  CameraStatus get status => _status;

  /// Subscribes to changes synchronously on listen, so no transition that
  /// follows the current status can be missed.
  @override
  Stream<CameraStatus> get statusChanges => Stream.multi((listener) {
    listener.add(_status);
    final subscription = _changes.stream.listen(
      listener.add,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<CameraPermission> permission() => _readPermission(_permissions.status);

  /// Serialised, so a prompt never overlaps another or a camera opening.
  @override
  Future<CameraPermission> requestPermission() =>
      _serial(() => _readPermission(_permissions.request));

  Future<CameraPermission> _readPermission(
    Future<CameraPermission> Function() read,
  ) async {
    final CameraPermission permission;
    try {
      permission = await read();
    } on Object catch (error) {
      throw _unexpected(error, CameraFailureCode.initializationFailed);
    }
    _update(permission: permission);
    return permission;
  }

  @override
  Future<bool> openPermissionSettings() async {
    try {
      return await _permissions.openSettings();
    } on Object {
      return false;
    }
  }

  @override
  Future<List<CameraDescriptor>> availableCameras() => _serial(() async {
    try {
      return await _driver.listCameras();
    } on CameraDriverException catch (error) {
      throw _failure(error, CameraFailureCode.cameraUnavailable);
    } on Object catch (error) {
      throw _unexpected(error, CameraFailureCode.cameraUnavailable);
    }
  });

  @override
  Future<CameraCapabilities> initialize(CameraRequest request) =>
      _serial(() async {
        final capabilities = _status.capabilities;
        if (_status.isReady &&
            _status.request == request &&
            capabilities != null) {
          return capabilities;
        }
        return _open(request, mayAsk: true);
      });

  Future<CameraCapabilities> _open(
    CameraRequest request, {
    required bool mayAsk,
  }) async {
    _set(
      CameraStatus(
        lifecycle: CameraLifecycle.initializing,
        permission: _status.permission,
        request: request,
      ),
    );
    try {
      var permission = await _permissions.status();
      if (mayAsk && permission == CameraPermission.notDetermined) {
        permission = await _permissions.request();
      }
      _update(permission: permission);
      if (permission != CameraPermission.granted) {
        throw permissionFailure(permission);
      }
      final cameras = await _driver.listCameras();
      final camera = cameras.where((c) => c.id == request.cameraId).firstOrNull;
      if (camera == null) {
        throw CameraFailure(
          cameras.isEmpty
              ? CameraFailureCode.noCamera
              : CameraFailureCode.cameraUnavailable,
        );
      }
      final capabilities = await _driver.open(camera);
      _set(
        CameraStatus(
          lifecycle: CameraLifecycle.ready,
          permission: CameraPermission.granted,
          request: request,
          capabilities: capabilities,
        ),
      );
      return capabilities;
    } on CameraFailure catch (failure) {
      _fail(failure);
      rethrow;
    } on CameraDriverException catch (error) {
      final failure = _failure(error, CameraFailureCode.initializationFailed);
      _fail(failure);
      throw failure;
    } on Object catch (error) {
      final failure = _unexpected(
        error,
        CameraFailureCode.initializationFailed,
      );
      _fail(failure);
      throw failure;
    }
  }

  @override
  Future<CapturedStill> captureStill({
    CaptureOrigin origin = CaptureOrigin.session,
  }) {
    if (_capturing) {
      return Future.error(const CameraFailure(CameraFailureCode.captureBusy));
    }
    _capturing = true;
    return _serial(() async {
      try {
        final request = _status.request;
        final capabilities = _status.capabilities;
        if (_status.lifecycle != CameraLifecycle.ready ||
            request == null ||
            capabilities == null) {
          throw const CameraFailure(CameraFailureCode.notReady);
        }
        if (!_isAppActive()) {
          throw const CameraFailure(CameraFailureCode.appNotActive);
        }
        _update(lifecycle: CameraLifecycle.capturing);
        final capturedAt = _clock();
        final DriverStill still;
        try {
          still = await _driver.capture();
        } on CameraDriverException catch (error) {
          throw _failure(error, CameraFailureCode.captureFailed);
        } on Object catch (error) {
          throw _unexpected(error, CameraFailureCode.captureFailed);
        }
        try {
          return await _store.commit(
            id: _newId(),
            bytes: still.bytes,
            context: CaptureContext(
              lens: capabilities.camera.lens,
              sensorOrientationDegrees:
                  capabilities.camera.sensorOrientationDegrees,
              mirrorPreviewRequested: request.mirrorPreview,
              mirrorOutputRequested: request.mirrorOutput,
              capturedAtUtc: capturedAt,
              deviceOrientation: still.orientation,
              origin: origin,
            ),
          );
        } on OriginalCommitException catch (error) {
          throw CameraFailure(
            CameraFailureCode.originalNotPersisted,
            detail: error.reason,
          );
        } on Object catch (error) {
          throw _unexpected(error, CameraFailureCode.originalNotPersisted);
        }
      } finally {
        if (_status.lifecycle == CameraLifecycle.capturing) {
          _update(lifecycle: CameraLifecycle.ready);
        }
        _capturing = false;
      }
    });
  }

  @override
  Future<void> suspend() => _serial(() async {
    switch (_status.lifecycle) {
      case CameraLifecycle.initializing ||
          CameraLifecycle.ready ||
          CameraLifecycle.capturing ||
          CameraLifecycle.failed:
        await _close();
        _set(
          CameraStatus(
            lifecycle: CameraLifecycle.suspended,
            permission: _status.permission,
            request: _status.request,
            failure: _status.failure,
          ),
        );
      case CameraLifecycle.uninitialized ||
          CameraLifecycle.suspended ||
          CameraLifecycle.disposed:
        break;
    }
  });

  @override
  Future<void> resume() => _serial(() async {
    final request = _status.request;
    final lifecycle = _status.lifecycle;
    if (request == null ||
        (lifecycle != CameraLifecycle.suspended &&
            lifecycle != CameraLifecycle.failed)) {
      return;
    }
    try {
      // Never prompts: a permission changed in Settings is simply read.
      await _open(request, mayAsk: false);
    } on CameraFailure {
      // The status says why.
    }
  });

  @override
  Future<void> dispose() => _serial(() async {
    await _driverErrors.cancel();
    await _close();
    _set(
      CameraStatus(
        lifecycle: CameraLifecycle.disposed,
        permission: _status.permission,
      ),
    );
    await _changes.close();
  });

  Future<void> _close() async {
    try {
      await _driver.close();
    } on Object {
      // Closing is best effort; the plugin may already have released it.
    }
  }

  /// The open camera reported an error by itself: close it and say why.
  void _onDriverError(CameraDriverException error) {
    final lifecycle = _status.lifecycle;
    if (lifecycle != CameraLifecycle.ready &&
        lifecycle != CameraLifecycle.capturing) {
      return;
    }
    final failure = _failure(error, CameraFailureCode.interrupted);
    unawaited(
      _serial(() async {
        if (_status.lifecycle != CameraLifecycle.ready) return;
        await _close();
        _fail(failure);
      }),
    );
  }

  CameraFailure _failure(
    CameraDriverException error,
    CameraFailureCode fallback,
  ) {
    final (code, permission) = classifyCameraError(
      error.code,
      operationFailure: fallback,
    );
    if (permission != null) _update(permission: permission);
    return CameraFailure(code, detail: error.code);
  }

  /// Errors outside the plugin's own (platform channel failures, file
  /// system errors) still become typed failures; only the error type is
  /// kept, so no paths or photo data reach logs.
  static CameraFailure _unexpected(Object error, CameraFailureCode code) =>
      CameraFailure(code, detail: '${error.runtimeType}');

  void _fail(CameraFailure failure) => _set(
    CameraStatus(
      lifecycle: CameraLifecycle.failed,
      permission: _status.permission,
      request: _status.request,
      failure: failure,
    ),
  );

  void _update({CameraLifecycle? lifecycle, CameraPermission? permission}) =>
      _set(
        CameraStatus(
          lifecycle: lifecycle ?? _status.lifecycle,
          permission: permission ?? _status.permission,
          request: _status.request,
          capabilities: _status.capabilities,
          failure: _status.failure,
        ),
      );

  void _set(CameraStatus status) {
    _status = status;
    if (!_changes.isClosed) _changes.add(status);
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
