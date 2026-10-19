import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/services/booth_capabilities.dart';

/// [DeviceStorageInfo] over the app's own `porcelain/device_storage`
/// channel (ADR-0012): `StatFs` on Android, the volume's capacity for
/// important usage on iPadOS. Never throws; null when unknown. Also keeps
/// the booth's data out of the tablet's own backups (ADR-0016).
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

  /// Excludes [directory] and everything in it from iCloud and computer
  /// backups on iPadOS (`isExcludedFromBackup`); Android's manifest already
  /// keeps app data out of cloud backup and device transfer. Throws
  /// [PlatformException] when the tablet refuses.
  Future<void> excludeFromBackup(Directory directory) => _channel
      .invokeMethod<void>('excludeFromBackup', {'path': directory.path});
}
