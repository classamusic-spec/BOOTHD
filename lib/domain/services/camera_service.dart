/// The camera boundary (ADR-0002, ADR-0012; A-04, A-09).
///
/// Implemented by `ManagedCameraService` over the `camera` plugin, and by
/// `SimulatedCameraService` for tests and hardware-free screens. Guest and
/// operator UI never call a camera plugin directly.
library;

import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A physical camera position as reported by the platform.
enum CameraLens { front, back, external }

/// Camera permission as the platform reports it.
enum CameraPermission {
  /// Not allowed yet; asking shows the system prompt.
  notDetermined,
  granted,

  /// Refused when asked; asking again may still show the prompt (Android).
  denied,

  /// Refused for good: only the system Settings can turn it back on.
  permanentlyDenied,

  /// Blocked by device management or parental controls; the operator
  /// cannot change it on the tablet.
  restricted;

  /// Whether asking would show the system prompt.
  bool get canAsk => this == notDetermined || this == denied;

  /// The launch-check and self-test code; null when [granted].
  String? get problemCode => switch (this) {
    granted => null,
    notDetermined => 'CAMERA_PERMISSION_NOT_ASKED',
    denied => 'CAMERA_PERMISSION_DENIED',
    permanentlyDenied => 'CAMERA_PERMISSION_PERMANENTLY_DENIED',
    restricted => 'CAMERA_PERMISSION_RESTRICTED',
  };
}

/// Lifecycle of the camera session owned by a [CameraService].
enum CameraLifecycle {
  uninitialized,
  initializing,
  ready,
  capturing,

  /// Released because the app left the foreground; [CameraService.resume]
  /// opens it again.
  suspended,
  failed,
  disposed,
}

/// Why a camera operation failed (A-14 `CAMERA_*` codes).
enum CameraFailureCode {
  permissionDenied('CAMERA_PERMISSION_DENIED'),
  permissionPermanentlyDenied('CAMERA_PERMISSION_PERMANENTLY_DENIED'),
  permissionRestricted('CAMERA_PERMISSION_RESTRICTED'),

  /// The tablet reports no usable camera.
  noCamera('CAMERA_NONE'),

  /// The requested camera is not (or no longer) available.
  cameraUnavailable('CAMERA_UNAVAILABLE'),

  /// Another app or the system holds the camera.
  cameraInUse('CAMERA_IN_USE'),
  initializationFailed('CAMERA_INIT_FAILED'),

  /// A capture was requested while another was in flight; captures are
  /// serialised, never queued behind the guest's back.
  captureBusy('CAMERA_CAPTURE_BUSY'),

  /// The app was not in the foreground; no shutter fires until it is.
  appNotActive('CAMERA_APP_NOT_ACTIVE'),

  /// The camera is not open (not initialised, suspended or failed).
  notReady('CAMERA_NOT_READY'),
  captureFailed('CAMERA_CAPTURE_FAILED'),

  /// The system interrupted the camera (another app, multitasking, a call).
  interrupted('CAMERA_INTERRUPTED'),

  /// The still could not be decoded, validated or durably committed;
  /// nothing was saved.
  originalNotPersisted('CAMERA_ORIGINAL_NOT_SAVED');

  const CameraFailureCode(this.diagnostic);

  /// The `CAMERA_*` code shown to operators and in sanitised logs.
  final String diagnostic;
}

/// A camera operation failed. [code] selects guest-safe and operator copy.
final class CameraFailure implements Exception {
  const CameraFailure(this.code, {this.detail});

  final CameraFailureCode code;

  /// Sanitised technical detail for operator diagnostics. Never shown to
  /// guests and never contains photo data or file system paths.
  final String? detail;

  @override
  String toString() => 'CameraFailure(${code.diagnostic})';
}

/// A camera the device exposes.
@immutable
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

  @override
  bool operator ==(Object other) =>
      other is CameraDescriptor &&
      other.id == id &&
      other.lens == lens &&
      other.sensorOrientationDegrees == sensorOrientationDegrees;

  @override
  int get hashCode => Object.hash(id, lens, sensorOrientationDegrees);
}

/// The camera a booth uses for a preferred lens (AC-0602, A-09): the
/// platform's first camera of that lens (its primary one), else the first
/// of the other built-in lens with a [fellBack] note. External cameras are
/// never chosen: their placement and behaviour are unknown.
@immutable
final class CameraChoice {
  const CameraChoice(this.camera, {required this.preferred});

  /// Null when the tablet has no built-in camera.
  final CameraDescriptor? camera;
  final CameraLens preferred;

  bool get fellBack => camera != null && camera!.lens != preferred;

  static CameraChoice of(List<CameraDescriptor> cameras, CameraLens preferred) {
    CameraDescriptor? first(CameraLens lens) =>
        cameras.where((c) => c.lens == lens).firstOrNull;
    final other = preferred == CameraLens.front
        ? CameraLens.back
        : CameraLens.front;
    return CameraChoice(
      first(preferred == CameraLens.external ? CameraLens.front : preferred) ??
          first(other),
      preferred: preferred,
    );
  }
}

/// What the open camera offers (A-04), measured when it opened.
@immutable
final class CameraCapabilities {
  const CameraCapabilities({
    required this.camera,
    required this.previewWidthPx,
    required this.previewHeightPx,
    required this.minZoom,
    required this.maxZoom,
    required this.focusPointSupported,
    required this.exposurePointSupported,
  });

  final CameraDescriptor camera;

  /// The preview stream's size as the sensor delivers it (usually
  /// landscape); the preview widget rotates it for the screen.
  final int previewWidthPx;
  final int previewHeightPx;
  final double minZoom;
  final double maxZoom;
  final bool focusPointSupported;
  final bool exposurePointSupported;

  /// Long side over short side: the preview's shape whatever the screen's
  /// orientation.
  double get previewAspectRatio {
    final long = previewWidthPx > previewHeightPx
        ? previewWidthPx
        : previewHeightPx;
    final short = previewWidthPx > previewHeightPx
        ? previewHeightPx
        : previewWidthPx;
    return short == 0 ? 1 : long / short;
  }
}

/// The camera configuration a booth asks for. [mirrorPreview] means guests
/// see themselves as in a mirror (whatever the platform does by default);
/// [mirrorOutput] means the printed photo is mirrored. They are
/// independent (CR-001 fix 5), and output mirroring is applied once, when
/// rendering, never to the stored original (A-07).
@immutable
final class CameraRequest {
  const CameraRequest({
    required this.cameraId,
    required this.mirrorPreview,
    required this.mirrorOutput,
  });

  final String cameraId;
  final bool mirrorPreview;
  final bool mirrorOutput;

  @override
  bool operator ==(Object other) =>
      other is CameraRequest &&
      other.cameraId == cameraId &&
      other.mirrorPreview == mirrorPreview &&
      other.mirrorOutput == mirrorOutput;

  @override
  int get hashCode => Object.hash(cameraId, mirrorPreview, mirrorOutput);
}

/// Everything a screen needs to show about the camera, as one value.
@immutable
final class CameraStatus {
  const CameraStatus({
    required this.lifecycle,
    required this.permission,
    this.request,
    this.capabilities,
    this.failure,
  });

  static const initial = CameraStatus(
    lifecycle: CameraLifecycle.uninitialized,
    permission: CameraPermission.notDetermined,
  );

  final CameraLifecycle lifecycle;
  final CameraPermission permission;

  /// The last configuration asked for; kept while suspended.
  final CameraRequest? request;

  /// Set while the camera is open.
  final CameraCapabilities? capabilities;

  /// Why the camera last failed; cleared when it opens again.
  final CameraFailure? failure;

  bool get isReady => lifecycle == CameraLifecycle.ready;
}

/// How the device was held when a still was taken. With the sensor
/// orientation and the file's EXIF tag it explains the stored pixels.
enum CaptureOrientation {
  portraitUp,
  landscapeLeft,
  portraitDown,
  landscapeRight,
  unknown,
}

/// Why a still was taken.
enum CaptureOrigin {
  /// A camera test in Diagnostics.
  diagnostics,

  /// A guest session (M07).
  session,

  /// Saved by the M01 spike before originals were in the database.
  legacy,
}

/// An original still that has been decoded, validated and committed to
/// managed storage with its record. Originals are immutable: a retake is a
/// new [CapturedStill], never an overwrite.
@immutable
final class CapturedStill {
  const CapturedStill({
    required this.id,
    required this.relativePath,
    required this.widthPx,
    required this.heightPx,
    required this.byteLength,
    required this.sha256,
    required this.lens,
    required this.sensorOrientationDegrees,
    required this.mirrorPreviewRequested,
    required this.mirrorOutputRequested,
    required this.capturedAtUtc,
    this.exifOrientation,
    this.deviceOrientation = CaptureOrientation.unknown,
    this.origin = CaptureOrigin.diagnostics,
  });

  final String id;

  /// Path relative to the managed app storage root; never absolute.
  final String relativePath;

  /// Size as decoded, with the file's EXIF orientation already applied by
  /// the platform decoder: orientation is normalised once, here (ADR-0007).
  final int widthPx;
  final int heightPx;

  final int byteLength;

  /// Lowercase hex SHA-256 of the stored bytes.
  final String sha256;

  final CameraLens lens;
  final int sensorOrientationDegrees;

  /// The booth's mirroring settings at capture time. The stored pixels are
  /// exactly what the camera produced; output mirroring is applied once,
  /// at render time (ARCHITECTURE A-07).
  final bool mirrorPreviewRequested;
  final bool mirrorOutputRequested;

  final DateTime capturedAtUtc;

  /// EXIF orientation tag (1–8) if the file has one.
  final int? exifOrientation;
  final CaptureOrientation deviceOrientation;
  final CaptureOrigin origin;

  @override
  bool operator ==(Object other) =>
      other is CapturedStill && other.id == id && other.sha256 == sha256;

  @override
  int get hashCode => Object.hash(id, sha256);
}

/// What startup recovery found among unfinished saves (A-11).
@immutable
final class OriginalsRecovery {
  const OriginalsRecovery({
    this.finished = 0,
    this.undone = 0,
    this.adopted = 0,
    this.quarantined = 0,
  });

  /// Saves whose file was complete, recorded now.
  final int finished;

  /// Saves that never wrote a complete file; their intent was dropped.
  final int undone;

  /// Originals the M01 spike saved before originals were recorded.
  final int adopted;

  /// Files that failed their checks, moved aside (never deleted).
  final int quarantined;

  bool get changedAnything => finished + undone + adopted + quarantined > 0;
}

/// Committed originals, which survive app restarts.
abstract interface class CapturedStillStore {
  /// Committed originals, newest first, at most [limit].
  Future<List<CapturedStill>> listCommitted({int? limit});

  /// The committed original [id], or null.
  Future<CapturedStill?> find(String id);

  /// The stored bytes of [still], verified against its checksum. Throws
  /// [CameraFailure] ([CameraFailureCode.originalNotPersisted]) when the
  /// file is missing or changed.
  Future<Uint8List> read(CapturedStill still);

  /// At startup, before any capture: finishes or undoes saves the app
  /// never finished. Never deletes an original.
  Future<OriginalsRecovery> reconcile();
}

/// Camera permission on the platform (ADR-0012).
abstract interface class CameraPermissions {
  Future<CameraPermission> status();

  /// Shows the system prompt when it can; returns the outcome.
  Future<CameraPermission> request();

  /// Opens this app's page in the system Settings; false if it could not.
  Future<bool> openSettings();
}

/// The only route from the app to built-in tablet cameras.
///
/// Implementations own the plugin lifecycle; serialise [initialize],
/// [captureStill], [suspend], [resume] and [dispose]; refuse to capture
/// while the app is not active; never queue a capture; and return a
/// [CapturedStill] only after the file has been decoded, validated and
/// durably committed. Failures throw [CameraFailure].
abstract interface class CameraService {
  /// The current status.
  CameraStatus get status;

  /// The current status, then every change.
  Stream<CameraStatus> get statusChanges;

  Future<CameraPermission> permission();

  /// Asks for camera permission (the system prompt, when it can).
  Future<CameraPermission> requestPermission();

  /// Opens the app's page in the system Settings, to repair a permanent
  /// denial; false if it could not.
  Future<bool> openPermissionSettings();

  Future<List<CameraDescriptor>> availableCameras();

  /// Opens the camera in [request]. Asks for permission first if it was
  /// never asked. Idempotent for the same request while ready.
  Future<CameraCapabilities> initialize(CameraRequest request);

  /// Takes one still, as [origin]. Throws
  /// [CameraFailureCode.captureBusy] at once while another is in flight.
  Future<CapturedStill> captureStill({
    CaptureOrigin origin = CaptureOrigin.session,
  });

  /// Releases the camera (the app left the foreground).
  Future<void> suspend();

  /// Re-checks permission and re-opens the last request after [suspend]
  /// or an interruption. Never takes a photo.
  Future<void> resume();

  Future<void> dispose();
}
