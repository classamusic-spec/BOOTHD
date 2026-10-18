import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/services/camera_service.dart';

/// The outcome of one press of a shutter button.
sealed class CaptureOutcome {
  const CaptureOutcome();
}

/// Saved: decoded, validated and committed.
final class CaptureSaved extends CaptureOutcome {
  const CaptureSaved(this.still);

  final CapturedStill still;
}

/// Not saved, and why.
final class CaptureFailed extends CaptureOutcome {
  const CaptureFailed(this.failure);

  final CameraFailure failure;
}

/// A second press while a photo was being taken: ignored, nothing taken.
final class CaptureIgnored extends CaptureOutcome {
  const CaptureIgnored();
}

/// A screen's use of the camera (A-09, AC-0601, AC-0606, AC-0607): opens
/// the camera the screen wants, follows the app's lifecycle and takes
/// photos one at a time.
///
/// While camera access has never been asked for, the wanted camera waits
/// for [allow], so the screen can say why the booth needs the camera
/// before the system asks. When the app is hidden (another app, the home
/// screen, the lock screen) the camera is released; when the app is back
/// in front it opens again, or opens for the first time if access was
/// turned on in Settings meanwhile, and no photo is ever taken by that. A
/// shutter press while a photo is being taken is ignored. Owned by the
/// screen, which disposes it (releasing the camera) when it closes.
final class CameraSessionController extends ChangeNotifier {
  CameraSessionController(this._service) {
    _status = _service.status;
    _subscription = _service.statusChanges.listen((status) {
      _status = status;
      notifyListeners();
    });
    _lifecycle = AppLifecycleListener(onStateChange: _onAppState);
    unawaited(_readPermission());
  }

  final CameraService _service;
  late final StreamSubscription<CameraStatus> _subscription;
  late final AppLifecycleListener _lifecycle;
  late CameraStatus _status;
  CameraRequest? _wanted;
  var _permissionKnown = false;
  var _capturing = false;
  var _disposed = false;

  CameraStatus get status => _status;

  /// Whether the permission has been read since the screen opened; until
  /// then [status] may show the service's earlier view of it.
  bool get permissionKnown => _permissionKnown;

  /// Whether a photo is being taken now.
  bool get capturing => _capturing;

  void _onAppState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        unawaited(_service.suspend());
      case AppLifecycleState.resumed:
        unawaited(_resumed());
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        // Inactive (a system prompt, Control Center): the camera stays
        // open, but the service refuses any capture until resumed.
        break;
    }
  }

  Future<void> _resumed() async {
    if (_service.status.request != null) {
      // Opens again, re-reading the permission; never prompts.
      await _service.resume();
      return;
    }
    // Never opened: access may have been turned on in Settings meanwhile.
    if (await _readPermission() == CameraPermission.granted) {
      await _openWanted();
    }
  }

  Future<CameraPermission?> _readPermission() async {
    try {
      return await _service.permission();
    } on CameraFailure {
      return null;
    } finally {
      _permissionKnown = true;
      if (!_disposed) notifyListeners();
    }
  }

  /// Opens the camera for [request], unless camera access has never been
  /// asked for: then [request] waits for [allow]. Failures land in
  /// [status].
  Future<void> open(CameraRequest request) async {
    _wanted = request;
    if (await _readPermission() == CameraPermission.notDetermined) return;
    await _openWanted();
  }

  Future<void> _openWanted() async {
    final wanted = _wanted;
    if (wanted == null || _disposed) return;
    try {
      await _service.initialize(wanted);
    } on CameraFailure {
      // The status says why.
    }
  }

  /// Asks for camera access (the system prompt, when it can) and opens the
  /// wanted camera if it is allowed.
  Future<CameraPermission> allow() async {
    final CameraPermission permission;
    try {
      permission = await _service.requestPermission();
    } on CameraFailure {
      return _status.permission;
    }
    if (permission == CameraPermission.granted) await _openWanted();
    return permission;
  }

  /// Opens this app's page in the system Settings; false if it could not.
  Future<bool> openSettings() => _service.openPermissionSettings();

  /// Takes one photo as [origin].
  Future<CaptureOutcome> capture({
    CaptureOrigin origin = CaptureOrigin.session,
  }) async {
    if (_capturing) return const CaptureIgnored();
    _capturing = true;
    notifyListeners();
    try {
      return CaptureSaved(await _service.captureStill(origin: origin));
    } on CameraFailure catch (failure) {
      return failure.code == CameraFailureCode.captureBusy
          ? const CaptureIgnored()
          : CaptureFailed(failure);
    } finally {
      _capturing = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    unawaited(_subscription.cancel());
    // The screen is gone: release the camera for whoever needs it next.
    unawaited(_service.suspend());
    super.dispose();
  }
}
