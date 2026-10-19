import 'package:flutter/foundation.dart';

import '../../domain/services/kiosk_lock.dart';

/// One way to lock a tablet to the booth app (docs/KIOSK_DEPLOYMENT.md).
@immutable
final class KioskMethod {
  const KioskMethod({
    required this.title,
    required this.goodFor,
    required this.steps,
    required this.note,
  });

  final String title;
  final String goodFor;
  final List<String> steps;
  final String note;
}

/// Words operators read about kiosk locks (M10, AC-1002). The booth app
/// reads the lock; only the tablet turns it on or off.
abstract final class KioskCopy {
  static bool _ipad(TargetPlatform platform) => platform == TargetPlatform.iOS;

  /// The lock in a few words.
  static String state(KioskLock lock) => switch (lock) {
    KioskLock.guidedAccess => 'Locked to the booth app',
    KioskLock.pinned => 'Pinned to the booth app',
    KioskLock.managed => 'Locked by device management',
    KioskLock.none => 'Guests can leave the booth app',
    KioskLock.unknown => "The tablet didn't say",
  };

  static String badge(KioskLock lock) => lock.locked
      ? 'Locked'
      : lock == KioskLock.none
      ? 'Not locked'
      : 'Unknown';

  /// What the lock means for guests.
  static String explain(KioskLock lock) => switch (lock) {
    KioskLock.guidedAccess =>
      'iPadOS reports Guided Access (or Single App Mode) is on: guests '
          "can't leave the booth app.",
    KioskLock.pinned =>
      'Android reports the booth app is pinned. Keep "Ask for PIN before '
          'unpinning" on, or a guest could unpin it.',
    KioskLock.managed =>
      'Android reports lock task mode from your device management '
          "service: guests can't leave the booth app.",
    KioskLock.none =>
      'The Home gesture, the app switcher and notifications all still '
          'work.',
    KioskLock.unknown =>
      "The tablet didn't say whether it is locked to this app. Check it "
          'yourself before guests arrive.',
  };

  /// What to do when the tablet is not locked, in one sentence.
  static String turnOn(TargetPlatform platform) => _ipad(platform)
      ? 'Turn on Guided Access (or Single App Mode) before guests arrive.'
      : 'Pin the booth app (or use lock task) before guests arrive.';

  /// The tablet's own ways to lock it to one app.
  static List<KioskMethod> methods(TargetPlatform platform) =>
      _ipad(platform) ? _ipadMethods : _androidMethods;

  static const _ipadMethods = [
    KioskMethod(
      title: 'Guided Access',
      goodFor: 'Any iPad, nothing to install. For events you run yourself.',
      steps: [
        'Settings > Accessibility > Guided Access: on. Set a passcode that '
            'is not the booth PIN.',
        'Open the booth and triple-click the top button (or the Home '
            'button), then Start.',
        'To end it, triple-click and enter the Guided Access passcode.',
      ],
      note: 'A restart ends Guided Access: start it again after one.',
    ),
    KioskMethod(
      title: 'Single App Mode',
      goodFor:
          'Supervised iPads with device management. For rental fleets and '
          'long installations.',
      steps: [
        'Supervise the iPad with Apple Configurator or Apple Business '
            'Manager (this erases it).',
        'In your device management service, install a Single App Mode '
            'profile for Porcelain Photo Booth.',
        'The iPad then starts in the booth, even after a restart.',
      ],
      note: 'Remove the profile in the management service to end it.',
    ),
  ];

  static const _androidMethods = [
    KioskMethod(
      title: 'App pinning',
      goodFor:
          'Any Android tablet with a screen lock. For events you run '
          'yourself.',
      steps: [
        'Settings > Security > App pinning (the name varies by maker): on, '
            'with "Ask for PIN before unpinning".',
        "Open Recents, tap the booth app's icon and choose Pin.",
        'To unpin, hold Back and Overview (or use the gesture the tablet '
            'shows), then enter the device PIN.',
      ],
      note: 'A restart unpins the app: pin it again after one.',
    ),
    KioskMethod(
      title: 'Lock task (managed)',
      goodFor:
          'Fully managed tablets. For rental fleets and long installations.',
      steps: [
        'Enrol the tablet as fully managed with your device management '
            'service (usually after a factory reset).',
        'Apply a single-app kiosk policy that allows Porcelain Photo '
            'Booth.',
        'The tablet then starts in the booth, even after a restart.',
      ],
      note: 'Change the policy in the management console to end it.',
    ),
  ];
}
