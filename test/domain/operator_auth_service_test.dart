// AC-0301: PIN set-up, verification, rate limiting and recovery, with no
// plaintext secret stored anywhere.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/repositories/operator_access_repository.dart';
import 'package:porcelain_photo_booth/domain/services/operator_auth_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_secrets.dart';
import 'package:porcelain_photo_booth/infrastructure/security/pbkdf2_pin_hasher.dart';

import '../support/fakes.dart';

const pin = '482916';

typedef Rig = ({
  OperatorAuthService auth,
  MemoryPinVerifierStore pins,
  MemoryOperatorAccessRepository access,
  FakeClock clock,
});

Rig rig({PinHasher? hasher}) {
  final pins = MemoryPinVerifierStore();
  final access = MemoryOperatorAccessRepository();
  final clock = FakeClock();
  return (
    auth: OperatorAuthService(
      pins: pins,
      access: access,
      hasher: hasher ?? FastTestHasher(),
      clock: clock,
    ),
    pins: pins,
    access: access,
    clock: clock,
  );
}

/// Sets up [pin] and stores the recovery verifier as the setup flow does.
Future<String> enrol(Rig r) async {
  final credentials = await r.auth.setUp(pin);
  r.access.record = OperatorAccessRecord(
    recoveryVerifier: credentials.recoveryVerifier,
  );
  return credentials.recoveryCode;
}

void main() {
  test('setup stores slow salted verifiers, never the PIN or code', () async {
    final r = rig(hasher: Pbkdf2PinHasher(iterations: 1000, useIsolate: false));
    final code = await enrol(r);
    final stored = [r.pins.value!, r.access.record.recoveryVerifier!];
    for (final verifier in stored) {
      expect(verifier, startsWith(r'pbkdf2-sha256$1000$'));
      expect(verifier, isNot(contains(pin)));
      expect(verifier, isNot(contains(RecoveryCodes.normalise(code)!)));
    }
    expect(await r.auth.verifyPin(pin), isA<AccessGranted>());
  });

  test('setup refuses a guessable PIN and stores nothing', () async {
    final r = rig();
    await expectLater(
      r.auth.setUp('123456'),
      throwsA(isA<PinRejectedException>()),
    );
    expect(r.pins.value, isNull);
  });

  test('a wrong PIN counts down, then locks for growing periods', () async {
    final r = rig();
    await enrol(r);
    for (var left = 4; left >= 1; left--) {
      final result = await r.auth.verifyPin('111222');
      expect(result, isA<AccessDenied>());
      expect((result as AccessDenied).attemptsBeforeLockout, left);
      expect(result.lockout, Duration.zero);
    }
    final fifth = await r.auth.verifyPin('111222') as AccessDenied;
    expect(fifth.lockout, const Duration(seconds: 30));

    // Even the right PIN is not checked while locked.
    final locked = await r.auth.verifyPin(pin);
    expect(locked, isA<AccessLockedOut>());
    expect((locked as AccessLockedOut).retryAfter, const Duration(seconds: 30));

    r.clock.advance(const Duration(seconds: 31));
    final sixth = await r.auth.verifyPin('111222') as AccessDenied;
    expect(sixth.lockout, const Duration(minutes: 1));

    r.clock.advance(const Duration(minutes: 1, seconds: 1));
    expect(await r.auth.verifyPin(pin), isA<AccessGranted>());
    expect(r.access.record.pinAttempts, AttemptHistory.none);
  });

  test(
    'the lockout is stored, so restarting the app does not reset it',
    () async {
      final r = rig();
      await enrol(r);
      for (var i = 0; i < 5; i++) {
        await r.auth.verifyPin('000111');
      }
      // A new service over the same stores: what a restart sees.
      final restarted = OperatorAuthService(
        pins: r.pins,
        access: r.access,
        hasher: FastTestHasher(),
        clock: r.clock,
      );
      final status = await restarted.pinStatus();
      expect(status.retryAfter, const Duration(seconds: 30));
      expect(status.attemptsBeforeLockout, 0);
      expect(await restarted.verifyPin(pin), isA<AccessLockedOut>());
    },
  );

  test('simultaneous attempts are checked one at a time', () async {
    final r = rig();
    await enrol(r);
    final results = await Future.wait([
      for (var i = 0; i < 7; i++) r.auth.verifyPin('000111'),
    ]);
    expect(results.whereType<AccessDenied>(), hasLength(5));
    expect(results.whereType<AccessLockedOut>(), hasLength(2));
    expect(r.access.record.pinAttempts.failures, 5);
  });

  test('an unreadable or missing PIN is reported, never accepted', () async {
    final r = rig();
    await enrol(r);
    r.pins.failReads = true;
    final unreadable = await r.auth.verifyPin(pin);
    expect(
      (unreadable as CredentialUnavailable).problem,
      CredentialProblem.unreadable,
    );
    r.pins
      ..failReads = false
      ..value = null;
    final missing = await r.auth.verifyPin(pin);
    expect(
      (missing as CredentialUnavailable).problem,
      CredentialProblem.missing,
    );
    expect((await r.auth.pinStatus()).available, isFalse);
  });

  test('the recovery code resets the PIN and is then replaced', () async {
    final r = rig();
    final code = await enrol(r);
    for (var i = 0; i < 5; i++) {
      await r.auth.verifyPin('000111');
    }
    expect(await r.auth.verifyPin(pin), isA<AccessLockedOut>());

    final granted = await r.auth.verifyRecoveryCode(code.toLowerCase());
    expect(granted, isA<AccessGranted>());
    final proof = (granted as AccessGranted).proof;
    await r.auth.replacePin(proof, '905172');
    final newCode = await r.auth.replaceRecoveryCode(proof);

    expect(newCode, isNot(code));
    expect(await r.auth.verifyPin('905172'), isA<AccessGranted>());
    expect(await r.auth.verifyPin(pin), isA<AccessDenied>());
    expect(
      await r.auth.verifyRecoveryCode(code),
      isA<AccessDenied>(),
      reason: 'the used code no longer works',
    );
    expect(await r.auth.verifyRecoveryCode(newCode), isA<AccessGranted>());
  });

  test('recovery codes have their own, stricter lockout', () async {
    final r = rig();
    await enrol(r);
    for (var i = 0; i < 3; i++) {
      expect(
        await r.auth.verifyRecoveryCode('0000-0000-0000-0000'),
        isA<AccessDenied>(),
      );
    }
    expect(
      await r.auth.verifyRecoveryCode('0000-0000-0000-0000'),
      isA<AccessLockedOut>(),
    );
    expect(await r.auth.verifyPin(pin), isA<AccessGranted>());
  });

  test('without a stored recovery code, recovery is unavailable', () async {
    final r = rig();
    await r.auth.setUp(pin);
    expect(
      await r.auth.verifyRecoveryCode('K7QM-2XRD-9BWE-H4TC'),
      isA<CredentialUnavailable>(),
    );
    expect(await r.auth.hasRecoveryCode(), isFalse);
  });

  test('changing the PIN needs a fresh proof from this service', () async {
    final r = rig();
    await enrol(r);
    final proof = (await r.auth.verifyPin(pin) as AccessGranted).proof;
    expect(r.auth.accepts(proof), isTrue);

    final other = rig();
    expect(other.auth.accepts(proof), isFalse);
    await expectLater(
      other.auth.replacePin(proof, '905172'),
      throwsA(isA<ProofRejectedException>()),
    );

    r.clock.advance(
      OperatorAuthService.proofLifetime + const Duration(seconds: 1),
    );
    expect(r.auth.accepts(proof), isFalse);
    await expectLater(
      r.auth.replacePin(proof, '905172'),
      throwsA(isA<ProofRejectedException>()),
    );
    expect(await r.auth.verifyPin(pin), isA<AccessGranted>());
  });

  test(
    'a weaker stored verifier is upgraded after a successful check',
    () async {
      final weak = Pbkdf2PinHasher(iterations: 500, useIsolate: false);
      final r = rig(hasher: weak);
      await enrol(r);
      final upgraded = OperatorAuthService(
        pins: r.pins,
        access: r.access,
        hasher: Pbkdf2PinHasher(iterations: 800, useIsolate: false),
        clock: r.clock,
      );
      expect(await upgraded.verifyPin(pin), isA<AccessGranted>());
      expect(r.pins.value, startsWith(r'pbkdf2-sha256$800$'));
      expect(await upgraded.verifyPin(pin), isA<AccessGranted>());
    },
  );
}
