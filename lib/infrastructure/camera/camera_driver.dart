import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../../domain/services/camera_service.dart';

/// A failure reported by the camera plugin, with its raw error [code]
/// (for example `CameraAccessDenied`). [ManagedCameraService] maps codes to
/// [CameraFailure]s.
final class CameraDriverException implements Exception {
  const CameraDriverException(this.code, [this.description]);

  final String code;
  final String? description;

  @override
  String toString() => 'CameraDriverException($code)';
}

/// The thin seam between the camera service and the plugin, so lifecycle,
/// serialisation and storage logic can be tested without a camera.
abstract interface class CameraDriver {
  Future<List<CameraDescriptor>> listCameras();

  Future<void> open(CameraDescriptor camera);

  /// Takes one still and returns its encoded bytes. The plugin's temporary
  /// file is deleted, so no guest photo lingers outside managed storage.
  Future<Uint8List> capture();

  Future<void> close();
}

/// [CameraDriver] over the maintained `camera` plugin (CameraX on Android,
/// AVFoundation on iPadOS). Spike-grade (M01).
final class PluginCameraDriver implements CameraDriver {
  final _controller = ValueNotifier<CameraController?>(null);
  Map<String, CameraDescription> _descriptions = const {};

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
      throw CameraDriverException(error.code, error.description);
    }
  }

  @override
  Future<void> open(CameraDescriptor camera) async {
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
    );
    try {
      await controller.initialize();
    } on CameraException catch (error) {
      await controller.dispose();
      throw CameraDriverException(error.code, error.description);
    }
    try {
      // The booth flashes the screen instead; many front cameras have no
      // flash, which the plugin reports as an error worth ignoring.
      await controller.setFlashMode(FlashMode.off);
    } on CameraException {
      // No flash unit.
    }
    _controller.value = controller;
  }

  @override
  Future<Uint8List> capture() async {
    final controller = _controller.value;
    if (controller == null) throw const CameraDriverException('notOpen');
    final XFile file;
    try {
      file = await controller.takePicture();
    } on CameraException catch (error) {
      throw CameraDriverException(error.code, error.description);
    }
    try {
      return await file.readAsBytes();
    } finally {
      final temporary = File(file.path);
      if (temporary.existsSync()) await temporary.delete();
    }
  }

  @override
  Future<void> close() async {
    final controller = _controller.value;
    _controller.value = null;
    await controller?.dispose();
  }

  /// The live preview for dev-only diagnostics. The plugin keeps the sensor
  /// aspect ratio, so the preview is not stretched; [mirror] adds a
  /// horizontal flip on top of whatever the platform already does.
  Widget buildPreview(BuildContext context, {required bool mirror}) =>
      ValueListenableBuilder<CameraController?>(
        valueListenable: _controller,
        builder: (context, controller, _) => controller == null
            ? const SizedBox.shrink()
            : Transform.flip(flipX: mirror, child: CameraPreview(controller)),
      );
}
