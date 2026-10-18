import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:porcelain_photo_booth/domain/services/booth_capabilities.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/camera/managed_camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/codecs/jpeg_encoder.dart';

/// A tablet's front and rear cameras, as Android and iPadOS report them.
const frontCamera = CameraDescriptor(
  id: 'front',
  lens: CameraLens.front,
  sensorOrientationDegrees: 270,
);
const rearCamera = CameraDescriptor(
  id: 'rear',
  lens: CameraLens.back,
  sensorOrientationDegrees: 90,
);

/// The camera service with no camera (M06 "mock service for testing"):
/// scripted permission, cameras and failures, and captures that commit a
/// small real JPEG to a [SimulatedStillStore]. It keeps the contract's
/// rules (serialised captures, busy refusal, no capture unless ready,
/// resume never prompts) and counts what it was asked to do.
///
/// It never stands in for a device run: no physical-camera acceptance
/// criterion passes on it.
final class SimulatedCameraService implements CameraService {
  SimulatedCameraService({
    this.systemPermission = CameraPermission.granted,
    this.promptAnswer = CameraPermission.granted,
    this.cameras = const [frontCamera, rearCamera],
    SimulatedStillStore? store,
    DateTime Function()? clock,
  }) : store = store ?? SimulatedStillStore(),
       _clock = clock ?? (() => DateTime.utc(2026, 11, 14, 18, 5));

  /// What the platform reports now; change it to simulate Settings.
  CameraPermission systemPermission;

  /// What the system prompt answers; becomes [systemPermission].
  CameraPermission promptAnswer;

  List<CameraDescriptor> cameras;
  final SimulatedStillStore store;
  final DateTime Function() _clock;

  /// The next [initialize] or [captureStill] fails with this, once.
  CameraFailure? initializeFailure;
  CameraFailure? captureFailure;

  /// While set, a capture waits for it: a photo in flight.
  Completer<void>? captureGate;

  /// Whether the app counts as in front; captures are refused otherwise.
  bool appActive = true;

  var prompts = 0;
  var settingsOpened = 0;
  var initializations = 0;
  var shutters = 0;
  var suspensions = 0;
  var resumptions = 0;

  final _changes = StreamController<CameraStatus>.broadcast();
  var _status = CameraStatus.initial;
  var _capturing = false;

  @override
  CameraStatus get status => _status;

  @override
  Stream<CameraStatus> get statusChanges => Stream.multi((listener) {
    listener.add(_status);
    final subscription = _changes.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<CameraPermission> permission() async {
    _set(permission: systemPermission);
    return systemPermission;
  }

  @override
  Future<CameraPermission> requestPermission() async {
    if (systemPermission.canAsk) {
      prompts++;
      systemPermission = promptAnswer;
    }
    _set(permission: systemPermission);
    return systemPermission;
  }

  @override
  Future<bool> openPermissionSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<List<CameraDescriptor>> availableCameras() async => cameras;

  @override
  Future<CameraCapabilities> initialize(CameraRequest request) async {
    final open = _status.capabilities;
    if (_status.isReady && _status.request == request && open != null) {
      return open;
    }
    initializations++;
    return _open(request, mayAsk: true);
  }

  Future<CameraCapabilities> _open(
    CameraRequest request, {
    required bool mayAsk,
  }) async {
    _replace(
      CameraStatus(
        lifecycle: CameraLifecycle.initializing,
        permission: _status.permission,
        request: request,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    if (mayAsk && systemPermission == CameraPermission.notDetermined) {
      prompts++;
      systemPermission = promptAnswer;
    }
    _set(permission: systemPermission);
    if (systemPermission != CameraPermission.granted) {
      throw _fail(permissionFailure(systemPermission));
    }
    final failure = initializeFailure;
    if (failure != null) {
      initializeFailure = null;
      throw _fail(failure);
    }
    final camera = cameras.where((c) => c.id == request.cameraId).firstOrNull;
    if (camera == null) {
      throw _fail(
        CameraFailure(
          cameras.isEmpty
              ? CameraFailureCode.noCamera
              : CameraFailureCode.cameraUnavailable,
        ),
      );
    }
    final capabilities = CameraCapabilities(
      camera: camera,
      previewWidthPx: 1920,
      previewHeightPx: 1440,
      minZoom: 1,
      maxZoom: camera.lens == CameraLens.back ? 5 : 1,
      focusPointSupported: camera.lens == CameraLens.back,
      exposurePointSupported: true,
    );
    _replace(
      CameraStatus(
        lifecycle: CameraLifecycle.ready,
        permission: CameraPermission.granted,
        request: request,
        capabilities: capabilities,
      ),
    );
    return capabilities;
  }

  @override
  Future<CapturedStill> captureStill({
    CaptureOrigin origin = CaptureOrigin.session,
  }) async {
    if (_capturing) {
      throw const CameraFailure(CameraFailureCode.captureBusy);
    }
    final request = _status.request;
    final capabilities = _status.capabilities;
    if (!_status.isReady || request == null || capabilities == null) {
      throw const CameraFailure(CameraFailureCode.notReady);
    }
    if (!appActive) {
      throw const CameraFailure(CameraFailureCode.appNotActive);
    }
    _capturing = true;
    _set(lifecycle: CameraLifecycle.capturing);
    try {
      shutters++;
      await captureGate?.future;
      final failure = captureFailure;
      if (failure != null) {
        captureFailure = null;
        throw failure;
      }
      return store.commit(
        lens: capabilities.camera.lens,
        sensorOrientationDegrees: capabilities.camera.sensorOrientationDegrees,
        mirrorPreview: request.mirrorPreview,
        mirrorOutput: request.mirrorOutput,
        capturedAtUtc: _clock(),
        origin: origin,
      );
    } finally {
      _capturing = false;
      if (_status.lifecycle == CameraLifecycle.capturing) {
        _set(lifecycle: CameraLifecycle.ready);
      }
    }
  }

  @override
  Future<void> suspend() async {
    switch (_status.lifecycle) {
      case CameraLifecycle.initializing ||
          CameraLifecycle.ready ||
          CameraLifecycle.capturing ||
          CameraLifecycle.failed:
        suspensions++;
        _replace(
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
  }

  @override
  Future<void> resume() async {
    final request = _status.request;
    final lifecycle = _status.lifecycle;
    if (request == null ||
        (lifecycle != CameraLifecycle.suspended &&
            lifecycle != CameraLifecycle.failed)) {
      return;
    }
    resumptions++;
    try {
      await _open(request, mayAsk: false);
    } on CameraFailure {
      // The status says why.
    }
  }

  @override
  Future<void> dispose() async {
    _replace(
      CameraStatus(
        lifecycle: CameraLifecycle.disposed,
        permission: _status.permission,
      ),
    );
    await _changes.close();
  }

  CameraFailure _fail(CameraFailure failure) {
    _replace(
      CameraStatus(
        lifecycle: CameraLifecycle.failed,
        permission: _status.permission,
        request: _status.request,
        failure: failure,
      ),
    );
    return failure;
  }

  void _set({CameraLifecycle? lifecycle, CameraPermission? permission}) =>
      _replace(
        CameraStatus(
          lifecycle: lifecycle ?? _status.lifecycle,
          permission: permission ?? _status.permission,
          request: _status.request,
          capabilities: _status.capabilities,
          failure: _status.failure,
        ),
      );

  void _replace(CameraStatus status) {
    _status = status;
    if (!_changes.isClosed) _changes.add(status);
  }
}

/// Committed originals in memory. A small real JPEG stands in for each
/// photo; [damage] makes one fail its checksum when read back.
final class SimulatedStillStore implements CapturedStillStore {
  SimulatedStillStore({this.recovery = const OriginalsRecovery()});

  /// What [reconcile] reports.
  OriginalsRecovery recovery;
  var reconciliations = 0;

  final _stills = <CapturedStill>[];
  final _bytes = <String, Uint8List>{};

  /// Committed originals, oldest first.
  List<CapturedStill> get stills => List.unmodifiable(_stills);

  /// The stand-in photo: 64 x 48 pixels of a soft gradient.
  static final Uint8List photoBytes = () {
    const width = 64;
    const height = 48;
    final rgba = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        rgba
          ..[i] = 200 + x ~/ 2
          ..[i + 1] = 170 + y
          ..[i + 2] = 140
          ..[i + 3] = 255;
      }
    }
    return encodeJpeg(rgba, width: width, height: height);
  }();

  CapturedStill commit({
    required CameraLens lens,
    required int sensorOrientationDegrees,
    required bool mirrorPreview,
    required bool mirrorOutput,
    required DateTime capturedAtUtc,
    CaptureOrigin origin = CaptureOrigin.session,
  }) {
    final id = 'still-${_stills.length + 1}';
    final still = CapturedStill(
      id: id,
      relativePath: 'originals/$id.jpg',
      widthPx: 64,
      heightPx: 48,
      byteLength: photoBytes.length,
      sha256: id.padRight(64, '0'),
      lens: lens,
      sensorOrientationDegrees: sensorOrientationDegrees,
      mirrorPreviewRequested: mirrorPreview,
      mirrorOutputRequested: mirrorOutput,
      capturedAtUtc: capturedAtUtc,
      deviceOrientation: CaptureOrientation.landscapeLeft,
      origin: origin,
    );
    _stills.add(still);
    _bytes[id] = photoBytes;
    return still;
  }

  /// Makes [still] read back as missing or changed.
  void damage(CapturedStill still) => _bytes.remove(still.id);

  @override
  Future<List<CapturedStill>> listCommitted({int? limit}) async {
    final newest = _stills.reversed.toList();
    return limit == null ? newest : newest.take(limit).toList();
  }

  @override
  Future<Uint8List> read(CapturedStill still) async {
    final bytes = _bytes[still.id];
    if (bytes == null) {
      throw const CameraFailure(
        CameraFailureCode.originalNotPersisted,
        detail: 'missing',
      );
    }
    return bytes;
  }

  @override
  Future<OriginalsRecovery> reconcile() async {
    reconciliations++;
    return recovery;
  }
}

/// Free space as the tablet would report it; null when it cannot say.
final class FakeDeviceStorage implements DeviceStorageInfo {
  FakeDeviceStorage({this.free = 64 * 1024 * 1024 * 1024});

  int? free;

  @override
  Future<int?> freeBytes() async => free;
}

/// The live preview of the simulated camera: an abstract warm scene (no
/// people), labelled with its mirroring so tests can read it.
Widget simulatedPreview(BuildContext context, {required bool mirror}) =>
    Semantics(
      container: true,
      label: mirror ? 'Simulated preview, mirrored' : 'Simulated preview',
      child: const SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8C7A64), Color(0xFF3B3129)],
            ),
          ),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.32,
              heightFactor: 0.56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x33F3EDE3),
                  borderRadius: BorderRadius.all(Radius.circular(120)),
                ),
              ),
            ),
          ),
        ),
      ),
    );

/// A stopwatch that always reads [elapsed], so measured times in screens
/// and goldens are repeatable.
final class FixedStopwatch implements Stopwatch {
  FixedStopwatch([this.elapsed = const Duration(milliseconds: 4)]);

  @override
  final Duration elapsed;

  @override
  void start() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
