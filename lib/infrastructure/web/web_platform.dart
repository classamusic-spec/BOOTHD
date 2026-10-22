import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/operator_files.dart';

/// Browser adapters for the booth's platform ports (ADR-0018).

/// Free space as the browser estimates it (quota less usage); null when
/// the browser cannot say.
final class WebDeviceStorage implements DeviceStorageInfo {
  const WebDeviceStorage();

  @override
  Future<int?> freeBytes() async {
    try {
      final estimate = await web.window.navigator.storage.estimate().toDart;
      final quota = estimate.quota;
      final usage = estimate.usage;
      if (quota <= 0) return null;
      return (quota - usage).clamp(0, quota);
    } on Object {
      return null;
    }
  }
}

/// Asks the browser to keep this site's storage (photos, events) instead
/// of clearing it when space runs low. Returns whether it agreed.
Future<bool> requestPersistentStorage() async {
  try {
    final storage = web.window.navigator.storage;
    if ((await storage.persisted().toDart).toDart) return true;
    return (await storage.persist().toDart).toDart;
  } on Object {
    return false;
  }
}

/// Camera permission through the browser: the Permissions API where it
/// answers for the camera, and a short `getUserMedia` call to ask.
final class WebCameraPermissions implements CameraPermissions {
  const WebCameraPermissions();

  @override
  Future<CameraPermission> status() async {
    try {
      final result = await web.window.navigator.permissions
          .query({'name': 'camera'}.jsify()! as JSObject)
          .toDart;
      return switch (result.state) {
        'granted' => CameraPermission.granted,
        'denied' => CameraPermission.permanentlyDenied,
        _ => CameraPermission.notDetermined,
      };
    } on Object {
      // Safari and Firefox may not answer for the camera: asking is the
      // only way to know.
      return CameraPermission.notDetermined;
    }
  }

  @override
  Future<CameraPermission> request() async {
    try {
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(video: true.toJS))
          .toDart;
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
      return CameraPermission.granted;
    } on Object catch (error) {
      // A rejected promise's DOMException reads 'NotAllowedError: ...'.
      final name = '$error';
      return name.contains('NotAllowed') || name.contains('Security')
          ? CameraPermission.permanentlyDenied
          : CameraPermission.restricted;
    }
  }

  /// A browser has no app settings page; the address bar's site settings
  /// are the way (the screens say so).
  @override
  Future<bool> openSettings() async => false;
}

/// Offers files to the operator from the browser: the system share sheet
/// where the browser can share files (phones and tablets), otherwise a
/// download per file. A download's outcome is unknown to the page.
Future<ShareReport> offerFilesInBrowser(
  List<({String name, Uint8List bytes, String mimeType})> files,
) async {
  final navigator = web.window.navigator;
  final shareable = [
    for (final file in files)
      web.File(
        [file.bytes.toJS].toJS,
        file.name,
        web.FilePropertyBag(type: file.mimeType),
      ),
  ];
  final data = web.ShareData(files: shareable.toJS);
  var canShare = false;
  try {
    canShare = navigator.canShare(data);
  } on Object {
    canShare = false;
  }
  if (canShare) {
    try {
      await navigator.share(data).toDart;
      return const ShareReport(ShareOutcome.shared);
    } on Object catch (error) {
      // A rejected promise's DOMException reads 'NotAllowedError: ...'.
      final name = '$error';
      if (name.contains('Abort')) {
        return const ShareReport(ShareOutcome.dismissed);
      }
      // Fall through to downloads (e.g. not allowed without a tap).
    }
  }
  for (final file in files) {
    downloadInBrowser(file.bytes, fileName: file.name, mimeType: file.mimeType);
  }
  return const ShareReport(ShareOutcome.unknown);
}

/// Saves [bytes] as a download named [fileName].
void downloadInBrowser(
  Uint8List bytes, {
  required String fileName,
  required String mimeType,
}) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  // Give the browser time to start the download before releasing it.
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}
