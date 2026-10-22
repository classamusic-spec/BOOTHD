import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../domain/services/camera_service.dart';

/// A failure reported by the camera plugin, with its error [code] (for
/// example `CameraAccessDenied`). [ManagedCameraService] maps codes to
/// [CameraFailure]s. Plugin descriptions are free text and may name the
/// device; only codes leave this layer.
final class CameraDriverException implements Exception {
  const CameraDriverException(this.code);

  final String code;

  @override
  String toString() => 'CameraDriverException($code)';
}

/// One still from the driver: the encoded bytes and how the device was
/// held.
final class DriverStill {
  const DriverStill(this.bytes, this.orientation);

  final Uint8List bytes;
  final CaptureOrientation orientation;
}

/// The seam between the camera service and the plugin, so lifecycle,
/// serialisation and storage logic can be tested without a camera.
abstract interface class CameraDriver {
  Future<List<CameraDescriptor>> listCameras();

  /// Opens [camera] (closing any other) and measures what it offers.
  Future<CameraCapabilities> open(CameraDescriptor camera);

  /// Takes one still. The plugin's temporary file is deleted, so no guest
  /// photo lingers outside managed storage.
  Future<DriverStill> capture();

  Future<void> close();

  /// Errors the open camera reports by itself: an interruption, another
  /// app taking the camera.
  Stream<CameraDriverException> get errors;
}

/// The platform's own preview mirroring: both plugin implementations
/// mirror the front camera's preview and no other (camera_avfoundation
/// 0.10.3+1 `DefaultCamera.swift`, camera_android_camerax 0.7.5+1
/// `image_reader_rotated_preview.dart`). Saved stills are not mirrored.
/// Device runs confirm it (M06 procedure).
bool platformMirrorsPreview(CameraLens lens) => lens == CameraLens.front;

/// The horizontal flip to add to the platform's preview so guests see
/// themselves mirrored exactly when [mirror] asks for it.
bool previewFlipFor(CameraLens lens, {required bool mirror}) =>
    mirror != platformMirrorsPreview(lens);

/// Sorts a plugin camera error description into a code. The CameraX
/// plugin reports camera state errors only as English text.
String classifyCameraErrorDescription(String? description) {
  final text = (description ?? '').toLowerCase();
  if (text.contains('already in use') || text.contains('open cameras')) {
    return 'cameraInUse';
  }
  if (text.contains('do not disturb')) return 'doNotDisturb';
  if (text.contains('device policy')) return 'cameraDisabled';
  if (text.contains('fatal')) return 'cameraFatal';
  return 'cameraInterrupted';
}

CaptureOrientation captureOrientationOf(DeviceOrientation orientation) =>
    switch (orientation) {
      DeviceOrientation.portraitUp => CaptureOrientation.portraitUp,
      DeviceOrientation.landscapeLeft => CaptureOrientation.landscapeLeft,
      DeviceOrientation.portraitDown => CaptureOrientation.portraitDown,
      DeviceOrientation.landscapeRight => CaptureOrientation.landscapeRight,
    };

/// [CameraDriver] over the maintained `camera` plugin (CameraX on Android,
/// AVFoundation on iPadOS).
final class PluginCameraDriver implements CameraDriver {
  final _controller = ValueNotifier<CameraController?>(null);
  final _errors = StreamController<CameraDriverException>.broadcast();
  Map<String, CameraDescription> _descriptions = const {};
  CameraLens _lens = CameraLens.front;
  String? _lastError;

  @override
  Stream<CameraDriverException> get errors => _errors.stream;

  @override
  Future<List<CameraDescriptor>> listCameras() async {
    try {
      final cameras = await availableCameras();
      _descriptions = {for (final camera in cameras) camera.name: camera};
      return [
        for (final camera in cameras)
          CameraDescriptor(
            id: camera.name,
            lens: switch (camera.lensDirection) {
              CameraLensDirection.front => CameraLens.front,
              CameraLensDirection.back => CameraLens.back,
              CameraLensDirection.external => CameraLens.external,
            },
            sensorOrientationDegrees: camera.sensorOrientation,
          ),
      ];
    } on CameraException catch (error) {
      throw CameraDriverException(error.code);
    }
  }

  @override
  Future<CameraCapabilities> open(CameraDescriptor camera) async {
    await close();
    final description = _descriptions[camera.id];
    if (description == null) {
      throw const CameraDriverException('cameraNotFound');
    }
    // Stills only: audio stays off, so no microphone permission is needed.
    final controller = CameraController(
      description,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
    } on CameraException catch (error) {
      await controller.dispose();
      throw CameraDriverException(error.code);
    } on Object {
      await controller.dispose();
      rethrow;
    }
    try {
      // The booth flashes the screen instead; many front cameras have no
      // flash, which the plugin reports as an error worth ignoring.
      await controller.setFlashMode(FlashMode.off);
    } on CameraException {
      // No flash unit.
    }
    final double minZoom;
    final double maxZoom;
    try {
      minZoom = await controller.getMinZoomLevel();
      maxZoom = await controller.getMaxZoomLevel();
    } on CameraException catch (error) {
      await controller.dispose();
      throw CameraDriverException(error.code);
    }
    _lastError = null;
    controller.addListener(() => _watch(controller));
    _lens = camera.lens;
    _controller.value = controller;
    final value = controller.value;
    final preview = value.previewSize;
    return CameraCapabilities(
      camera: camera,
      previewWidthPx: preview?.width.round() ?? 0,
      previewHeightPx: preview?.height.round() ?? 0,
      minZoom: minZoom,
      maxZoom: maxZoom,
      focusPointSupported: value.focusPointSupported,
      exposurePointSupported: value.exposurePointSupported,
    );
  }

  /// Passes on each new error the open camera reports.
  void _watch(CameraController controller) {
    if (!identical(controller, _controller.value)) return;
    final description = controller.value.errorDescription;
    if (description == null || description == _lastError) return;
    _lastError = description;
    if (!_errors.isClosed) {
      _errors.add(
        CameraDriverException(classifyCameraErrorDescription(description)),
      );
    }
  }

  @override
  Future<DriverStill> capture() async {
    final controller = _controller.value;
    if (controller == null) throw const CameraDriverException('notOpen');
    final orientation = captureOrientationOf(
      controller.value.deviceOrientation,
    );
    final XFile file;
    try {
      file = await controller.takePicture();
    } on CameraException catch (error) {
      throw CameraDriverException(error.code);
    }
    try {
      return DriverStill(await file.readAsBytes(), orientation);
    } finally {
      // In the browser the picture is a blob URL, not a file to remove.
      if (!kIsWeb) {
        final temporary = File(file.path);
        if (temporary.existsSync()) await temporary.delete();
      }
    }
  }

  @override
  Future<void> close() async {
    final controller = _controller.value;
    _controller.value = null;
    await controller?.dispose();
  }

  /// The live preview: never stretched (the plugin keeps the stream's
  /// aspect ratio), mirrored exactly when [mirror] asks for it, whatever
  /// the platform does by default.
  Widget buildPreview(BuildContext context, {required bool mirror}) =>
      ValueListenableBuilder<CameraController?>(
        valueListenable: _controller,
        builder: (context, controller, _) => controller == null
            ? const SizedBox.shrink()
            : Transform.flip(
                flipX: previewFlipFor(_lens, mirror: mirror),
                child: CameraPreview(controller),
              ),
      );
}
