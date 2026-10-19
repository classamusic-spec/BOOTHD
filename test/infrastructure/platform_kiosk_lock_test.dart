// AC-1002: the kiosk lock is read from the app's own read-only channel
// (ADR-0016) and anything the tablet does not clearly report is "unknown",
// never "locked". The native side has one method, lockState, and nothing
// that starts or stops a lock.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/kiosk_lock.dart';
import 'package:porcelain_photo_booth/infrastructure/device/platform_kiosk_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('porcelain/kiosk');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;

  void answer(Object? Function() reply) =>
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return reply();
      });

  setUp(() => calls = []);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('each state the tablet reports', () async {
    for (final (reply, lock) in [
      ('none', KioskLock.none),
      ('guidedAccess', KioskLock.guidedAccess),
      ('pinned', KioskLock.pinned),
      ('managed', KioskLock.managed),
      ('unknown', KioskLock.unknown),
    ]) {
      answer(() => reply);
      expect(await const PlatformKioskLock().current(), lock, reason: reply);
    }
    expect(calls.toSet(), {'lockState'}, reason: 'it only ever reads');
  });

  test('anything else is unknown, never locked', () async {
    for (final reply in <Object? Function()>[
      () => 'LOCKED',
      () => null,
      () => throw PlatformException(code: 'unavailable'),
    ]) {
      answer(reply);
      final lock = await const PlatformKioskLock().current();
      expect(lock, KioskLock.unknown);
      expect(lock.locked, isFalse);
    }
  });

  test('a platform without the channel is unknown', () async {
    messenger.setMockMethodCallHandler(channel, null);
    expect(await const PlatformKioskLock().current(), KioskLock.unknown);
  });

  test('only Guided Access, pinning and lock task count as locked', () {
    expect(
      [
        for (final lock in KioskLock.values)
          if (lock.locked) lock,
      ],
      [KioskLock.guidedAccess, KioskLock.pinned, KioskLock.managed],
    );
  });
}
