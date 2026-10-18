/// DRAFT camera boundary (ADR-0002). Placeholder contract only.
///
/// Nothing implements or reads this interface in M00. The M01 spike
/// implements it with the `camera` plugin and may revise it; M06 hardens and
/// finalises it. Guest UI never calls a camera plugin directly.
library;

/// A physical camera position as reported by the platform.
enum CameraLens { front, back, external }

/// Camera permission as last observed by the platform adapter.
enum CameraPermission {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

/// Lifecycle of the camera session owned by a [CameraService].
enum CameraLifecycle {
  uninitialized,
  initializing,
  ready,
  capturing,
  suspended,
  failed,
  disposed,
}

/// Why a camera operation failed. Each value maps to a `CAMERA_*` diagnostic
/// code (ARCHITECTURE A-14).
enum CameraFailureCode {
  permissionDenied,
  permissionRestricted,
  cameraUnavailable,
  initializationFailed,

  /// A capture was requested while another was in flight; captures are
  /// serialised, never queued behind the guest's back.
  captureBusy,

  /// The app left the foreground; no shutter may fire until it returns.
  appNotActive,
  captureFailed,

  /// The still could not be decoded, validated or durably committed.
  originalNotPersisted,
}

/// A camera operation failed. [code] selects guest-safe and operator copy.
final class CameraFailure implements Exception {
  const CameraFailure(this.code, {this.detail});

  final CameraFailureCode code;

  /// Sanitised technical detail for operator diagnostics. Never shown to
  /// guests and never contains photo data or file system paths.
  final String? detail;

  @override
  String toString() => 'CameraFailure(${code.name})';
}

/// A camera the device exposes.
final class CameraDescriptor {
  const CameraDescriptor({
    required this.id,
    required this.lens,
    required this.sensorOrientationDegrees,
  });

  final String id;
  final CameraLens lens;

  /// Clockwise rotation of the sensor relative to the device's natural
  /// orientation.
  final int sensorOrientationDegrees;
}

/// The camera configuration a booth asks for. Preview mirroring and saved
/// output mirroring are independent settings.
final class CameraRequest {
  const CameraRequest({
    required this.cameraId,
    required this.mirrorPreview,
    required this.mirrorOutput,
  });

  final String cameraId;
  final bool mirrorPreview;
  final bool mirrorOutput;
}

/// An original still that has been decoded, validated and committed to
/// managed storage. Originals are immutable: a retake is a new
/// [CapturedStill], never an overwrite.
final class CapturedStill {
  const CapturedStill({
    required this.relativePath,
    required this.widthPx,
    required this.heightPx,
    required this.lens,
    required this.mirrorApplied,
    required this.capturedAtUtc,
  });

  /// Path relative to the managed originals directory; never absolute.
  final String relativePath;
  final int widthPx;
  final int heightPx;
  final CameraLens lens;
  final bool mirrorApplied;
  final DateTime capturedAtUtc;
}

/// The only route from the app to built-in tablet cameras.
///
/// Implementations own the plugin lifecycle; serialise [initialize],
/// [captureStill], [suspend] and [dispose]; refuse to capture while the app
/// is not active; and return a [CapturedStill] only after the file has been
/// decoded, validated and durably committed. Failures throw [CameraFailure].
abstract interface class CameraService {
  /// The current lifecycle state, then every change.
  Stream<CameraLifecycle> get lifecycle;

  Future<CameraPermission> permission();

  Future<List<CameraDescriptor>> availableCameras();

  Future<void> initialize(CameraRequest request);

  Future<CapturedStill> captureStill();

  /// Releases the camera when the app leaves the foreground.
  Future<void> suspend();

  /// Re-checks permission and idempotently re-opens the last request.
  Future<void> resume();

  Future<void> dispose();
}
