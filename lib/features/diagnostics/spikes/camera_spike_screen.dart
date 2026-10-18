import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_providers.dart';
import '../../../domain/services/camera_service.dart';

/// Operator-facing explanation and repair steps for [failure].
String describeCameraFailure(CameraFailure failure) => switch (failure.code) {
  CameraFailureCode.permissionDenied =>
    'Camera access is off. iPad: Settings > Porcelain Photo Booth > Camera. '
        'Android: Settings > Apps > Porcelain Photo Booth > Permissions > '
        'Camera. Then open the camera again.',
  CameraFailureCode.permissionRestricted =>
    'Camera access is restricted by device management or Screen Time; an '
        'administrator must allow it.',
  CameraFailureCode.cameraUnavailable =>
    'No usable camera: none selected, not open, or in use by another app.',
  CameraFailureCode.initializationFailed =>
    'The camera could not start (${failure.detail}).',
  CameraFailureCode.captureBusy => 'A photo is already being taken.',
  CameraFailureCode.appNotActive =>
    'The app was not in the foreground, so no photo was taken.',
  CameraFailureCode.captureFailed =>
    'The camera failed to take the photo (${failure.detail}).',
  CameraFailureCode.originalNotPersisted =>
    'The photo could not be saved and verified (${failure.detail}); '
        'nothing was stored.',
};

/// Dev-only M01 camera spike (debug and profile builds only).
///
/// Opens a built-in camera through [CameraService], shows the live preview,
/// captures a still into managed storage and lists stored originals, which
/// must survive an app restart. Records everything AC-0106/AC-0107 need.
class CameraSpikeScreen extends ConsumerStatefulWidget {
  const CameraSpikeScreen({super.key});

  @override
  ConsumerState<CameraSpikeScreen> createState() => _CameraSpikeScreenState();
}

class _CameraSpikeScreenState extends ConsumerState<CameraSpikeScreen> {
  late final CameraService _camera;
  late final CapturedStillStore _store;
  late final AppLifecycleListener _appLifecycle;
  StreamSubscription<CameraLifecycle>? _states;

  var _state = CameraLifecycle.uninitialized;
  var _permission = CameraPermission.notDetermined;
  List<CameraDescriptor> _cameras = const [];
  String? _selectedId;
  var _mirrorPreview = true;
  var _mirrorOutput = false;
  CapturedStill? _last;
  Uint8List? _lastBytes;
  List<CapturedStill> _saved = const [];
  String? _message;

  @override
  void initState() {
    super.initState();
    _camera = ref.read(cameraServiceProvider);
    _store = ref.read(capturedStillStoreProvider);
    // The camera is released whenever the app stops being active (including
    // while a permission dialog is up) and reopened on return; the service
    // serialises these with any open or capture already in progress.
    _appLifecycle = AppLifecycleListener(
      onInactive: () => _run(_camera.suspend),
      onResume: () => _run(_camera.resume),
    );
    _states = _camera.lifecycle.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    unawaited(_run(_loadCameras));
    unawaited(_run(_loadSaved));
  }

  @override
  void dispose() {
    _appLifecycle.dispose();
    unawaited(_states?.cancel());
    unawaited(_camera.suspend());
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on CameraFailure catch (failure) {
      _say(describeCameraFailure(failure));
    } on Object catch (error) {
      _say('Unexpected error: $error');
    }
    final permission = await _camera.permission();
    if (mounted) setState(() => _permission = permission);
  }

  void _say(String message) {
    if (mounted) setState(() => _message = message);
  }

  Future<void> _loadCameras() async {
    final cameras = await _camera.availableCameras();
    final preferred =
        cameras.where((c) => c.lens == CameraLens.front).firstOrNull ??
        cameras.firstOrNull;
    if (!mounted) return;
    setState(() {
      _cameras = cameras;
      _selectedId ??= preferred?.id;
    });
  }

  Future<void> _loadSaved() async {
    final saved = await _store.listCommitted();
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _open() async {
    final id = _selectedId;
    if (id == null) return;
    await _camera.initialize(
      CameraRequest(
        cameraId: id,
        mirrorPreview: _mirrorPreview,
        mirrorOutput: _mirrorOutput,
      ),
    );
    _say('Camera ready.');
  }

  Future<void> _capture() async {
    final still = await _camera.captureStill();
    final bytes = await _store.read(still);
    if (mounted) {
      setState(() {
        _last = still;
        _lastBytes = bytes;
      });
    }
    _say('Saved and verified ${still.relativePath}.');
    await _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _state == CameraLifecycle.ready;
    final open = ready || _state == CameraLifecycle.capturing;
    final busy =
        _state == CameraLifecycle.initializing ||
        _state == CameraLifecycle.capturing;
    final textTheme = Theme.of(context).textTheme;
    final last = _last;
    final lastBytes = _lastBytes;

    return Scaffold(
      appBar: AppBar(title: const Text('M01 camera spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Camera: ${_state.name} · permission: ${_permission.name}',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_cameras.isEmpty)
            const Text('No cameras reported yet.')
          else
            DropdownButton<String>(
              value: _selectedId,
              isExpanded: true,
              onChanged: busy ? null : (id) => setState(() => _selectedId = id),
              items: [
                for (final camera in _cameras)
                  DropdownMenuItem(
                    value: camera.id,
                    child: Text(
                      '${camera.lens.name} · sensor '
                      '${camera.sensorOrientationDegrees}° · ${camera.id}',
                    ),
                  ),
              ],
            ),
          SwitchListTile(
            title: const Text('Mirror preview (extra flip on top of platform)'),
            value: _mirrorPreview,
            onChanged: (value) => setState(() => _mirrorPreview = value),
          ),
          SwitchListTile(
            title: const Text(
              'Mirror saved output (recorded; applied at render)',
            ),
            value: _mirrorOutput,
            onChanged: busy
                ? null
                : (value) => setState(() => _mirrorOutput = value),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _selectedId == null || open || busy
                    ? null
                    : () => _run(_open),
                child: const Text('Open camera'),
              ),
              FilledButton(
                onPressed: ready ? () => _run(_capture) : null,
                child: const Text('Capture still'),
              ),
              OutlinedButton(
                onPressed: open ? () => _run(_camera.suspend) : null,
                child: const Text('Close camera'),
              ),
            ],
          ),
          if (_message case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(message),
            ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 360,
                child: Center(
                  child: ref.watch(cameraPreviewBuilderProvider)(
                    context,
                    mirror: _mirrorPreview,
                  ),
                ),
              ),
            ),
          if (last != null && lastBytes != null) ...[
            const SizedBox(height: 16),
            Text('Last capture', style: textTheme.titleMedium),
            Text(_describe(last)),
            const SizedBox(height: 8),
            SizedBox(height: 240, child: Image.memory(lastBytes)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Stored originals (${_saved.length}), re-verified from disk',
                  style: textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => _run(_loadSaved),
                child: const Text('Refresh'),
              ),
            ],
          ),
          for (final still in _saved) Text(_describe(still)),
        ],
      ),
    );
  }

  static String _describe(CapturedStill still) =>
      '${still.id}: ${still.widthPx}x${still.heightPx} decoded, '
      '${still.byteLength} bytes, EXIF orientation '
      '${still.exifOrientation ?? 'none'}, ${still.lens.name} lens, sensor '
      '${still.sensorOrientationDegrees}°, mirror preview '
      '${still.mirrorPreviewRequested}, mirror output '
      '${still.mirrorOutputRequested}, sha256 ${still.sha256.substring(0, 12)}…, '
      '${still.capturedAtUtc.toIso8601String()}';
}
