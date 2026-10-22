import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../domain/models/booth_event.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/finished_photos.dart';
import '../../domain/session/session_plan.dart';
import '../../domain/session/session_shots.dart';
import '../../domain/template/template_assets.dart';

/// The Full Experience Preview's stand-ins (EP08): a sample camera, and
/// sessions, originals and finished photos kept in memory for as long as
/// the preview is open. Nothing here touches the booth's database, its
/// files, the real camera or the network, so a preview can never become
/// an event session, a gallery photo or a text.

/// A camera that "sees" a drawn sample scene and takes sample photos.
final class PreviewCameraService implements CameraService {
  PreviewCameraService(this.stills);

  final PreviewStillStore stills;

  static const _front = CameraDescriptor(
    id: 'preview-front',
    lens: CameraLens.front,
    sensorOrientationDegrees: 270,
  );
  static const _back = CameraDescriptor(
    id: 'preview-back',
    lens: CameraLens.back,
    sensorOrientationDegrees: 90,
  );

  final _changes = StreamController<CameraStatus>.broadcast();
  var _status = const CameraStatus(
    lifecycle: CameraLifecycle.uninitialized,
    permission: CameraPermission.granted,
  );
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
  Future<CameraPermission> permission() async => CameraPermission.granted;

  @override
  Future<CameraPermission> requestPermission() async =>
      CameraPermission.granted;

  @override
  Future<bool> openPermissionSettings() async => false;

  @override
  Future<List<CameraDescriptor>> availableCameras() async => const [
    _front,
    _back,
  ];

  @override
  Future<CameraCapabilities> initialize(CameraRequest request) async {
    final camera = request.cameraId == _back.id ? _back : _front;
    final capabilities = CameraCapabilities(
      camera: camera,
      previewWidthPx: 1600,
      previewHeightPx: 1200,
      minZoom: 1,
      maxZoom: 1,
      focusPointSupported: false,
      exposurePointSupported: false,
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
    final request = _status.request;
    final capabilities = _status.capabilities;
    if (_capturing) throw const CameraFailure(CameraFailureCode.captureBusy);
    if (!_status.isReady || request == null || capabilities == null) {
      throw const CameraFailure(CameraFailureCode.notReady);
    }
    _capturing = true;
    try {
      return await stills.add(
        await samplePhotoPng(stills.count),
        lens: capabilities.camera.lens,
        sensorOrientationDegrees: capabilities.camera.sensorOrientationDegrees,
        mirrorPreview: request.mirrorPreview,
        mirrorOutput: request.mirrorOutput,
        origin: origin,
      );
    } finally {
      _capturing = false;
    }
  }

  @override
  Future<void> suspend() async {
    if (_status.lifecycle == CameraLifecycle.ready) {
      _replace(
        CameraStatus(
          lifecycle: CameraLifecycle.suspended,
          permission: CameraPermission.granted,
          request: _status.request,
        ),
      );
    }
  }

  @override
  Future<void> resume() async {
    final request = _status.request;
    if (request != null && _status.lifecycle == CameraLifecycle.suspended) {
      await initialize(request);
    }
  }

  @override
  Future<void> dispose() async {
    _replace(
      const CameraStatus(
        lifecycle: CameraLifecycle.disposed,
        permission: CameraPermission.granted,
      ),
    );
    await _changes.close();
  }

  void _replace(CameraStatus status) {
    _status = status;
    if (!_changes.isClosed) _changes.add(status);
  }
}

/// Sample originals in memory, gone when the preview closes.
final class PreviewStillStore implements CapturedStillStore {
  final _stills = <String, (CapturedStill, Uint8List)>{};

  int get count => _stills.length;

  Future<CapturedStill> add(
    Uint8List png, {
    required CameraLens lens,
    required int sensorOrientationDegrees,
    required bool mirrorPreview,
    required bool mirrorOutput,
    required CaptureOrigin origin,
  }) async {
    final id = 'preview-photo-${_stills.length + 1}';
    final still = CapturedStill(
      id: id,
      relativePath: 'preview/$id.png',
      widthPx: samplePhotoSize.width.round(),
      heightPx: samplePhotoSize.height.round(),
      byteLength: png.length,
      sha256: sha256HexOf(png),
      lens: lens,
      sensorOrientationDegrees: sensorOrientationDegrees,
      mirrorPreviewRequested: mirrorPreview,
      mirrorOutputRequested: mirrorOutput,
      capturedAtUtc: DateTime.now().toUtc(),
      origin: origin,
    );
    _stills[id] = (still, png);
    return still;
  }

  @override
  Future<List<CapturedStill>> listCommitted({int? limit}) async {
    final all = [for (final (still, _) in _stills.values) still].reversed;
    return (limit == null ? all : all.take(limit)).toList();
  }

  @override
  Future<CapturedStill?> find(String id) async => _stills[id]?.$1;

  @override
  Future<Uint8List> read(CapturedStill still) async {
    final stored = _stills[still.id];
    if (stored == null) {
      throw const CameraFailure(CameraFailureCode.originalNotPersisted);
    }
    return stored.$2;
  }

  @override
  Future<OriginalsRecovery> reconcile() async => const OriginalsRecovery();
}

/// Sessions in memory, with the same rules a guest session follows.
final class MemorySessionRepository implements SessionRepository {
  final _sessions = <String, SessionRecord>{};
  final _outputs = <String, SessionOutput>{};

  /// Every session the preview ran, for its own tests.
  Iterable<SessionRecord> get sessions => _sessions.values;

  SessionRecord _session(String id) =>
      _sessions[id] ?? (throw const SessionStoreException('SESSION_NOT_FOUND'));

  void _put(
    SessionRecord s, {
    SessionStatus? status,
    List<ShotPhoto>? photos,
    DateTime? endedAtUtc,
    SessionEndReason? endReason,
    String? outputId,
    int? renderAttempts,
  }) => _sessions[s.id] = SessionRecord(
    id: s.id,
    number: s.number,
    plan: s.plan,
    status: status ?? s.status,
    photos: photos ?? s.photos,
    startedAtUtc: s.startedAtUtc,
    updatedAtUtc: DateTime.now().toUtc(),
    endedAtUtc: endedAtUtc ?? s.endedAtUtc,
    endReason: endReason ?? s.endReason,
    outputId: outputId ?? s.outputId,
    renderAttempts: renderAttempts ?? s.renderAttempts,
  );

  @override
  Future<void> create({
    required String id,
    required SessionPlan plan,
    required DateTime startedAtUtc,
  }) async {
    _sessions[id] = SessionRecord(
      id: id,
      number: _sessions.length + 1,
      plan: plan,
      status: SessionStatus.capturing,
      photos: const [],
      startedAtUtc: startedAtUtc,
      updatedAtUtc: startedAtUtc,
    );
  }

  @override
  Future<void> addPhoto(String sessionId, ShotPhoto photo) async {
    final s = _session(sessionId);
    _put(s, photos: [...s.photos, photo], status: SessionStatus.capturing);
  }

  @override
  Future<void> markReviewing(String sessionId) async =>
      _put(_session(sessionId), status: SessionStatus.reviewing);

  @override
  Future<int> beginRender(String sessionId) async {
    final s = _session(sessionId);
    final attempt = s.renderAttempts + 1;
    _put(s, status: SessionStatus.rendering, renderAttempts: attempt);
    return attempt;
  }

  @override
  Future<SessionOutput> complete(String sessionId, ExportedFile output) async {
    final s = _session(sessionId);
    final recorded = _record(sessionId, output, SessionOutputOrigin.session);
    _put(
      s,
      status: SessionStatus.completed,
      outputId: recorded.id,
      endedAtUtc: recorded.createdAtUtc,
    );
    return recorded;
  }

  @override
  Future<SessionOutput> addRerender(
    String sessionId,
    ExportedFile output,
  ) async {
    _session(sessionId);
    return _record(sessionId, output, SessionOutputOrigin.rerender);
  }

  SessionOutput _record(
    String sessionId,
    ExportedFile output,
    SessionOutputOrigin origin,
  ) => _outputs[output.id] = SessionOutput(
    id: output.id,
    sessionId: sessionId,
    relativePath: output.relativePath,
    sha256: output.sha256,
    byteLength: output.byteLength,
    widthPx: output.widthPx,
    heightPx: output.heightPx,
    format: output.format,
    renderVersion: output.renderVersion,
    createdAtUtc: DateTime.now().toUtc(),
    origin: origin,
  );

  @override
  Future<void> end(
    String sessionId, {
    required SessionStatus status,
    required SessionEndReason reason,
  }) async => _put(
    _session(sessionId),
    status: status,
    endReason: reason,
    endedAtUtc: DateTime.now().toUtc(),
  );

  @override
  Future<SessionRecord?> find(String sessionId) async => _sessions[sessionId];

  @override
  Future<List<SessionRecord>> unfinished() async => [
    for (final s in _sessions.values)
      if (s.status == SessionStatus.capturing ||
          s.status == SessionStatus.reviewing ||
          s.status == SessionStatus.rendering)
        s,
  ];

  @override
  Future<SessionOutput?> output(String outputId) async => _outputs[outputId];

  @override
  Future<List<SessionOutput>> outputs(String sessionId) async => [
    for (final o in _outputs.values)
      if (o.sessionId == sessionId) o,
  ];
}

/// Finished photos rendered by the real print renderer, at screen size
/// (the scene is the same; full print size is not needed to look at it),
/// and kept in memory.
final class PreviewExportService implements ExportService, FinishedPhotos {
  PreviewExportService(this.renderer);

  final CompositionRenderer renderer;
  final _files = <String, Uint8List>{};

  @override
  Future<ExportedFile> export(
    TemplateRender render, {
    OutputProfile output = const OutputProfile(),
    int flattenArgb = 0xFFFFFFFF,
  }) async {
    final artifact = await renderer.renderPreview(
      render,
      maxWidthPx: 1200,
      maxHeightPx: 1200,
    );
    final id = 'preview-output-${_files.length + 1}';
    final path = 'preview/$id.png';
    _files[path] = artifact.bytes;
    return ExportedFile(
      id: id,
      relativePath: path,
      sha256: sha256HexOf(artifact.bytes),
      byteLength: artifact.bytes.length,
      widthPx: artifact.widthPx,
      heightPx: artifact.heightPx,
      format: artifact.format,
      renderVersion: rendererVersion,
      warnings: artifact.warnings,
      stats: artifact.stats,
    );
  }

  @override
  Future<Uint8List> read({
    required String relativePath,
    required String sha256,
  }) async =>
      _files[relativePath] ??
      (throw const FinishedPhotoUnreadable('preview photo not found'));
}

/// The sample photos' size: 4:3 landscape, as tablet cameras take them.
const samplePhotoSize = Size(1200, 900);

/// Sample photo [index]: a warm studio backdrop with a soft figure, a
/// different tint each time, so the review shows distinct photos. Drawn,
/// never a stock or guest picture.
Future<Uint8List> samplePhotoPng(int index) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paintSampleScene(canvas, samplePhotoSize, index: index);
  final image = await recorder.endRecording().toImage(
    samplePhotoSize.width.round(),
    samplePhotoSize.height.round(),
  );
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// The sample scene in [size]: also the preview camera's live picture.
void paintSampleScene(Canvas canvas, Size size, {int index = 0}) {
  final hue = (28 + index * 47) % 360.0;
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
        HSLColor.fromAHSL(1, hue, 0.35, 0.72).toColor(),
        HSLColor.fromAHSL(1, (hue + 40) % 360, 0.3, 0.42).toColor(),
      ]),
  );
  final figure = HSLColor.fromAHSL(0.55, hue, 0.15, 0.92).toColor();
  final unit = math.min(size.width, size.height);
  final centre = Offset(size.width / 2, size.height * 0.42);
  canvas
    ..drawCircle(centre, unit * 0.14, Paint()..color = figure)
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.9),
          width: unit * 0.56,
          height: unit * 0.6,
        ),
        Radius.circular(unit * 0.2),
      ),
      Paint()..color = figure,
    );
}

/// The preview camera's live picture: the sample scene, mirrored when the
/// event mirrors its preview.
Widget previewCameraPicture(BuildContext context, {required bool mirror}) =>
    Semantics(
      container: true,
      label: 'Sample camera picture',
      child: Transform.flip(
        flipX: mirror,
        child: const SizedBox.expand(
          child: CustomPaint(painter: _SampleScenePainter()),
        ),
      ),
    );

class _SampleScenePainter extends CustomPainter {
  const _SampleScenePainter();

  @override
  void paint(Canvas canvas, Size size) => paintSampleScene(canvas, size);

  @override
  bool shouldRepaint(_SampleScenePainter oldDelegate) => false;
}
