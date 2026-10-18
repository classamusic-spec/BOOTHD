import 'package:flutter/services.dart';

import '../../domain/services/booth_capabilities.dart';

/// [DeviceStorageInfo] over the app's own `porcelain/device_storage`
/// channel (ADR-0012): `StatFs` on Android, the volume's capacity for
/// important usage on iPadOS. Never throws; null when unknown.
final class PlatformDeviceStorage implements DeviceStorageInfo {
  const PlatformDeviceStorage();

  static const _channel = MethodChannel('porcelain/device_storage');

  @override
  Future<int?> freeBytes() async {
    try {
      final bytes = await _channel.invokeMethod<int>('freeBytes');
      return bytes == null || bytes < 0 ? null : bytes;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
