/// Whether the tablet is locked to the booth app, as the operating system
/// reports it (M10, ADR-0016). Read only: the app never turns a lock on or
/// off; the tablet's own kiosk features do (docs/KIOSK_DEPLOYMENT.md).
library;

enum KioskLock {
  /// Not locked: guests could leave the app.
  none,

  /// iPadOS Guided Access. Single App Mode from device management is
  /// expected to be reported the same way (checked on a supervised iPad in
  /// M11).
  guidedAccess,

  /// Android app pinning. Leaving needs a gesture, and the device PIN only
  /// when "Ask for PIN before unpinning" is on, which the app cannot see.
  pinned,

  /// Android lock task mode, started by a device management service.
  managed,

  /// The tablet did not say.
  unknown;

  /// The operating system reports the app locked in front.
  bool get locked => switch (this) {
    guidedAccess || pinned || managed => true,
    none || unknown => false,
  };
}

/// Reads the operating system's kiosk lock state (ADR-0016).
abstract interface class KioskLockInfo {
  /// The lock as the tablet reports it now. Never throws.
  Future<KioskLock> current();
}
