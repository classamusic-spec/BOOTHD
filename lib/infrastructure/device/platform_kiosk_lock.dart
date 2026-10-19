import 'package:flutter/services.dart';

import '../../domain/services/kiosk_lock.dart';

/// [KioskLockInfo] over the app's own `porcelain/kiosk` channel
/// (ADR-0016): `ActivityManager.getLockTaskModeState` on Android,
/// `UIAccessibility.isGuidedAccessEnabled` on iPadOS. Read only; never
/// throws.
final class PlatformKioskLock implements KioskLockInfo {
  const PlatformKioskLock();

  static const _channel = MethodChannel('porcelain/kiosk');

  @override
  Future<KioskLock> current() async {
    try {
      return switch (await _channel.invokeMethod<String>('lockState')) {
        'none' => KioskLock.none,
        'guidedAccess' => KioskLock.guidedAccess,
        'pinned' => KioskLock.pinned,
        'managed' => KioskLock.managed,
        _ => KioskLock.unknown,
      };
    } on PlatformException {
      return KioskLock.unknown;
    } on MissingPluginException {
      return KioskLock.unknown;
    }
  }
}
